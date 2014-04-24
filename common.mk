PROJECT = maybe
LIB = $(PROJECT)
DEPS = ./deps
BIN_DIR = ./bin
EXPM = $(BIN_DIR)/expm
LFETOOL=$(BIN_DIR)/lfetool
SOURCE_DIR = ./src
OUT_DIR = ./ebin
TEST_DIR = ./test
TEST_OUT_DIR = ./.eunit
SCRIPT_PATH=.:./bin:$(PATH):/usr/local/bin

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(LFETOOL): $(BIN_DIR)
	@[ -f $(LFETOOL) ] || \
	curl -o ./lfetool https://raw.github.com/lfe/lfetool/master/lfetool && \
	chmod 755 ./lfetool && \
	mv ./lfetool $(BIN_DIR)

get-version:
	@PATH=$(SCRIPT_PATH) lfetool info version

$(EXPM): $(BIN_DIR)
	@[ -f $(EXPM) ] || \
	PATH=$(SCRIPT_PATH) lfetool install expm $(BIN_DIR)

get-deps:
	@echo "Getting dependencies ..."
	@rebar get-deps
	@PATH=$(SCRIPT_PATH) lfetool update deps

clean-ebin:
	@echo "Cleaning ebin dir ..."
	@rm -f $(OUT_DIR)/*.beam

clean-eunit:
	@PATH=$(SCRIPT_PATH) lfetool tests clean

compile: get-deps clean-ebin
	@echo "Compiling project code and dependencies ..."
	@rebar compile

compile-no-deps: clean-ebin
	@echo "Compiling only project code ..."
	@rebar compile skip_deps=true

compile-tests:
	@PATH=$(SCRIPT_PATH) lfetool tests build

shell: compile
	@clear
	@echo "Starting shell ..."
	@PATH=$(SCRIPT_PATH) lfetool repl lfe

shell-no-deps: compile-no-deps
	@clear
	@echo "Starting shell ..."
	@PATH=$(SCRIPT_PATH) lfetool repl

clean: clean-ebin clean-eunit
	@rebar clean

check-unit-only:
	@PATH=$(SCRIPT_PATH) lfetool tests unit

check-integration-only:
	@PATH=$(SCRIPT_PATH) lfetool tests integration

check-system-only:
	@PATH=$(SCRIPT_PATH) lfetool tests system

check-unit-with-deps: get-deps compile compile-tests check-unit-only
check-unit: compile-no-deps check-unit-only
check-integration: compile check-integration-only
check-system: compile check-system-only
check-all-with-deps: compile check-unit-only check-integration-only \
	check-system-only
check-all: get-deps compile-no-deps
	@PATH=$(SCRIPT_PATH) lfetool tests all

check: check-unit-with-deps

check-travis: $(LFETOOL) check

push-all:
	@echo "Pusing code to github ..."
	git push --all
	git push upstream --all
	git push --tags
	git push upstream --tags

install: compile
	@echo "Installing maybe ..."
	@PATH=$(SCRIPT_PATH) lfetool install lfe

upload: $(EXPM) get-version
	@echo "Preparing to upload maybe ..."
	@echo
	@echo "Package file:"
	@echo
	@cat package.exs
	@echo
	@echo "Continue with upload? "
	@read
	$(EXPM) publish