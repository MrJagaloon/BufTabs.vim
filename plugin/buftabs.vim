"------------------------------------------------------------------------------"
"        file: buftabs.vim                                                     "
"      author: Justin Gifford (MrJagaloon)                                     "
"     version: 0.1                                                             "
" description: The main file of the BufTabs.vim plugin.                        "
"------------------------------------------------------------------------------"

if exists("g:loaded_buftabs")
    finish
endif
let g:loaded_buftabs = 1

" Variable Declarations {{{1
let s:defaults = {
 \  'g:buftabs_hi_tab':         'BufTab           ctermfg=20 ctermbg=18 cterm=none',
 \  'g:buftabs_hi_cur_tab':     'BufTabCur        ctermfg=02 ctermbg=19 cterm=none',
 \  'g:buftabs_hi_alt_tab':     'BufTabAlt        ctermfg=07 ctermbg=19 cterm=none',
 \  'g:buftabs_hi_sep':         'BufTabSep        ctermfg=08 ctermbg=00 cterm=none',
 \  'g:buftabs_hi_line_prefix': 'BufTabLinePrefix ctermfg=08 ctermbg=00 cterm=none',
 \  'g:buftabs_hi_line_suffix': 'BufTabLineSuffix ctermfg=08 ctermbg=00 cterm=none',
 \  'g:buftabs_hi_fill_before': 'BufTabFillBefore ctermfg=08 ctermbg=00 cterm=none',
 \  'g:buftabs_hi_fill_after':  'BufTabFillAfter  ctermfg=08 ctermbg=00 cterm=none',
 \  'g:buftabs_bufname_fmt':    ':t',
 \  'g:buftabs_inner_sep':      ' ',
 \  'g:buftabs_outer_sep':      '',
 \  'g:buftabs_tab_prefix':     '',
 \  'g:buftabs_tab_suffix':     '',
 \  'g:buftabs_line_prefix':    '    ',
 \  'g:buftabs_line_suffix':    '',
 \  'g:buftabs_mod_flag':       '+',
 \  'g:buftabs_show_number':    0,
 \  'g:buftabs_align':          'left',
 \  'g:buftabs_tab_padding':    1
 \  }

" Function: init {{{1
" Initialize the BufTabLine.
function! s:init() 
    for [var, default] in items(s:defaults)
        call s:init_var(var, default)
    endfor

    if exists('g:buftabs_enabled') && g:buftabs_enabled
        let g:buftabs_enabled = 0   " buftabs#enable needs this to work properly
        call buftabs#enable()
    endif
endfunction


" Function: init_var {{{1
" Checks if 'var' has been defined, and if not, sets it to 'default'.
function! s:init_var(var, default)
    if !exists(a:var)
        let {a:var} = a:default
    endif
endfunction

" Initialize the script {{{1
call s:init()
