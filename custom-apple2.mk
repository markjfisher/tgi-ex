# set to 1 to boot via STARTUP, 2 via LOADER.SYSTEM
AUTOSTART := 2
LDFLAGS   += --start-addr 0x4000
