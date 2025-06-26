# Week 5

### Table of contents

1. [Tuesday 24 June](#monday--24-june)
2. [Wednesday 25 June](#wednesday--25-june)
3. [Thursday 26 June](#thursday--26-june)

### Tasks

- [ ] Check for Michaël's problem about Bucket converging to 0
- [ ] Test the FPGA simulator of SYCL
- [ ] Make the intermediate report

### Links

- [FPGA Support Package for the Intel](https://www.intel.com/content/www/us/en/developer/articles/release-notes/intel-oneapi-compiler-fpga-add-on-release-notes.html)
- [Get FPGA SUpport Package for Intel](https://www.intel.com/content/www/us/en/developer/tools/oneapi/fpga-download.html?operatingsystem=linux&linux-install=offline)
- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)
- [FPGA tutorial - How to compile SYCL for FPGAs](https://github.com/oneapi-src/oneAPI-samples/tree/master/DirectProgramming/C++SYCL_FPGA/Tutorials/GettingStarted/fpga_compile)


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
  return sycl::queue(DeviceSelector{}, std::forward<AsyncHandlerT>(handler), sycl::property::queue::in_order{});
}

// [...]

#if defined(FPGA_EMULATOR) || defined(FPGA_FAST_EMULATOR) || defined(FPGA_SIMULATOR) || defined(FPGA_HARDWARE)
  queues.push_back(make_fpga_queue(asyncHandler));
  device = cpu; // fallback value so the rest of the code treats it as 1 device
#else
  // native code
#endif
```

Those modification let you use the 4 level of the FPGA summarized on this table from the FPGA tutorial :

| Target              | Expected Time  | Output              | Description
|:---                 |:---            |:---                 |:---
| Emulator            | Seconds        | x86-64 binary       | Compiles the FPGA device code to the CPU. Use the Intel® FPGA Emulation Platform for OpenCL™ software to verify your SYCL code’s functional correctness.
| Optimization Report | Minutes        | RTL + FPGA reports  | Compiles the FPGA device code to RTL and generates an optimization report that describes the structures generated on the FPGA, identifies performance bottlenecks, and estimates resource utilization. This report will include the interfaces defined in your selected Board Support Package.
| Simulator          | Minutes         | RTL + FPGA reports + x86-64 binary    | Compiles the FPGA device code to RTL and generates a simulation test bench. Use the Questa*-Intel® FPGA Edition simulator to verify your design.
| FPGA Hardware      | Multiple Hours  | Quartus Place & Route (Multiarchitecture binary) + FPGA reports + x86-64 host binary                                                  | Compiles the FPGA device code to RTL and compiles the generated RTL using Intel® 

The typical FPGA development workflow is to iterate in each of these stages, refining the code using the feedback provided by that stage.
You can avoid long compile times by relying on emulation and the optimization report whenever possible.
_See more details on FPGA tutorial linked above_.

When I try to compile, I notice that I forget to install `./intel-fpga-support-for-compiler-2025.0.0.591_offline.sh` (I add it on `week5.md` too).
Then something strange happens, even if I just install the FPGA support, I couldn't use the `aocl` command.
The problem was coming from the fact that I install some of the package with `sudo` and others without, that cringe because there was two instance of OneAPI that don't saw each others.

I'll update that on my PC setup.


## Wednesday : 25 June

I start by cleaning my setup and making sure that all installed thing was on the same directory (all install without `sudo`).
After installing all the necessary, I try to `make fpga_emu` but I had an error telling me that I don't had the FPGA Emulator Platform :

```
OpenCL platform ID is empty
OpenCL platform name is empty
Failed to find any of these OpenCL platforms:
  Intel(R) FPGA Emulation Platform for OpenCL(TM)
  Intel(R) FPGA Emulation Platform for OpenCL(TM) (preview)
llvm-foreach:
icpx: error: fpga compiler command failed with exit code 14 (use -v to see invocation)
```

I spend a lot of time between trying to solve it installing some other version but nothing worked.

On that day, I received the parameters Michaël was using to create his error.
I'll try this error when I finish to setup the FPGA emulator.


## Thursday : 26 June

So about this error of platforms OpenCL.
I skip all the investigation part, but in summary the error was caused to silent crash of a library that didn't find another one.
Here is, in short, how I debug it :

First, every platforms the pc had can be list with the command `clinfo -l`, for my part I had this (no FPGA Emulator) :

```
🎗️ ❯ clinfo -l
Platform #0: Intel(R) OpenCL
 `-- Device #0: Intel(R) Core(TM) i7-1065G7 CPU @ 1.30GHz
Platform #1: rusticl
 `-- Device #0: Mesa Intel(R) Iris(R) Plus Graphics (ICL GT2)
Platform #2: NVIDIA CUDA
 `-- Device #0: NVIDIA GeForce GTX 1660 Ti with Max-Q Design
```

What enable `clinfo` to show those platforms are files contains in the `/etc/OpenCL/vendors/`, in my case :

```
🎗️ ❯ l /etc/OpenCL/vendors/
total 20K
drwxr-xr-x 1 root root 178 Jun 26 15:04 .
drwxr-xr-x 1 root root  14 May 16 16:58 ..
-rw-r--r-- 1 root root  15 Jun 25 19:22 Altera.icd
-rw-r--r-- 1 root root  32 Jun 26 15:04 Intel_FPGA_SSG_Emulator.icd
-rw-r--r-- 1 root root  22 May 24 23:30 nvidia.icd
-rw-r--r-- 1 root root  22 May 26 16:26 rusticl.icd
```

But even if the file `Intel_FPGA_SSG_Emulator` is here with the right content (`libintelocl_emu.so`) the `clinfo` didn't manage to get it, meaning that the library was not found or crash silently.
I first start by making sure the library was on the `LD_LIBRARY_PATH` and it was not the case.
Thing I could check by using `ldconfig`.
So I add it by copying it on the `/usr/lib/ib` and another folder listed by this constants (not sure which one of those worked).
But even with that it didn't worked.

To see if the library was crashing silently I make an `ldd` on it, whose result on :

```
🎗️ ❯ ldd /home/adrian/intel/oneapi/compiler/2025.0/lib/libintelocl_emu.so
	linux-vdso.so.1 (0x00007a05eb696000)
	libcommon_clang.so.2024.18.10.0 => not found
	libtbb.so.12 => /home/adrian/intel/oneapi/tbb/2022.0/env/../lib/intel64/gcc4.8/libtbb.so.12 (0x00007a05e5e00000)
  ...
```

The `libcommon_clang.so.2024.18.10.0` was not found.
What I understand later is that the package was delivered with the `2024.18.12` and not the `2024.18.10`.
What I did is make an symlink of the `2024.18.10` to the `2024.18.12` and after that I could see my platform with my `clinfo -l` :

```
🎗️ ❯ clinfo -l
Platform #0: Intel(R) FPGA Emulation Platform for OpenCL(TM)
 `-- Device #0: Intel(R) FPGA Emulation Device
Platform #1: Intel(R) OpenCL
 `-- Device #0: Intel(R) Core(TM) i7-1065G7 CPU @ 1.30GHz
Platform #2: rusticl
 `-- Device #0: Mesa Intel(R) Iris(R) Plus Graphics (ICL GT2)
Platform #3: NVIDIA CUDA
 `-- Device #0: NVIDIA GeForce GTX 1660 Ti with Max-Q Design
```

Thus, the `make fpga_emu` worked.

Special thanks to David Da Silva Marques who help me with this issue.

