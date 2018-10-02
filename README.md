vim-gh-line
=============

A Vim plugin that opens a link to the current line on GitHub (and also supports Bitbucket and self-deployed GitHub and GitLab).

![gh-line](https://cloud.githubusercontent.com/assets/486382/10865375/142cd426-8012-11e5-92f8-44357b7acf9c.gif)

How to install
-----------------------
### Vundle
Put this in your .vimrc

```vim
Bundle 'ruanyl/vim-gh-line'
```

Then restart vim and run `:BundleInstall`.
To update the plugin to the latest version, you can run `:BundleUpdate`.

How to use
----------

Default key mapping for a blob view: `<leader>gh`

Default key mapping for a blame view: `<leader>gb`

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

Use self-deployed GitHub:
```
let g:gh_github_domain = "<your github domain>"
```

Use self-deployed GitLab:
Use a self deployed gitlab (the value is a matching regex, i.e. you can use
multiple domains separated with `|`):
```
let g:gh_gitlab_domain = "<your gitlab domain>"
```

Use self deployed gitlab only with http:
```
let g:gh_gitlab_only_http = 1
```
