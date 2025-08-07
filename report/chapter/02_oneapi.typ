#import "../conf.typ": *

= OneAPI

#todo[Is chapter 2.3 to much a repetition of the rest ?]

Traditionally, programming FPGAs relies on hardware description languages like Verilog HDL or VHDL, which require specifying low-level circuit structure and functionality.
While powerful, these languages are complex and challenging for most developers, leading to high development costs and steep learning curves.
High-Level Synthesis (HLS) has emerged as a solution, allowing developers to describe hardware behavior using more familiar languages like C or C++.
HLS tools then translate this high-level code into register-transfer level designs, simplifying hardware development.

Initially, the task of this project was to implement an algorithm (e.g. The Myers’ Bit-parallel) entirely in VHDL.
However, because maintaining and transferring this low-level code proved challenging for the client, we decided to shift to an HLS-based approach using oneAPI, making the project more accessible and manageable for future development.


== oneAPI Overview

CPUs, GPUs, and FPGAs are all essential computing engines, but each excels at different types of workloads due to architectural differences.
As modern applications become more diverse, achieving optimal performance increasingly requires a mix of specialized architectures, including CPUs, GPUs, AI accelerators, and FPGAs.
However, programming each of these devices typically involves different languages and tools, making code less portable and increasing software development effort.

To address these challenges, Intel introduced oneAPI, a unified programming model designed to simplify development across CPUs, GPUs, FPGAs, and other accelerators.
By providing a single set of tools, languages, and libraries, oneAPI enables developers to write code once and deploy it efficiently across diverse hardware platforms, streamlining workflow and enhancing code portability.
Those features are offered thanks to the use of modern C++ features and the help of SYCL to express parallelism.

Within the oneAPI ecosystem, Intel provides FPGA programming support through tools like the Intel FPGA SDK for OpenCL and the Intel FPGA Add-on for the oneAPI Base Toolkit.
These tools allow developers to program FPGAs using the DPC++ language.
Once development is complete, the DPC++ (Data Parallel C++) compiler, in combination with Intel Quartus software and the relevant board support package, efficiently compiles and deploys the code onto the FPGA hardware.


== SYCL and Data Parallel C++ (DPC++) Overview

SYCL (pronounced “sick-el”) is an open standard developed by the Khronos Group for programming heterogeneous architectures using standard C++.
It provides a single-source programming model, allowing both host and device code to be written in the same file called a "big binary".
SYCL is designed to enable efficient execution on a wide range of hardware, including CPUs, GPUs, and FPGAs, without requiring platform-specific code changes.

#figure(
  caption: [SYCL Logo],

  image("../figure/sycl.png", width: 50%)
)

SYCL works by expressing parallelism through kernels, which are functions executed on the device (such as a GPU or FPGA).
The runtime manages data transfer between host and device, as well as the scheduling of kernels.
SYCL uses modern C++ features, such as templates and lambdas, to define kernels and data management abstractions.
The programmer writes a single codebase, and SYCL ensures that the appropriate hardware is targeted at runtime, depending on the available devices and configuration.

The Intel® oneAPI DPC++/C++ Compiler is Intel’s implementation of the SYCL standard.
It optimizes applications for Intel® 64 architectures on Linux and Windows, supporting the latest C and C++ standards.
Builds upon SYCL by introducing additional extensions and features aimed at optimizing performance and increasing productivity for developers targeting Intel architectures.
We can say that the DPC++/C++ is contained in the oneAPI framework.

// source: link("https://www.khronos.org/blog/sycl-the-dawn-of-a-unified-programming-model-for-heterogeneous-modern-c-at-sc19", [from khronos.org, ref. URL05]),
#figure(
  caption: [SYCL Implementations Provide Access to Diverse Processors Through Standard C++],

  image("../figure/sycl-provide-access-to-diverse-processors.jpg")
)


== Advantages of SYCL for FPGA Acceleration

SYCL offers significant benefits for developers seeking to leverage FPGA acceleration in their applications.
One of the primary advantages is hardware abstraction: SYCL enables the writing of code that can be efficiently compiled for FPGA using High-Level Synthesis (HLS) tools, eliminating the need for FPGA-specific programming.
This abstraction simplifies the development process and broadens the accessibility of FPGA technology.
Notably, SYCL is based on C++, making it much easier for software developers to target FPGAs without having to learn traditional HDLs.
This lowers the entry barrier and accelerates the adoption of FPGA acceleration, especially for those with a software background.

Another key benefit is performance portability.
With SYCL, it is possible to target specific kernels for FPGA execution while running other parts of an application on CPU or GPU.
This flexibility allows developers to optimize for both performance and energy efficiency, depending on the requirements of individual computational tasks.

SYCL’s single-source approach further simplifies development.
Developers can experiment with FPGA acceleration without the need to rewrite their entire codebase, making it easier to integrate FPGA into existing pipelines.
This approach streamlines the adoption of FPGA technology and reduces development overhead, something that was searched by the DNAMIC engineers.


== Programming with DPC++

As DPC++ is based on C++ programming language, its syntax and usage look exactly like those in C++.
The difference occurs when programming with different types of devices.
Here is a first example of SYCL code, the different elements will be explained in coming sections.

// source: link("https://www.khronos.org/blog/sycl-the-dawn-of-a-unified-programming-model-for-heterogeneous-modern-c-at-sc19", [ADD SOURCE]),
#figure(
  caption: [A first example of SYCL code explained],

  image("../figure/basic-code-explained.png", width: 92%)
) <fig_img_basic-code>

=== Queues and Device Selector

The concept of device code revolves around the use of kernels in DPC++.
A kernel is a piece of code that is sent to a device such as a CPU, GPU, or FPGA.
Is at the moment to send this piece of code that queues come into play.

#figure(
  caption: [SYCL `queue` initialization example],

```cpp
sycl::queue q();

q.submit([&](sycl::handler& h){
    // Command group function
}).wait();
```
) <fig_code_sycl-queue>

The queue has an associated device that any commands enqueued to it will target.
The SYCL runtime will discover a set of device and their platforms that are available in the system.

To simplify the process of traversing the system topology SYCL provides device selectors.
A device selector is is a callable C++ object which defines a heuristic for scoring devices.
A device selector takes a parameter of type `const device` and gives it a "score".
It is used to query all devices and return the one with the highest "score".
SYCL provides a number of standard device selectors, e.g. `default_selector_v`, `gpu_selector_v`, etc.

#figure(
  caption: [SYCL device selector example],

```cpp
int my_gpu_selector(const device& dev) {
    if (dev.is_gpu()){
        return 1;
    }
    else {
        return -1;
    }
}

int main(int argc, char *argv[]) {
  auto gpuQueue = queue{my_gpu_selector};
}
```
) <fig_code_sycl-queue>

=== Parrallel For

A key feature of SYCL for enabling efficient parallel processing on heterogeneous hardware such as FPGA, CPU, and GPU is the `parallel_for` construct.
This construct allows developers to express data-parallel computations in a straightforward manner, where the same kernel function is executed concurrently over a range of data elements.
In the context of DNA sequence analysis or similarity joins, `parallel_for` enables the simultaneous processing of multiple sequences, significantly increasing throughput and reducing overall execution time.

When targeting FPGA with DPC++, the `parallel_for` construct is mapped to hardware pipelines by the High-Level Synthesis (HLS) tools.
This mapping allows FPGA resources to be used efficiently, exploiting spatial parallelism where independent operations are performed simultaneously on different data streams.
Additionally, SYCL’s memory management features, such as buffers and accessors, ensure that data is automatically transferred between host and device memory, further simplifying the integration of `parallel_for` into complex pipelines.
You can see how it's being used in the @fig_img_basic-code.

=== Memory Management

Memory management is essential for accelerating applications on FPGA and other heterogeneous hardware.
SYCL simplifies this by providing high-level abstractions for data movement and access, allowing data to be transferred efficiently between the CPU and FPGA without requiring low-level code from the developer.

SYCL’s buffer and accessor model enables seamless data sharing between host and device.
Buffers manage data on the host, and the SYCL runtime automatically handles transfers to and from the device.
When a kernel is launched, entire runtime ensures all required data is available on the device and synchronizes results back to the host.
The example @fig_img_basic-code use a memory management with buffers.

Unified shared memory (USM) provides an alternative pointer-based data management model to the accessor-buffer model.
USM memory allocations return pointers which are consistent between the host application and kernel functions on a device.
Its pointer-based API is more familiar to C or C++ programmers.
USM has three different kinds of memory allocation :

- A host allocation is allocated in host memory
- A device allocation is allocation in device memory
- A shared allocation is allocated in shared memory and can migrate back and forth

With our FPGA, only USM was able to work.
Here is a basic example of the use of USM :

#figure(
  caption: [SYCL USM usage example],

```cpp
float a[size], b[size], r[size];
for (int i = 0; i < size; ++i) {
  a[i] = static_cast<float>(i);
  b[i] = static_cast<float>(i);
  r[i] = 0.0f;
}

auto q = sycl::queue{usm_selector};

auto ptrA = sycl::malloc_device<float>(size, q);
auto ptrB = sycl::malloc_device<float>(size, q);
auto ptrR = sycl::malloc_device<float>(size, q);

usmQueue.memcpy(ptrA, a, sizeof(float) * size).wait();
usmQueue.memcpy(ptrB, b, sizeof(float) * size).wait();

q.parallel_for<vector_add>(sycl::range{size}, [=](sycl::id<1> idx) {
    auto g_id = idx[0];
    ptrR[g_id] = ptrA[g_id] + ptrB[g_id];
}).wait();

q.memcpy(r, ptrR, sizeof(float) * size).wait();

sycl::free(ptrA, q);
sycl::free(ptrB, q);
sycl::free(ptrR, q);
```
) <fig_code_USM-example>


=== Pragma

In DPC++ programming for FPGAs, pragma directives are special compiler hints used to optimize the hardware implementation of your code.
They help control how loops and other code structures are translated into FPGA hardware, allowing for better performance and efficient resource use.

A common pragma is `#pragma unroll`, which tells the compiler to fully or partially unroll a loop.
Loop unrolling can increase parallelism by generating multiple hardware operations for each loop iteration.
For example:

#figure(
  caption: [Bitwise OR operations on integer 256 using pragma],

```cpp
DNABitVector256 operator|(const DNABitVector256& other) const {
    DNABitVector256 result;

    #pragma unroll
    for (int i = 0; i < NUM_WORDS; i++) {
        result.words[i] = words[i] | other.words[i];
    }

    return result;
}
```
) <fig_code_USM-example>

This instructs the compiler to replicate the loop body multiple times, effectively executing iterations in parallel on the FPGA.
Using pragmas strategically is essential for tuning your FPGA design to meet performance goals without wasting resources.
