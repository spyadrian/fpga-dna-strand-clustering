#import "../conf.typ": *

= Heterogeneous Programming with CPU and FPGA


== Compiling for Mixed Devices

When creating a program with offload, the compiler must generate code for both the host and the device.
This requires two compilation: one for the host code and one for the device code.

#figure(
  caption: [Basic compilation flow @noauthor_home_nodate],

  image("../figure/sycl-compiling.png", width: 75%)
)

Thus, it is necessary to have the appropriate backend for the device being programmed.
SYCL currently supports backends such as OpenCL, CUDA, HIP, OpenMP, and others.

When writing code for multiple devices, it is important to ensure proper compilation, since some features are not compatible from one backend to another.
Sometimes, it is necessary to separate the compilation processes in order to produce static or dynamic libraries, which are then assembled to create a fat binary.
A fat binary is a host executable that includes embedded device code for one or more target devices.
This is especially the case for FPGA compilation.

== Compiling for FPGA

FPGAs differ significantly from CPUs and GPUs in several ways.
Regarding compilation, compared to CPUs and GPUs, generating an image for an FPGA is a very time-consuming process.
Generally, this can take several hours.
For this reason, the ahead-of-time (AOT) compilation flow is used for FPGAs.

In the AOT compilation flow, the device code is translated to SPIR-V and then processed by the device-specific backend in the host compiler, with the resulting device code being embedded in the generated fat binary.
In this process, the target device must be specified at compilation time, which provides less flexibility than the just-in-time (JIT) compilation used for CPUs and GPUs.
This trade-off between compilation time and deployment flexibility is a fundamental characteristic of FPGA development workflows, where the lengthy synthesis process makes runtime compilation impractical for most applications.

#figure(
  caption: [AOT compilation flow @noauthor_intel_nodate-1],

  image("../figure/aot-compilation.png", width: 100%)
)

There are four types of compilation for FPGAs, which are summarized in @fig_tab_compilation-fpga-targets.

#figure(
  caption: [Compilation targets and their characteristics @noauthor_home_nodate],

  table(
    columns: (1fr, 1.75fr, 3.25fr),
    align: (left, left, left),
    table.header([*Target*], [*Output*], [*Description*]),
    [Emulator], [x86-64 binary (seconds)], [Compiles the FPGA device code to the CPU. Use the Intel® FPGA Emulation Platform for OpenCL™ software to verify the SYCL code's functional correctness.],
    [Optimization Report], [RTL + FPGA reports (minutes)], [Compiles the FPGA device code to RTL and generates an optimization report that describes the structures generated on the FPGA, identifies performance bottlenecks, and estimates resource utilization. This report will include the interfaces defined in the selected Board Support Package.],
    [Simulator], [RTL + FPGA reports + x86-64 binary (minutes)], [Compiles the FPGA device code to RTL and generates a simulation test bench. Use the Questa\*-Intel® FPGA Edition simulator to verify the design.],
    [FPGA Hardware], [Quartus Place & Route + FPGA reports + x86-64 host binary (Multiple Hours)], [Compiles the FPGA device code to RTL and compiles the generated RTL using Intel®]
  )
) <fig_tab_compilation-fpga-targets>

The typical workflow for FPGA development involves going through all the different compilation types and optimizing or correcting the code at each stage as needed.

== Compilation Flow

To compile both the CPU and FPGA, it was necessary to separate the code into two different files.
One reason for this is the incompatibility between the compilation flags required for the CPU and those needed for the FPGA.
Another reason is efficiency: if the FPGA kernel does not change (which is most often the case), it is not necessary to recompile it with the rest of the code.

In this compilation flow, the device kernels are built first, after which the host source code is compiled and linked with the device kernels (provided as a library).
@fig_img_compilation-flow shows an example of separate compilation using the `vector-add` example, where two kernels, one CPU and one FPGA, are built separately before being linked together.
This type of compilation was used for compiling the OneJoin implementation, but not for the Tag Matcher, since it only uses a single queue.

#figure(
  caption: [Schematic of the compilation flow @liang_using_2024],

  image("../figure/compile-flow.png", width: 80%)
) <fig_img_compilation-flow>

#figure(
  caption: [Command lines of the compilation flow @liang_using_2024],

```bash
#(1) Generate kernel-cpu.o (object file)
icpx -fsycl -fPIC -fsycl-targets=spir64 -c kernel-cpu.cpp -o kernel-cpu.o
#(2) Generate kernel-fpga.a (static lib)
icpx -fsycl -fintelfpga -fsycl-link=image -DFPGA_HARDWARE -Xshardware -Xstarget=a7sk_usm kernel-fpga.cpp -o kernel-fpga.a
#(3) Generate executable from main.cpp and both lib and object files
icpx -fsycl -fintelfpga -o vector-add main.cpp kernel-cpu.o kernel-fpga-hw.a
```
)

1. This step aims to produce a standard machine object compatible with the CPU, for the parts of the code that will run on the host processor. The `-fsycl` option enables SYCL C++ compilation. The `-fPIC` option tells the compiler to generate position-independent code for the host portion of the device code, so that pointers in the shared library reference global addresses. The `-fsycl-targets=spir64` option specifies that the target is a CPU device.

2. Here, the FPGA kernel is compiled and packaged into a static library intended to be linked and later programmed onto the board. The `-fintelfpga` option enables the Intel FPGA toolchain for bitstream generation. The `-fsycl-link=image` option tells the compiler to generate an FPGA bitstream, making it ready to be linked and used on an FPGA board. The `-DFPGA_HARDWARE` flag sets a compiler variable used to determine which `device_selector` to use, in this case `fpga_selector_v`. Options prefixed with `-Xs` are passed to the FPGA backend; for example, `-Xshardware` instructs the compiler to target FPGA hardware, and `-Xstarget=a7sk_usm` specifies the target FPGA device family.

3. At this stage, the linker combines all the pieces: the host code (`main.cpp`), the CPU objects, and the FPGA archive, into a single executable. Since the FPGA library is static, the `-fintelfpga` flag should be included in the compile command.

If needed, the `kernel-fpga.cpp` can be compiled as a GPU kernel for a GPU device.
Using then the `-fsycl-targets=nvptx64-nvidia-cuda` flag combined with the right backend, the executable would be able to run on GPU.

