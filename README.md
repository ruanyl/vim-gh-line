vim-gh-line
=============

A vim plugin that open the link to current line at Github

How to install
-----------------------
###Vundle
Put this in your .vimrc

```vim
Bundle 'ruanyl/vim-gh-line'
```

Then restart vim and run `:BundleInstall`.
To update the plugin to the latest version, you can run `:BundleUpdate`.

How to use
----------

Default key mapping: `<leader>gh`

To disable default key mapping:

```
let g:gh_line_map_default = 0
```

Use your own mapping:

```
let g:gh_line_map = '<leader>gh'
```
