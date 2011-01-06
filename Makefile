# requirements: inotify-tools, sass, coffee-script
NAME = test
DEST = test
SRC = src
LIB  = $(SRC)/moka.coffee
CSS  = style

INOTIFY = inotifywait

DIV='********************************************************************************'

.PHONY:all js css

all: js css

js: $(DEST)/$(NAME).js

css: $(DEST)/$(CSS).css

$(DEST)/$(NAME).js: $(LIB) $(SRC)/$(NAME).coffee
	@echo $(DIV)
	coffee -c -j -o $(DEST) $^
	@echo $(DIV)
	mv $(DEST)/concatenation.js $@

$(DEST)/$(CSS).css: $(SRC)/$(CSS).scss
	@echo $(DIV)
	sass $^:$@
	@echo $(DIV)

$(SRC)/$(CSS).scss:
$(SRC)/$(NAME).coffee:
$(LIB):
	while [ ! -f $@ ]; do sleep 0.1; done

watch:
	$(MAKE) -j2 watch_css watch_js

watch_css:
	$(MAKE) css; while true; do $(INOTIFY) $(SRC)/$(CSS).scss && $(MAKE) css; done

watch_js:
	$(MAKE) js; while true; do $(INOTIFY) $(LIB) $(SRC)/$(NAME).coffee && $(MAKE) js; done

