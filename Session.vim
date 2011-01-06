let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
inoremap <silent> <S-Tab> =BackwardsSnippet()
inoremap <silent> <Plug>NERDCommenterInInsert  <BS>:call NERDComment(0, "insert")
imap <C-CR> :w:!./%
imap <C-Space> 
imap <F5> :make
imap <F2> :w
imap <C-S-Tab> :tabprev
inoremap <C-Tab> 	
imap <F6> :w:!LANG=cs_CZ.iso-8859-2 aspell -t -x --lang=cs -c %:eki
inoremap <expr> <PageUp> pumvisible() ? "\<PageUp>\\" : "\<PageUp>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\\" : "\<PageDown>"
inoremap <expr> <Up> pumvisible() ? "\" : "\<Up>"
inoremap <expr> <Down> pumvisible() ? "\" : "\<Down>"
map! <S-Insert> <MiddleMouse>
map  ,c j
map  :split ~/.vimrc 
nmap <silent>  :%!xxd
vmap <silent>  :!xxd
omap <silent>  :%!xxd
xmap 	 
nmap 	 
snoremap <silent> 	 i<Right>=TriggerSnippet()
omap 	 
map  :mksession!:qa
map  :w
map  :source ~/.vimrc 
snoremap  b<BS>
map [6;5~ :tabnext
map [5;5~ :tabprev
noremap <silent>   :silent noh|echo
snoremap % b<BS>%
snoremap ' b<BS>'
nmap ,ca <Plug>NERDCommenterAltDelims
vmap ,cA <Plug>NERDCommenterAppend
nmap ,cA <Plug>NERDCommenterAppend
vmap ,c$ <Plug>NERDCommenterToEOL
nmap ,c$ <Plug>NERDCommenterToEOL
vmap ,cu <Plug>NERDCommenterUncomment
nmap ,cu <Plug>NERDCommenterUncomment
vmap ,cn <Plug>NERDCommenterNest
nmap ,cn <Plug>NERDCommenterNest
vmap ,cb <Plug>NERDCommenterAlignBoth
nmap ,cb <Plug>NERDCommenterAlignBoth
vmap ,cl <Plug>NERDCommenterAlignLeft
nmap ,cl <Plug>NERDCommenterAlignLeft
vmap ,cy <Plug>NERDCommenterYank
nmap ,cy <Plug>NERDCommenterYank
vmap ,ci <Plug>NERDCommenterInvert
nmap ,ci <Plug>NERDCommenterInvert
vmap ,cs <Plug>NERDCommenterSexy
nmap ,cs <Plug>NERDCommenterSexy
vmap ,cm <Plug>NERDCommenterMinimal
nmap ,cm <Plug>NERDCommenterMinimal
vmap ,c  <Plug>NERDCommenterToggle
nmap ,c  <Plug>NERDCommenterToggle
vmap ,cc <Plug>NERDCommenterComment
nmap ,cc <Plug>NERDCommenterComment
nnoremap ; :
imap <silent>  :%!xxd -r
map TT :TlistToggle
snoremap U b<BS>U
snoremap \ b<BS>\
snoremap ^ b<BS>^
snoremap ` b<BS>`
nmap gx <Plug>NetrwBrowseX
map tt :NERDTreeToggle
map td :tabclose
map tn :tabnew 
snoremap <Left> bi
snoremap <Right> a
snoremap <BS> b<BS>
snoremap <silent> <S-Tab> i<Right>=BackwardsSnippet()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
nmap <silent> <Plug>NERDCommenterAppend :call NERDComment(0, "append")
nnoremap <silent> <Plug>NERDCommenterToEOL :call NERDComment(0, "toEOL")
vnoremap <silent> <Plug>NERDCommenterUncomment :call NERDComment(1, "uncomment")
nnoremap <silent> <Plug>NERDCommenterUncomment :call NERDComment(0, "uncomment")
vnoremap <silent> <Plug>NERDCommenterNest :call NERDComment(1, "nested")
nnoremap <silent> <Plug>NERDCommenterNest :call NERDComment(0, "nested")
vnoremap <silent> <Plug>NERDCommenterAlignBoth :call NERDComment(1, "alignBoth")
nnoremap <silent> <Plug>NERDCommenterAlignBoth :call NERDComment(0, "alignBoth")
vnoremap <silent> <Plug>NERDCommenterAlignLeft :call NERDComment(1, "alignLeft")
nnoremap <silent> <Plug>NERDCommenterAlignLeft :call NERDComment(0, "alignLeft")
vmap <silent> <Plug>NERDCommenterYank :call NERDComment(1, "yank")
nmap <silent> <Plug>NERDCommenterYank :call NERDComment(0, "yank")
vnoremap <silent> <Plug>NERDCommenterInvert :call NERDComment(1, "invert")
nnoremap <silent> <Plug>NERDCommenterInvert :call NERDComment(0, "invert")
vnoremap <silent> <Plug>NERDCommenterSexy :call NERDComment(1, "sexy")
nnoremap <silent> <Plug>NERDCommenterSexy :call NERDComment(0, "sexy")
vnoremap <silent> <Plug>NERDCommenterMinimal :call NERDComment(1, "minimal")
nnoremap <silent> <Plug>NERDCommenterMinimal :call NERDComment(0, "minimal")
vnoremap <silent> <Plug>NERDCommenterToggle :call NERDComment(1, "toggle")
nnoremap <silent> <Plug>NERDCommenterToggle :call NERDComment(0, "toggle")
vnoremap <silent> <Plug>NERDCommenterComment :call NERDComment(1, "norm")
nnoremap <silent> <Plug>NERDCommenterComment :call NERDComment(0, "norm")
map <C-F2> :execute Zoom(-0.5)
map <C-F1> :execute Zoom(0.5)
map <C-CR> :w:!./%
map <S-F11> :call PreviousColorScheme()
map <F11> :call NextColorScheme()
nnoremap <silent> <F8> :execute RotateColorTheme()
map <F5> :make
map <F2> :w
map <F4> :bd
map <C-S-Tab> :tabprev
map <C-Tab> :tabnext
nmap <C-S-F9> zM
nmap <C-F9> zR
nmap <F9> za
map <F6> :w:!LANG=cs_CZ.iso-8859-2 aspell -t -x --lang=cs -c %::ek
map <F7> :set spell
map <S-Insert> <MiddleMouse>
imap  ,c <Down>
imap <silent>  :%!xxd
inoremap <silent> 	 =TriggerSnippet()
imap  :mksession!:qa
inoremap <silent> 	 =ShowAvailableSnips()
imap  :w
inoremap <expr>  pumvisible() ? "\" : "\"
nmap <silent>  :%!xxd -r
vmap <silent>  :!xxd -r
omap <silent>  :%!xxd -r
let &cpo=s:cpo_save
unlet s:cpo_save
set backspace=indent,eol,start
set binary
set cindent
set clipboard=unnamed
set completeopt=longest,menuone,preview
set dictionary=/usr/share/dict/words
set expandtab
set fileencodings=utf-8,iso8859-2,cp852,cp1250
set nofsync
set guicursor=n-v-c:block-Cursor/lCursor,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175,a:blinkon0
set guifont=Bitstream\ Vera\ Sans\ Mono\ 9.5
set helplang=cs
set history=512
set hlsearch
set ignorecase
set imsearch=0
set incsearch
set isident=@,48-57,_,192-255,$
set nojoinspaces
set nomodeline
set mouse=a
set ruler
set runtimepath=~/.vim,~/.vim/bundle/vim-coffee-script,/usr/share/vim/vimfiles,/usr/share/vim/vim73,/usr/share/vim/vimfiles/after,~/.vim/after
set scrolloff=5
set shiftwidth=4
set showcmd
set showmatch
set smartcase
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabstop=4
set termencoding=utf-8
set wildignore=*.o,*.pyc
set wildmenu
set wildmode=longest:full,full
set window=37
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/dev/moka
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +442 src/moka.coffee
badd +479 test/test.js
badd +1 src/style.scss
badd +0 test.
badd +53 src/test.coffee
args src/moka.coffee
edit src/moka.coffee
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe 'vert 1resize ' . ((&columns * 103 + 83) / 166)
exe 'vert 2resize ' . ((&columns * 62 + 83) / 166)
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal binary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s:###,m:\ ,e:###,:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'coffee'
setlocal filetype=coffee
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=0
setlocal include=
setlocal includeexpr=
setlocal indentexpr=GetCoffeeIndent(v:lnum)
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0],0),0.,=else,=when,=catch,=finally
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'coffee'
setlocal syntax=coffee
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
39
normal zo
39
normal zo
169
normal zo
185
normal zo
197
normal zo
226
normal zo
234
normal zo
237
normal zo
243
normal zo
248
normal zo
253
normal zo
254
normal zo
258
normal zo
262
normal zo
253
normal zo
288
normal zo
289
normal zo
309
normal zo
313
normal zo
317
normal zo
288
normal zo
321
normal zo
322
normal zo
367
normal zo
466
normal zo
471
normal zo
475
normal zo
479
normal zo
485
normal zo
491
normal zo
496
normal zo
501
normal zo
513
normal zo
532
normal zo
537
normal zo
553
normal zo
561
normal zo
573
normal zo
577
normal zo
606
normal zo
626
normal zo
668
normal zo
730
normal zo
735
normal zo
740
normal zo
777
normal zo
321
normal zo
788
normal zo
789
normal zo
796
normal zo
801
normal zo
805
normal zo
808
normal zo
788
normal zo
817
normal zo
818
normal zo
827
normal zo
832
normal zo
836
normal zo
842
normal zo
846
normal zo
851
normal zo
867
normal zo
894
normal zo
899
normal zo
817
normal zo
921
normal zo
922
normal zo
930
normal zo
933
normal zo
921
normal zo
942
normal zo
943
normal zo
976
normal zo
981
normal zo
985
normal zo
992
normal zo
999
normal zo
1007
normal zo
1033
normal zo
1042
normal zo
1063
normal zo
1069
normal zo
942
normal zo
1123
normal zo
1124
normal zo
1130
normal zo
1136
normal zo
1140
normal zo
1123
normal zo
1148
normal zo
1149
normal zo
1155
normal zo
1161
normal zo
1165
normal zo
1170
normal zo
1180
normal zo
1148
normal zo
1192
normal zo
1193
normal zo
1234
normal zo
1274
normal zo
1279
normal zo
1285
normal zo
1300
normal zo
1305
normal zo
1315
normal zo
1319
normal zo
1333
normal zo
1337
normal zo
1192
normal zo
234
normal zo
253
normal zo
254
normal zo
258
normal zo
263
normal zo
253
normal zo
289
normal zo
290
normal zo
294
normal zo
317
normal zo
325
normal zo
333
normal zo
334
normal zo
379
normal zo
478
normal zo
483
normal zo
487
normal zo
491
normal zo
497
normal zo
503
normal zo
508
normal zo
513
normal zo
525
normal zo
544
normal zo
549
normal zo
565
normal zo
573
normal zo
585
normal zo
589
normal zo
618
normal zo
638
normal zo
680
normal zo
742
normal zo
747
normal zo
752
normal zo
789
normal zo
333
normal zo
800
normal zo
801
normal zo
808
normal zo
813
normal zo
817
normal zo
820
normal zo
800
normal zo
829
normal zo
830
normal zo
839
normal zo
844
normal zo
848
normal zo
854
normal zo
858
normal zo
863
normal zo
879
normal zo
906
normal zo
911
normal zo
829
normal zo
933
normal zo
934
normal zo
942
normal zo
945
normal zo
933
normal zo
954
normal zo
955
normal zo
988
normal zo
993
normal zo
997
normal zo
1004
normal zo
1011
normal zo
1019
normal zo
1045
normal zo
1054
normal zo
1075
normal zo
1081
normal zo
954
normal zo
1135
normal zo
1136
normal zo
1142
normal zo
1148
normal zo
1152
normal zo
1135
normal zo
1160
normal zo
1161
normal zo
1167
normal zo
1173
normal zo
1177
normal zo
1182
normal zo
1192
normal zo
1160
normal zo
1204
normal zo
1205
normal zo
1246
normal zo
1286
normal zo
1291
normal zo
1297
normal zo
1312
normal zo
1317
normal zo
1327
normal zo
1331
normal zo
1345
normal zo
1349
normal zo
1204
normal zo
289
normal zo
333
normal zo
334
normal zo
379
normal zo
478
normal zo
482
normal zo
488
normal zo
494
normal zo
499
normal zo
504
normal zo
516
normal zo
535
normal zo
540
normal zo
556
normal zo
564
normal zo
576
normal zo
580
normal zo
609
normal zo
629
normal zo
671
normal zo
733
normal zo
738
normal zo
743
normal zo
780
normal zo
333
normal zo
791
normal zo
792
normal zo
799
normal zo
791
normal zo
808
normal zo
809
normal zo
818
normal zo
825
normal zo
829
normal zo
834
normal zo
850
normal zo
877
normal zo
882
normal zo
808
normal zo
904
normal zo
905
normal zo
913
normal zo
916
normal zo
904
normal zo
925
normal zo
926
normal zo
959
normal zo
967
normal zo
974
normal zo
982
normal zo
1008
normal zo
1017
normal zo
1038
normal zo
1044
normal zo
925
normal zo
1098
normal zo
1099
normal zo
1098
normal zo
1110
normal zo
1111
normal zo
1117
normal zo
1123
normal zo
1133
normal zo
1110
normal zo
1145
normal zo
1146
normal zo
1187
normal zo
1226
normal zo
1231
normal zo
1237
normal zo
1253
normal zo
1258
normal zo
1268
normal zo
1272
normal zo
1286
normal zo
1290
normal zo
1145
normal zo
1306
normal zo
185
normal zo
1306
normal zo
let s:l = 1123 - ((21 * winheight(0) + 18) / 36)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1123
normal! 018l
wincmd w
argglobal
edit test/test.js
setlocal keymap=
setlocal noarabic
setlocal noautoindent
setlocal autoread
setlocal balloonexpr=
setlocal binary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=j1,J1
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://
setlocal commentstring=//%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal noexpandtab
if &filetype != 'javascript.doxygen'
setlocal filetype=javascript.doxygen
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=0
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=javascriptcomplete#CompleteJS
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal readonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'javascript.doxygen'
setlocal syntax=javascript.doxygen
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 1418 - ((7 * winheight(0) + 18) / 36)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1418
normal! 04l
wincmd w
exe 'vert 1resize ' . ((&columns * 103 + 83) / 166)
exe 'vert 2resize ' . ((&columns * 62 + 83) / 166)
tabedit src/test.coffee
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal binary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s:###,m:\ ,e:###,:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'coffee'
setlocal filetype=coffee
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=0
setlocal include=
setlocal includeexpr=
setlocal indentexpr=GetCoffeeIndent(v:lnum)
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0],0),0.,=else,=when,=catch,=finally
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'coffee'
setlocal syntax=coffee
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
2
normal zo
let s:l = 1 - ((0 * winheight(0) + 18) / 37)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
normal! 0
tabedit src/style.scss
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal noautoindent
setlocal balloonexpr=
setlocal binary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=//\ %s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=^\\s*\\%(@mixin\\|=\\)
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'scss'
setlocal filetype=scss
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=0
setlocal include=^\\s*@import\\s\\+\\%(url(\\)\\=[\"']\\=
setlocal includeexpr=substitute(v:fname,'\\%(.*/\\|^\\)\\zs','_','')
setlocal indentexpr=GetCSSIndent()
setlocal indentkeys=0{,0},!^F,o,O
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=csscomplete#CompleteCSS
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.sass,.scss,.css
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'scss'
setlocal syntax=scss
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
75
normal zo
let s:l = 202 - ((7 * winheight(0) + 18) / 37)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
202
normal! 029l
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
