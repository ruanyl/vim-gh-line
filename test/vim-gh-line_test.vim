
if exists('g:loaded_vim_gt_line_test') || &compatible
  finish
endif
let g:loaded_vim_gt_line_test = 1


func! s:testGithub(sid)
    call s:persistedPrint('Calling testGithub')

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://github.com/ruanyl/vim-gh-line.git')
    call assert_equal(1, l:act, 'Github can parse github remote correctly')

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://otherDomain.com/ruanyl/vim-gh-line.git')
    call assert_equal(0, l:act, 'Github can detect non-github domain.')
endfunction

func! s:testCommit(sid)
    call s:persistedPrint('Calling testCommit')

    let l:fileDir = resolve(expand("%:p:h"))
    let l:cdDir = "cd '" . fileDir . "'; "

    let l:branch = system(l:cdDir . 'git rev-parse --abbrev-ref HEAD')

    let g:gh_use_canonical = 0
    let l:act = s:callWithSID(a:sid, 'Commit', l:cdDir)
    call assert_match(l:branch, l:act,
        \ 'Expected to find branch name in the Commit output ')
    unlet g:gh_use_canonical
endfunction

func! s:testGithubUrl(sid)
    call s:persistedPrint('Calling testGithubUrl')

    let l:act = s:callWithSID(a:sid, 'GithubUrl',
        \ 'https://github.com/ruanyl/vim-gh-line.git')
    call assert_equal('https://github.com/ruanyl/vim-gh-line', l:act,
        \ 'GithubUrl unexpected result with https protocol')

    let l:act = s:callWithSID(a:sid, 'GithubUrl',
        \ 'git@github.com:ruanyl/vim-gh-line.git')
    call assert_equal('https://github.com/ruanyl/vim-gh-line', l:act,
        \ 'GithubUrl unexpected result with ssh protocol')
endfunction

func! s:testBitBucketUrl(sid)
    call s:persistedPrint('Calling testBitBucketUrl')

    let l:act = s:callWithSID(a:sid, 'BitBucketUrl',
        \ 'https://bitbucket.org/atlassian/django_scim.git')
    call assert_equal('https://bitbucket.org/atlassian/django_scim', l:act,
        \ 'BitBucketUrl unexpected result with https protocol')

    let l:act = s:callWithSID(a:sid, 'BitBucketUrl',
        \ 'git@bitbucket.org:atlassian/django_scim.git')
    call assert_equal('https://bitbucket.org/atlassian/django_scim', l:act,
        \ 'BitBucketUrl unexpected result with ssh protocol')
endfunction

func! s:testGitLabUrl(sid)
    call s:persistedPrint('Calling testGitLabUrl')

    let l:act = s:callWithSID(a:sid, 'GitLabUrl',
        \ 'https://gitlab.com/gitlab-org/gitlab-ce.git')
    call assert_equal('https://gitlab.com/gitlab-org/gitlab-ce', l:act,
        \ 'GitLabUrl unexpected result with https protocol')

    let l:act = s:callWithSID(a:sid, 'GitLabUrl',
        \ 'git@gitlab.com:gitlab-org/gitlab-ce.git')
    call assert_equal('https://gitlab.com/gitlab-org/gitlab-ce', l:act,
        \ 'GitLabUrl unexpected result with ssh protocol')
endfunction


func! s:testCGitUrl(sid)
    call s:persistedPrint('Calling testCGitUrl')

    let g:gh_cgit_pattern_to_url = [
        \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ['.\+git.savannah.gnu.org:/srv/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ]

    " Possible remotes for bash.git repo are listed here
    " https://savannah.gnu.org/git/?group=bash
    " and here
    " http://git.savannah.gnu.org/cgit/bash.git/
    let l:possibleRemotes = [
        \ 'https://git.savannah.gnu.org/git/bash.git',
        \ 'myUserName@git.savannah.gnu.org:/srv/git/bash.git',
    \ ]
    for l:currRemote in l:possibleRemotes
        let l:act = s:callWithSID(a:sid, 'CGitUrl', l:currRemote)
        call assert_equal('http://git.savannah.gnu.org/cgit/bash.git', l:act,
            \ 'CgitUrl unexpected result with remote: ' . l:currRemote)
    endfor


endfunction

" runAllTests is the entrance function of this test file. It is called from the
" RunAllTests command. Right now all other test functions need to be explicitly
" called in it. Once you add a new test function, make sure you modify
" runAllTest too.
func! s:runAllTests()
    call s:persistedPrint('Calling runAllTest')

    let l:scriptName = 'vim-gh-line.vim'
    let l:scriptID = s:getScriptID(l:scriptName)


    " Add all test functions here.
    call s:testGithub(l:scriptID)
    call s:testCommit(l:scriptID)

    call s:testGithubUrl(l:scriptID)
    call s:testBitBucketUrl(l:scriptID)
    call s:testGitLabUrl(l:scriptID)
    call s:testCGitUrl(l:scriptID)

endfunction

" persistedPrint prints the given string in vim and also outside of vim.
func! s:persistedPrint(output)
  echom a:output

  let lines = split(a:output, '\n')
  let tmp = tempname()
  call writefile(lines, tmp)
  execute printf('silent !%s %s 1>&2', 'cat', tmp)
  call delete(tmp)
endfunction

" getScriptID returns the SID of the given scriptName in the current runtime
" of vim.  Lists all sourced scripts, finds the line that mathes the
" given scriptName. Expects only one match. Then parses the line describing
" the given scriptName.
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

" callWithSID gives us the ability to call script local functions in the
" plugin implementation. For implementation details see
" https://vi.stackexchange.com/a/17871/13792
func! s:callWithSID(sid,funcName,...)
    let l:FuncRef = function('<SNR>' . a:sid . '_' . a:funcName)
    let l:rv = call(l:FuncRef, a:000)
    return l:rv
endfunc

func! s:exitWithError()
    call s:persistedPrint('TESTS FAILED')
    " quit with error
    cq
endfunction

" tryRunAllTests, does error checking after all tests are called. Catches
" exceptions and checks for failed assertions.
func! s:tryRunAllTests()
    try
        call s:runAllTests()
    catch
        " In case of an exception always fail
        let l:error = 'Exception: ' . v:exception . ' (in ' . v:throwpoint . ')'
        call s:persistedPrint(l:error)
        call s:exitWithError()
    endtry

    " No exception. But check for assertion errors
    if len(v:errors) > 0
        " We had assertion errors. Tests will fail
        for err in v:errors
            let l:error = 'assertion error: ' . err
            call s:persistedPrint(l:error)
        endfor
        call s:exitWithError()
    else
        " No exception, no assertion errors.
        call s:persistedPrint('TESTS PASSED')
        " quit with sucess
        qall
    endif

endfunction

command!  RunAllTests call s:tryRunAllTests()

