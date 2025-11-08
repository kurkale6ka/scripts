# Install
`uv tool install -e .`

# Bash setup

In `.bashrc`:
```bash
c() {
    script=/path/to/fuzzy_cd/.venv/bin/fcd

    for arg in "$@"
    do
        if [[ $arg == @(-h|--help|-s|--stats|-v|--view-cds|-c|--cleanup) ]]
        then
            "$script" "$@"
            return
        fi
    done

    dir="$("$script" "$@")"

    if [[ -n $dir ]]
    then
        cd -- "$dir"
    fi
}

HISTIGNORE='c:c *'
```

# ZSH setup

In an [autoload function](https://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions):
```bash
script=/path/to/fuzzy_cd/.venv/bin/fcd

for arg in "$@"
do
    if [[ $arg == (-h|--help|-s|--stats|-v|--view-cds|-c|--cleanup) ]]
    then
        "$script" "$@"
        return
    fi
done

dir="$("$script" "$@")"

if [[ -n $dir ]]
then
    cd -- "$dir"
fi
```

In `.zshenv`:
```bash
HISTORY_IGNORE='(c|c *)'
```
