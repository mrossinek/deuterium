if (exists('g:deuterium#loaded') && g:deuterium#loaded isnot 0)
            \ || !has('pythonx') || !has('python3') || &compatible
    finish
endif

let g:deuterium#loaded = 1

if !deuterium#initialize()
    finish
endif

let g:deuterium#namespace = nvim_create_namespace('deuterium')

if !exists('g:deuterium#symbol_success')
    let g:deuterium#symbol_success = '✔'  " U+2714 heavy check mark
endif
if !exists('g:deuterium#symbol_failure')
    let g:deuterium#symbol_failure = '✘'  " U+2718 heavy ballot x
endif
if !exists('g:deuterium#jump_line_after_execute')
    let g:deuterium#jump_line_after_execute = 1
endif
if !exists('g:deuterium#stdout_handler')
    let g:deuterium#stdout_handler = 'popup'
endif
if !exists('g:deuterium#stderr_handler')
    let g:deuterium#stderr_handler = 'preview'
endif

highlight default DeuteriumSuccess ctermfg=green
highlight default DeuteriumFailure ctermfg=red
highlight default link DeuteriumText Comment
highlight default link DeuteriumError Error

command! DeuteriumStart call deuterium#start()
command! DeuteriumShutdown call deuterium#shutdown()
command! DeuteriumConnect call deuterium#connect()
command! -range DeuteriumExecute <line1>,<line2>call deuterium#execute()

if !hasmapto('<Plug>DeuteriumExecute')
    map <S-CR> <Plug>DeuteriumExecute
endif
noremap <unique> <script> <silent> <Plug>DeuteriumExecute :DeuteriumExecute<CR>

augroup DeuteriumEnter
    autocmd!
    autocmd VimEnter *.py DeuteriumConnect
augroup end

augroup DeuteriumLeave
    autocmd!
    autocmd VimLeavePre * DeuteriumShutdown
augroup end
