ifndef VERBOSE
.SILENT:
endif

test: all
	echo "Tests should be run, do something about that!"

deps: clean
	dart pub get >>/dev/null

all: clean deps
	dart fix --apply >/dev/null
	dart format . >/dev/null
	dart analyze --fatal-infos

clean:
	rm -rf doc coverage

docs:
	dartdoc

install: all
	dart pub global activate --source path .

default: all
