---
name: secret-drop
description: Use when a task needs confidential values from the user — passwords, WLAN keys, API keys, tokens, credentials, private data — or when about to ask the user to type/paste a secret into the chat. Secrets must never enter the conversation, transcript, or model context.
---

# secret-drop

## Overview

Secrets vom User holen, ohne dass sie je in Chat, Transcript oder Modell-Kontext landen. Der User füllt Platzhalter-Dateien in `Downloads\SECRET-DROP\`, ein Skript konsumiert die Werte prozess-intern, danach wird der Ordner geschreddert.

**Kernprinzip: Der Wert darf nie durch Claude laufen — weder rein (User tippt in Chat) noch raus (Claude liest Datei).**

Alle Aktionen über: `powershell -File ~\.claude\skills\secret-drop\scripts\secret-drop.ps1 -Action <action> ...`

## Workflow

1. **init** — Platzhalter anlegen:
   `-Action init -Secrets 'wlan_password=WLAN-Passwort für HomeNet;api_key=Resend API-Key'` (`;`-getrennt, ein String)
2. **Tutorial sofort ausgeben** (Blocker-First, als **[DU MUSST MACHEN]**): Ordner `Downloads\SECRET-DROP` öffnen, jede .txt ausfüllen, speichern. Nicht auf Turn-Ende warten.
3. **wait** — `-Action wait -TimeoutSec 900` im Hintergrund laufen lassen (`run_in_background`), parallel weiterarbeiten an allem, was ohne Secret geht. `check` für einmaligen Poll.
4. **Konsumieren** (genau einer der zwei Wege, nie selbst lesen):
   - `-Action inject -Target <datei>` — ersetzt `{{name}}`-Tokens in einer Config/einem Script durch die Werte.
   - `-Action env -Command '<befehl>'` — führt Befehl mit Env-Vars `SECRET_<NAME>` aus.
5. **destroy** — sofort nach erfolgreicher Verwendung: `-Action destroy`. 3× Überschreiben + Löschen. Erst nach `DESTROY OK` weiterarbeiten.

## Eiserne Regeln

- **NIE** Dateien in SECRET-DROP mit Read, `cat`, `type`, `Get-Content` in die Ausgabe holen — auch nicht "nur zum Prüfen des Formats". Prüfen = `check` (zeigt nur Namen).
- **NIE** den User bitten, einen Secret-Wert in den Chat zu tippen — auch nicht als "Option B", auch nicht mit Warnhinweis.
- **NIE** eine Datei, in die injected wurde, danach mit Read öffnen. Verifikation nur boolesch (Datei existiert, Token weg: `Select-String -Quiet '{{'`).
- **NIE** die inject-Zieldatei mit dem Write- oder Edit-Tool anlegen/ändern — das Harness trackt solche Dateien und injiziert nach dem inject den Inhalt (mit Klartext-Secret) automatisch in den Kontext. Zieldatei nur per Shell anlegen (`Set-Content`/Heredoc).
- **NIE** Secret-Werte in Befehlszeilen-Argumente schreiben (landen im Transcript). Nur inject/env.
- **destroy ist Pflicht**, direkt nach Verwendung — nicht am Turn-Ende, nicht "später".

## Rote Flaggen — STOPP

| Gedanke | Realität |
|---|---|
| "Ich lese kurz, ob das Format stimmt" | Wert im Kontext = geleakt. `check` reicht. |
| "User kann's auch einfach in den Chat tippen" | Chat = Klartext in Session-History + bei Anthropic. Genau das verhindert dieser Skill. |
| "Ordner lösche ich am Ende der Session" | Sofort nach Verwendung. Session kann abbrechen. |
| "Der Wert ist eh nicht so geheim" | Nicht deine Entscheidung. User hat Drop gewählt = vertraulich. |
| "Zieldatei leg ich schnell mit Write an" | Write/Edit = Harness-Tracking = Secret landet nach inject im Kontext. Nur Shell. |

## Grenzen (dem User ehrlich sagen)

- Muss der Wert dauerhaft in eine Datei (z.B. Config), liegt er dort im Klartext — Drop schützt nur den Übertragungsweg.
- SSD/NTFS: Überschreiben ist Best-Effort-Schreddern.
