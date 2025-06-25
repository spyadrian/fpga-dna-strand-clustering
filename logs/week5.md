# Week 5

### Table of contents

1. [Tuesday 24 June](#monday--24-june)

### Tasks

- [ ] Check for Michaël's problem about Bucket converging to 0
- [ ] Test the FPGA simulator of SYCL
- [ ] Make the intermediate report

### Links

- [FPGA Support Package for the Intel](https://www.intel.com/content/www/us/en/developer/articles/release-notes/intel-oneapi-compiler-fpga-add-on-release-notes.html)
- [OneJoin paper](https://adms-conf.org/2021-camera-ready/marinelli_adms21.pdf)
- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)


## Tuesday : 24 June

I had the `dataset-generator` Git as a sub-module, just in case.

I tried to replicate the problem of Michaël using the `big` dataset with quite the basic parameters, but I didn't had the buckets converging to zero.
I'll ask his parameters to continue on this issue.

I continue by doing the report that I stop after doing the template.

To compile for FPGA I need to change the Makefile to add some flag.
I decide to make more modification that allows you to choose for which devices you are compiling for.
It was a bit mandatory as you cannot combine some flag and there are some different output according to them.
In addition, you don't have to wait to much time to have one binary that have all devices and you don't have to erase each output every time you do another one.

Thus, modification has been made on the `Makefile` to change the flag and on the `onejoin_dpcpp.cpp` to choose the right queue.
Here are the main modification :

```make
DEVICE ?= cpu# cpu | gpu | fpga_emu | report | fpga_sim | fpga_hw
BOARD ?= Agilex7

ifeq ($(DEVICE),cpu)
  DEVICE_FLAGS = -fsycl-targets=spir64_x86_64
  EXE_SUFFIX   = .cpu
else ifeq ($(DEVICE),gpu)
  DEVICE_FLAGS = -fsycl-targets=nvptx64-nvidia-cuda
  EXE_SUFFIX   = .gpu
else ifeq ($(DEVICE),fpga_emu)
  DEVICE_FLAGS = -DFPGA_EMULATOR -fintelfpga
  EXE_SUFFIX   = .femu
else ifeq ($(DEVICE),report)
  DEVICE_FLAGS = -DFPGA_HARDWARE -fintelfpga -Xscompile-time-report -Xstarget=$(BOARD)
  EXE_SUFFIX   = .report
else ifeq ($(DEVICE),fpga_sim)
  DEVICE_FLAGS = -DFPGA_SIMULATOR -fintelfpga -Xssimulation -Xsghdl -Xstarget=$(BOARD)
  EXE_SUFFIX   = .fsim
else ifeq ($(DEVICE),fpga_hw)
  DEVICE_FLAGS = -DFPGA_HARDWARE -fintelfpga -Xshardware -Xstarget=$(BOARD)
  EXE_SUFFIX   = .fpga
else
  $(error DEVICE=$(DEVICE) not recognized)
endif

DPCPP_FLAGS = $(COMMON_FLAGS) $(DEVICE_FLAGS)

cpu gpu fpga_emu report fpga_sim fpga_hw:
	$(MAKE) build DEVICE=$@
```

```c
#if   defined(FPGA_SIMULATOR)
  using DeviceSelector = sycl::ext::intel::fpga_simulator_selector;
#elif defined(FPGA_HARDWARE)
  using DeviceSelector = sycl::ext::intel::fpga_selector;
#elif defined(FPGA_EMULATOR)
  using DeviceSelector = sycl::ext::intel::fpga_emulator_selector;
#endif

// Helper that builds a queue with the proper properties (in‑order + profiling)
template <typename AsyncHandlerT>
inline sycl::queue make_fpga_queue(AsyncHandlerT &&handler) {
#ifdef DeviceSelector
  return sycl::queue(DeviceSelector{}, std::forward<AsyncHandlerT>(handler),
                     sycl::property::queue::in_order{});
#else
  static_assert(false,
                "No FPGA_* macro defined — add -DFPGA_EMULATOR | _FAST_EMULATOR | _SIMULATOR | _HARDWARE");
#endif
}

// [...]

#if defined(FPGA_EMULATOR) || defined(FPGA_FAST_EMULATOR) || defined(FPGA_SIMULATOR) || defined(FPGA_HARDWARE)
  queues.push_back(make_fpga_queue(asyncHandler));
  device = cpu; // fallback value so the rest of the code treats it as 1 device
#else
  // native code
#endif
```

When I try it, I notice that I forget to install `./intel-fpga-support-for-compiler-2025.0.0.591_offline.sh` (I add it on Week 4 too).
Then something strange happens, even if I just install the FPGA support, I couldn't use the `aocl` command.
The problem was coming from the fact that I install some of the package with `sudo` and others without, that cringe because there was two instance of OneAPI that don't saw each others.

I'll update that on my PC setup.


## Wednesday : 25 June

Trying to compile for fpga -> aocl not find or something, trying to correct that
I recieve Michaël mail to authors -> do I get the same error ?

