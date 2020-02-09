if exists('g:loaded_deuterium') || !has('pythonx') || !has('python3') || &compatible
    finish
endif

let g:loaded_deuterium = 1

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

highlight default DeuteriumSuccess ctermfg=green
highlight default DeuteriumFailure ctermfg=red
highlight default link DeuteriumText Comment

command! DeuteriumInit call deuterium#initialize()
command! DeuteriumStart call deuterium#start()
command! DeuteriumShutdown call deuterium#shutdown()
command! DeuteriumConnect call deuterium#connect()
command! -range DeuteriumSend <line1>,<line2>call deuterium#send()

if !hasmapto('<Plug>DeuteriumSend')
    map <F13> <Plug>DeuteriumSend
endif
noremap <unique> <script> <Plug>DeuteriumSend :DeuteriumSend<CR>

augroup Deuterium
    autocmd!
    autocmd VimEnter *.py DeuteriumConnect
    autocmd VimLeavePre * DeuteriumShutdown
augroup end
