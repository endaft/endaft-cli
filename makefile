ifndef VERBOSE
.SILENT:
endif

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
