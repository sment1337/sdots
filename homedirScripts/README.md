# homedirScripts

Helper scripts that are meant to live **directly in `$HOME`** — callable from an
ordinary shell prompt, independent of tmux.

Link them individually, e.g.:

```sh
ln -s ~/sdots/homedirScripts/OpenPDK.sh    ~/OpenPDK.sh
ln -s ~/sdots/homedirScripts/previewPDF.sh ~/previewPDF.sh
ln -s ~/sdots/homedirScripts/NewNote.sh    ~/NewNote.sh
```

Some helpers call their siblings **by `$HOME` path**, so link the pair together
(`OpenPDK.sh` expects `~/previewPDF.sh` to exist).

## Naming convention

| Prefix | Meaning |
|---|---|
| `Open*` | interactive search-and-open entry points |
| `preview*` | small helpers invoked by an fzf `preview=`/`enter:preview=` binding — not meant to be run by hand |

## Scripts

| Script | What it does |
|---|---|
| `OpenPDK.sh` | `pdfgrep` search over the **PDK docs** (`$PDK_DIR`, or a path given as `$1`) → fzf → zathura at the matching page with the phrase highlighted. |
| `previewPDF.sh` | fzf helper: opens zathura at `path:page` and `--find`s the given term. Called by `OpenPDK.sh`. |
| `previewNote.sh` | fzf helper: prints a read-only snippet of a note around the matched line with `bat --line-range`. No editor is opened. |
| `NewNote.sh` | Create/open a dated note (`YYYYMMDD_<title>.md`) in `$NOTES_DIR`. |

## Relationship to `tmux/`

`tmux/` holds the variants wired to tmux keybindings; this folder holds the
standalone ones. They deliberately overlap in *purpose* but not in code, so the
names are kept distinct to avoid implying they're interchangeable:

| tmux keybinding | tmux script | closest standalone |
|---|---|---|
| `prefix C-o` | `tmux/OpenNote.sh` | — (the old duplicate here was removed; use the tmux one) |
| `prefix O` | `tmux/OpenPDF.sh` (Literature books) | `OpenPDK.sh` (PDK docs — different corpus) |
| `ctrl-p` inside that fzf | `tmux/preview.sh` (opens **vim** at the line) | `previewNote.sh` (**bat** snippet, read-only) |
| `enter` inside the PDF fzf | `tmux/pdfPreview.sh` | `previewPDF.sh` |

`$NOTES_DIR` and `$PDK_DIR` come from `~/.local.zshrc` (untracked), which
`~/.zshrc` sources in interactive shells.
