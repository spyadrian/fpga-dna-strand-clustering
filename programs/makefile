# -- Compiler and flags --
CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c99 -Ialgorithm
LDFLAGS = 

# -- Docker variables --
DOCKER_IMAGE = benchmark-docker

# -- Source files --
TESTBENCH_SRCS = testbench.c algorithm/algorithm.c
BENCHMARK_SRCS = benchmark.c algorithm/algorithm.c
TARGETS = benchmark testbench

# -- Python environment --
VENV_DIR = .venv
PYTHON = $(VENV_DIR)/bin/python
PIP = $(VENV_DIR)/bin/pip
GENERATOR_SCRIPT = generator.py

# -- Rules --

usage:
	@echo "Usage:"
	@echo "  make usage          # Displays this usage information"
	@echo "  make run            # Runs the full process (generates data and runs in Docker)"
	@echo "  make generate-data  # Generates test data (data.txt)"
	@echo "  make all            # Builds the benchmark and testbench programs"
	@echo "  make benchmark      # Build the benchmark programs"
	@echo "  make testbench      # Build the testbench programs"
	@echo "  make docker-build   # Builds the Docker image"
	@echo "  make docker-run     # Runs the build in Docker"
	@echo "  make clean          # Cleans the build and virtual environment"

run: generate-data docker-run

all: $(TARGETS)

benchmark: $(BENCHMARK_SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

testbench: $(TESTBENCH_SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)
	rm -rf $(VENV_DIR)
	rm -f data.txt

docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm -v $(PWD):/app -w /app $(DOCKER_IMAGE) make all

generate-data: $(VENV_DIR)/bin/activate
	$(PYTHON) $(GENERATOR_SCRIPT)

$(VENV_DIR)/bin/activate: requirements.txt
	python3 -m venv $(VENV_DIR)
	$(PIP) install -r requirements.txt

.PHONY: run clean docker-build docker-run generate-data usage
