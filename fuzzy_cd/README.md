# Shell setup

```bash
c() {
    for arg in "$@"
    do
        if [[ $arg == -h || $arg == --help ]]
        then
            ~/repos/github/scripts/cd.py -h
            return
        fi
    done

    cd -- "$(~/repos/github/scripts/cd.py "$@")"
}
```
