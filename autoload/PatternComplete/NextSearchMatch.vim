" PatternComplete/NextSearchMatch.vim: Get next match for command-line insertion.
"
" DEPENDENCIES:
"   - PatternComplete.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2011-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.02.003	14-Jun-2013	Use ingo/msg.vim.
"   1.00.002	06-Feb-2013	DWIM: Remove the \<...\> enclosure when the last
"				used search pattern is a whole word search (that
"				just has no matches now).
"	001	06-Feb-2013	file creation from PatternComplete.vim.

function! s:DefaultSearchResult()
    if @/ =~# '^\\<\k\+\\>$'
	" DWIM: Remove the \<...\> enclosure when the last used search pattern
	" is a whole word search (that just has no matches now).
	return substitute(@/, '^\\<\|\\>$', '', 'g')
    endif

    return @/
endfunction
function! PatternComplete#NextSearchMatch#Get( completeOption )
    " As an optimization, try a buffer-search from the cursor position first,
    " before triggering the full completion search over all windows.
    let l:startPos = searchpos(@/, 'cnw')
    if l:startPos != [0, 0]
	let l:endPos = searchpos(@/, 'enw')
	if l:endPos != [0, 0]
	    let l:searchMatch = CompleteHelper#ExtractText(l:startPos, l:endPos)
	    if ! empty(l:searchMatch)
		return l:searchMatch
	    endif
	endif
    endif

    if empty(a:completeOption) || a:completeOption ==# '.'
	" No completion from other buffers desired.
	return s:DefaultSearchResult()
    endif

    " Do a full completion search.
    " XXX: As the CompleteHelper#FindMatches() implementation visits every
    " window (and this is not allowed in a :cmap), we need to jump out of
    " command-line mode for that, and then do the insertion into the
    " command-line ourselves.
    let [s:cmdline, s:cmdpos] = [getcmdline(), getcmdpos()]
    return "\<C-c>:call PatternComplete#NextSearchMatch#Set(" . string(a:completeOption) . ")\<CR>"
endfunction
function! PatternComplete#NextSearchMatch#Set( completeOption )
    try
	let l:completeMatches = []
	" As the command-line is directly set via c_CTRL-\_e, no translation of
	" newlines is necessary.
	call CompleteHelper#FindMatches(l:completeMatches, @/, {'complete': a:completeOption})
	if ! empty(l:completeMatches)
	    let s:match = l:completeMatches[0].word
	else
	    " Fall back to returning the search pattern itself. It's up to the
	    " user to turn it into literal text by editing out the regular
	    " expression atoms.
	    let s:match = s:DefaultSearchResult()
	endif

	call feedkeys(":\<C-\>e(PatternComplete#NextSearchMatch#SetCmdline())\<CR>")
    catch /^Vim\%((\a\+)\)\=:E/
	call ingo#msg#VimExceptionMsg()
    endtry
endfunction
function! PatternComplete#NextSearchMatch#SetCmdline()
    call setcmdpos(s:cmdpos + len(s:match))
    return strpart(s:cmdline, 0, s:cmdpos - 1) . s:match . strpart(s:cmdline, s:cmdpos - 1)
endfunction
function! PatternComplete#NextSearchMatch#InsertInCmdline()
    " For the command-line, newlines must be represented by a ^@; otherwise, the
    " newline would be interpreted as <CR> and prematurely execute the
    " command-line.
    return substitute(PatternComplete#NextSearchMatch#Get(PatternComplete#GetCompleteOption()), '\n', "\<C-v>\<C-@>", 'g')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
