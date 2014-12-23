if exists('g:loaded_scalaapi') && g:loaded_scalaapi == 1
  finish
endif

command! -nargs=0 ScalaApiLoad :call scalaapi#load()

let g:loaded_scalaapi = 1
