# INSTALL

## mkconfig module
[Dotfiles setup](https://github.com/kurkale6ka/scripts/tree/master/mkconfig)

Editable mode install
```bash
cd ~/repos/github/scripts/mkconfig
python3 -mvenv .venv
source .venv/bin/activate
pip install -U pip
pip install -e .
```

## decorate module
[Text with styles: color, bold, ...](https://gitlab.com/kurkale6ka/styles)

Editable mode install
```bash
mkdir -p ~/repos/gitlab
cd ~/repos/gitlab
git clone git@gitlab.com:kurkale6ka/styles.git # or https
source ~/repos/github/scripts/mkconfig/.venv/bin/activate
pip install -U pip
pip install -e styles
```
