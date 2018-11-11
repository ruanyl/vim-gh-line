
if exists('g:loaded_vim_gt_line_test') || &compatible
  finish
endif
let g:loaded_vim_gt_line_test = 1

" Print the given string in vim and also outside of vim.
func! s:persistedPrint(output)
  echom a:output

  let lines = split(a:output, '\n')
  let tmp = tempname()
  call writefile(lines, tmp)
  execute printf('silent !%s %s 1>&2', 'cat', tmp)
  call delete(tmp)
endfunction

" Given the scriptName return the SID for the current runtime of vim.
" Lists all sourced scripts, finds the scrip line that mathes the given
" scriptName. Expects only one match. Then parses the line describing the
" given scriptName
func! s:getScriptID(scriptName)

    let l:allScripts = split(execute('scriptnames'), '\n')

    let l:matchingLine = ''
    for line in l:allScripts
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
    let l:matchingList = split(l:matchingLine)
    if len(l:matchingList) != 2
        throw 'Unexlected line in scriptnames: ' . l:matchingLine
    endif

    let l:firstEntry = l:matchingList[0]
    let l:rv =  substitute(l:firstEntry, ':', '', '')
    return l:rv
endfunction


func! s:callWithSID(sid,funcName,...)
    let l:FuncRef = function('<SNR>' . a:sid . '_' . a:funcName)
    let l:rv = call(l:FuncRef, a:000)
    return l:rv
endfunc

func! s:testGithub(sid)
    call s:persistedPrint('Calling testGithub')

    let l:act = s:callWithSID(a:sid, 'Github', 'https://github.com/ruanyl/vim-gh-line.git')
    call assert_equal(l:act, 1, 'Github can parse github remote correctly')

    let l:act = s:callWithSID(a:sid, 'Github', 'https://otherDomain.com/ruanyl/vim-gh-line.git')
    call assert_equal(l:act, 0, 'Github detect non-github domain.')

endfunction


" runAllTests is the entrance function of this test file. It is called from the
" RunAllTests command. Right now all other test functions need to be explicitly
" called in it. Once you add a new test function, make sure you modify
" runAllTest too.
func! s:runAllTests()
    call s:persistedPrint('Calling runAllTest')

    let l:scriptName = 'vim-gh-line.vim'
    let l:scriptID = s:getScriptID(l:scriptName)
    call s:persistedPrint('SID for script: ' . l:scriptName . ' is: ' . l:scriptID)


    " Add all test functions here.
    call s:testGithub(l:scriptID)


endfunction

func! s:tryRunAllTests()
    try
        call s:runAllTests()
    catch
        let l:error = 'Test error: ' . v:exception . ' (in ' . v:throwpoint . ')'
        call s:persistedPrint(l:error)
        call s:persistedPrint('TESTS FAILED')
        " quit with error
        cq
    finally
        call s:persistedPrint('TESTS PASSED')
        " quit with sucess
        qall
    endtry
endfunction

command!  RunAllTests call s:tryRunAllTests()

