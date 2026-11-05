# Voorkeuren voor claude-cmd
<!-- Beheerd in chezmoi. Bewerken: claude-cmd-prefs -->

## Tools (gebruik deze als ze geïnstalleerd zijn)
- Zoeken in bestanden: rg, niet grep
- Bestanden vinden: fd, niet find
- Bestanden bekijken: bat; in pipes en scripts gewoon cat
- Directory-listing: eza, niet ls
- Bestanden openen of bewerken: zed <pad>
- JSON: jq; YAML: yq
- HTTP: xh voor interactief gebruik, curl in scripts
- Find-and-replace in bestanden: sd, niet sed -i
- Schijfgebruik: dust; vrije ruimte: duf
- GitHub: gh

## Stijl
- Gebruik long-form opties (--ignore-case, --hidden, --recursive) als de tool die ondersteunt. Korte flags alleen als er geen lange variant bestaat.
- Verzin nooit opties. De macOS-basistools (ls, find, sed, cp, xargs, date, stat) zijn BSD-varianten zonder de meeste GNU-opties; gebruik GNU-opties alleen via de g-variant (gsed, gdate, gfind) als die geïnstalleerd is.
- Geen sudo tenzij echt nodig.
- Bij destructieve acties: maak één van de alternatieven een veilige variant (dry run, interactief, of eerst tonen wat er geraakt wordt).
- Paden met spaties altijd quoten.
