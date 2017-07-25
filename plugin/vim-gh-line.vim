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

    " Set Line Number/s
    if a:firstline == a:lastline
        let lineRange = 'L' . lineNum
    else
        let lineRange = 'L' . a:firstline . "-L" . a:lastline
    endif

    " String Setup
    let blob = "/blob/"
    let sed_cmd = "sed 's\/git@\/https:\\/\\/\/g; s\/.git$\/\/g; s\/\.com:\/.com\\/\/g'"

    " Get Directory & File Names
    let fullPath = resolve(expand("%:p"))
    let fileDir = resolve(expand("%:p:h"))
    let cdDir = "cd " . fileDir . "; "

    " Git Commands
    let origin = system(cdDir . "git config --get remote.origin.url" . " | " . sed_cmd)
    if exists('g:gh_use_canonical')
        let commit = system(cdDir . "git rev-parse HEAD")
    else
        let commit = system(cdDir . "git rev-parse --abbrev-ref HEAD")
    endif

    let gitRoot = system(cdDir . "git rev-parse --show-toplevel")

    " Strip Newlines
    let origin = <SID>StripNL(origin)
    let commit = <SID>StripNL(commit)
    let gitRoot = <SID>StripNL(gitRoot)
    let fullPath = <SID>StripNL(fullPath)

    " Git Relative Path
    let relative = split(fullPath, gitRoot)[-1]

    " Form URL With Line Range
    let url = origin . blob . commit . relative . '#' . lineRange
    call system(g:gh_open_command . url)

endfun

func! s:StripNL(l)
  return substitute(a:l, '\n$', '', '')
endfun

noremap <silent> <Plug>(gh-line) :call <SID>gh_line()<CR>

if !hasmapto('<Plug>(gh-line)') && exists('g:gh_line_map')
    exe "map" g:gh_line_map "<Plug>(gh-line)"
end

