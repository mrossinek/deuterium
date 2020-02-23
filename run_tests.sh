#!/bin/bash
nvim -N --noplugin -u <(cat << VIMRC
let g:python3_host_prog='./ext/venv/bin/python'
set rtp+=./ext/vader.vim
source ./ext/vader.vim/plugin/vader.vim
set rtp+=.
source ./plugin/deuterium.vim
VIMRC
) -c 'Vader! test/*.vader' 2>results.txt
ret_code=$?
cat results.txt
rm results.txt
exit $ret_code
