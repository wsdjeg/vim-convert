" convert.vim - Convert units to other units quickly and easily
" " Maintainer: Christopher Peterson <https://chrispeterson.info>

if exists('g:loaded_convert')
  finish
endif
let g:loaded_convert = 1


""" DOCS {{{1
" Example $HOME/.units file to make CSS make sense
" ```
" pt      computerpoint
" pc      computerpica
" add computer iunits mb mB  gb etc
"
" list env vars from manpage
"
" ```
""" }}}

""" Config {{{1
  " Config things
  "   * shortcut keys or something? i dunno.
  "   * Config default sig figs
if !exists('g:convert_command')
  let g:convert_command = 'units'
endif

" An example mapping for CSS conversions as a couple of them conflict with
" short unit names that `units` uses for something else.
let g:remapped_units = {
  \ 'pt': 'point',
  \ 'pts': 'point',
  \ 'pc': 'computerpica',
  \ 'pcs': 'computerpica',
\ }
""" }}}

""" Commands and functions {{{1
command! -range -nargs=+ Convert
  \ call s:Convert_units(<f-args>)

command! Units
  \ call s:Display_units_defs()

function! s:Display_units_defs()
  """ Display the unit definitions file in a split
  let output = system(g:convert_command . ' -V')
  let defs_file = matchstr(output, '\(Units data file is ''\)\@<=[^'']\+\(''\)\@=')

  execute 'split|view ' . fnameescape(defs_file)
endfunction

function! s:Convert_units(...) range
  """ Convert units and insert the result, considering formatting and whether
  """ to overwrite a selection or insert anew
  if argc() ==# 0
    echo 'Convert requires at least one argument specifying a target unit for conversion.'
  endif

  " Get current visual selection in reg n, but back it up the orig value first
  let nbak = @n

  if a:0 >=# 3
    echoerr 'Too many arugments for conversion'
    return
  elseif a:0 ==# 2
    " Look at the first arg. Is it a value *and* unit, or just a unit?
    if a:1 =~# '[0-9]\+[a-zAaZ]\+[a-zA-Z0-9]*'
      " If given a value-unit combo a la "15kg"
      let @n = a:1
      let new_unit = a:2
      let nakedval = 0
      let replace_selection = 0
    else
      " Else we got just a unit specified, which means we're operating on the
      " last selection
      " Get the last selection into reg n
      silent! normal! gv"ny

      let @n = @n . a:1
      let new_unit = a:2
      let nakedval = 1
      let replace_selection = 1
    endif
  else
    " Only one arg: assume it is the target unit
    " Get the last selection into reg n
    silent! normal! gv"ny

    let new_unit = a:1
    let nakedval = 0
    let replace_selection = 1
  endif

  " Actually convert things between units
  let unitsargs = "'" . @n . "' '" . new_unit . "'"
  let @n = system(g:convert_command . ' ' . unitsargs)
  if v:shell_error !=# 0
    """ Bail
    echon @n
    let @n = nbak
    return
  endif
  let @n = split(@n, '\n')[0] " Get first line
  " Pare down to just the numerical result
  let @n = substitute(@n, '^\s\+\*\s\+', '', '')
  " Limit significant figures if configured to do so
  if !nakedval
    " If the source unit was given as an arg and not part of the selection,
    " put the answer back in place in the same manner: no units
    let @n = join([@n, new_unit], '')
  endif

  if replace_selection
    " If the function was apparently called unrelated to any prev text selection
    " Delete original selection
    normal! gvd
    normal! "nP
    " restore the visual selection to the whole new value
    let selectrange = repeat('l', len(@n) - 1)
    execute 'normal! `<v' . selectrange
  else
    " ...and replace it with the new value
    normal! "np
  endif

  " Restore register n to its original state
  let @n = nbak
endfunction
""" }}}
