#import "../conf.typ": *

= Heterogeneous Programming with CPU and FPGA


== Compiling for Mixed Device

When you create a program with offload, the compiler must generate code for both the host and the device.
This requires two compilation passes; one for the host code and one for the device code.

// source: link("https://www.intel.com/content/www/us/en/docs/oneapi/programming-guide/2024-2/compilation-flow-overview.html", [Compilation Flow Overview]),
#figure(
  caption: [Basic compilation flow],

  image("../figure/sycl-compiling.png", width: 75%)
)

Thus, it is necessary to have the appropriate backend for the device being programmed.
Currently, SYCL supports backends such as OpenCL, CUDA, HIP, OpenMP, and others.

When writing code for multiple different devices, careful attention must be paid to compilation, because some features are not compatible from one backend to another.
Sometimes, it is necessary to separate the compilation processes in order to produce static or dynamic libraries, which are then assembled to create a fat binary.
A fat binary is a host executable that includes embedded device code for one or more target devices.
This is especially the case for FPGA compilation.

== FPGA Compile Feature

FPGAs differ significantly from CPUs and GPUs in several ways.
Regarding compilation, compared to CPUs and GPUs, generating an image for FPGA is a very time-consuming process.
Generally, this can take several hours.
For this reason, the ahead-of-time (AOT) compilation flow is used for FPGAs.

In the AOT compilation flow, the device code is translated to SPIR-V and then processed by the device-specific backend in the host compiler, with the resulting device code being embedded in the generated fat binary.
In this process, the target device must be specified at compilation time, which provides less flexibility than the just-in-time (JIT) compilation used for CPUs and GPUs.
This trade-off between compilation time and deployment flexibility is a fundamental characteristic of FPGA development workflows, where the lengthy synthesis process makes runtime compilation impractical for most applications.

// source: link("https://www.intel.com/content/www/us/en/docs/oneapi/programming-guide/2024-2/compilation-flow-overview.html", [Compilation Flow Overview]),
#figure(
  caption: [AOT Compilation Flow],

  image("../figure/aot-compilation.png", width: 100%)
)

There are four types of compilation for FPGAs, which are summarized in the table below :

#figure(
  table(
    columns: (1fr, 1.75fr, 3.25fr),
    align: (left, left, left),
    table.header([*Target*], [*Output*], [*Description*]),
    [Emulator], [x86-64 binary (seconds)], [Compiles the FPGA device code to the CPU. Use the Intel® FPGA Emulation Platform for OpenCL™ software to verify your SYCL code's functional correctness.],
    [Optimization Report], [RTL + FPGA reports (minutes)], [Compiles the FPGA device code to RTL and generates an optimization report that describes the structures generated on the FPGA, identifies performance bottlenecks, and estimates resource utilization. This report will include the interfaces defined in your selected Board Support Package.],
    [Simulator], [RTL + FPGA reports + x86-64 binary (minutes)], [Compiles the FPGA device code to RTL and generates a simulation test bench. Use the Questa\*-Intel® FPGA Edition simulator to verify your design.],
    [FPGA Hardware], [Quartus Place & Route + FPGA reports + x86-64 host binary (Multiple Hours)], [Compiles the FPGA device code to RTL and compiles the generated RTL using Intel®]
  ),

  caption: [Compilation targets and their characteristics]
)

The typical workflow for FPGA development involves going through all the different compilation types, and optimizing or correcting the code at each stage as needed.

== Compilation Flow

During compilation for both the CPU and FPGA, a separate compilation was performed.
One reason for this is the incompatibility between the flags required for the CPU and those needed for the FPGA during compilation.
Another reason is that if the FPGA kernel does not change (which is the case most of the time), it is not necessary to recompile it with the rest of the code if it has already been compiled separately.
There is also another compilation style using the `-reuse-exe` flag, where the FPGA kernel is not recompile, but this method was not used.

In this compilation flow, the device kernel is compiled first, and then the host source code is compiled and linked against the device kernel (provided as a library).
Below is an example of separate compilation using `vector-add` example, where two kernels, one CPU and one FPGA, are compiled separately before being linked together.
This type of compilation was used for compiling the OneJoin implementation, but not for OneMyers.
Since OneMyers only uses a single queue, separate compilation was not necessary in that case.

// https://dl.acm.org/doi/fullHtml/10.1145/3636480.3637220
#figure(
  caption: [Schematic of the Compilation Flow],

  image("../figure/compile-flow.png", width: 80%)
)

// https://dl.acm.org/doi/fullHtml/10.1145/3636480.3637220
#figure(
  caption: [Commands Lines of the Compilation Flow],

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

