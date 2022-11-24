# vim-gh-line

 [![Build Status](https://travis-ci.org/ruanyl/vim-gh-line.svg?branch=master)](https://travis-ci.org/ruanyl/vim-gh-line)

A Vim plugin that opens a link to the current line on GitHub (and also supports Bitbucket, self-deployed GitHub, Googlesource, GitLab, and SourceHut).

![gh-line](https://cloud.githubusercontent.com/assets/486382/10865375/142cd426-8012-11e5-92f8-44357b7acf9c.gif)

## How to install

### Vundle
Put this in your .vimrc

```vim
Bundle 'ruanyl/vim-gh-line'
```

Then restart vim and run `:BundleInstall`.
To update the plugin to the latest version, you can run `:BundleUpdate`.

## How to use

Default key mapping for a blob view: `<leader>gh`

Default key mapping for a blame view: `<leader>gb`

Default key mapping for repo view: `<leader>go`

To disable default key mappings:

```
let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 1
```

Use your own mappings:

```
let g:gh_line_map = '<leader>gh'
let g:gh_line_blame_map = '<leader>gb'
```

Use a custom program to open link:
```
let g:gh_open_command = 'open '
```

Copy link to a clipboard instead of opening a browser:
```
let g:gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '
```

Use [canonical version hash](https://help.github.com/articles/getting-permanent-links-to-files/) for url in place of branch name:
```
let g:gh_use_canonical = 1
```

### Working with multiple remotes
When work with repo which has multiple remotes, the plugin will ask for your input of which remote you want to use.
The plugin always remember the last remote selection and use it as default remote name the next time you use it.

But you can use the following command to enforce to show the interactive input and change the default remote that's set previously:

```
:GHInteractive
:GBInteractive
```

it is also possible to always enforce interactive input by setting:

```
" gh_always_interactive is 0 by default
g:gh_always_interactive = 1
```

### Different git hosting alternatives

#### Use self-deployed GitHub:
```
let g:gh_github_domain = "<your github domain>"
```

#### Use self-deployed GitLab:
Use a self deployed gitlab (the value is a matching regex, i.e. you can use
multiple domains separated with `|`):
```
let g:gh_gitlab_domain = "<your gitlab domain>"
```

##### Use self deployed gitlab only with http:
```
let g:gh_gitlab_only_http = 1
```

#### Use self-deployed SourceHut:
Use a self deployed SourceHut (the value is a matching regex, i.e. you can use
multiple domains separated with `|`):
```
let g:gh_srht_domain = "<your sourcehut domain>"
```

#### Use a git remote with Cgit front end:
For Cgit frontends, the user needs to specify a pattern -> sub mapping to
compile the url. `vim-gh-line` uses the `origin` remote of your repo heuristicly to
come up with the url of the hosting site. For cgit deployments, there is no
simple heuristic to compile the url of the cgit frontend's webpage.

```
let g:gh_cgit_url_pattern_sub = [ [{pattern}, {sub}], ... ]
```

The `g:gh_cgit_url_pattern_sub` variable is a list of tuples. Each tuple is of
form `[{pattern}, {sub}]`. The `origin` remote in a repo is matched against
each `pattern` in the tuples in `g:gh_cgit_url_pattern_sub` in order. The `sub`
of the first tuple whose `pattern` matches will be used in a
[`substitute()`](http://vimhelp.appspot.com/eval.txt.html#substitute%28%29)
command to compile the final url.

For example say you are working on the
[`bash`](http://git.savannah.gnu.org/cgit/bash.git/) source code. The `origin` of
your local repo is `https://git.savannah.gnu.org/git/bash.git`. And the Cgit
front end url for a line link looks like
`http://git.savannah.gnu.org/cgit/bash.git/tree/Makefile.in?id=64447609994bfddeef1061948022c074093e9a9f#n12`.

The `g:gh_cgit_url_pattern_sub` could  be
```
let g:gh_cgit_url_pattern_sub = [
    \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
 \ ]
```

In addition to `bash`, say you also do kernel development in
https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git say the remote
you use is `git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git`

To handle both bash and kernel repos, the following `g:gh_cgit_url_pattern_sub`
would work.

```
let g:gh_cgit_url_pattern_sub = [
    \ ['.\+git.savannah.gnu.org/git/', 'http://git.savannah.gnu.org/cgit/'],
    \ ['.\+git.kernel.org/', 'https://git.kernel.org/'],
 \ ]
```

## Debugging

For getting verbose prints from vim-gh-line plugin set.

```
let g:gh_trace = 1
```
