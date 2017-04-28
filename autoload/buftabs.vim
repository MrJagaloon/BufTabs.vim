"------------------------------------------------------------------------------"
"        file: buftabs.vim                                                     "
"      author: Justin Gifford (MrJagaloon)                                     "
"     version: 0.1                                                             "
" description: The autoload file for the plugin BufTabs.vim                    "
"------------------------------------------------------------------------------"

" Section: Public {{{1

" Function: buftabs#tabline {{{2
function! buftabs#tabline()
    if !exists('g:buftabs_enabled') || !g:buftabs_enabled
        return
    endif
    call s:update_buftabs()

    if s:buftab_updated
        call s:update_tabline()
        let s:buftab_updated = 0
    endif

    return s:buftabline
endfunction

" Function: buftabs#toggle {{{2
function! buftabs#toggle()
    if g:buftabs_enabled
        call buftabs#disable()
    else
        call buftabs#enable()
    endif
endfunction

" Function: buftabs#enable {{{2
function! buftabs#enable()
    if !g:buftabs_enabled
        let g:buftabs_enabled = 1
        let s:usertabline = &tabline
        call s:update_highlights()
        call s:update_buftabs()
        call s:update_tabline()
        set tabline=%!buftabs#tabline()
    endif
endfunction

" Function: buftabs#disable {{{2
function! buftabs#disable()
    if g:buftabs_enabled
        let &tabline = s:usertabline
        let g:buftabs_enabled = 0
    endif
endfunction

" Function: buftabs#toggle_numbers {{{2
function! buftabs#toggle_numbers()
    if g:buftabs_show_number
        call buftabs#hide_numbers()
    else
        call buftabs#show_numbers()
    endif
endfunction

" Function: buftabs#show_numbers {{{2
function! buftabs#show_numbers()
    let g:buftabs_show_number = 1
    if g:buftabs_enabled 
        let s:buftab_updated = 1
        call s:update_tabline()
        set tabline=%!buftabs#tabline()
    endif
endfunction

" Function: buftabs#hide_numbers {{{2
function! buftabs#hide_numbers()
    let g:buftabs_show_number = 0
    if g:buftabs_enabled 
        let s:buftab_updated = 1
        call s:update_tabline()
        set tabline=%!buftabs#tabline()
    endif
endfunction


" Section: Private {{{1

let s:buftabs = []
let s:buftabline = ""
let s:usertabline = ""
let s:buftab_updated = 0

augroup BufTabs
    autocmd!
    autocmd ColorScheme * call s:update_highlights()
augroup END

command! -nargs=0 BufTabsToggle call buftabs#toggle()
command! -nargs=0 BufTabsEnable call buftabs#enable()
command! -nargs=0 BufTabsDisable call buftabs#disable()
command! -nargs=0 BufTabsToggleNumbers call buftabs#toggle_numbers()
command! -nargs=0 BufTabsShowNumbers call buftabs#show_numbers()
command! -nargs=0 BufTabsHideNumbers call buftabs#hide_numbers()

" Function: update_highlights {{{2
function! s:update_highlights() 
    if g:buftabs_enabled
        exec 'hi ' . g:buftabs_hi_tab
        exec 'hi ' . g:buftabs_hi_cur_tab
        exec 'hi ' . g:buftabs_hi_alt_tab
        exec 'hi ' . g:buftabs_hi_sep
        exec 'hi ' . g:buftabs_hi_line_prefix
        exec 'hi ' . g:buftabs_hi_line_suffix
        exec 'hi ' . g:buftabs_hi_fill_before
        exec 'hi ' . g:buftabs_hi_fill_after
        set tabline=%!buftabs#tabline()
    endif
endfunction

" Function: update_tabline {{{2
function! s:update_tabline()
    if !g:buftabs_enabled
        return
    endif

    let s:buftabline = "%#BufTabFillBefore#"
    let s:buftabline = "%#BufTabLinePrefix#" . g:buftabs_line_prefix
    let s:buftabline .= "%#BufTabSep#" . g:buftabs_outer_sep

    let idx = 0
    while idx < len(s:buftabs)
        let buftab = s:buftabs[idx]
        let s:buftabline .= buftab.label
        if idx != len(s:buftabs) - 1
            let s:buftabline .= "%#BufTabSep#" . g:buftabs_inner_sep
        endif
        let idx += 1
    endwhile

    let s:buftabline .= "%#BufTabSep#" . g:buftabs_outer_sep
    let s:buftabline .= "%#BufTabLineSuffix#" . g:buftabs_line_suffix 
    let s:buftabline .= "%#BufTabFillAfter#"
    
    " Align the tabline
    "if g:buftabs_align !=? 'left'
    "    let screen_cols = system("tput cols")

    "    if g:buftabs_align ==? 'center'

    "    elseif g:buftabs_align ==? 'right'

    "    endif
    "endif
endfunction

" Function: new_buffer {{{2
function! s:new_buffer(bnr)
    " Make sure buffer does not already have a buftab.
    for buftab in s:buftabs
        if buftab.bufnr == a:bnr | return | endif
    endfor

    " If tabbable, create a new buftab
    if s:buffer_is_tabbable(a:bnr)
        call setbufvar(a:bnr, "buftabbed", 1)
        let name = fnamemodify(bufname(a:bnr), g:buftabs_bufname_fmt)
        let buftab = {
         \  'bufnr':    a:bnr,
         \  'name':     name,
         \  'status':   '',
         \  'modified': 0,
         \  'label':    ''
         \  }
        call s:update_buftab(buftab)
        call add(s:buftabs, buftab)
        let s:buftabs = sort(copy(s:buftabs), "s:cmp_buftabs")
    endif
endfunction

" Function: update_buftabs {{{2
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

" Function: update_buftab {{{2
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

    let bufmodified = getbufvar(a:buftab.bufnr, '&modified')
    if a:buftab.modified != bufmodified
        let a:buftab.modified = bufmodified
        let s:buftab_updated = 1
    endif

    if s:buftab_updated
        call s:update_buftab_label(a:buftab)
    endif
endfunction

" Function: update_buftab_label {{{2
function! s:update_buftab_label(buftab)

    let padding = ''
    if g:buftabs_tab_padding > 0
        let padding = repeat(' ', g:buftabs_tab_padding)
    endif
    
    if a:buftab.status == '%'
        let higroup = 'BufTabCur'
    elseif a:buftab.status == '#'
        let higroup = 'BufTabAlt'
    else
        let higroup = 'BufTab'
    endif

    let a:buftab.label = '%#' . higroup . '#' . padding . g:buftabs_tab_prefix

    if g:buftabs_show_number 
        let a:buftab.label .= a:buftab.bufnr . ':'
    endif

    let a:buftab.label .= a:buftab.name

    if a:buftab.modified
        let a:buftab.label .= g:buftabs_mod_flag
    endif

    let a:buftab.label .= g:buftabs_tab_suffix . padding
endfunction

" Function: buffer_is_tabbable {{{2
function! s:buffer_is_tabbable(bnr)
    return getbufvar(a:bnr, '&buflisted')
endfunction

" Function: cmp_buftabs {{{2
function! s:cmp_buftabs(buftab1, buftab2)
    return a:buftab1.bufnr - a:buftab2.bufnr
endfunction

