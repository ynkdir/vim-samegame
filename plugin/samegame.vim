
let s:RAND_MAX = 32767

let s:seed = 0

function! s:srand(seed)
  let s:seed = a:seed
endfunction

" msvcrt rand
function! s:rand()
  let s:seed = s:seed * 214013 + 2531011
  return (s:seed < 0 ? s:seed - 0x80000000 : s:seed) / 0x10000 % 0x8000
endfunction

function! s:random()
  let a = (s:rand() / 0x08 * 0x8000) + s:rand() " 27 bit
  let b = (s:rand() / 0x10 * 0x8000) + s:rand() " 26 bit
  return (a*67108864.0+b)*(1.0/9007199254740992.0)
endfunction

function! s:choice(seq)
  return a:seq[float2nr(s:random() * len(a:seq))]
endfunction

if has('reltime')
  call s:srand(float2nr(fmod(str2float(reltimestr(reltime())) * 256, 2147483648.0)))
else
  call s:srand(localtime())
endif

let s:SameGame = {}
let s:SameGame.width = 0
let s:SameGame.height = 0

function s:SameGame.new(width, height)
  let inst = copy(self)
  call inst.__init__(a:width, a:height)
  return inst
endfunction

function s:SameGame.__init__(width, height)
  let self.width = a:width
  let self.height = a:height
  let discs = ['a', 'b', 'c', 'd', 'e']
  for y in range(self.height)
    for x in range(self.width)
      call self.set(x, y, s:choice(discs))
    endfor
  endfor
endfunction

function s:SameGame.get(x, y)
  return getline(a:y + 1)[a:x]
endfunction

function s:SameGame.set(x, y, disc)
  let lnum = a:y + 1
  while lnum > line('$')
    call append('$', '')
  endwhile
  let line = split(getline(lnum), '\zs')
  while a:x >= len(line)
    call add(line, ' ')
  endwhile
  let line[a:x] = a:disc
  call setline(lnum, join(line, ''))
endfunction

function s:SameGame.erase(x, y)
  let disc = self.get(a:x, a:y)
  call self.set(a:x, a:y, ' ')
  if self.get(a:x - 1, a:y) == disc
    call self.erase(a:x - 1, a:y)
  endif
  if self.get(a:x + 1, a:y) == disc
    call self.erase(a:x + 1, a:y)
  endif
  if self.get(a:x, a:y - 1) == disc
    call self.erase(a:x, a:y - 1)
  endif
  if self.get(a:x, a:y + 1) == disc
    call self.erase(a:x, a:y + 1)
  endif
endfunction

function s:SameGame.fall()
  for x in range(self.width)
    for i in range(self.height)
      for y in range(self.height - 1, i + 1, -1)
        if self.get(x, y) == ' ' && self.get(x, y - 1) != ' '
          call self.set(x, y, self.get(x, y - 1))
          call self.set(x, y - 1, ' ')
        endif
      endfor
    endfor
  endfor
endfunction

function s:SameGame.slide()
  for i in range(self.width)
    for x in range(self.width - i)
      let found = 0
      for y in range(self.height)
        if self.get(x, y) != ' '
          let found = 1
          break
        endif
      endfor
      if !found
        for y in range(self.height)
          call self.set(x, y, self.get(x + 1, y))
          call self.set(x + 1, y, ' ')
        endfor
      endif
    endfor
  endfor
endfunction

function s:SameGame.click(x, y)
  let disc = self.get(a:x, a:y)
  if disc == '' || disc == ' '
    return ''
  endif
  if self.get(a:x - 1, a:y) != disc
        \ && self.get(a:x + 1, a:y) != disc
        \ && self.get(a:x, a:y - 1) != disc
        \ && self.get(a:x, a:y + 1) != disc
    return
  endif
  call self.erase(a:x, a:y)
  call self.fall()
  call self.slide()
  return ''
endfunction

function! s:start()
  tabnew

  highlight Disc1 guibg=blue ctermbg=blue
  highlight Disc2 guibg=red ctermbg=red
  highlight Disc3 guibg=brown ctermbg=brown
  highlight Disc4 guibg=green ctermbg=green
  highlight Disc5 guibg=cyan ctermbg=cyan

  syntax match Disc1 /a/
  syntax match Disc2 /b/
  syntax match Disc3 /c/
  syntax match Disc4 /d/
  syntax match Disc5 /e/

  nnoremap <buffer> <silent> x :call b:game.click(col('.') - 1, line('.') - 1)<CR>

  let b:game = s:SameGame.new(20, 10)
  call append('$', '')
  call append('$', 'PRESS x TO ERASE')
endfunction

command! SameGame call s:start()

