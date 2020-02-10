# Deuterium

## Disclaimer
**This is a WIP!**
Currently only Neovim is supported!

Deuterium is a vim-implementation of the popular [hydrogen plugin](https://atom.io/packages/hydrogen)
for Atom.
Thus, it connects you to an IPython kernel running in the background which
allows in-line feedback on the execution of your Python code.


## Features
- In-line feedback of successful execution
- In-line preview of output (or error information in case of failure)

### Future Ideas
- utilize popup or preview window for longer outputs
- automatically select block of code based on indentation level (in normal mode)
- allow count to specify indent levels to be removed before sending code
- preview media output (such as images)
- allow setting break points


## Installation
Install deuterium with your favorite plugin manager.
Furtermore, this plugin requires the `ipykernel` and `jupyter_client` python
packages.
You can simply install them with pip: `pip install ipykernel jupyter_client`

If you have configured vim with a hard-coded python interpreter as explained at
`:h python-virtualenv` it suffices to install these two packages in said
virtualenv.
Deuterium will automatically start the background kernel using the active
virtualenv in the folder where you started vim.


## Usage
Deuterium will automatically start an IPython in the background when you open a
Python file.
By default it sets up a number of commands to interact with.

Furthermore, `<S-CR>` is bound to send the code under the cursor to the
kernel for execution.
This works for the current line in normal mode and for a visual selection, too.

If you do not like the defaults, they are fully configurable so you can adapt
them to your needs.
For more information on this, be sure to check out the
[documentation](./doc/deuterium.txt).


## Why the name "deuterium"?

Deuterium is an isotope of hydrogen. Thus, the pun.


## How does deuterium differ from other projects?

There are many plugins, tips and tricks out there which allow you to execute
Python code from within vim.
Heck, it can even be as simple as [this vim tip](https://vim.fandom.com/wiki/Execute_Python_from_within_current_file).
Or a simple plugin to communicate with a Python shell running in a tmux pane:
https://gitlab.com/mrossinek/vim-tmux-controller

However, all of these approaches may be considered flawed in the sense that they
simply `exec` or `eval` the code passed to them which is generally not a good
idea.

Thus, the implementation of a proper message parsing protocol such as
[Jupyter ones'](https://jupyter-client.readthedocs.io/en/stable/messaging.html)
has things going for it.
After a little searching I only found [jupyter-vim](https://github.com/jupyter-vim/jupyter-vim)
which uses this messaging interface in combination with vim.
However, jupyter-vim does not provide any real feedback on the results utilizing
newer features offered by vim and neovim.

Thus, deuterium was born!

