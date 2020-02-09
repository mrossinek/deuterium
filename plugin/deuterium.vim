if exists('g:loaded_deuterium') || !has('pythonx') || !has('python3') || &compatible
    finish
endif

let g:loaded_deuterium = 1

if !deuterium#initialize()
    finish
endif

let g:deuterium#namespace = nvim_create_namespace('deuterium')

" TODO allow suppressing all of the below
highlight default DeuteriumSuccess ctermfg=green
highlight default DeuteriumFailure ctermfg=red

command! DeuteriumInit call deuterium#initialize()
command! DeuteriumStart call deuterium#start()
command! DeuteriumShutdown call deuterium#shutdown()
command! DeuteriumConnect call deuterium#connect()
command! -range DeuteriumSend <line1>,<line2>call deuterium#send()

nnoremap <F13> :DeuteriumSend<CR>
vnoremap <F13> :DeuteriumSend<CR>

augroup Deuterium
    autocmd!
    autocmd VimEnter *.py DeuteriumConnect
    autocmd VimLeavePre * DeuteriumShutdown
augroup end
