.PHONY: build cpu gpu fpga_emu report fpga_sim fpga_hw clean
PARAMS=-DDEF_NUM_STR=5 -DDEF_NUM_HASH=7 -DDEF_NUM_BITS=12 -DDEF_NUM_CHAR=4 -DDEF_K_INPUT=6 -DDEF_SHIFT=6

DPCPP=dpcpp
COMMON_FLAGS= -O3 -std=c++17 -Wno-enum-constexpr-conversion -fsycl -fsycl-unnamed-lambda -w $(PARAMS)

LDFLAGS= -lsycl -ltbb -lpthread -lboost_program_options -lboost_thread -lboost_system -lboost_log -lboost_log_setup
EXE_NAME=onejoin

SRC=src
BUILD=build

DEVICE ?= cpu# cpu | gpu | fpga_emu | report | fpga_sim | fpga_hw
BOARD ?= a7sk_usm

ifeq ($(DEVICE),cpu)
  DEVICE_FLAGS = -fsycl-targets=spir64_x86_64
  EXE_SUFFIX   = .cpu
else ifeq ($(DEVICE),gpu)
  DEVICE_FLAGS = -fsycl-targets=nvptx64-nvidia-cuda
  EXE_SUFFIX   = .gpu
else ifeq ($(DEVICE),fpga_emu)
  DEVICE_FLAGS = -DFPGA_EMULATOR -fsycl-targets=spir64_x86_64,spir64_fpga
  EXE_SUFFIX   = .femu
else ifeq ($(DEVICE),report)
  DEVICE_FLAGS = -DFPGA_HARDWARE -fsycl-targets=spir64_fpga -fsycl-link=early -Xshardware -Xstarget=$(BOARD)
  EXE_SUFFIX   = .report
else ifeq ($(DEVICE),fpga_sim)
  DEVICE_FLAGS = -DFPGA_SIMULATOR -fsycl-targets=spir64_x86_64,spir64_fpga -Xsghdl -Xssimulation -Xstarget=$(BOARD)
  EXE_SUFFIX   = .fsim
else ifeq ($(DEVICE),fpga_hw)
  DEVICE_FLAGS = -DFPGA_HARDWARE -fsycl-targets=spir64_x86_64,spir64_fpga -Xshardware -Xstarget=$(BOARD)
  EXE_SUFFIX   = .fpga
else
  $(error DEVICE=$(DEVICE) not recognized)
endif

DPCPP_FLAGS = $(COMMON_FLAGS) $(DEVICE_FLAGS)

build: $(BUILD)/main.o $(BUILD)/onejoin_dpcpp.o $(BUILD)/verification.o $(BUILD)/Time.o $(BUILD)/utils.o $(BUILD)/DBSCAN.o $(BUILD)/constants.o $(BUILD)/create_buckets_fpga.o
	$(DPCPP) $(DPCPP_FLAGS) $(BUILD)/main.o $(BUILD)/onejoin_dpcpp.o $(BUILD)/verification.o $(BUILD)/Time.o $(BUILD)/utils.o $(BUILD)/DBSCAN.o $(BUILD)/constants.o $(BUILD)/create_buckets_fpga.o $(LDFLAGS) -o $(EXE_NAME)$(EXE_SUFFIX)

cpu gpu fpga_emu report fpga_sim fpga_hw:
	$(MAKE) build DEVICE=$@

update:
	rm $(BUILD)/constants.o && make build

$(BUILD)/constants.o: $(SRC)/constants.cpp
	$(DPCPP) $(DPCPP_FLAGS) $< -c -o $@

$(BUILD)/%.o: $(SRC)/%.cpp makefile
	$(DPCPP) $(DPCPP_FLAGS)  $< -c -o $@


test-join:
	./$(EXE_NAME)$(EXE_SUFFIX) -a 1 -r test/dummy_dataset.txt -d 2 -s 91 -c 0 --batch_size 500

test-cluster:
	./$(EXE_NAME)$(EXE_SUFFIX) -a 2 -r test/dummy_dataset.txt -d 2 -s 91 -c 0 --batch_size 500 --min_pts 3


clean:
	rm -rf $(BUILD)/* $(EXE_NAME).* report--*.csv consensus_results_chunk*
