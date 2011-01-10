# requirements: sass, coffee-script, inotify-tools
NAME = test
CSS = default
DEST = $(PWD)
SRC = src
LIB = moka

INOTIFY = inotifywait

DIV='********************************************************************************'

.PHONY:all js css deps

all: js css

js: $(DEST)/$(NAME).js $(SRC)/$(LIB).js

css: css/$(CSS).css

# TODO: fetch dependencies (git or download and unpack)
deps:

%.js: %.coffee
	@echo $(DIV)
	coffee -c -o $(DEST) $^
	@echo $(DIV)

%.css: %.scss
	@echo $(DIV)
	sass $^:$@
	@echo $(DIV)


.PHONY:watch watch.%.scss watch.%.coffee

watch:
	$(MAKE) -j3 $(SRC)/$(LIB).coffee.watch $(NAME).coffee.watch css/$(CSS).scss.watch

%.scss.watch: %.scss
	while true; do \
		while [ ! -f $^ ]; do sleep 0.1; done && \
		$(MAKE) $(^:.scss=.css); \
		$(INOTIFY) $^; done

%.coffee.watch: %.coffee
	while true; do \
		while [ ! -f $^ ]; do sleep 0.1; done && \
		$(MAKE) $(^:.coffee=.js); \
		$(INOTIFY) $^; done

