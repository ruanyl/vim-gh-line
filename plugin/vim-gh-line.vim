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

if !exists('g:gh_open_command')
    let g:gh_open_command = 'open '
endif

if !exists('g:gh_line_map') && g:gh_line_map_default == 1
    let g:gh_line_map = '<leader>gh'
endif

if !exists('g:gh_use_canonical')
  let g:gh_use_canonical = 1
endif

func! s:gh_line() range
    " Get Line Number/s
    let lineNum = line('.')
    let fileName = resolve(expand('%:t'))
    let fileDir = resolve(expand("%:p:h"))
    let cdDir = "cd " . fileDir . "; "
    let sed_cmd = "sed 's\/git@\/https:\\/\\/\/g; s\/.git$\/\/g; s\/\.com:\/.com\\/\/g; s\/\.org:\/.org\\/\/g'"
    let origin = system(cdDir . "git config --get remote.origin.url" . " | " . sed_cmd)

    " Get Directory & File Names
    let fullPath = resolve(expand("%:p"))
    " Git Commands
    let commit = s:Commit(cdDir)
    let gitRoot = system(cdDir . "git rev-parse --show-toplevel")

    " Strip Newlines
    let origin = <SID>StripNL(origin)
    let commit = <SID>StripNL(commit)
    let gitRoot = <SID>StripNL(gitRoot)
    let fullPath = <SID>StripNL(fullPath)

    " Git Relative Path
    let relative = split(fullPath, gitRoot)[-1]

    " Set Line Number/s; Form URL With Line Range
    if s:Github(origin)
      let lineRange = s:GithubLineLange(a:firstline, a:lastline, lineNum)
      let url = origin . '/blob/' . commit . relative . '#' . lineRange
    elseif s:Bitbucket(origin)
      let lineRange = s:BitbucketLineRange(a:firstline, a:lastline, lineNum)
      let url = s:BitBucketUrl(origin) . '/src/' . commit . relative . '#' . lineRange
    elseif s:Gitlab(origin)
      let lineRange = s:GitLabLineRange(a:firstline, a:lastline, lineNum)
      let url = origin . '/blob/' . commit . relative . '#' . lineRange
    endif

    call system(g:gh_open_command . url)
endfun

func! s:Commit(cdDir)
  if exists('g:gh_use_canonical')
    let gitCommand = 'git rev-parse HEAD'
  else
    let gitCommand = 'git rev-parse --abbrev-ref HEAD'
  endif
  return system(a:cdDir . gitCommand)
endfunc

func! s:Github(origin)
  return match(a:origin, 'github') >= 0
endfunc

func! s:Bitbucket(origin)
  return match(a:origin, 'bitbucket.org') >= 0
endfunc

func! s:Gitlab(origin)
  return exists('g:gh_gitlab_domain') && match(a:origin, g:gh_gitlab_domain) || match(a:origin, 'gitlab') >= 0
endfunc

func! s:GithubLineLange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    let lineRange = 'L' . a:lineNum
  else
    let lineRange = 'L' . a:firstLine . '-L' . a:lastLine
  endif
  return lineRange
endfunc

func! s:BitbucketLineRange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    let lineRange = '-' . a:lineNum
  else
    let lineRange = '-' . a:firstLine . ':' . a:lastLine
  endif
  return lineRange
endfunc

func! s:GitLabLineRange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    let lineRange = 'L' . a:lineNum
  else
    let lineRange = 'L' . a:firstLine . '-' . a:lastLine
  endif
  return lineRange
endfunc

func! s:StripNL(l)
  return substitute(a:l, '\n$', '', '')
endfun

func! s:BitBucketUrl(origin)
  return substitute(a:origin, '\(:\/\/\)\@<=.*@', '', '')
endfunc

noremap <silent> <Plug>(gh-line) :call <SID>gh_line()<CR>

if !hasmapto('<Plug>(gh-line)') && exists('g:gh_line_map')
    exe "map" g:gh_line_map "<Plug>(gh-line)"
end
