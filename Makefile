# BINARY_NAME defaults to the name of the repository
# Show tabs with `cat -e -t -v  makefile` (for debugging)
BINARY_NAME := $(notdir $(shell pwd))
LIST_NO_VENDOR := $(go list -e ./... | grep -v /vendor/ | grep -v /task-runner)
GOBIN := $(GOPATH)/bin
BUILDINFO := -ldflags "-X main.BuildTime=`date -u '+%Y-%m-%d_%I:%M:%S%p'` -X main.BuildGitHash=`git rev-parse HEAD`"

default: check fmt deps build crosscompile

.PHONY: build
build:
	# Build project for native os.  This is only to be used by dev local for convenience.
	go build $(BUILDINFO) -a -o $(BINARY_NAME) .

.PHONY: crosscompile
# add additional supported platforms here
crosscompile:
	make linux
	# make windows
	make mac

.PHONY: linux
linux:
	# Build project for linux
	env GOOS=linux GOARCH=amd64 go build $(BUILDINFO) -a -o $(BINARY_NAME).linux .
	# This is so the wercker build enviro will have the correct ./edge
	cp $(BINARY_NAME).linux $(BINARY_NAME)

.PHONY: windows
windows:
	# Build project for windows
	#env GOOS=windows GOARCH=amd64 go build $(BUILDINFO) -a -o $(BINARY_NAME).win .
	# no op - windows support is deprecated so we can support some posix file operations

.PHONY: mac
mac:
	# Build project for mac
	env GOOS=darwin GOARCH=amd64 go build $(BUILDINFO) -a -o $(BINARY_NAME).mac .

.PHONY: check
check:
	# Only continue if go is installed
	go version || ( echo "Go not installed, exiting"; exit 1 )

.PHONY: clean
clean:
	go clean -i
	rm -rf ./vendor/*/
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_NAME).mac
	rm -f $(BINARY_NAME).win
	rm -r $(BINARY_NAME).linux

deps:
	# Install or update govend
	go get -u github.com/govend/govend
	# Fetch vendored dependencies
	$(GOBIN)/govend -v

.PHONY: fmt
fmt:
	# Format all Go source files (excluding vendored packages)
	go fmt $(LIST_NO_VENDOR)

generate-deps:
	# Generate vendor.yml
	govend -v -l
	git checkout vendor/.gitignore

