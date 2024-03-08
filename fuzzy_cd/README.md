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
# in .bashrc
c() {
    script=/path/to/fuzzy_cd/.venv/bin/fcd

    for arg in "$@"
    do
        if [[ $arg == @(-h|--help|-c|--cleanup|-s|--stats) ]]
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

# ZSH autoload setup

[ZSH Autoloading Functions](https://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions)

```bash
# autoload function
script=/path/to/fuzzy_cd/.venv/bin/fcd

for arg in "$@"
do
    if [[ $arg == (-h|--help|-c|--cleanup|-s|--stats) ]]
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

```bash
# in .zshenv
HISTORY_IGNORE='(c|c *)'
```
