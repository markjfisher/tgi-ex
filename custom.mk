ifeq ($(CURRENT_PLATFORM),atari)
# Fix for graphics calls on Atari
# LDFLAGS += -Wl -D__RESERVED_MEMORY__=0x1
# Fix for loading location for Atari to be above SDX
# LDFLAGS += --start-addr 0x2D00
endif

# for apple only, set to 1 to boot via STARTUP, 2 via LOADER.SYSTEM
AUTOSTART := 2
