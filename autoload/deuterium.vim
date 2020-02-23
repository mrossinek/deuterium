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

    " initialize script variables
    let s:deuterium_namespace = nvim_create_namespace('deuterium')
    let s:deuterium_extmarks = {}
    " return success code
    return get(g:, 'deuterium#init_success', 0)
endfunction


function! deuterium#start()
    let s:kernel_jobid = jobstart('ipython kernel')
    echomsg '[deuterium] kernel is booting up @pid '.jobpid(s:kernel_jobid)
    " need to wait for kernel to properly boot
    sleep 1
    return 0
endfunction


function! deuterium#shutdown()
    if !exists('s:kernel_jobid')
        " no kernel registered
        return 1
    endif
    " close remaining popup windows
    for [extmark, winid] in items(s:deuterium_extmarks)
        call nvim_win_close(winid, v:false)
        call remove(s:deuterium_extmarks, extmark)
    endfor
    " clear namespace
    call nvim_buf_clear_namespace(0, s:deuterium_namespace, 0, -1)
    echomsg '[deuterium] kernel is shutting down'
    python3 Deuterium.shutdown()
    " need to wait for kernel to clean up connection file
    sleep 500m
    unlet s:kernel_jobid
    return 0
endfunction


function! deuterium#connect()
    if !exists('s:kernel_jobid')
        echomsg '[deuterium] no kernel registered. trying to start one now'
        call deuterium#start()
    endif
    echomsg '[deuterium] connecting to kernel'
    python3 Deuterium.connect()
    return 0
endfunction


function! deuterium#auto_select()
    let initial_line = line('.')
    " empty line case
    if getline(initial_line) ==# ''
        " only relevant if surrounded by zero-indent level lines
        if indent(max([initial_line-1, 1])) ==# 0
                    \ || indent(min([initial_line+1, line('$')])) ==# 0
            return
        endif
    endif
    " find first line
    for first_line in range(initial_line, 1, -1)
        " stop at any non-empty zero-indent level line
        if getline(first_line) ==# ''
            continue
        elseif indent(first_line) ==# 0
            break
        endif
    endfor
    " find first non-empty zero-indent level line
    for after_last in range(min([initial_line+1, line('$')]), line('$')+1, 1)
        if getline(after_last) ==# ''
            continue
        elseif indent(after_last) ==# 0
            break
        endif
    endfor
    " backtrack to last non-empty line before this one
    for last_line in range(max([after_last-1, initial_line]), initial_line, -1)
        if getline(last_line) !=# ''
            break
        endif
    endfor
    echo [first_line, last_line]
endfunction


function! deuterium#execute() range
    if !exists('s:kernel_jobid')
        echoerr '[deuterium] please connect to a kernel first!'
        return 1
    endif
    let code = ''
    let popup_col = 0
    " gather code which is to be executed
    for line in range(a:firstline, a:lastline)
        let text = getline(line)
        let code .= text . "\n"
        " update popup_col position
        let popup_col = max([len(text), popup_col])
        " remove any virtualtext in executed lines
        call nvim_buf_set_virtual_text(0, s:deuterium_namespace, line-1, [], {})
    endfor
    let popup_row = a:lastline - 1
    " close any popups in the region
    let local_extmarks = nvim_buf_get_extmarks(0, s:deuterium_namespace,
                \ [max([a:firstline - 1 - g:deuterium#max_popup_height, line('w0')]), 0],
                \ [min([a:lastline + 1 - g:deuterium#max_popup_height, line('w$')]), 0],
                \ {})
    for [extmark, _, _] in local_extmarks
        let index = index(keys(s:deuterium_extmarks), string(extmark))
        if index >=# 0
            call nvim_win_close(s:deuterium_extmarks[string(extmark)], v:false)
            call remove(s:deuterium_extmarks, extmark)
        endif
    endfor
    try
        let [success, stdout, stderr] = deuterium#send(code)

        " if we got this far this means some code was executed
        " in that case: if any handler is using the preview window, close it
        if (g:deuterium#stdout_handler ==? 'preview' ||
                    \ g:deuterium#stderr_handler ==? 'preview')
            pclose
        endif

        let varname = success ? 'success' : 'failure'
        let symbol = get(g:, 'deuterium#symbol_' . varname)
        let hi_group = 'Deuterium' . toupper(varname[0]) . varname[1:]
        " set success indicator label
        let virtualtext = [[symbol, hi_group]]

        " process streams
        for [stream, hi_group] in [
                    \ ['stdout', 'DeuteriumText'],
                    \ ['stderr', 'DeuteriumError']]
            let text = get(l:, stream)
            if text ==# ''
                continue
            endif
            if len(split(text, '\n')) ==# 1
                " short outputs are added to virtual text
                let virtualtext += [
                            \ [' ' . substitute(text, '\n', '', 'g'), hi_group]
                            \ ]
            else
                " obtain configuration value on how to handle current stream
                let handler = get(g:, 'deuterium#' . stream . '_handler')
                if handler ==? 'none'
                    continue
                elseif handler ==? 'popup'
                    call deuterium#popup(text, [popup_row, popup_col])
                elseif handler ==? 'preview'
                    call deuterium#preview(text)
                else
                    throw 'Invalid option for g:deuterium#'.stream.'_handler'
                endif
            endif
        endfor

        " add virtual text to last executed line
        call nvim_buf_set_virtual_text(0, s:deuterium_namespace,
                    \ popup_row, virtualtext, {})

    catch /EmptyCode/
        " no code to execute
        return
    finally
        " if configured: jump to next line
        if g:deuterium#jump_line_after_execute
            normal +
        endif
    endtry
    return 0
endfunction


function! deuterium#popup(text, bufpos)
    let parsed = split(a:text, '\n')
    let popup_buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(popup_buf, 0, -1, v:true, parsed)
    " configure popup window
    let height = max([len(parsed), g:deuterium#max_popup_height])
    let width = nvim_win_get_width(0)
    let width -= ((&l:number || &l:relativenumber) ? &l:numberwidth : 0)
    let width -= &l:foldcolumn
    let width -= ((&l:signcolumn) ? 2 : 0)
    let width -= a:bufpos[1] + 5
    let config = {
                \ 'relative': 'win',
                \ 'width': width,
                \ 'height': height,
                \ 'bufpos': a:bufpos,
                \ 'row': 0,
                \ 'col': 3,
                \ 'style': 'minimal',
                \ }
    let popup_win = nvim_open_win(popup_buf, v:false, config)
    call nvim_win_set_option(popup_win, 'winhl', 'NormalFloat:DeuteriumText')
    " store popup window id associated with an extmark
    let ns_id = nvim_buf_set_extmark(0, s:deuterium_namespace, 0,
                \ a:bufpos[0], 0, {})
    let s:deuterium_extmarks[ns_id] = popup_win
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
        call nvim_set_current_buf(preview_buf)
        normal p
    endtry
endfunction


function! deuterium#send(code)
    if match(a:code, '^[\s\r\n]*$') ==? 0
        throw 'EmptyCode'
    endif
    python3 Deuterium.send()
    " return values are set inside python function
    return [success, stdout, stderr]
endfunction
