# INSTALL

## mkconfig module

Editable mode install
```bash
cd ~/repos/github/scripts/mkconfig
python3 -mvenv .venv
source .venv/bin/activate
pip install -U pip
pip install -e .
```

## styles module

Editable mode install
```bash
mkdir -p ~/repos/gitlab
cd ~/repos/gitlab
git clone git@gitlab.com:kurkale6ka/styles.git
source ~/repos/github/scripts/mkconfig/.venv/bin/activate
pip install -e styles
```
