# claude-cmd

Een zsh-widget die tekst omzet naar een shell-commando, of een bestaand commando aanpast, via de Claude CLI (`claude -p`, standaard Haiku).

## Features

| Toets | Wat |
|---|---|
| `⌃G` | Genereer 3 alternatieven uit de tekst in de buffer; het beste komt in de buffer. Aanpassen kan met `commando # instructie`. |
| `⌃G` (nogmaals) | Wissel tussen de 3 alternatieven, lokaal, zonder nieuwe call. |
| `⌃X e` | Leg het commando in de buffer uit (lege buffer: het vorige commando). Buffer blijft staan. |
| `⌃X f` | Fix het vorige commando, met exitcode als context. Typ eventueel eerst een hint (bv. de foutmelding). |
| `⌃_` | Ongedaan maken (standaard zle undo). |

- **Infobalk:** na elke actie toont `zle -M` onder de prompt de positie (`1/3`), het label van het alternatief en de sneltoetsen.
- **Waarschuwing:** bij destructieve commando's (`rm`, `--force`, `git reset --hard`, …) toont de infobalk een ⚠-regel.
- **Hulpcommando's:**
  - `claude-cmd-prefs`: voorkeuren bewerken, via `chezmoi edit --apply`.
  - `claude-cmd-refresh`: toollijst verversen.
  - `claude-cmd-context`: laat zien wat Claude als context krijgt.

## Beslissingen

- **Via `claude -p`, niet via de API.** Zo gaat alles automatisch via de gateway-config van de Claude CLI. Er is geen eigen API-key of endpoint nodig.
- **Eigen widget in plaats van een bestaande plugin.** De bestaande plugins zijn dunne wrappers. Met een eigen widget zijn we niet afhankelijk van een hobbyproject en kunnen we commando's tweaken, alternatieven tonen en voorkeuren meegeven.
- **3 alternatieven in één call.** Dat is sneller dan opnieuw vragen, omdat `claude -p` 1–3 seconden opstarttijd heeft. De alternatieven moeten wezenlijk verschillen: een andere tool, een andere aanpak, of een veilige variant.
- **Nooit automatisch uitvoeren.** Het commando komt altijd in de buffer, en jij drukt zelf op Enter.
- **Context per call:**
  - de voorkeuren uit `prefs.md`;
  - geïnstalleerde tools: `brew leaves`, maximaal 24 uur gecachet en op de achtergrond ververst, plus een vaste kandidatenlijst die tegen `$PATH` wordt gecheckt;
  - OS, cwd en git-branch.
  
  Bewust niet: de volledige inhoud van `$PATH` (te groot), aliases (werken niet buiten je shell) en `--help`-output (te zwaar).
- **Voorkeuren in een apart bestand, beheerd in chezmoi.** Een toollijst zegt niets over voorkeur, dus `rg` boven `grep` staat expliciet in `prefs.md`. Daar staat ook de regel voor long-form opties.
- **Long-form opties waar mogelijk, nooit verzonnen.** macOS-basistools zijn BSD; GNU-opties alleen via `g`-varianten als die geïnstalleerd zijn.
- **Infobalk via `zle -M`, geen Ghostty-escapes.** Dit werkt in elke terminal. Een balk helemaal onderaan het venster zou scroll-region-trucs nodig hebben en dat breekt bij resizen.
- **Sneltoetsen `⌃X e` / `⌃X f` in plaats van Alt.** `⌥F` is standaard `forward-word`, en Alt werkt in Ghostty alleen met `macos-option-as-alt`. Alle toetsen zijn instelbaar.
- **Bewust weggelaten:**
  - autosuggest tijdens het typen (te traag en te duur via `claude -p`);
  - chatmodus;
  - output van het vorige commando vastleggen (vereist `script`-wrapping).

## Waar staat wat

| Bestand | Inhoud |
|---|---|
| `~/.config/zsh/conf.d/55-claude-cmd.zsh` | de widget; geladen na de plugins (50), zodat de sneltoetsen winnen |
| `~/.config/claude-cmd/prefs.md` | voorkeuren; bewerken met `claude-cmd-prefs` |
| `~/.config/claude-cmd/README.md` | dit bestand |
| `~/.cache/claude-cmd/` | gecachte `brew leaves` en de laatste foutmelding |

De widget doet niets als `claude` niet op het `PATH` staat, dus kan veilig op beide MacBooks.

## Instellingen (zetten vóór 55, bv. in `00-env.zsh`)

| Variabele | Standaard |
|---|---|
| `CLAUDE_CMD_MODEL` | `haiku` |
| `CLAUDE_CMD_LANG` | `Dutch` (taal van uitleg en labels) |
| `CLAUDE_CMD_KEY_GEN` / `_EXPLAIN` / `_FIX` | `^G` / `^Xe` / `^Xf` |
| `CLAUDE_CMD_CANDIDATES` | array met losse binaries om te checken |

## Bekende beperkingen

- `⌃C` tijdens het wachten breekt de hele regel af.
- Als je gateway de alias `haiku` niet kent, zet je een volledig model-ID in `CLAUDE_CMD_MODEL`.
