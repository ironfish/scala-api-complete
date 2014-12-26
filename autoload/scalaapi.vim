let [ s:TYPE_RESERVED, s:TYPE_PACKAGE, s:TYPE_CLASS, s:TYPE_TRAIT ] = range(4)
let [ s:MODE_RESERVED, s:MODE_PACKAGE, s:MODE_CLASS, s:MODE_TRAIT ] = range(4)

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

  let start = cur
  while start > 0 && line[start - 1] !~ '[ \t]'
    let start -= 1
  endwhile
"  while idx > 0 && line[idx] !~ '[. \t(;]'
"    let idx -= 1
"  endwhile
"  while start > 0 && line[start - 1] =~ '\a'
"    let start -= 1
"  endwhile

  " class mode
  if start >= 8 && line[ start - 8 : ] =~ '\<extends\>'
"    let idx -= 3
"    while idx > 0 && line[idx] =~ '[ \t=]'
"      let idx -= 1
"    endwhile
    echo line[ start - 7 : ]
    return [ start, s:MODE_CLASS, '', [] ]
  endif

  echo line[ start - 7 : ]
  " reserved mode
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
    elseif s:complete_mode == s:MODE_CLASS
      call s:obj_completion(a:base, res, s:class)
      call s:obj_completion(a:base, res, s:trait)
 "     call s:class_completion(a:base, res)
 "     call s:trait_completion(a:base, res)
    endif
    return res
  endif
endfunction


function! s:obj_completion(base, res, objects)
  for obj in a:objects
    if obj.name =~ '^' . a:base
      call add(a:res, s:obj_compitem(obj))
    endif
  endfor
endfunction

function! s:obj_compitem(obj)
  let abbr = a:obj.typ . " " . a:obj.name . " (" . a:obj.package . ")"
  return {
    \ 'word' : a:obj.name,
    \ 'abbr' : abbr,
    \ 'menu' : a:obj.inhereted,
    \ 'kind' : 't',
    \}
endfunction

" --- reserved word functions {{
function! s:reserved_completion(base, res)
  for rsv in s:reserved
    if rsv.name =~ '^' . a:base
      call add(a:res, s:reserved_to_completion(rsv))
    endif
  endfor
endfunction

function! s:reserved_to_completion(rsv)
  return {
    \ 'word' : a:rsv.name,
    \ 'menu' : a:rsv.detail,
    \ 'kind' : 'R',
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
let s:package_tmp = []
function! scalaapi#package(pkg)
  call add(s:package_tmp, a:pkg)
"  let parts = split(a:pkg, '\.')
"  for part in parts
"    call s:package_item(part, '', [])
"  endfor
endfunction

"let s:class = {}
"function! s:package_item(name, extend, members)
"  let s:class[ a:name ] = {
"    \ 'type'   : s:TYPE_PACKAGE,
"    \ 'name'   : a:name,
"    \ 'kind'   : 't',
"    \ 'extend' : a:extend,
"    \ 'members': a:members,
"    \}
"endfunction
" --- package functions }}

" --- trait functions {{
let s:trait = []
function! scalaapi#trait(name, package, typ, inhereted, members)
  call add(s:trait,
    \ {
    \ 'type'       : s:TYPE_TRAIT,
    \ 'name'       : a:name,
    \ 'package'    : a:package,
    \ 'typ'        : a:typ,
    \ 'inhereted'  : a:inhereted
    \ })
endfunction
" ___ trait functions }}

" --- class functions {{
let s:class = []
function! scalaapi#class(name, package, typ, inhereted, members)
  call add(s:class,
    \ {
    \ 'type'       : s:TYPE_CLASS,
    \ 'name'       : a:name,
    \ 'package'    : a:package,
    \ 'typ'        : a:typ,
    \ 'inhereted'  : a:inhereted
    \ })
endfunction
" --- class functions }}

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
  let s:package = sort(s:package_tmp)
endfunction

