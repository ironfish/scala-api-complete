function! scalaapi#complete(findstart, base)
  if a:findstart
    let line = getline('.')
    let cur = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    let res = []
    call s:reserved_completion(a:base, res)
    return res
  endif
endfunction

function! s:reserved_completion(base, res)
  for fun in s:reserved
    if fun.name =~ '^' . a:base
      call add(a:res, s:reserved_to_completion(fun))
    endif
  endfor
endfunction

function! s:reserved_to_completion(func)
  return {
    \ 'word' : a:func.name,
    \ 'menu' : a.func.detail,
    \ 'kind' : 't',
    \ }
endfunction

let s:reserved = []
function! scalaapi#reserved(name, detail)
  call add(s:reserved,
    \ {
    \ 'type'       : s:TYPE_RESERVED,
    \ 'name'       : a:name,
    \ 'detail'     : a:detail
    \ })
endfunction
