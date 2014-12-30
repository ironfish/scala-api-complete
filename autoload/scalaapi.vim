let [ s:KIND_RESERVED, s:KIND_PACKAGE, s:KIND_CLASS, s:KIND_TRAIT, s:KIND_OBJECT ] = range(5)
let [ s:MODE_RESERVED, s:MODE_PACKAGE, s:MODE_TYPE, s:MODE_TYPE_CLASS, s:MODE_TYPE_TRAIT, s:MODE_OBJECT ] = range(6)

let s:complete_mode = s:MODE_RESERVED
let s:complete_kind = ''
let s:parts = []

function! s:analize(line, cur)
  let line = getline(a:line)
  let cur = a:cur

  " MODE_PACKAGE
  if line[0:10] =~ '\<import\>\s'
    let start = matchend(line, '\<import\>\s\+')
    let exists = 0
    for pkg in s:package
      if pkg.name =~ '^' . line[ start : ]
        let exists = 1
        break
      endif
    endfor
    if exists == 1
      return [ start, s:MODE_PACKAGE, '', [] ]
    endif
  endif

  let start = cur
  while start > 0 && line[start - 1] !~ '[ \t[;]'
    let start -= 1
  endwhile

  " MODE_TYPE
  " enforces strict style ( extends class | trait)
  if start >= 8 && line[ start - 8 : ] =~ '\<extends\>'
    return [ start, s:MODE_TYPE, '', [] ]
  endif

  " MODE_TYPE_TRAIT
  " enforces strict style ( with trait)
  if start >= 5 && line[ start - 5 : ] =~ '\<with\>'
    return [ start, s:MODE_TYPE_TRAIT, '', [] ]
  endif

  " MODE_TYPE
  " enforces strict style (variable: type)
  if start > 3 && line[ start - 3 : ] =~ '\a\:'
    return [ start, s:MODE_TYPE, '', [] ]
  endif

  " MODE_TYPE
  " enforces strict style (type <: | >: | <% type)
  if start > 4 && line[ start - 4 : ] =~ '\ \(\(<\:\)\|\(>\:\)\|\(<%\)\)'
    return [ start, s:MODE_TYPE, '', [] ]
  endif

  echo "cur:" . cur . " start:" . start . " line:" . line[ start - 4 : ]

  " MODE_TYPE
  " enforces strict style ([type)
  if cur > 0 && line[cur - 1] == '['
    return [ cur, s:MODE_TYPE, '', [] ]
  endif

  " MODE_RESERVED
  return [ start, s:MODE_RESERVED, '', [] ]
endfunction

function! scalaapi#complete(findstart, base)
  if a:findstart
    let line = line('.')
    let start = col('.') - 1
    let [ sstart, s:complete_mode, s:complete_kind, s:parts ] = s:analize(line, start)
    return sstart
  else
    let res = []
    if s:complete_mode == s:MODE_RESERVED
      call s:obj_completion(a:base, res, s:reserved)
    elseif s:complete_mode == s:MODE_PACKAGE
      call s:obj_completion(a:base, res, s:package)
    elseif s:complete_mode == s:MODE_TYPE
      call s:obj_completion(a:base, res, s:class)
      call s:obj_completion(a:base, res, s:object)
      call s:obj_completion(a:base, res, s:trait)
    elseif s:complete_mode == s:MODE_TYPE_TRAIT
      call s:obj_completion(a:base, res, s:trait)
    endif
    return res
  endif
endfunction

" --- complete functions
function! s:obj_completion(base, res, objects)
  for obj in a:objects
    if obj.name =~ '^' . a:base
      call add(a:res, s:obj_compitem(obj))
    endif
  endfor
endfunction

function! s:obj_compitem(obj)
  let abbr = a:obj.kind . " " . a:obj.name
  if strlen(a:obj.inherit) > 0
    let abbr = abbr . " " . a:obj.inherit
  endif
  if strlen(abbr) > 40
    let abbr = strpart(abbr, 0, 60) . "..."
  endif
  let root = ''
  if strlen(a:obj.root) > 0
    let root = "(" . a:obj.root . ")"
  endif
  return {
    \ 'word' : a:obj.name,
    \ 'abbr' : abbr,
    \ 'kind' : '',
    \ 'menu' : root,
    \ 'dup'  : 1,
    \}
endfunction
" --- complete functions }}

" --- load functions {{
let s:reserved = []
function! scalaapi#reserved(name, root, kind, inherit, members)
  call add(s:reserved,
    \ {
    \ 'name'       : a:name,
    \ 'root'       : a:root,
    \ 'kind'       : a:kind,
    \ 'inherit'    : a:inherit,
    \ 'ckind'      : s:KIND_RESERVED
    \ })
endfunction

let s:package = []
function! scalaapi#package(name, root, kind, inherit, members)
  call add(s:package,
    \ {
    \ 'name'       : a:name,
    \ 'root'       : a:root,
    \ 'kind'       : a:kind,
    \ 'inherit'    : a:inherit,
    \ 'ckind'      : s:KIND_PACKAGE
    \ })
endfunction

let s:trait = []
function! scalaapi#trait(name, root, kind, inherit, members)
  call add(s:trait,
    \ {
    \ 'name'       : a:name,
    \ 'root'       : a:root,
    \ 'kind'       : a:kind,
    \ 'inherit'    : a:inherit,
    \ 'ckind'      : s:KIND_TRAIT
    \ })
endfunction

let s:class = []
function! scalaapi#class(name, root, kind, inherit, members)
  call add(s:class,
    \ {
    \ 'name'       : a:name,
    \ 'root'       : a:root,
    \ 'kind'       : a:kind,
    \ 'inherit'    : a:inherit,
    \ 'ckind'      : s:KIND_CLASS
    \ })
endfunction

let s:object = []
function! scalaapi#object(name, root, kind, inherit, members)
  call add(s:object,
    \ {
    \ 'name'       : a:name,
    \ 'root'       : a:root,
    \ 'kind'       : a:kind,
    \ 'inherit'    : a:inherit,
    \ 'ckind'      : s:KIND_OBJECT
    \ })
endfunction

function! s:msg(msg)
  redraw
  let msg = strpart( a:msg, 0, winwidth(0) - &numberwidth - 10)
  echo 'scalaapi: ' . msg
endfunction

function! scalaapi#load()
  let rtp = split(&runtimepath, ',')
  let files = split(globpath(join(rtp, ','), 'autoload/scalaapi/*.vim'), '\n')
  let files = sort(files, "s:sortfiles")
  for file in files
    if file
      continue
    endif
    call s:msg('load ' . substitute(file, '^.*\','',''))
    exe 'so ' . file
  endfor
  echo '[scala-complete] loaded!'
endfunction

" sort the files based on name w/o the .vim ending.
function s:sortfiles(i1, i2)
  let new_i1 = substitute(a:i1, '.vim$', '', '')
  let new_i2 = substitute(a:i2, '.vim$', '', '')
  return new_i1 == new_i2 ? 0 : new_i1 > new_i2 ? 1 : -1
endfunction

" load
if !exists('s:loaded')
  call scalaapi#load()
  let s:loaded = 1
endif 
"--- load functions }}

