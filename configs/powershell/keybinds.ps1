Set-PSReadLineKeyHandler -Chord "Ctrl+l" -Function ClearScreen

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
