function! deuterium#initialize() abort
    python3 << EOF
import sys
import vim
# synchronize the paths of vim and python
for path in vim.call('globpath', vim.options['runtimepath'],
                     'rplugin/python3', 1).split('\n'):
    sys.path.append(path)
# try importing deuterium
try:
    from deuterium import Deuterium
except Exception:
    vim.vars['deuterium#init_success'] = 0
else:
    vim.vars['deuterium#init_success'] = 1
EOF
    " return success code
    return get(g:, 'deuterium#init_success', 0)
endfunction


function! deuterium#start()
    let s:kernel_jobid = jobstart('ipython kernel')
    echomsg '[deuterium] started ipython kernel @pid '.jobpid(s:kernel_jobid)
endfunction


function! deuterium#shutdown()
    call nvim_buf_clear_namespace(0, nvim_create_namespace('deuterium'), 0, -1)
    python3 Deuterium.shutdown()
endfunction


function! deuterium#connect()
    if !exists('s:kernel_jobid')
        echomsg '[deuterium] no kernel registered. trying to start one now'
        call deuterium#start()
        sleep 1
    endif
    python3 Deuterium.connect()
endfunction


function! deuterium#send() range
    if !exists('s:kernel_jobid')
        echoerr '[deuterium] please connect to a kernel first!'
        return 1
    endif
    python3 Deuterium.send()
endfunction
