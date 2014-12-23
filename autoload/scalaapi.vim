let [ s:TYPE_RESERVED, s:TYPE_PACKAGE ] = range(2)
let [ s:MODE_RESERVED, s:MODE_PACKAGE ] = range(2)

let s:complete_mode = s:MODE_RESERVED
let s:type = ''
let s:parts = []

function! s:analize(line, cur)
  let line = getline('.')
  let cur = a:cur

  " package mode
  if line[0:10] =~ '\<import\>\s'
    let start = matchend(line, '\<import\>\s\+')
    let exists = 0
    for pkg in s:package
      if pkg =~ '^' . line[ start : ]
        let exists = 1
        break
      endif
    endfor
    if exists == 1
      return [ start, s:MODE_PACKAGE, '', [] ]
    endif
  endif

  " reserved mode
  let start = cur
  while start > 0 && line[start - 1] =~ '\a'
    let start -= 1
  endwhile
  return [ start, s:MODE_RESERVED, '', [] ]
endfunction

function! scalaapi#complete(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    let [ sstart, s:complete_mode, s:type, s:parts ] = s:analize(line, start)
    return sstart
  else
    let res = []
    if s:complete_mode == s:MODE_RESERVED
      call s:reserved_completion(a:base, res)
    elseif s:complete_mode == s:MODE_PACKAGE
      call s:package_completion(a:base, res)
    endif
    return res
  endif
endfunction

" --- reserved word functions {{
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
    \ 'menu' : a:func.detail,
    \ 'kind' : 't',
    \}
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
" --- reserved word functions }}

" --- package functions {{
function! s:package_completion(base, res)
  for pkg in s:package
    if pkg =~ '^' . a:base
      call add(a:res, s:package_to_completion(pkg))
    endif
  endfor
endfunction

function! s:package_to_completion(pkg)
  return {
    \ 'word' : a:pkg,
    \ 'menu' : 'package',
    \ 'kind' : 't',
    \}
endfunction

let s:package = []
function scalaapi#package(pkg)
  call add(s:package, a:pkg)
  let parts = split(a:pkg, '\.')
  for part in parts
    call s:package_item(part, '', [])
  endfor
endfunction

let s:class = {}
function! s:package_item(name, extend, members)
  let s:class[ a:name ] = {
    \ 'type'   : s:TYPE_PACKAGE,
    \ 'name'   : a:name,
    \ 'kind'   : 't',
    \ 'extend' : a:extend,
    \ 'members': a:members,
    \}
endfunction
" --- package functions }}

function! s:msg(msg)
  redraw
  let msg = strpart( a:msg, 0, winwidth(0) - &numberwidth - 10)
  echo 'scalaapi: ' . msg
endfunction

function! scalaapi#load()
  let rtp = split(&runtimepath, ',')
  let files = split(globpath(join(rtp, ','), 'autoload/scalaapi/*.vim'), '\n')
  for file in files
    if file
      continue
    endif
    call s:msg('load ' . substitute(file, '^.*\','',''))
    exe 'so ' . file
  endfor
  echo '[scala-complete] loaded!'
endfunction

