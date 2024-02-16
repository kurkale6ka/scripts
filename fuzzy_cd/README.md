# Install

```bash
mkdir fuzzy_cd
cd fuzzy_cd
python3 -mvenv .venv
source ./.venv/bin/activate
pip install -e .
deactivate
```

# Bash setup

```bash
c() {
    script=/path/to/fuzzy_cd/.venv/bin/fcd

    for arg in "$@"
    do
        if [[ $arg == @(-h|--help|-s|--stats) ]]
        then
            "$script" "$@"
            return
        fi
    done

    cd -- "$("$script" "$@")"
}

# in .bashrc
HISTIGNORE='c:c *'
```

# ZSH autoload setup

[ZSH Autoloading Functions](https://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions)

```bash
script=/path/to/fuzzy_cd/.venv/bin/fcd

for arg in "$@"
do
    if [[ $arg == (-h|--help|-s|--stats) ]]
    then
        "$script" "$@"
        return
    fi
done

cd -- "$("$script" "$@")"

# in .zshenv
HISTORY_IGNORE='(c|c *)'
```
