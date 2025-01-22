# -- Compiler and flags --
CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c99 -Ialgorithm
LDFLAGS = 

# -- Docker variables --
DOCKER_IMAGE = benchmark-docker

# -- Source files --
SRCS = benchmark.c algorithm/algorithm.c
TARGETS = benchmark testbench

# -- Rules --

run: docker-run

all: $(TARGETS)

benchmark: $(SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

testbench: $(SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)

docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm -v $(PWD):/app -w /app $(DOCKER_IMAGE) make all

.PHONY: run clean docker-build docker-run
