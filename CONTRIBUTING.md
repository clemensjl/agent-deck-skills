# Beitragen

Die Registry besteht aus `index.json`. Ein Beitrag ist in der Regel ein neuer oder korrigierter Eintrag dort.

## Eintrag vorschlagen

1. Repository forken und einen Branch anlegen.
2. Die `SKILL.md` des Ziel-Repos öffnen und `name` und `description` aus dem Frontmatter übernehmen, nicht raten. `subdir` ist der Pfad zum Ordner mit der `SKILL.md`.
3. Eintrag in `index.json` ergänzen. Felder und Format stehen im [README](./README.md#format-version-1). Die `description` ist deutsch, sachlich und ohne Superlative, die `id` ist eindeutig und ändert sich später nicht.
4. JSON prüfen:

   ```bash
   python -c "import json; json.load(open('index.json', encoding='utf-8'))"
   ```

5. Pull Request gegen `main` öffnen, mit Link auf den Skill.

Der Eintrag muss auf ein existierendes Repo und Verzeichnis mit gültiger `SKILL.md` zeigen. Das prüft agent-deck erst beim Klick auf "Installieren".

## Eintrag melden

Ist ein Repo verschwunden, ein Pfad verschoben oder eine Beschreibung falsch, genügt ein Issue mit der `id` des Eintrags.

Mit dem Pull Request stimmst du zu, dass dein Beitrag unter der [MIT-Lizenz](./LICENSE) steht. Die verlinkten Skills behalten ihre eigene Lizenz.
