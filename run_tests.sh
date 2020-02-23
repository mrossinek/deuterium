#!/bin/bash
wget https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage -N --noplugin -u <(cat << VIMRC
let g:python3_host_prog='./ext/venv/bin/python'
set rtp+=./ext/vader.vim
source ./ext/vader.vim/plugin/vader.vim
set rtp+=.
source ./plugin/deuterium.vim
VIMRC
) -c 'Vader! test/*.vader' > /dev/null
rm nvim.appimage
