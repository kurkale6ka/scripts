INSTALL
=======

mkconfig module
---------------

.. code-block:: bash
    :caption: Editable mode install

        cd ~/repos/github/scripts/mkconfig
        python3 -mvenv .venv
        source .venv/bin/activate
        pip install -U pip
        pip install -e .

styles module
-------------

.. code-block:: bash
    :caption: Editable mode install

        mkdir -p ~/repos/gitlab
        cd ~/repos/gitlab
        git clone git@gitlab.com:kurkale6ka/styles.git
        source ~/repos/github/scripts/mkconfig/.venv/bin/activate
        pip install -e styles
