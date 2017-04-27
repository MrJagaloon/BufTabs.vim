"------------------------------------------------------------------------------"
"        file: buftabs.vim                                                     "
"      author: Justin Gifford (MrJagaloon)                                     "
"     version: 0.1                                                             "
" description: A plugin to change vim's tabline into a buffer tab line.        "
"------------------------------------------------------------------------------"

if exists("g:loaded_buftabs")
    finish
endif
let g:loaded_buftabs = 1

" Function: init {{{1
" Initialize the BufTabLine.
function! s:init() 
    " Initialize global variables
    " highlights
    call s:init_var('g:buftabs#hi', 'BufTab ctermfg=20 ctermbg=18 cterm=none')
    call s:init_var('g:buftabs#cur_hi', 'BufTabCur ctermfg=02 ctermbg=19 cterm=none')
    call s:init_var('g:buftabs#alt_hi', 'BufTabAlt ctermfg=20 ctermbg=18 cterm=none')
    call s:init_var('g:buftabs#sep_hi', 'BufTabSep ctermfg=08 ctermbg=00 cterm=none')
    call s:init_var('g:buftabs#fill_hi', 'BufTabFill ctermfg=08 ctermbg=00 cterm=none')
    call s:init_var('g:buftabs#before_hi', 'BufTabBefore ctermfg=08 ctermbg=00 cterm=none')
    call s:init_var('g:buftabs#after_hi', 'BufTabAfter ctermfg=08 ctermbg=00 cterm=none')
    " buftab variables
    call s:init_var('g:buftabs#before_name',     ' ')
    call s:init_var('g:buftabs#name_fmt',        ':t')
    call s:init_var('g:buftabs#after_name',      ' ')
    " current buftab variables
    call s:init_var('g:buftabs#before_cur_name', ' ')
    call s:init_var('g:buftabs#cur_name_fmt',    ':t')
    call s:init_var('g:buftabs#after_cur_name',  ' ')
    " alternate buftab variables
    call s:init_var('g:buftabs#before_alt_name', ' #')
    call s:init_var('g:buftabs#alt_name_fmt',    ':t')
    call s:init_var('g:buftabs#after_alt_name',  ' ')

    call s:init_var('g:buftabs#sep',             '|')
    call s:init_var('g:buftabs#before',          ' -|')
    call s:init_var('g:buftabs#after',           '|- ')
    call s:init_var('g:buftabs#mod_flag',        '+')
    call s:init_var('g:buftabs#mod_flag_pos',    'right')

    " Initialize script variables
    let s:buftabs = []
    let s:buftabline = ""
    let s:buftab_updated = 0

    " Initialize the buftabs
    call s:update_highlights()
    call s:update_buftabs()

    augroup BufTabs
        autocmd!
        autocmd ColorScheme * call s:update_highlights()
    augroup END
endfunction

" Function: init_var {{{1
" Checks if 'var' has been defined, and if not, sets it to 'default'.
function! s:init_var(var, default)
    if !exists(a:var)
        let {a:var} = a:default
    endif
endfunction

" Function: update_highlights {{{1
function! s:update_highlights() 
    exec 'hi ' . g:buftabs#hi
    exec 'hi ' . g:buftabs#cur_hi
    exec 'hi ' . g:buftabs#alt_hi
    exec 'hi ' . g:buftabs#sep_hi
    exec 'hi ' . g:buftabs#fill_hi
    exec 'hi ' . g:buftabs#before_hi
    exec 'hi ' . g:buftabs#after_hi
    set tabline=%!BufTabLine()
endfunction

" Function: get_buftabline {{{1
function! BufTabLine()
    call s:update_buftabs()

    if s:buftab_updated
        call s:update_buftabline()
        let s:buftab_updated = 0
    endif

    return s:buftabline
endfunction

" Function: update_buftabline {{{1
function! s:update_buftabline()
    let s:buftabline = "%#BufTabBefore#" . g:buftabs#before

    let idx = 0
    while idx < len(s:buftabs)
        let buftab = s:buftabs[idx]
        let s:buftabline .= buftab.label
        if idx != len(s:buftabs) - 1
            let s:buftabline .= "%#BufTabSep#" . g:buftabs#sep
        endif
        let idx += 1
    endwhile

    let s:buftabline .= "%#BufTabAfter#" . g:buftabs#after . "%#BufTabFill#"
endfunction

" Function: update_buftabs {{{1
function! s:update_buftabs()
    " Check for new buffers
    for bnr in range(0, bufnr("$"))
        if bufexists(bnr) && !getbufvar(bnr, "buftabbed", 0) 
            call s:new_buffer(bnr) 
        endif
    endfor
    for buftab in s:buftabs
        call s:update_buftab(buftab)
    endfor
endfunction

" Function: new_buffer {{{1
function! s:new_buffer(bnr)
    " Make sure buffer does not already have a buftab.
    for buftab in s:buftabs
        if buftab.bufnr == a:bnr | return | endif
    endfor

    " If tabbable, create a new buftab
    if s:buffer_is_tabbable(a:bnr)
        call setbufvar(a:bnr, "buftabbed", 1)
        let buftab = {
         \  'bufnr':    a:bnr,
         \  'status':   '',
         \  'modified': 0,
         \  'label':    ''
         \  }
        call s:update_buftab(buftab)
        call add(s:buftabs, buftab)
        let s:buftabs = sort(copy(s:buftabs), "s:cmp_buftabs")
    endif
endfunction

" Function: update_buftab {{{1
function! s:update_buftab(buftab)

    " Check if buffer is still tabbable
    if !s:buffer_is_tabbable(a:buftab.bufnr)
        call remove(s:buftabs, index(s:buftabs, a:buftab))
        return
    endif

    " Get the buffer's current status.
    if a:buftab.bufnr == bufnr('%')
        if a:buftab.status != '%'
            let a:buftab.status = '%'
            let s:buftab_updated = 1
        endif
    elseif a:buftab.bufnr == bufnr('#') 
        if a:buftab.status != '#'
            let a:buftab.status = '#'
            let s:buftab_updated = 1
        endif
    else 
        if a:buftab.status != ''
            let a:buftab.status = ''
            let s:buftab_updated = 1
        endif
    endif

    " Get the buffer's current flags.
    let bufmodified = getbufvar(a:buftab.bufnr, '&modified')

    if a:buftab.modified != bufmodified
        let a:buftab.modified = bufmodified
        let s:buftab_updated = 1
    endif

    if s:buftab_updated
        call s:update_buftab_label(a:buftab)
    endif
endfunction

" Function: update_buftab_label {{{1
function! s:update_buftab_label(buftab)

    " Update buftab's hi group, format, and separators.
    if a:buftab.status == '%'
        " buffer is current
        let higroup = 'BufTabCur'
        let name_fmt = g:buftabs#cur_name_fmt
        let before_name = g:buftabs#before_cur_name
        let after_name = g:buftabs#after_cur_name
    elseif a:buftab.status == '#'
        " buffer is alternate 
        let higroup ='BufTabAlt'
        let name_fmt = g:buftabs#alt_name_fmt
        let before_name = g:buftabs#before_alt_name
        let after_name = g:buftabs#after_alt_name
    else
        let higroup ='BufTab'
        let name_fmt = g:buftabs#name_fmt
        let before_name = g:buftabs#before_name
        let after_name = g:buftabs#after_name
    endif

    " Add modified flag, if buffer was modified
    if a:buftab.modified
        if g:buftabs#mod_flag_pos ==? 'right'
            let after_name = ' ' . g:buftabs#mod_flag . after_name
        else
            let before_name .= g:buftabs#mod_flag . ' '
        endif
    endif

    let higroup = "%#". higroup. "#"
    let name = bufname(a:buftab.bufnr)
    let fmtd_name = fnamemodify(name, name_fmt)

    " Update the buftab's label
    let a:buftab.label = higroup . before_name . fmtd_name . after_name
endfunction

" Function: buffer_is_tabbable {{{1
function! s:buffer_is_tabbable(bnr)
    return getbufvar(a:bnr, '&buflisted')
endfunction

" Function: cmp_buftabs {{{1
function! s:cmp_buftabs(buftab1, buftab2)
    return a:buftab1.bufnr - a:buftab2.bufnr
endfunction

" Initialize the script {{{1
call s:init()
