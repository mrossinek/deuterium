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
    echomsg '[deuterium] kernel is booting up @pid '.jobpid(s:kernel_jobid)
    " need to wait for kernel to properly boot
    sleep 1
endfunction


function! deuterium#shutdown()
    if !exists('s:kernel_jobid')
        " no kernel registered
        return
    endif
    call nvim_buf_clear_namespace(0, nvim_create_namespace('deuterium'), 0, -1)
    echomsg '[deuterium] kernel is shutting down'
    python3 Deuterium.shutdown()
    " need to wait for kernel to clean up connection file
    sleep 500m
endfunction


function! deuterium#connect()
    if !exists('s:kernel_jobid')
        echomsg '[deuterium] no kernel registered. trying to start one now'
        call deuterium#start()
    endif
    echomsg '[deuterium] connecting to kernel'
    python3 Deuterium.connect()
    let s:deuterium_popup_win = -1
endfunction


function! deuterium#execute() range
    if !exists('s:kernel_jobid')
        echoerr '[deuterium] please connect to a kernel first!'
        return 1
    endif
    let code = ''
    for line in range(a:firstline, a:lastline)
        let code .= getline(line) . "\n"
        " remove any virtualtext in executed lines
        call nvim_buf_set_virtual_text(0, g:deuterium#namespace, line-1, [], {})
    endfor
    try
        let [success, stdout, stderr] = deuterium#send(code)

        " if we got this far this means some code was executed
        " in that case close any open popup or preview window
        if s:deuterium_popup_win ># 0
            call nvim_win_close(s:deuterium_popup_win, v:false)
            let s:deuterium_popup_win = -1
        endif

        let varname = success ? 'success' : 'failure'
        let symbol = get(g:, 'deuterium#symbol_' . varname)
        let hi_group = 'Deuterium' . toupper(varname[0]) . varname[1:]
        " set success indicator label
        let virtualtext = [[symbol, hi_group]]

        " process streams
        for [stream, hi_group] in [['stdout', 'DeuteriumText'], ['stderr', 'DeuteriumError']]
            let text = get(l:, stream)
            if text ==# ''
                continue
            endif
            if len(split(text, '\n')) <=# 1
                " short outputs are added to virtual text
                let virtualtext += [[' ' . substitute(text, '\n', '', 'g'), hi_group]]
            else
                let handler = get(g:, 'deuterium#' . stream . '_handler')
                if handler ==? 'none'
                    continue
                elseif handler ==? 'popup'
                    call deuterium#popup(text)
                elseif handler ==? 'preview'
                    call deuterium#preview(text)
                else
                    throw 'Invalid Option for g:deuterium#' . stream . '_handler'
                endif
            endif
        endfor

        " add virtual text to last executed line
        call nvim_buf_set_virtual_text(0, g:deuterium#namespace, a:lastline-1, virtualtext, {})
    catch /EmptyCode/
        " no code to execute
        return
    finally
        " if configured: jump to next line
        if g:deuterium#jump_line_after_execute
            normal +
        endif
    endtry
endfunction


function! deuterium#popup(text)
    let parsed = split(a:text, '\n')
    let popup_buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(popup_buf, 0, -1, v:true, parsed)
    " configure popup window
    let height = len(parsed)
    let width = max(map(parsed, {_, s -> len(s)}))
    let config = {'relative': 'cursor', 'width': width+width/2, 'height': height,
                \ 'row': 0, 'col': len(getline('.'))+3, 'style': 'minimal'}
    let s:deuterium_popup_win = nvim_open_win(popup_buf, v:false, config)
    call nvim_win_set_option(s:deuterium_popup_win, 'winhl', 'NormalFloat:DeuteriumText')
endfunction


function! deuterium#preview(text)
    let parsed = split(a:text, '\n')
    let preview_buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(preview_buf, 0, -1, v:true, parsed)
    try
        " try reaching preview window
        normal P
    catch /^Vim\%((\a\+)\)\=:E441/
        " if failed, open a new one
        10split +setlocal\ previewwindow
    finally
        " open current buffer
        let s:deuterium_popup_win = nvim_get_current_win()
        call nvim_set_current_buf(preview_buf)
        normal p
    endtry
endfunction


function! deuterium#send(code)
    if match(a:code, '^[\s\r\n]*$') ==? 0
        throw 'EmptyCode'
    endif
    python3 Deuterium.send()
    return [success, stdout, stderr]
endfunction
