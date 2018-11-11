#!/bin/bash

set -x


# Start vi in the cleanest possible way and only load the tests and the
# plugin directory
vim  -N -U NONE -i NONE -u <(cat << VIMRC
set rtp+=../
source ./vim-gh-line_test.vim
VIMRC) -c 'RunAllTests'

