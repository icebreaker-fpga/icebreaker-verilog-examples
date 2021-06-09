all:
	@printf "Building icebreaker examples\n";
	@$(MAKE) -C icebreaker
	@printf "Building icebitsy examples\n";
	@$(MAKE) -C icebitsy

clean:
	@printf "Building icebreaker examples\n";
	@$(MAKE) -C icebreaker clean
	@printf "Building icebitsy examples\n";
	@$(MAKE) -C icebitsy clean

.PHONY: clean
