# Port of configs/powershell/keybinds.ps1 -- fish equivalent.
# fish's default bindings already give Up/Down history-prefix-search-like
# behavior via `history-search-backward`/`-forward` isn't bound by default
# in the emacs-mode bindings fish ships with, so bind it explicitly to
# mirror PSReadLine's HistorySearchBackward/Forward.

bind \cl 'clear; commandline -f repaint'
bind -k up history-search-backward
bind -k down history-search-forward
