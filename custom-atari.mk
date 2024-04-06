# reserved memory for graphics
LDFLAGS += -Wl -D__RESERVED_MEMORY__=0x2000

# set start address into 16k bank to avoid nonsense
LDFLAGS += --start-addr 0x4000

ALTIRRA ?= $(ALTIRRA_HOME)/Altirra64.exe \
  $(XS)/portable $(XS)/portablealt:altirra-debug.ini \

#   $(XS)/debug \
#   $(XS)/debugcmd: ".loadsym build\$(PROGRAM).$(CURRENT_TARGET).lbl" \
#   $(XS)/debugcmd: "bp _debug" \

atari_EMUCMD := $(ALTIRRA)

TARGET_PATH := $(shell $(CL) --print-target-path)
SUBST_TARGET_PATH := $(subst \$(SPACE),?,$(TARGET_PATH))

TGI := $(wildcard $(TARGET_PATH)/$(SYS)/drv/tgi/*)
TGI := $(addprefix $(SUBST_TARGET_PATH)/$(SYS)/drv/tgi/,$(notdir $(filter %.tgi,$(TGI))))
