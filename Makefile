.PHONY: all objects clean

SDCC ?= sdcc-sdcc
TARGET ?= $(notdir $(CURDIR))
BUILD_DIR ?= Build

# Keep sources and include paths in dedicated variables for easy editing.
SOURCES := \
	main.c

INCLUDE_DIRS := \
	inc

# Default to the classic 8051 / MCS-51 small-memory model.
PORT_FLAGS ?= -mmcs51 --model-small
CPPFLAGS ?=
CFLAGS ?=
LDFLAGS ?=

INCLUDE_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))
HEADERS := $(wildcard $(addsuffix /*.h,$(INCLUDE_DIRS)))
OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.rel,$(SOURCES))
LINK_OBJECTS := $(patsubst $(BUILD_DIR)/%,%,$(OBJECTS))
IHX_OUTPUT := $(BUILD_DIR)/$(TARGET).ihx
OUTPUT := $(BUILD_DIR)/$(TARGET).hex

all: $(OUTPUT)

objects: $(OBJECTS)

$(OUTPUT): $(IHX_OUTPUT)
	cp -f $< $@

$(IHX_OUTPUT): $(OBJECTS)
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(SDCC) $(PORT_FLAGS) $(LDFLAGS) -o $(notdir $@) $(LINK_OBJECTS)

$(BUILD_DIR)/%.rel: %.c $(HEADERS)
	mkdir -p $(dir $@)
	$(SDCC) $(PORT_FLAGS) $(CPPFLAGS) $(CFLAGS) $(INCLUDE_FLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
