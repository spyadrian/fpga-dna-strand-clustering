# -- Compiler and flags --
CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c99
LDFLAGS = 
TARGET = benchmark

# -- Source files --
SRCS = benchmark.c

# -- Rules --

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: run clean
