#import "../conf.typ": *

= OneAPI

Traditionally, programming FPGAs relies on hardware description languages like Verilog HDL or VHDL, which require specifying low-level circuit structures and functionalities.
While powerful, these languages are complex and challenging for most developers, leading to high development costs and steep learning curves.
High-Level Synthesis (HLS) has emerged as a solution, allowing developers to describe hardware behavior using more familiar languages like C or C++.
HLS tools then translate this high-level code into register-transfer level designs, simplifying hardware development.

Initially, the goal of this project was to implement an algorithm (e.g. The Myers’ Bit-parallel) entirely in VHDL.
However, maintaining and transferring this low-level code proved challenging for the client, so we decided to shift to an HLS-based approach using oneAPI, making the project more accessible and manageable for future development.


== OneAPI Overview

CPUs, GPUs, and FPGAs are all essential computing engines, but each excels at different types of workloads due to architectural differences.
As modern applications become more diverse, achieving optimal performance increasingly requires a mix of specialized architectures, including CPUs, GPUs, AI accelerators, and FPGAs.
However, programming each of these devices typically involves different languages and tools, making code less portable and increasing software development effort.

To address these challenges, Intel introduced oneAPI, a unified programming model designed to simplify development across CPUs, GPUs, FPGAs, and other accelerators.
By providing a single set of tools, languages, and libraries, oneAPI enables developers to write code once and deploy it efficiently across diverse hardware platforms, streamlining workflow and enhancing code portability.
Those features are offered thanks to the use of modern C++ features and the help of SYCL to express parallelism.

Within the oneAPI ecosystem, Intel provides FPGA programming support through tools like the Intel FPGA SDK for OpenCL and the Intel FPGA Add-on for the oneAPI Base Toolkit.
These tools allow developers to program FPGAs using DPC++ (Data Parallel C++) compiler.
Once development is complete, the DPC++, in combination with Intel Quartus software and the relevant board support package, efficiently compiles and deploys the code onto the FPGA hardware.
@fig_img_hld-intelofs-model illustrates some of the design layers between oneAPI and the Open FPGA Stack.

#figure(
  caption: [High Level Design Tool on OFS Platforms @noauthor_ofs_nodate],

  image("../figure/HLD_IntelOFS_Model.png", width: 90%)
) <fig_img_hld-intelofs-model>


== SYCL and Data Parallel C++ (DPC++) Overview

SYCL (pronounced “sick-el”) is an open standard developed by the Khronos Group for programming heterogeneous architectures using standard C++.
It provides a single-source programming model, allowing both host and device code to be written in the same file called a "big binary".
SYCL is designed to enable efficient execution on a wide range of hardware, including CPUs, GPUs, and FPGAs, without requiring platform-specific code changes.

#figure(
  caption: [SYCL Logo],

  image("../figure/sycl.png", width: 50%)
)

SYCL works by expressing parallelism through kernels, which are functions executed on the device (such as a GPU or FPGA).
The runtime manages data transfer between the host and device, as well as the scheduling of kernels.
SYCL uses modern C++ features, such as templates and lambdas, to define kernels and data management abstractions.
The programmer writes a single codebase, and SYCL ensures that the appropriate hardware is targeted at runtime, depending on the available devices and configuration.

The Intel® oneAPI DPC++/C++ Compiler is Intel’s implementation of the SYCL standard.
It optimizes applications for Intel® 64 architectures on Linux and Windows, supporting the latest C and C++ standards.
It builds upon SYCL by introducing additional extensions and features aimed at optimizing performance and increasing productivity for developers targeting Intel architectures.
The DPC++/C++ Compiler is included as part of the oneAPI framework.

#figure(
  caption: [SYCL Implementations Provide Access to Diverse Processors Through Standard C++ @noauthor_sycl_2020],

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

Since DPC++ is based on the C++ programming language, its syntax and usage are very similar to standard C++.
The differences arise when programming for different types of devices.
@fig_img_basic-code is a first example of SYCL code, with its various elements explained in the following sections.

#figure(
  caption: [A first example of SYCL code explained @noauthor_home_nodate],

  image("../figure/basic-code-explained.png", width: 92%)
) <fig_img_basic-code>

=== Queues and Device Selector

In DPC++, the concept of device code revolves around the use of kernels.
A kernel is a piece of code that is sent to a device such as a CPU, GPU, or FPGA.
It is at the moment of sending this code that queues come into play.

#figure(
  caption: [SYCL `queue` initialization example],

```cpp
sycl::queue q();

q.submit([&](sycl::handler& h){
    // Command group function
}).wait();
```
) <fig_code_sycl-queue>

A queue has an associated device, and any commands enqueued to it will target that device.
The SYCL runtime discovers the set of devices and their platforms that are available in the system.

To simplify the process of traversing the system topology SYCL provides device selectors.
A device selector is a callable C++ object that defines a heuristic for scoring devices.
A device selector takes a parameter of type `const device` and assigns it a "score".
It is used to query all devices and return the one with the highest "score".
SYCL provides a number of standard device selectors, such as `default_selector_v`, `gpu_selector_v`, etc.

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
This construct allows developers to express data-parallel computations in a straightforward manner, where the same kernel function is executed concurrently across a range of data elements.
In the context of DNA sequence analysis or similarity joins, `parallel_for` enables the simultaneous processing of multiple sequences, significantly increasing throughput and reducing overall execution time.

When targeting FPGA with DPC++, the `parallel_for` construct is mapped to hardware pipelines by the High-Level Synthesis (HLS) tools.
This mapping allows FPGA resources to be used efficiently, exploiting spatial parallelism where independent operations are performed simultaneously on different data streams.
Additionally, SYCL’s memory management features, such as buffers and accessors, ensure that data is automatically transferred between host and device memory, further simplifying the integration of `parallel_for` into complex pipelines.
@fig_img_basic-code illustrates how this construct is used.

=== Memory Management

Memory management is essential for accelerating applications on FPGA and other heterogeneous hardware.
SYCL simplifies this by providing high-level abstractions for data movement and access, allowing data to be transferred efficiently between the CPU and FPGA without requiring low-level code from the developer.
In SYCL there are two models for managing data.

SYCL’s buffer and accessor model enables seamless data sharing between host and device.
Buffers manage data on the host, while the SYCL runtime automatically handles transfers to and from the device.
When a kernel is launched, the entire runtime ensures that all required data is available on the device and synchronizes the results back to the host.
The example in @fig_img_basic-code demonstrates memory management using buffers.

There are multiple ways to initialize an accessor, depending on how the data need to be accessed.
An accessor is always associated with a command group, leading to the following connection :

#figure(
  caption: [Buffer Host Memory Accessor CG @noauthor_home_nodate],

  image("../figure/buffer-hostmemory-accessor-cg.png", width: 80%)
)

The buffer being accessed is connected to the accessor based on how the data is used.
The accessor is linked to the command group that uses it, and finally to the device.

Unified shared memory (USM) provides an alternative pointer-based data management model to the accessor-buffer model.
USM memory allocations return pointers which are consistent between the host application and kernel functions on a device.
Its pointer-based API is more familiar to C or C++ programmers.

#figure(
  caption: [Host CPU and Co-processor Sharing a Single Address Space for USM Allocations @noauthor_home_nodate],

  image("../figure/unified_virtual_address_space.png", width: 75%)
) <fig_img_unified-virtual-address-space>

The @fig_img_unified-virtual-address-space illustrates how the host CPU and a co-processor (the SYCL device such as a GPU or FPGA) share a single unified virtual address space.
This allow pointers to USM allocations to reference the same memory addresses on both sides. 
USM can be allocated in three different ways : host, device and shared.

#figure(
  caption: [USM Allocation Types],

  table(
    columns: 5,
    align: (left, left, center + horizon, center + horizon, left),
    table.header(align(center)[*Type*], align(center)[*Description*], [*Access Host*], [*Access Device*], align(center)[*Nominal Location*]),
    [device], [device global allocations], [X], [✓], [device],
    [host], [host allocation], [✓], [✓], [host],
    [shared], [allocations shared between both], [✓], [✓], [migrates as required],
  ),
)

Here is a basic example of the use of USM :

#figure(
  caption: [SYCL USM usage example],

```cpp
float a[size], b[size], r[size];
// init a, b and r with values...

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

In DPC++ programming for FPGAs, pragma directives are special hints given to the compiler used to optimize the hardware implementation of the code.
They help control how loops and other code structures are translated into FPGA hardware, allowing for better performance and more efficient use of resources.

A common pragma is `#pragma unroll`, which tells the compiler to fully or partially unroll a loop @noauthor_intel_nodate.
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
Using pragmas strategically is essential for tuning an FPGA design to meet performance goals without wasting resources.

A second pragma useful for this type of project is the pipeline pragma.
This pragma is responsible for reducing the initiation interval (II) for a function or loop by allowing multiple operations to run at the same time.
Let's say we have a function `func` doing three operations: `op_read`, `op_compute` and `op_write`.
Below is an example of how it would be with and without the pipeline.

#figure(
  caption: [Example code for the pipeline pragma @noauthor_introduction_nodate],

```cpp
void func(m, n, o) {
  for (i = 2; i >= 0; i--) {
    op_read;
    op_compute;
    op_write;
  }
}
```
)

#figure(
  caption: [Schema of an Example Code being Executed With and Without the Pipeline Pragma @noauthor_introduction_nodate],

  image("../figure/pipeline-schema.png", width: 90%)
) <fig_img_pipeline-schema>

In @fig_img_pipeline-schema, (A) shows the execution timeline of the `func` function without the pipeline pragma where three clock cycles separate each loop (`II=3`).
Using the pragma, (B) shows that the clock cycles are now reduce to one (`II=1`).
To instruct the oneAPI DPC++/C++ Compiler to attempt loop pipelining, the flag `-Xsauto-pipeline` must be added at the compilation.
Another way to do it, is by using the `[[intel::initiation_interval(n)]]` attribute to instruct the compiler to attempt to set the initiation interval to `n`.

The dataflow pragma implements task-level pipelining by enabling functions and loops to execute concurrently.
Thereby increasing the parallelism in the RTL implementation and boosting overall design throughput.

#figure(
  caption: [Example code for the dataflow pragma @noauthor_introduction_nodate],

```cpp
void top(a, b, c, d) {
  for (i = 2; i >= 0; i--) {
    func_A(a, b, i1);
    func_B(c, i1, i2);
    func_C(d, i2);
  }
}
```
) <fig_code_dataflow-pragma>

#figure(
  caption: [Schema of an Example Code being Executed With and Without the dataflow Pragma @noauthor_introduction_nodate],

  image("../figure/dataflow-schema.png", width: 90%)
) <fig_img_dataflow-schema>

The @fig_img_dataflow-schema shows the difference between the execution of @fig_code_dataflow-pragma with (B) and without (A) the dataflow pragma.
When the dataflow pragma is applied, the HLS tool examines the flow of data between sequential functions or loops and introduces channels (implemented with ping-pong RAMs or FIFOs).
These channels enable consumer functions or loops to begin execution before the corresponding producer functions or loops have fully completed.
Here it save up to three clock cycles per loop.
It's important to note that the data dependencies between functions can limit this optimization.
For instance, if `func_B` requires the output from `func_A`, `func_B` cannot begin execution until `func_A` has completed, introducing a two-clock-cycle delay per loop iteration.
This mechanism creates latency between functions but ensures that functions or loops only access data after it has been properly processed.

To take advantage of this pragma with the oneAPI DPC++/C++ Compiler, it is not a matter of simply adding a flag or a `#pragma` before a loop, but rather of designing the code in a way that avoids unnecessary data transfers.
The use of memory buffers/accessors also helps in this regard, as they provide automated and optimized memory access.

