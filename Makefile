.PHONY: all menu orig


DIRSRC = ./src
DIROUT = ./out
ASSETS = ./assets

MENUBIN = $(DIROUT)/menu.z80
ROMBIN = ./fm_logo_menu.bin
ROMEMPTY = $(ASSETS)/16k_msx2p_fm_logo_menu.bin
ADDRESS = 0x7d40
ADDRESSBIN = $(shell echo "$$(( $(ADDRESS) - 0x4000 ))" | bc)

rom: cleanrom $(ROMBIN)

orig: $(DIRSRC)/menu_orig.asm
	@echo "###### Compiling $@"
	@cp $^ $(DIROUT)/
	asmsx -z -r $(DIROUT)/ $(DIROUT)/menu_orig.asm
	@rm $(DIROUT)/~tmppre.*
	@echo "###### Creating ROM"
	@cp $(ROMEMPTY) $(ROMBIN)
	@dd if="$(DIROUT)/menu_orig.z80" of="$(ROMBIN)" bs=1 seek=$(ADDRESSBIN) conv=notrunc > /dev/null

$(MENUBIN): $(DIRSRC)/menu.asm
	@echo "###### Compiling $^"
	@cp $^ $(DIROUT)/
	asmsx -z -r $(DIROUT)/ $(DIROUT)/menu.asm
	@rm $(DIROUT)/~tmppre.*

$(ROMBIN): $(MENUBIN)
	@echo "###### Creating ROM"
	@cp $(ROMEMPTY) $@
	@dd if="$^" of="$@" bs=1 seek=$(ADDRESSBIN) conv=notrunc > /dev/null


test: $(ROMBIN)
	openmsx -machine msx2plus -carta $^


cleanrom:
	@rm -rf $(ROMBIN)