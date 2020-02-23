#!/bin/bash
nvim -N --noplugin -u minimal.vimrc -c 'Vader! test/*.vader' 2>results.txt
ret_code=$?
cat results.txt
rm results.txt
exit $ret_code
