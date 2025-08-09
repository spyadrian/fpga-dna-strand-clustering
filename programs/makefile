# Makefile for DNA Matcher implementations
# Supports compilation for CPU, GPU, FPGA Emulator, FPGA Simulator, and FPGA Hardware

# Compiler
CXX = icpx

# Base flags
BASE_FLAGS = -fsycl -std=c++17 -O3

# Source files
USM_SRC = dna-matcher-usm.cpp
BUF_SRC = dna-matcher-buf.cpp

# Default target
all: cpu

# CPU targets (default)
cpu: dna-matcher-buf.cpu dna-matcher-usm.cpu

dna-matcher-buf.cpu: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) $< -o $@

dna-matcher-usm.cpu: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) $< -o $@

# GPU targets (NVIDIA CUDA)
gpu: dna-matcher-buf.gpu dna-matcher-usm.gpu

dna-matcher-buf.gpu: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) -fsycl-targets=nvptx64-nvidia-cuda -DGPU $< -o $@

dna-matcher-usm.gpu: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) -fsycl-targets=nvptx64-nvidia-cuda -DGPU $< -o $@

# FPGA Emulator targets
fpga_emu: dna-matcher-buf.fpga_emu dna-matcher-usm.fpga_emu

dna-matcher-buf.fpga_emu: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_EMULATOR $< -o $@

dna-matcher-usm.fpga_emu: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_EMULATOR $< -o $@

# FPGA Reports (resource usage and timing analysis)
fpga-reports: dna-matcher-buf.a dna-matcher-usm.a

dna-matcher-buf.a: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -fsycl-link=early -DFPGA_HARDWARE -Xshardware -Xsboard=a7sk $< -o $@

dna-matcher-usm.a: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -fsycl-link=early -DFPGA_HARDWARE -Xshardware -Xsboard=a7sk_usm $< -o $@

# FPGA Simulator targets
fpga_sim: dna-matcher-buf.fpga_sim dna-matcher-usm.fpga_sim

dna-matcher-buf.fpga_sim: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_SIMULATOR -Xsghdl -Xssimulation -Xstarget=a7sk $< -o $@

dna-matcher-usm.fpga_sim: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_SIMULATOR -Xsghdl -Xssimulation -Xstarget=a7sk_usm $< -o $@

# FPGA Hardware targets (A7SK)
fpga_hw: dna-matcher-buf.fpga_hw dna-matcher-usm.fpga_hw

dna-matcher-buf.fpga_hw: $(BUF_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_HARDWARE -Xshardware -Xsboard=a7sk $< -o $@

dna-matcher-usm.fpga_hw: $(USM_SRC)
	$(CXX) $(BASE_FLAGS) -fintelfpga -DFPGA_HARDWARE -Xshardware -Xstarget=a7sk_usm $< -o $@

# Individual file targets
buf-cpu: dna-matcher-buf.cpu
buf-gpu: dna-matcher-buf.gpu
buf-report: dna-matcher-buf.a
buf-fpga-emu: dna-matcher-buf.fpga_emu
buf-fpga-sim: dna-matcher-buf.fpga_sim
buf-fpga-hw: dna-matcher-buf.fpga_hw

usm-cpu: dna-matcher-usm.cpu
usm-gpu: dna-matcher-usm.gpu
usm-report: dna-matcher-usm.a
usm-fpga-emu: dna-matcher-usm.fpga_emu
usm-fpga-sim: dna-matcher-usm.fpga_sim
usm-fpga-hw: dna-matcher-usm.fpga_hw

# Clean targets
clean:
	rm -f *.cpu *.gpu *.fpga_emu *.fpga_sim *.fpga_hw
	rm -f *.prj *.log

clean-reports:
	rm -rf *.prj

# Help target
help:
	@echo "Available targets:"
	@echo "  all           - Build CPU versions (default)"
	@echo "  cpu           - Build both implementations for CPU"
	@echo "  gpu           - Build both implementations for GPU (NVIDIA CUDA)"
	@echo "  report        - Build both implementations for Report"
	@echo "  fpga_emu      - Build both implementations for FPGA Emulator"
	@echo "  fpga_sim      - Build both implementations for FPGA Simulator"
	@echo "  fpga_hw       - Build both implementations for FPGA Hardware (A7SK)"
	@echo ""
	@echo "Individual targets:"
	@echo "  buf-*         - Build only buffer/accessor version for specific device"
	@echo "  usm-*         - Build only USM version for specific device"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean         - Remove all compiled binaries"
	@echo "  clean-reports - Remove FPGA compilation reports"
	@echo "  help          - Show this help message"

.PHONY: all cpu gpu fpga_emu fpga_sim fpga_hw fpga-reports clean clean-reports help
.PHONY: buf-cpu buf-gpu buf-report buf-fpga-emu buf-fpga-sim buf-fpga-hw
.PHONY: usm-cpu usm-gpu usm-report usm-fpga-emu usm-fpga-sim usm-fpga-hw

