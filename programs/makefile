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

docker-build:
	docker build -t benchmark-docker .

docker-run:
	docker run --rm -v $(PWD):/app -w /app benchmark-docker make

docker-clean:
	docker run --rm -v $(PWD):/app -w /app benchmark-docker make clean

.PHONY: run clean docker-build docker-run docker-clean
