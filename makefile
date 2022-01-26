ifndef VERBOSE
.SILENT:
endif

deps: clean
	dart pub get

all: clean deps
	dart fix --apply >/dev/null
	dart format . >/dev/null

clean:
	rm -rf .dart_tool doc .packages pubspec.lock

docs:
	dartdoc
