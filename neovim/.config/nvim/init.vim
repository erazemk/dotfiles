"
" ~/.config/nvim/init.vim
"

" Map Leader key to Space
let maplocalleader="\<space>"
let mapleader="\<space>"

set clipboard+=unnamedplus      " Use the system clipboard
set colorcolumn=80,120          " Highlight max length column
set encoding=utf-8              " Set encoding
set hlsearch                    " Highlight search results
set ignorecase                  " Case insensitive matching
set incsearch                   " Incremental search results
set number relativenumber       " Relative line numbers
set scrolloff=999               " Scroll when at half the screen
set wildmode=longest,list,full  " Get bash-like tab completions
set tabstop=4                   " Show tabs 4 spaces wide
set shiftwidth=4                " Indent tabs 4 spaces wide
filetype plugin indent on       " Allows auto-indenting depending on file type
syntax enable                   " Syntax highlighting

" Automatically delete trailing whitespace
autocmd BufWritePre * %s/\s\+$//e

" Change matching parenthesis' color
hi MatchParen cterm=underline ctermbg=none ctermfg=blue

" Install vim-plug if not found
if empty(glob("$HOME/.local/share/nvim/site/autoload/plug.vim"))
    silent !curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs
            \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
    \| PlugInstall --sync | source $MYVIMRC
\| endif

" Installed plugins
call plug#begin("$HOME/.local/share/nvim/site/autoload/plugged")
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
    "Plug 'tpope/vim-sleuth'
call plug#end()
