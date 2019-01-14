"% Preliminary validation of global variables
"  and version of the editor.

if v:version < 700
  finish
endif

" check whether this script is already loaded
if exists('g:loaded_gh_line')
  finish
endif

let g:loaded_gh_line = 1

if !exists('g:gh_line_map_default')
    let g:gh_line_map_default = 1
endif

if !exists('g:gh_trace')
    let g:gh_trace = 0
endif

if !exists('g:gh_line_blame_map_default')
    let g:gh_line_blame_map_default = 1
endif

if !exists('g:gh_open_command')
    let g:gh_open_command = 'open '
endif

if !exists('g:gh_line_map') && g:gh_line_map_default == 1
    let g:gh_line_map = '<leader>gh'
endif

if !exists('g:gh_line_blame_map') && g:gh_line_blame_map_default == 1
    let g:gh_line_blame_map = '<leader>gb'
endif

if !exists('g:gh_use_canonical')
    let g:gh_use_canonical = 1
endif

if !exists('g:gh_gitlab_only_http')
    let g:gh_gitlab_only_http = 0
endif

if !exists('g:gh_cgit_url_pattern_sub')
    let g:gh_cgit_url_pattern_sub = []
endif

if !exists('g:gh_git_remote')
    let g:gh_git_remote = ""
endif

if !exists('g:gh_always_interactive')
    let g:gh_always_interactive = 0
endif

func! s:gh_line(action, force_interactive) range
    " Get Line Number/s
    let lineNum = line('.')
    let fileName = resolve(expand('%:t'))
    let fileDir = resolve(expand("%:p:h"))
    let cdDir = "cd '" . fileDir . "'; "

    let l:remotes = system(cdDir . "git remote")
    let l:remote_list = split(l:remotes, '\n')
    if len(l:remote_list) == 0
      echom "It seems the repo does not have any remote"
      return
    endif

    " try to find git remote:
    " if force interactive input, or g:gh_git_remote is not set, or
    " g:gh_git_remote is not the remote of current file, try to find git
    " remote name again
    if a:force_interactive == 1 || g:gh_git_remote == "" || index(l:remote_list, g:gh_git_remote) < 0
      let g:gh_git_remote = s:find_git_remote(l:remote_list)
    endif

    if g:gh_git_remote == ""
      return
    endif

    let remote_url = system(cdDir . "git config --get remote." . g:gh_git_remote . ".url")

    " Get Directory & File Names
    let fullPath = resolve(expand("%:p"))
    " Git Commands
    let commit = s:Commit(cdDir)
    let gitRoot = system(cdDir . "git rev-parse --show-toplevel")

    " Strip Newlines
    let remote_url = <SID>StripNL(remote_url)
    let commit = <SID>StripNL(commit)
    let gitRoot = <SID>StripNL(gitRoot)
    let fullPath = <SID>StripNL(fullPath)
    let action = s:Action(remote_url, a:action)

    " Git Relative Path
    let relative = split(fullPath, gitRoot)[-1]

    " Set Line Number/s; Form URL With Line Range
    if s:Github(remote_url)
      let lineRange = s:GithubLineLange(a:firstline, a:lastline, lineNum)
      let url = s:GithubUrl(remote_url) . action . commit . relative . '#' . lineRange
    elseif s:Bitbucket(remote_url)
      let lineRange = s:BitbucketLineRange(a:firstline, a:lastline, lineNum)
      let url = s:BitBucketUrl(remote_url) . action . commit . relative . '#' . lineRange
    elseif s:GitLab(remote_url)
      let lineRange = s:GitLabLineRange(a:firstline, a:lastline, lineNum)
      let url = s:GitLabUrl(remote_url) . action . commit . relative . '#' . lineRange
    elseif s:Cgit(remote_url)
      let lineRange = s:CgitLineRange(a:firstline, a:lastline, lineNum)
      let l:commitStr = ''
      if g:gh_use_canonical > 0
          let l:commitStr = '?id=' . commit
      endif
      let url = s:CgitUrl(remote_url) . action . relative . l:commitStr . '#' . lineRange
    else
        throw 'The remote: ' . remote_url . 'has not been recognized as belonging to ' .
            \ 'one of the supported git hosing environments: ' .
            \ 'GitHub, GitLab, BitBucket, Cgit.'
    endif

    let l:finalCmd = g:gh_open_command . url
    if g:gh_trace
        echom "vim-gh-line executing: " . l:finalCmd
    endif
    call system(l:finalCmd)
endfun

func! s:find_git_remote(remote_list)
  let l:remote = ""

  if len(a:remote_list) > 1
    call inputsave()
    let l:remote = input('Please select one remote(' . join(a:remote_list, ',') . '): ')
    call inputrestore()

    if index(a:remote_list, l:remote) < 0
      echom " <- seems it is not a valid remote name"
      let l:remote = ""
    endif
  elseif len(a:remote_list) == 1
    let l:remote = a:remote_list[0]
  endif

  return l:remote
endfunc

func! s:Action(remote_url, action)
  if a:action == 'blame'
    if s:Github(a:remote_url)
      return '/blame/'
    elseif s:Bitbucket(a:remote_url)
      return '/annotate/'
    elseif s:GitLab(a:remote_url)
      return '/blame/'
    elseif s:Cgit(a:remote_url)
      " TODO: Most Cgit frontends do not support blame functionality
      return '/blame'
    endif
  elseif a:action == 'blob'
    if s:Github(a:remote_url)
      return '/blob/'
    elseif s:Bitbucket(a:remote_url)
      return '/src/'
    elseif s:GitLab(a:remote_url)
      return '/blob/'
    elseif s:Cgit(a:remote_url)
      return '/tree'
    endif
  endif
endfunc

func! s:Commit(cdDir)
  if exists('g:gh_use_canonical') && g:gh_use_canonical > 0
    return system(a:cdDir . 'git rev-parse HEAD')
  else
    return system(a:cdDir . 'git rev-parse --abbrev-ref HEAD')
  endif
endfunc

func! s:Github(remote_url)
  return exists('g:gh_github_domain') && match(a:remote_url, g:gh_github_domain) >= 0 || match(a:remote_url, 'github') >= 0
endfunc

func! s:Bitbucket(remote_url)
  return match(a:remote_url, 'bitbucket.org') >= 0
endfunc

func! s:GitLab(remote_url)
  return exists('g:gh_gitlab_domain') && match(a:remote_url, g:gh_gitlab_domain) >= 0 || match(a:remote_url, 'gitlab') >= 0
endfunc

func! s:Cgit(remote_url)
  " Cgit returns true if remote_url is hosted on a Cgit frontend.
  " There is no one major site for hosting repositories in cgit , like in github.com.
  " Instead, cgit frontend is used by various open source communities with
  " different organization names. We iterate over the
  " g:gh_cgit_url_pattern_sub variable the user has provided.

    for pair in g:gh_cgit_url_pattern_sub
      let l:pattern = pair[0]
      if a:remote_url =~ l:pattern
          return 1
      endif
    endfor

    return 0
endfunc

func! s:GithubLineLange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    return 'L' . a:lineNum
  else
    return 'L' . a:firstLine . '-L' . a:lastLine
  endif
endfunc

func! s:BitbucketLineRange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    return '-' . a:lineNum
  else
    return '-' . a:firstLine . ':' . a:lastLine
  endif
endfunc

func! s:GitLabLineRange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    return 'L' . a:lineNum
  else
    return 'L' . a:firstLine . '-' . a:lastLine
  endif
endfunc

func! s:CgitLineRange(firstLine, lastLine, lineNum)
    " TODO: Does cgit gui support line number ranges ? Until we figure out
    " ignore the lastLine
    return 'n' . a:lineNum
endfunc

func! s:StripNL(l)
  return substitute(a:l, '\n$', '', '')
endfun

func! s:StripSuffix(input,fix)
  return substitute(a:input, a:fix . '$' , '', '')
endfun

func! s:StripPrefix(input,fix)
  return substitute(a:input, '^' . a:fix , '', '')
endfun

func! s:TransformSSHToHTTPS(input)
    " If the remote is using ssh protocol, we need to turn a git remote like this:
    " `git@github.com:<suffix>`
    " To a url like this:
    " `https://github.com/<suffix>`
    let l:rv = a:input
    let l:sed_cmd = "sed 's\/^[^@:]*@\\([^:]*\\):\/https:\\\/\\\/\\1\\\/\/;'"
    let l:rv = system("echo " . l:rv . " | " . l:sed_cmd)
    return l:rv
endfun

func! s:GithubUrl(remote_url)
  let l:rv = s:TransformSSHToHTTPS(a:remote_url)
  let l:rv = s:StripNL(l:rv)
  let l:rv = s:StripSuffix(l:rv, '.git')
  return l:rv
endfunc

func! s:BitBucketUrl(remote_url)
  let l:rv = s:TransformSSHToHTTPS(a:remote_url)
  let l:rv = s:StripNL(l:rv)
  let l:rv = s:StripSuffix(l:rv, '.git')
  " TODO: What does the following line do ?
  let l:rv = substitute(l:rv, '\(:\/\/\)\@<=.*@', '', '')
  return l:rv
endfunc

func! s:GitLabUrl(remote_url)
  let l:rv = s:TransformSSHToHTTPS(a:remote_url)
  let l:rv = s:StripNL(l:rv)
  let l:rv = s:StripSuffix(l:rv, '.git')
  if g:gh_gitlab_only_http
    let l:rv= substitute(l:rv, 'https://', 'http://', '')
  endif
  return l:rv
endfunc

func! s:CgitUrl(remote_url)
    " Cgit urls do not follow a regular consistent standard. For example the
    " following are all valid Cgit urls:
    "
    " (1) https://repo.or.cz/clang.git/...
    " (2) http://git.savannah.gnu.org/cgit/bash.git/...
    " (3) https://git.zx2c4.com/linux-dev/...
    " (4) https://git.yoctoproject.org/cgit.cgi/meta-intel/...
    "
    " Some of them have kept the .git extension in the url path (1),(2), some of them
    " have a novel string as the first path component ( ..org/CGIT/bash..(2) or
    " org/CGIT.CGI/meta (4) ), and some lack both (3). With these existing
    " variations, there is no simple heuristic to return the url for a cgit
    " remote.
    "
    " In addition to non-uniformity in the cgit front-end url, the remote
    " names also do not follow an obvious pattern. For example for GNU Bash,
    " (hosted on cgit) one of the following can be a remote:
    "
    " (A) git://git.savannah.gnu.org/bash.git
    " (B) https://git.savannah.gnu.org/git/bash.git
    " (C) ssh://git.savannah.gnu.org:/srv/git/bash.git
    "
    " The https based remote has `git` as the first path component (B), similarly,
    " the ssh based remote has `srv` (C). We do not have a heuristic to
    " compile the url by just looking at the remote. So we ask the user to
    " provide a mapping via g:gh_cgit_url_pattern_sub variable.

    for pair in g:gh_cgit_url_pattern_sub
      let l:pattern = pair[0]
      let l:sub= pair[1]
      if a:remote_url =~ l:pattern
          return substitute(a:remote_url, l:pattern, l:sub, '')
      endif
    endfor

    " No specified pattern has matched the passed remote_url
    throw 'Could not match remote url: ' . a:remote_url . ' with any of the patterns in ' .
                \ 'g:gh_cgit_url_pattern_sub:' . string(g:gh_cgit_url_pattern_sub)
endfunc

command! -range GH <line1>,<line2>call <SID>gh_line('blob', g:gh_always_interactive)
noremap <silent> <Plug>(gh-line) :call <SID>gh_line('blob', g:gh_always_interactive)<CR>

command! -range GB <line1>,<line2>call <SID>gh_line('blame', g:gh_always_interactive)
noremap <silent> <Plug>(gh-line-blame) :call <SID>gh_line('blame', g:gh_always_interactive)<CR>

command! -range GHIteractive <line1>,<line2>call <SID>gh_line('blob', 1)
command! -range GBIteractive <line1>,<line2>call <SID>gh_line('blame', 1)

if !hasmapto('<Plug>(gh-line)') && exists('g:gh_line_map')
    exe "map" g:gh_line_map "<Plug>(gh-line)"
end

if !hasmapto('<Plug>(gh-line-blame)') && exists('g:gh_line_blame_map')
    exe "map" g:gh_line_blame_map "<Plug>(gh-line-blame)"
end
