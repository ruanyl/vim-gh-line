
if exists('g:loaded_vim_gt_line_test') || &compatible
  finish
endif
let g:loaded_vim_gt_line_test = 1


" testUnrecognizedRemoteErrors verifies that a reasonable error is generated
" if the remote cannot be recognized belonging to a known git hosting
" environment. GitHub, GitLab ....
func! s:testUnrecognizedRemoteErrors(sid)
    call s:persistedPrint('Calling testUnrecognizedRemoteErrors')

    let l:initialRemote = system('git config --get remote.origin.url')
    let l:unrecognizableRemote = 'someStringThatCannotBeRemote'
    let g:git_remote = 'origin'

    call system('git config remote.origin.url ' . l:unrecognizableRemote)

    try
        call s:callWithSID(a:sid, 'gh_line', 'blob', 0)
        assert_report('gh_line did not throw an expected exception')
    catch
        call assert_exception(l:unrecognizableRemote)
        call assert_exception('has not been recognized as belonging to ' ,
            \ 'one of the supported git hosing environments: ')
    endtry

    call system('git config remote.origin.url ' . l:initialRemote)
endfunction

func! s:testFindGitRemote(sid)
    call s:persistedPrint('Calling testFindGitRemote')

    let l:remote_list = ['origin']
    let l:expected_remote = 'origin'
    let l:remote = s:callWithSID(a:sid, 'find_git_remote', l:remote_list)

    call assert_equal(l:expected_remote, l:remote,
        \ 'it should return the remote directly if there is only one remote')
    " TODO: test interactive input?
endfunction

func! s:testGithub(sid)
    call s:persistedPrint('Calling testGithub')

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://github.com/ruanyl/vim-gh-line.git')
    call assert_equal(1, l:act, 'Github can parse github remote correctly')

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://otherDomain.com/ruanyl/vim-gh-line.git')
    call assert_equal(0, l:act, 'Github can detect non-github domain.')


    let g:gh_github_domain = "git.dev.acme.net"

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://git.dev.acme.net/ruanyl/vim-gh-line.git')
    call assert_equal(1, l:act,
        \ 'Github can detect github domain while g:gh_github_domain is set')

    let l:act = s:callWithSID(a:sid, 'Github',
        \ 'https://otherDomain.com/ruanyl/vim-gh-line.git')
    call assert_equal(0, l:act,
        \ 'Github can detect non-github domain while g:gh_github_domain is set')

    unlet g:gh_github_domain
endfunction

func! s:testAction(sid)
    call s:persistedPrint('Calling testAction')

    let g:gh_cgit_url_pattern_sub = [
        \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ]

    let l:act = s:callWithSID(a:sid, 'Action',
        \ 'https://git.savannah.gnu.org/git/bash.git', 'blob')
    call assert_equal('/tree', l:act,
        \ 'Action did not return the correct value for blob in cgit repo')

    unlet g:gh_cgit_url_pattern_sub
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
        \ 'GithubUrl unexpected result with ssh protocol (scp style)')

    let l:act = s:callWithSID(a:sid, 'GithubUrl',
        \ 'ssh://git@github.com/ruanyl/vim-gh-line.git')
    call assert_equal('https://github.com/ruanyl/vim-gh-line', l:act,
        \ 'GithubUrl unexpected result with ssh protocol (ssh:// style)')
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


func! s:testGhCgitUrlPatternSubUsage(sid)
    " testGhCgitUrlPatternSubUsage verifies code that uses g:gh_cgit_url_pattern_sub
    " variable. Verify that CgitUrl() parses {pattern} and {sub} correctly and
    " retuns expected results. Vefify that Cgit() returns true if a match can
    " be found.
    call s:persistedPrint('Calling testGhCgitUrlPatternSubUsage')

    let g:gh_cgit_url_pattern_sub = [
        \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ['.\+git.savannah.gnu.org:/srv/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ['.\+git.kernel.org/', 'https://git.kernel.org/'],
        \ ['.\+anongit.kde.org/', 'https://cgit.kde.org/'],
        \ ]

    " Possible remotes for bash.git repo are listed here
    " https://savannah.gnu.org/git/?group=bash
    " and here
    " http://git.savannah.gnu.org/cgit/bash.git/
    let l:urlToPossibleRemotes = [
      \ ['http://git.savannah.gnu.org/cgit/bash.git',
          \ [
            \ 'https://git.savannah.gnu.org/git/bash.git',
            \ 'myUserName@git.savannah.gnu.org:/srv/git/bash.git',
            \ ]
        \ ],
      \ ['https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git',
          \ [
            \ 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git',
            \ 'https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git',
            \ ]
        \ ],
      \ ['https://cgit.kde.org/ark.git',
          \ [
            \ 'git://anongit.kde.org/ark.git',
            \ 'https://anongit.kde.org/ark.git',
            \ ]
        \ ],
    \ ]

    for l:testCase in l:urlToPossibleRemotes
        let l:expectedUrl = l:testCase[0]
        let l:possibleRemotes = l:testCase[1]
        for l:currRemote in l:possibleRemotes
            " Verify CgitUrl()
            let l:act = s:callWithSID(a:sid, 'CgitUrl', l:currRemote)
            call assert_equal(l:expectedUrl, l:act,
                \ 'CgitUrl unexpected result with url: ' . l:expectedUrl .
                \ ' remote: ' . l:currRemote)

            " Verify Cgit()
            let l:act = s:callWithSID(a:sid, 'Cgit', l:currRemote)
            call assert_true(l:act,
                \ 'Cgit did not return true on a remote that should match')
        endfor
    endfor

    unlet g:gh_cgit_url_pattern_sub
endfunction

func! s:testGhCgitUrlPatternSubUsageErrors(sid)
    " testGhCgitUrlPatternSubUsageErrors verifies that the CgitUrl throws an
    " exception if a remote cannot be matched in any of the patterns in
    " g:gh_cgit_url_pattern_sub. Also Cgit() function returns false if a match
    " cannot be found.
    call s:persistedPrint('Calling testGhCgitUrlPatternSubUsageErrors')

    let g:gh_cgit_url_pattern_sub = [
        \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
        \ ]

    let l:urlToPossibleRemotes = [
      \ ['https://cgit.kde.org/ark.git',
          \ [
            \ 'git://anongit.kde.org/ark.git',
            \ 'https://anongit.kde.org/ark.git',
            \ ]
        \ ],
    \ ]

    for l:testCase in l:urlToPossibleRemotes
        let l:possibleRemotes = l:testCase[1]

        for l:currRemote in l:possibleRemotes
            " Verify CgitUrl()
            try
                call s:callWithSID(a:sid, 'CgitUrl', l:currRemote)
                assert_report('CgitUrl did not throw an expected exception')
            catch
                call assert_exception('Could not match remote url',
                    \ 'CgitUrl did not throw the expected exception')
            endtry

            " Verify Cgit()
            let l:act = s:callWithSID(a:sid, 'Cgit', l:currRemote)
            call assert_false(l:act,
                \ 'Cgit did not return false on a remote that should not match')

        endfor
    endfor

    unlet g:gh_cgit_url_pattern_sub
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
    call s:testUnrecognizedRemoteErrors(l:scriptID)

    call s:testGithub(l:scriptID)
    call s:testAction(l:scriptID)
    call s:testCommit(l:scriptID)

    call s:testGithubUrl(l:scriptID)
    call s:testBitBucketUrl(l:scriptID)
    call s:testGitLabUrl(l:scriptID)

    call s:testGhCgitUrlPatternSubUsage(l:scriptID)
    call s:testGhCgitUrlPatternSubUsageErrors(l:scriptID)
    call s:testFindGitRemote(l:scriptID)

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

