" PatternComplete.vim: Insert mode completion for matches of queried / last search pattern.
"
" DEPENDENCIES:
"   - CompleteHelper.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2011-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.01.009	14-Jun-2013	Use ingo/msg.vim.
"   1.01.008	06-Feb-2013	Move command-line insertion functions to
"				separate PatternComplete/NextSearchMatch.vim
"				script. Only need to additionally expose
"				s:GetCompleteOption().
"   1.00.007	01-Sep-2012	Make a:matchObj in CompleteHelper#ExtractText()
"				optional; it's not used there, anyway.
"	006	20-Aug-2012	Split off functions into separate autoload
"				script and documentation into dedicated help
"				file.
"	005	14-Dec-2011	BUG: Forgot to rename s:Process().
"	004	12-Dec-2011	Factor out s:ErrorMsg().
"				Error message delay is only necessary when
"				'cmdheight' is 1.
"	003	04-Oct-2011	CompleteHelper multiline handling is now
"				disabled; remove dummy function.
"	002	04-Oct-2011	Move s:Process() to CompleteHelper#Abbreviate().
"	001	03-Oct-2011	file creation from MotionComplete.vim.

function! PatternComplete#GetCompleteOption()
    return (exists('b:PatternComplete_complete') ? b:PatternComplete_complete : g:PatternComplete_complete)
endfunction

function! s:ErrorMsg( exception )
    call ingo#msg#VimExceptionMsg()

    if &cmdheight == 1
	sleep 500m
    endif
endfunction
function! PatternComplete#PatternComplete( findstart, base )
    if a:findstart
	" This completion does not consider the text before the cursor.
	return col('.') - 1
    else
	try
	    let l:matches = []
	    call CompleteHelper#FindMatches(l:matches, s:pattern, {'complete': PatternComplete#GetCompleteOption()})
	    call map(l:matches, 'CompleteHelper#Abbreviate(v:val)')
	    return l:matches
	catch /^Vim\%((\a\+)\)\=:E/
	    call s:ErrorMsg(v:exception)
	    return []
	endtry
    endif
endfunction
function! PatternComplete#WordPatternComplete( findstart, base )
    if a:findstart
	" This completion does not consider the text before the cursor.
	return col('.') - 1
    else
	try
	    let l:matches = []
	    call CompleteHelper#FindMatches(l:matches, '\<\%(' . s:pattern . '\m\)\>', {'complete': PatternComplete#GetCompleteOption()})
	    if empty(l:matches)
		call CompleteHelper#FindMatches(l:matches, '\%(^\|\s\)\zs\%(' . s:pattern . '\m\)\ze\%($\|\s\)', {'complete': PatternComplete#GetCompleteOption()})
	    endif

	    call map(l:matches, 'CompleteHelper#Abbreviate(v:val)')
	    return l:matches
	catch /^Vim\%((\a\+)\)\=:E/
	    call s:ErrorMsg(v:exception)
	    return []
	endtry
    endif
endfunction

function! s:PatternInput( isWordInput )
    call inputsave()
    let s:pattern = input('Pattern to find ' . (a:isWordInput ? 'word-' : '') . 'completions: ')
    call inputrestore()
endfunction
function! PatternComplete#InputExpr( isWordInput )
    call s:PatternInput(a:isWordInput)
    if empty(s:pattern)
	" Note: When nothing is returned, the command-line isn't cleared
	" correctly, so it isn't clear that we're back in insert mode. Avoid
	" this by making a no-op insert.
	"return ''
	return "$\<BS>"
    endif

    if a:isWordInput
	set completefunc=PatternComplete#WordPatternComplete
    else
	set completefunc=PatternComplete#PatternComplete
    endif
    return "\<C-x>\<C-u>"
endfunction
function! PatternComplete#SearchExpr()
    if empty(@/)
	call ingo#msg#ErrorMsg('E35: No previous regular expression')
	return "$\<BS>"
    endif

    let s:pattern = @/
    set completefunc=PatternComplete#PatternComplete
    return "\<C-x>\<C-u>"
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
