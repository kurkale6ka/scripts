# Export
```sh
td -e                     > /tmp/mydir.src
td -e ~/repos/github/help > /tmp/help.src
```

# Paste
faster pasting in vim
```viml
set noswapfile
set paste
w /tmp/help.src
```

# Import
`uv run td -i /tmp/help.src`
