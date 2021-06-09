Q := @
EXAMPLE_DIRS := $(sort $(dir $(wildcard */Makefile)))

all: $(EXAMPLE_DIRS)
	$(Q)true

clean: $(EXAMPLE_DIRS:=.clean)
	$(Q)true

$(EXAMPLE_DIRS):
	@printf "  BUILD    $@\n";
	$(Q)$(MAKE) --directory=$@

%.clean:
	@printf "  CLEAN   $*\n";
	$(Q)$(MAKE) --directory=$* clean

.PHONY: $(EXAMPLE_DIRS) clean