CC = gcc
CFLAGS = -Wall -Wextra -O2 -Isrc/core/cjson
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
TEST_DIR = test

SRCS := $(shell find $(SRC_DIR) -name '*.c')
OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

TARGET = $(BIN_DIR)/hello_devlite

all: $(TARGET) copy-to-test

$(TARGET): $(OBJS) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TEST_DIR):
	mkdir -p $(TEST_DIR)

copy-to-test: $(TARGET) | $(TEST_DIR)
	cp $(TARGET) $(TEST_DIR)/hello_devlite

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR) $(TEST_DIR)/hello_devlite
