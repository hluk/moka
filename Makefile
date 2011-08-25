# requirements: sass, coffee-script, inotify-tools
# run: npm install -d
COFFEE = node_modules/coffee-script/bin/coffee
SASS = /usr/bin/sass

NAME = test
CSS_CONFIG = css/default.sass
CSS_CORE = css/core.scss
CSS_LIBS = css/utils.scss
DEST = $(PWD)
SRC = src
LIB = moka

INOTIFY = inotifywait

DIV='********************************************************************************'

.PHONY:all js css deps

all: js css

js: $(DEST)/$(NAME).js $(SRC)/$(LIB).js

css: $(DEST)/$(NAME).css

# TODO: fetch dependencies (git or download and unpack)
deps:

%.js: %.coffee
	@echo $(DIV)
	$(COFFEE) -c -o $(DEST) $^
	@echo $(DIV)

$(DEST)/$(NAME).css: $(CSS_CONFIG) $(CSS_CORE) $(CSS_LIBS)
	@echo $(DIV)
	ln -sf $< config.sass
	$(SASS) $(CSS_CORE):$(DEST)/$(NAME).css
	@echo $(DIV)


.PHONY:watch watch.%.sass watch.%.coffee

watch:
	$(MAKE) -j3 $(SRC)/$(LIB).coffee.watch $(NAME).coffee.watch $(CSS_CONFIG).watch

%.sass.watch: %.sass $(CSS_CORE) $(CSS_LIBS)
	while true; do \
		while ! ls $^ 2>/dev/null ; do sleep 0.1; done && \
		$(MAKE) $(DEST)/$(NAME).css; \
		$(INOTIFY) $^; done

%.coffee.watch: %.coffee
	while true; do \
		while [ ! -f $^ ]; do sleep 0.1; done && \
		$(MAKE) $(^:.coffee=.js); \
		$(INOTIFY) $^; done

