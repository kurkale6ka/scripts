# Shell setup

```bash
c() {
    script='/path/to/cd.py'

    for arg in "$@"
    do
        if [[ $arg == -h || $arg == --help ]]
        then
            "$script" -h
            return
        fi
    done

    cd -- "$("$script" "$@")"
}
```
