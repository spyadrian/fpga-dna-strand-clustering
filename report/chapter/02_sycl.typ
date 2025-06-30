#import "../conf.typ": *

= High-Level Synthesis for Cross-Architecture Programming

#todo[why better for DNAMIC + context + yareta]

SYCL (pronounced “sickle”) is an open standard developed by the Khronos Group for programming heterogeneous architectures using standard C++. It provides a single-source programming model, allowing both host and device code to be written in the same file. SYCL is designed to enable efficient execution on a wide range of hardware, including CPUs, GPUs, and FPGAs, without requiring platform-specific code changes.

SYCL works by expressing parallelism through kernels, which are functions executed on the device (such as a GPU or FPGA). The runtime manages data transfer between host and device, as well as the scheduling of kernels. SYCL uses modern C++ features, such as templates and lambdas, to define kernels and data management abstractions (buffers and accessors). The programmer writes a single codebase, and SYCL ensures that the appropriate hardware is targeted at runtime, depending on the available devices and the configuration.

#sourced_figure(
  source: link("https://www.khronos.org/blog/sycl-the-dawn-of-a-unified-programming-model-for-heterogeneous-modern-c-at-sc19", [from khronos.org, ref. URL05]),
  fig : figure(
    caption: [SYCL Implementations Provide Access to Diverse Processors Through Standard C++],

    image("../figure/sycl-provide-access-to-diverse-processors.jpg")
  )
)

== Advantages of SYCL for FPGA Acceleration

SYCL offers significant benefits for developers seeking to leverage FPGA acceleration in their applications.
One of the primary advantages is hardware abstraction: SYCL enables the writing of code that can be efficiently compiled for FPGA using High-Level Synthesis (HLS) tools, eliminating the need for FPGA-specific programming.
This abstraction simplifies the development process and broadens the accessibility of FPGA technology.
Notably, SYCL is based on C++, making it much easier for software developers to target FPGAs without having to learn traditional hardware description languages (HDLs) such as VHDL or Verilog.
This lowers the entry barrier and accelerates the adoption of FPGA acceleration, especially for those with a software background.

Another key benefit is performance portability.
With SYCL, it is possible to target specific kernels for FPGA execution while running other parts of an application on CPU or GPU.
This flexibility allows developers to optimize for both performance and energy efficiency, depending on the requirements of individual computational tasks.

SYCL’s single-source approach further simplifies development.
Developers can experiment with FPGA acceleration without the need to rewrite their entire codebase, making it easier to integrate FPGA into existing pipelines.
This approach streamlines the adoption of FPGA technology and reduces development overhead, something that was searched by the DNAMIC engineers.


== Parrallel For

A key feature of SYCL for enabling efficient parallel processing on heterogeneous hardware such as FPGA, CPU, and GPU is the `parallel_for` construct.
This construct allows developers to express data-parallel computations in a straightforward manner, where the same kernel function is executed concurrently over a range of data elements.
In the context of DNA sequence analysis or similarity joins, `parallel_for` enables the simultaneous processing of multiple sequences or sequence segments, significantly increasing throughput and reducing overall execution time.

When targeting FPGA with SYCL, the `parallel_for` construct is mapped to hardware pipelines by the High-Level Synthesis (HLS) tools.
This mapping allows FPGA resources to be used efficiently, exploiting spatial parallelism where independent operations are performed simultaneously on different data streams.
Additionally, SYCL’s memory management features, such as buffers and accessors, ensure that data is automatically transferred between host and device memory, further simplifying the integration of `parallel_for` into complex pipelines.

Here’s a simple example using SYCL’s `parallel_for` to perform a basic operation—adding a constant value to each element of an array.
This example uses a SYCL queue and buffer to illustrate how you might write a kernel that runs in parallel on a device (CPU, GPU, or FPGA).

#figure(
  caption: [SYCL `parallel_for` example: array element addition],

```cpp
#include <CL/sycl.hpp>
#include <iostream>

int main() {
    // Data
    constexpr int N = 10;
    int data[N] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    int add = 5;

    // SYCL queue and buffer
    sycl::queue q;
    sycl::buffer<int, 1> data_buf(data, sycl::range<1>(N));

    // Submit work to the queue
    q.submit([&](sycl::handler& h) {
        auto acc = data_buf.get_access<sycl::access::mode::read_write>(h);
        h.parallel_for<class add_kernel>(sycl::range<1>(N), [=](sycl::id<1> idx) {
            acc[idx] += add;
        });
    });

    return 0;
}
```
) <fig_code_sycl-parallel_for>


== Shared Memory

Memory management is essential for accelerating applications on FPGA and other heterogeneous hardware.
SYCL simplifies this by providing high-level abstractions for data movement and access, allowing data to be transferred efficiently between the CPU and FPGA without requiring low-level code from the developer.

SYCL’s buffer and accessor model enables seamless data sharing between host and device.
Buffers manage data on the host, and the SYCL runtime automatically handles transfers to and from the device.
When a kernel is launched, entire runtime ensures all required data is available on the device and synchronizes results back to the host.
An example can be found in the @fig_code_sycl-parallel_for above.

