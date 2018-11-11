
if exists('g:loaded_vim_gt_line_test') || &compatible
  finish
endif
let g:loaded_vim_gt_line_test = 1

" Given the scriptName return the SID for the current runtime of vim.
" Lists all sourced scripts, finds the scrip line that mathes the given
" scriptName. Expects only one match. Then parses the line describing the
" given scriptName
func! s:getScriptID(scriptName)

    let l:allScripts = split(execute('scriptnames'), '\n')

    let l:matchingLine = ''
    for line in l:allScripts
        echom 'Printing line ' . line
        if line =~ a:scriptName
            " First time seeing a matching script.
            if l:matchingLine == ''
                let l:matchingLine = line
            else
                " Multiple matches of the scriptName. Unexpected
                throw 'Found ' . a:scriptName . ' multiple times in sourced scripts.'
            endif
        endif
    endfor
    if l:matchingLine == ''
        throw  'Could not find ' . a:scriptName . ' in sourced scripts'
    endif

    " The matching line looks like this:
    " 20: ~/src/ruanyl/vim-gh-line/plugin/vim-gh-line.vim
    " extract the first number before : and return it as the scriptID
endfunction


" TODO: Add an Assert function that prints an error message and exists with
" error (cq)


" runAllTests is the entrance function of this test file. It is called from the
" RunAllTests command. Right now all other test functions need to be explicitly
" called in it. Once you add a new test function, make sure you modify
" runAllTest too.
func! s:runAllTests()
    echom "Calling runAllTest"

    " let l:scriptID = s:getScriptID("vim-gh-line.vim")
    let l:scriptID = s:getScriptID("vim-gh-line.vim")

endfunction

func! s:printStderr(output)
  let lines = split(a:output, '\n')
  let tmp = tempname()
  call writefile(lines, tmp)
  execute printf('silent !%s %s 1>&2', 'cat', tmp)
  call delete(tmp)
endfunction

func! s:tryRunAllTests()
    try
        call s:runAllTests()
    catch
        let l:error = 'Test error: ' . v:exception . ' (in ' . v:throwpoint . ')'
        call s:printStderr(l:error)
        echom 'TESTS FAILED'
        " quit with error
        cq
    finally
        echom 'TESTS PASSED'
        " quit with sucess
        qall
    endtry
endfunction

command!  RunAllTests call s:tryRunAllTests()

