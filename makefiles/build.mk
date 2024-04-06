# Generic Build script for CC65
# 
# Will look in following directories for source:
# src/*.[c|s]               # considered the "top level" dir, you can keep everything in here if you like, will not recurse into subdirs
# src/common/**/*.[c|s]     # ie. including its subdirs - allows for splitting functionality out into subdirs
# src/<target>/**/*.[c|s]   # ie. including its subdirs - only CURRENT_TARGET files will be found
#
# NOTE: All files referenced in this makefile are relative to the ORIGINAL Makefile in the root dir, not this dir

-include makefiles/os.mk

APPLE_TOOLS_DIR := ./apple-tools

CC := cl65
CL := cl65

SRCDIR := src
BUILD_DIR := build
OBJDIR := obj

# This allows src to be nested withing sub-directories.
rwildcard=$(wildcard $(1)$(2))$(foreach d,$(wildcard $1*), $(call rwildcard,$d/,$2))

PROGRAM_TGT := $(PROGRAM).$(CURRENT_TARGET)

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)

# allow for a src/common/ dir and recursive subdirs
SOURCES += $(call rwildcard,$(SRCDIR)/common/,*.s)
SOURCES += $(call rwildcard,$(SRCDIR)/common/,*.c)

# allow src/<target>/ and its recursive subdirs
SOURCES_TG := $(call rwildcard,$(SRCDIR)/$(CURRENT_TARGET)/,*.s)
SOURCES_TG += $(call rwildcard,$(SRCDIR)/$(CURRENT_TARGET)/,*.c)

# remove trailing and leading spaces.
SOURCES := $(strip $(SOURCES))
SOURCES_TG := $(strip $(SOURCES_TG))

# convert from src/your/long/path/foo.[c|s] to obj/your/long/path/foo.o
OBJ1 := $(SOURCES:.c=.o)
OBJECTS := $(OBJ1:.s=.o)
OBJECTS := $(OBJECTS:$(SRCDIR)/%=$(OBJDIR)/%)

OBJ2 := $(SOURCES_TG:.c=.o)
OBJECTS_TG := $(OBJ2:.s=.o)
OBJECTS_TG := $(OBJECTS_TG:$(SRCDIR)/%=$(OBJDIR)/%)

OBJECTS += $(OBJECTS_TG)

ASFLAGS += --asm-include-dir src/common --asm-include-dir src/$(CURRENT_TARGET)
CFLAGS += --include-dir src/common --include-dir src/$(CURRENT_TARGET)

ASFLAGS += --asm-include-dir $(SRCDIR)
CFLAGS += --include-dir $(SRCDIR)

# Split out OBJ files for each target separately.
# TARGETOBJDIR := $(OBJDIR)/$(CURRENT_TARGET)

# allow for additional flags etc
-include ./custom-$(CURRENT_PLATFORM).mk

STATEFILE := Makefile.options
-include $(STATEFILE)

define _listing_
  CFLAGS += --listing $$(@:.o=.lst)
  ASFLAGS += --listing $$(@:.o=.lst)
endef

define _mapfile_
  LDFLAGS += --mapfile $$@.map
endef

define _labelfile_
  LDFLAGS += -Ln $$@.lbl
endef

ifeq ($(origin _OPTIONS_),file)
OPTIONS = $(_OPTIONS_)
$(eval $(OBJECTS): $(STATEFILE))
endif

# Transform the abstract OPTIONS to the actual cc65 options.
$(foreach o,$(subst $(COMMA),$(SPACE),$(OPTIONS)),$(eval $(_$o_)))

# Autoboot detection
ifeq ($(CURRENT_PLATFORM),apple2)
ifeq ($(AUTOSTART),1)
AUTOBOOT := -a
else ifeq ($(AUTOSTART),2)
AUTOBOOT := -l
else
AUTOBOOT :=
endif
endif

.SUFFIXES:
.PHONY: all clean dist disk po atr $(PROGRAM).$(CURRENT_TARGET)

all: $(PROGRAM_TGT)

$(OBJDIR):
	$(call MKDIR,$@)

# $(TARGETOBJDIR):
# 	$(call MKDIR,$@)

$(BUILD_DIR):
	$(call MKDIR,$@)

SRC_INC_DIRS := \
  $(sort $(dir $(wildcard $(SRCDIR)/$(CURRENT_TARGET)/*))) \
  $(sort $(dir $(wildcard $(SRCDIR)/common/*)))

vpath %.c $(SRC_INC_DIRS) $(SRCDIR)

$(OBJDIR)/%.o: %.c | $(OBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CURRENT_PLATFORM) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SRC_INC_DIRS)

$(OBJDIR)/%.o: %.s | $(OBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CURRENT_PLATFORM) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<


$(BUILD_DIR)/$(PROGRAM_TGT): $(OBJECTS) $(LIBS) | $(BUILD_DIR)
	$(CC) -t $(CURRENT_PLATFORM) $(LDFLAGS) -o $@ $(patsubst %.cfg,-C %.cfg,$^)


$(PROGRAM_TGT): $(BUILD_DIR)/$(PROGRAM_TGT) | $(BUILD_DIR)

test: $(PROGRAM_TGT)
	$(PREEMUCMD)
	$(EMUCMD) $(BUILD_DIR)\\$<
	$(POSTEMUCMD)

clean:
	$(call RMFILES,$(OBJECTS))
	$(call RMFILES,$(BUILD_DIR)/$(PROGRAM_TGT))

dist: $(PROGRAM_TGT)
	$(call MKDIR,dist/)
	$(call RMFILES,dist/$(PROGRAM_TGT)*)
	cp build/$(PROGRAM_TGT) dist/$(PROGRAM_TGT).com

atr: dist
	$(call MKDIR,dist/atr)
	cp dist/$(PROGRAM_TGT).com dist/atr/$(PROGRAM).com
	$(call RMFILES,dist/*.atr)
	dir2atr -S dist/$(PROGRAM).atr dist/atr

po: dist
	$(call RMFILES,dist/$(APP_NAME)*.po)
	cp dist/$(PROGRAM_TGT).com dist/$(PROGRAM)
	$(APPLE_TOOLS_DIR)/mk-bitsy.sh dist/$(PROGRAM).po TEST_$(PROGRAM)
	$(APPLE_TOOLS_DIR)/add-file.sh ${AUTOBOOT} dist/$(PROGRAM).po dist/$(PROGRAM) $(PROGRAM)

disk:
ifeq ($(CURRENT_PLATFORM),atari)
	@$(MAKE) -f makefiles/build.mk TARGETS=$(CURRENT_TARGET) PROGRAM=$(PROGRAM) atr
else ifeq ($(CURRENT_PLATFORM),apple2)
	@$(MAKE) -f makefiles/build.mk TARGETS=$(CURRENT_TARGET) PROGRAM=$(PROGRAM) po
else
	$(error Unknown target $(CURRENT_TARGET))
endif