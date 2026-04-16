TEST_TARGETS := \
	test-b1 test-b2 test-b3 test-b4 \
	test-b5 test-b6 test-b7 test-b8 \
	test-release-trigger test-display-replace \
	test-buzzer-duration

.PHONY: all objects clean test $(TEST_TARGETS)
.PHONY: build

# Fedora uses sdcc-sdcc and sdcc-ucsim_51, Ubuntu/Debian uses sdcc and ucsim_51
SDCC ?= sdcc-sdcc
UCSIM ?= sdcc-ucsim_51
UCSIM_CPU ?= 51
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
TEST_DIR := test

all: build

build: $(OUTPUT)

objects: $(OBJECTS)

test: build $(TEST_TARGETS)
	@echo "All ucsim tests passed."

$(TEST_TARGETS): $(OUTPUT)
	mkdir -p $(BUILD_DIR)
	UCSIM="$(UCSIM)" UCSIM_CPU="$(UCSIM_CPU)" TEST_OUTPUT="$(OUTPUT)" TEST_LOG="$(BUILD_DIR)/$@.log" \
		sh $(TEST_DIR)/$@.sh

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
