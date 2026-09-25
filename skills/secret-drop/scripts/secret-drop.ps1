# secret-drop.ps1 — Secrets vom User holen, ohne dass Werte je in Chat/Transcript landen.
# Werte existieren nur innerhalb dieses Skript-Prozesses. Ausgaben enthalten NIE Secret-Werte.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('init', 'check', 'wait', 'inject', 'env', 'destroy')]
    [string]$Action,

    # init: Liste "name=Beschreibung" (name: a-z0-9_-)
    [string[]]$Secrets,

    [string]$Drop = "$env:USERPROFILE\Downloads\SECRET-DROP",

    # inject: Zieldatei, in der {{name}}-Tokens ersetzt werden
    [string]$Target,

    # env: Befehl, der mit SECRET_<NAME>-Env-Vars laeuft
    [string]$Command,

    [int]$TimeoutSec = 900
)

$ErrorActionPreference = 'Stop'
$PLACEHOLDER_PREFIX = '<<HIER-EINTRAGEN'

function Get-SecretFiles {
    Get-ChildItem -Path $Drop -Filter '*.txt' -File |
        Where-Object { $_.Name -ne '_ANLEITUNG.txt' }
}

function Test-Filled {
    param($File)
    $raw = [IO.File]::ReadAllText($File.FullName).Trim()
    return ($raw.Length -gt 0 -and -not $raw.StartsWith($PLACEHOLDER_PREFIX))
}

function Get-SecretValue {
    param($File)
    # Wert nur prozess-intern verwenden, NIE ausgeben.
    # Trim([char]0xFEFF): BOM aus Editor-Saves entfernen (U+FEFF ist kein Whitespace fuer Trim()).
    return [IO.File]::ReadAllText($File.FullName).Trim([char]0xFEFF).Trim()
}

switch ($Action) {

    'init' {
        if (-not $Secrets -or $Secrets.Count -eq 0) { throw "init braucht -Secrets 'name=Beschreibung;name2=...'" }
        New-Item -ItemType Directory -Force -Path $Drop | Out-Null
        # powershell -File flacht Arrays ab -> auch ';'-getrennte Einzelstrings akzeptieren
        $entries = $Secrets | ForEach-Object { $_ -split ';' } | Where-Object { $_.Trim() }
        $names = @()
        foreach ($s in $entries) {
            $name, $desc = $s -split '=', 2
            if ($name -notmatch '^[a-z0-9_-]+$') { throw "Ungueltiger Name '$name' (erlaubt: a-z 0-9 _ -)" }
            if (-not $desc) { $desc = $name }
            Set-Content -Path (Join-Path $Drop "$name.txt") -Value "$PLACEHOLDER_PREFIX`: $desc>>" -Encoding utf8
            $names += $name
        }
        $anleitung = @(
            'SECRET-DROP — vertrauliche Werte sicher an Claude uebergeben'
            '============================================================'
            ''
            '1. Oeffne jede .txt-Datei in diesem Ordner.'
            '2. Loesche die <<HIER-EINTRAGEN...>>-Zeile und fuege NUR den echten Wert ein.'
            '3. Speichern. Fertig — Claude erkennt es automatisch.'
            ''
            'Claude liest diese Dateien NIE direkt. Ein Skript verwendet die Werte'
            'lokal und schreddert den Ordner danach automatisch.'
        )
        Set-Content -Path (Join-Path $Drop '_ANLEITUNG.txt') -Value ($anleitung -join "`r`n") -Encoding utf8
        Write-Output "INIT OK: $Drop"
        Write-Output ("Platzhalter: " + ($names -join ', '))
    }

    'check' {
        $missing = @(Get-SecretFiles | Where-Object { -not (Test-Filled $_) } | ForEach-Object { $_.BaseName })
        if ($missing.Count -eq 0) { Write-Output 'READY' }
        else { Write-Output ("WAITING: " + ($missing -join ', ')); exit 1 }
    }

    'wait' {
        $deadline = (Get-Date).AddSeconds($TimeoutSec)
        while ((Get-Date) -lt $deadline) {
            $missing = @(Get-SecretFiles | Where-Object { -not (Test-Filled $_) })
            if ($missing.Count -eq 0) { Write-Output 'READY'; exit 0 }
            Start-Sleep -Seconds 5
        }
        Write-Output 'TIMEOUT'; exit 1
    }

    'inject' {
        if (-not $Target -or -not (Test-Path $Target)) { throw "inject braucht -Target <existierende Datei>" }
        $content = [IO.File]::ReadAllText($Target)
        $replaced = @()
        foreach ($f in Get-SecretFiles) {
            $token = '{{' + $f.BaseName + '}}'
            if ($content.Contains($token)) {
                $content = $content.Replace($token, (Get-SecretValue $f))
                $replaced += $f.BaseName
            }
        }
        [IO.File]::WriteAllText($Target, $content)
        Write-Output ("INJECT OK: " + ($replaced -join ', ') + " -> $Target")
        Write-Output "WARNUNG: Zieldatei enthaelt jetzt Klartext-Secrets. Diese Datei NICHT mit Read/cat oeffnen."
    }

    'env' {
        if (-not $Command) { throw "env braucht -Command '<Befehl>'" }
        $set = @()
        foreach ($f in Get-SecretFiles) {
            $var = 'SECRET_' + $f.BaseName.ToUpper().Replace('-', '_')
            Set-Item -Path "Env:$var" -Value (Get-SecretValue $f)
            $set += $var
        }
        Write-Output ("ENV gesetzt: " + ($set -join ', '))
        # Pipe-an-Native-Falle (PS 5.1): $OutputEncoding mit BOM-Preamble haengt U+FEFF vor
        # stdin-Daten (z.B. `$env:SECRET_X | gh secret set`). BOM-loses UTF-8 erzwingen.
        $OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        try {
            Invoke-Expression $Command
            $code = $LASTEXITCODE
        }
        finally {
            foreach ($v in $set) { Remove-Item -Path "Env:$v" -ErrorAction SilentlyContinue }
        }
        Write-Output "ENV entfernt. Exit-Code: $code"
        if ($code) { exit $code }
    }

    'destroy' {
        if (-not (Test-Path $Drop)) { Write-Output 'DESTROY OK: Ordner existierte nicht mehr'; break }
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        foreach ($f in Get-ChildItem -Path $Drop -File) {
            $len = [Math]::Max($f.Length, 256)
            for ($i = 0; $i -lt 3; $i++) {
                $bytes = New-Object byte[] $len
                $rng.GetBytes($bytes)
                [IO.File]::WriteAllBytes($f.FullName, $bytes)
            }
        }
        Remove-Item -Path $Drop -Recurse -Force
        if (Test-Path $Drop) { throw 'DESTROY FEHLGESCHLAGEN: Ordner existiert noch' }
        Write-Output 'DESTROY OK: alle Dateien 3x ueberschrieben, Ordner geloescht'
    }
}
