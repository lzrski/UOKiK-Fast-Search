PATH:=./bin/:./node_modules/.bin/:$(PATH)
BROWSERIFY := $(shell cat .browserify | sed 's/.*/-r & /g')

# $(for package in $(cat .browserify); do echo -n " -r $package"; done)
all: install build test start

clean:
	rm -rf lib/*
	rm -rf assets/scripts/app/*

browserify:
	mkdir -p assets/scripts/app/
	node_modules/.bin/browserify $(BROWSERIFY) > assets/scripts/app/browserified.js

build: clean browserify
	./node_modules/.bin/coffee -cm -o lib src
	./node_modules/.bin/coffee -cm -o assets/scripts/app/ scripts/
	

dev: watch
	NODE_ENV=development DEBUG=ufs,ufs:*,persona,persona:* nodemon

watch: end-watch
	./node_modules/.bin/coffee -cmw -o lib src          & echo $$! > .watch_pid
	./node_modules/.bin/coffee -cmw -o assets/scripts/app/ scripts/  & echo $$! > .watch_frontend_pid

end-watch:
	if [ -e .watch_pid ]; then kill `cat .watch_pid`; rm .watch_pid;  else  echo no .watch_pid file; fi
	if [ -e .watch_frontend_pid ]; then kill `cat .watch_frontend_pid`; rm .watch_frontend_pid; else echo no .watch_pid file; fi

docs:
	echo "Error: no docs generator installed"
	# ./node_modules/.bin/groc "src/*.coffee?(.md)" "src/**/*.coffee?(.md)" readme.md

clean-docs:
	rm -rf docs/*
