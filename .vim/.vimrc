if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
   set fileencodings=ucs-bom,utf-8,latin1
endif

set nocompatible	" Use Vim defaults (much better!)
set bs=indent,eol,start	" allow backspacing over everything in insert mode
"set backup		" keep a backup file
set viminfo='20,\"50	" read/write a .viminfo file, don't store more
			" than 50 lines of registers
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set relativenumber
set number
"set list
set hls
set softtabstop=0
set noexpandtab
set autoindent
set statusline=%<%F\ %h%m%r\ %y%=%{v:register}\ %-14.(%l/%L,%c%V%)\ %P
set laststatus=2
set title

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Plug 'Valloric/YouCompleteMe'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
call plug#end()
set rtp+=/opt/homebrew/bin/fzf
map \l :Lines<CR>
noremap \g :Files %:p:h<CR>
map \d :put=strftime('%F')<CR> \| :norm 0i## 
noremap \p :set list!
noremap \h :set hls!
noremap \w :MarkdownPreviewToggle

set lcs=tab:>\ ,trail:~,nbsp:_,eol:$

" Only do this part when compiled with support for autocommands
if has("autocmd")
  augroup redhat
  autocmd!
  " In text files, always limit the width of text to 78 characters
  " autocmd BufRead *.txt set tw=78
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal! g'\"" |
  \ endif
  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
  autocmd BufNewFile,BufReadPre /media/*,/run/media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
  " start with spec file template
  autocmd BufNewFile *.spec 0r /usr/share/vim/vimfiles/template.spec
  augroup END
endif

if has("cscope") && filereadable("/usr/bin/cscope")
   set csprg=/usr/bin/cscope
   set csto=0
   set cst
   set nocsverb
   " add any database in current directory
   if filereadable("cscope.out")
      cs add $PWD/cscope.out
   " else add database pointed to by environment
   elseif $CSCOPE_DB != ""
      cs add $CSCOPE_DB
   endif
   set csverb
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch off highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set nohlsearch
endif

filetype plugin on

if &term=="xterm"
     set t_Co=8
     set t_Sb=[4%dm
     set t_Sf=[3%dm
endif

" Don't wake up system with blinking cursor:
" http://www.linuxpowertop.org/known.php
let &guicursor = &guicursor . ",a:blinkon0"

" ==============================================================================
" " Vim-Gitgutter Configuration: Lazygit-Style Added Lines Only (Dark Red
" Theme)
" "
" ==============================================================================
"
" 1. Enable background line highlighting for changes
let g:gitgutter_highlight_lines = 1
"
" 2. Suppress Gutter Signs for Modified and Deleted Lines
" (Links them to 'Normal' so they blend invisibly into your default background)
highlight link GitGutterChange       Normal
highlight link GitGutterDelete       Normal
highlight link GitGutterChangeDelete Normal
"
" 3. Suppress Line Background Highlighting for Modified and Deleted Lines
" (Prevents bright blue/green block backgrounds on modified blocks)
highlight link GitGutterChangeLine       Normal
highlight link GitGutterDeleteLine       Normal
highlight link GitGutterChangeDeleteLine Normal
"
" 4. Style New Additions in Dark Red
" - GitGutterAdd controls the text/foreground color of the '+' sign in the gutter.
" - GitGutterAddLine controls the full-line background highlight of the added code.
" - ctermfg / ctermbg: Used for standard 256-color terminal setups.
" - guifg / guibg: Used for GUI Vim or terminals running set termguicolors (Hex values).
highlight GitGutterAdd     ctermfg=88  guifg=#870000
"highlight GitGutterAddLine ctermbg=237 guibg=#5f0000
highlight GitGutterAddLine ctermbg=236 guibg=#5f0000

" 5. Optimization: Increase the update interval (Default is 4000ms)
" This makes GitGutter refresh its highlighting 250ms after you stop typing.
set updatetime=250
