ERLC_OPTIONS ?= -Wall -Werror

ERL_SRC := $(wildcard src/*.erl)
ERL_OBJ := $(patsubst src/%.erl, ebin/%.beam,$(ERL_SRC))

$(info ERL_SRC=$(ERL_SRC))
$(info ERL_OBJ=$(ERL_OBJ))

all: build

build: ${ERL_OBJ}

ebin/%.beam: src/%.erl
	erlc $(ERLC_OPTIONS) -o $(dir $@) $<

clean: 
	$(RM) ebin/*.beam

.PHONY: all build clean
