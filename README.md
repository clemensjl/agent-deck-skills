# agent-deck-skills

Kuratierte Skill-Registry für agent-deck ("Entdecken" → Meilenstein S4).

`index.json` in diesem Repo wird von agent-deck geladen unter:

```
https://raw.githubusercontent.com/clemensjl/agent-deck-skills/main/index.json
```

Ist die Datei nicht erreichbar (Repo existiert noch nicht, offline, 404,
kaputtes JSON, leeres `entries`-Array), fällt agent-deck automatisch auf einen
gebündelten Seed im eigenen Code zurück (`src/shared/skill-registry-data.ts`)
— "Entdecken" bricht dadurch nie.

## Format (Version 1)

```json
{
  "version": 1,
  "entries": [
    {
      "id": "design-taste-frontend",
      "repo": "Leonxlnx/taste-skill",
      "subdir": "skills/taste-skill",
      "name": "design-taste-frontend",
      "description": "Deutsche Kurzbeschreibung, nüchtern, keine Superlative.",
      "category": "design",
      "tags": ["frontend", "landingpage"],
      "featured": true
    }
  ]
}
```

Felder:

- `id` — stabiler Slug, eindeutig im Index. Änderungen brechen bestehende
  Installationen nicht (die merken sich `owner/repo/subdir`, nicht die
  Registry-`id`), verwirren aber die UI-Historie — nicht ohne Grund ändern.
- `repo` — `"owner/name"` des GitHub-Repos, das den Skill enthält.
- `subdir` — Pfad zum Ordner mit der `SKILL.md`, relativ zum Repo-Root.
  Weglassen (oder `""`), wenn die `SKILL.md` direkt im Root liegt.
- `name` / `description` — wie in "Entdecken" angezeigt. `description`
  deutsch, sachlich, keine Superlative.
- `category` — freier Slug. agent-deck kennt feste deutsche Labels für
  `design`, `motion`, `web-qualitaet`, `marketing`, `3d`, `methodik`,
  `dokumente`, `dev-tools`, `sonstiges` — ein unbekannter Slug wird einfach
  roh als Chip-Label angezeigt (kein Absturz bei neuen Kategorien).
- `tags` — freie Suchbegriffe, Array von Strings.
- `featured` — `true` = erscheint oben in der Featured-Sektion.

## Robustheit

agent-deck parst defensiv: unbekannte Zusatzfelder werden ignoriert, einzelne
kaputte Einträge (fehlendes Pflichtfeld, `repo` nicht im Format
`owner/name`) werden übersprungen statt den ganzen Index zu verwerfen,
doppelte `id`s werden auf das erste Vorkommen reduziert. Ein Eintrag muss
trotzdem *tatsächlich* auf ein existierendes Repo/Verzeichnis mit gültiger
`SKILL.md` zeigen — das prüft agent-deck erst beim Klick auf "Installieren"
(GitHub-API-Aufruf, gleicher Durchsicht-Flow wie bei der freien
GitHub-Suche).

## Pflege

- Neue Einträge: `SKILL.md`-Frontmatter des Ziel-Repos verifizieren (echter
  `name`, echte `description`), nicht raten.
- Reihenfolge in `entries` ist beliebig — die UI gruppiert selbst nach
  `featured`/`category`.
- Ein Eintrag entfernen bricht keine bestehende Installation (die läuft über
  `github:<owner>/<repo>/<pfad>` weiter) — nur die Sichtbarkeit in
  "Entdecken" verschwindet.
