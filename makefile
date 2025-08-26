CXX = dpcpp
BASE_FLAGS = -fsycl -std=c++17 -O3 -Wno-enum-constexpr-conversion -fsycl -fsycl-unnamed-lambda -w $(PARAMS)
LDFLAGS = -lsycl -ltbb -lpthread -lboost_program_options -lboost_thread -lboost_system -lboost_log -lboost_log_setup
PARAMS = -DDEF_NUM_STR=24 -DDEF_NUM_HASH=28 -DDEF_NUM_BITS=11 -DDEF_NUM_CHAR=4 -DDEF_K_INPUT=48 -DDEF_SHIFT=16

SRC_DIR = src
BUILD_DIR = build
CPU_SRC = main.cpp verification.cpp Time.cpp utils.cpp DBSCAN.cpp constants.cpp
EXT_SRC = create_buckets_ext.cpp

CPU_OBJ = $(addprefix $(BUILD_DIR)/, $(CPU_SRC:.cpp=.cpu.o))
EXT_OBJ_GPU = $(BUILD_DIR)/create_buckets_ext.gpu.o
EXT_OBJ_FPGA = $(BUILD_DIR)/create_buckets_ext.fpga.a

BOARD = a7sk
DEVICE_CST ?= -DCPU
EXE_NAME = onejoin


$(BUILD_DIR)/%.cpu.o: $(SRC_DIR)/%.cpp
	$(CXX) $(BASE_FLAGS) $(DEVICE_CST) -fPIC -fsycl-targets=spir64_x86_64 -c $< -o $@

$(BUILD_DIR)/onejoin_dpcpp.cpu.o $(BUILD_DIR)/onejoin_dpcpp.gpu.o $(BUILD_DIR)/onejoin_dpcpp.fpga.o: $(SRC_DIR)/onejoin_dpcpp.cpp
	$(CXX) $(BASE_FLAGS) $(DEVICE_CST) -fPIC -fsycl-targets=spir64_x86_64 -c $< -o $@


$(BUILD_DIR)/create_buckets_ext.gpu.o: $(SRC_DIR)/create_buckets_ext.cpp
	$(CXX) $(BASE_FLAGS) $(DEVICE_CST) -fsycl-targets=nvptx64-nvidia-cuda -c $< -o $@

$(BUILD_DIR)/create_buckets_ext.fpga.a: $(SRC_DIR)/create_buckets_ext.cpp
	$(CXX) $(BASE_FLAGS) $(DEVICE_CST) -fintelfpga -Xshardware -Xstarget=$(BOARD) -c $< -o $@


cpu: DEVICE_CST=-DCPU
cpu: $(CPU_OBJ) $(BUILD_DIR)/onejoin_dpcpp.cpu.o
	$(CXX) $(BASE_FLAGS) $(LDFLAGS) -fsycl-targets=spir64_x86_64 $^ -o $(EXE_NAME).cpu

gpu: DEVICE_CST=-DGPU
gpu: $(CPU_OBJ) $(BUILD_DIR)/onejoin_dpcpp.gpu.o $(EXT_OBJ_GPU)
	$(CXX) $(BASE_FLAGS) $(LDFLAGS) -fsycl-targets=spir64_x86_64,nvptx64-nvidia-cuda $^ -o $(EXE_NAME).gpu

fpga: DEVICE_CST=-DFPGA_HARDWARE
fpga: $(CPU_OBJ) $(BUILD_DIR)/onejoin_dpcpp.fpga.o $(EXT_OBJ_FPGA)
	$(CXX) $(BASE_FLAGS) $(LDFLAGS) -fintelfpga $^ -o $(EXE_NAME).fpga


clean:
	rm -rf $(BUILD_DIR)/* $(EXE_NAME).cpu $(EXE_NAME).gpu $(EXE_NAME).fpga

help:
	@echo "make cpu     # Compile et lie pour CPU"
	@echo "make gpu     # Compile pour GPU (create_buckets_ext en GPU)"
	@echo "make fpga    # Compile pour FPGA (create_buckets_ext en FPGA)"
	@echo "make clean   # Supprime binaires et objets"

.PHONY: cpu gpu fpga clean help
