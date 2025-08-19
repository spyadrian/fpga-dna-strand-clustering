#import "../conf.typ": *

= Conclusions and Perspectives

#todo[données des chiffres]

This work explores FPGA-based hardware acceleration for the implementation of Levenshtein distance, applied to the clustering of DNA strands within the DNAMIC project.
We emphasize the use of tools such as SYCL, which enables efficient execution across a wide range of hardware platforms, including CPUs, GPUs, and FPGAs, without requiring platform-specific code modifications.
Two approaches were studied and implemented: OneJoin and DNA Tag Matcher.

OneJoin relies on a preprocessing stage using CGK embedding and Locality-Sensitive Hashing (LSH) to reduce the number of comparisons.
In addition to accelerating the clustering of DNA strands, this algorithm achieves full cluster coverage on medium-sized datasets.

Despite OneJoin’s speed, the DNA Tag Matcher was designed to perform a pre-clustering step based on fixed-length tags found within DNA strands.
This pre-clustering stage groups sequences before applying OneJoin to them.
By feeding OneJoin with smaller subsets of data, its execution speed is significantly improved.
Despite the insertions, deletions, and substitutions occurring in DNA sequences, this module achieves a recall of 99% with a precision of 88.6%.

Experimental results showed that the GPU remains the best performer for massive editing distance processing.
The FPGA approach offers low speed, among other things because of the significant latency due to memory access and the moderate use of FPGA resources.

Experimental results showed that, although the GPU remains the most efficient device for large-scale edit distance computation, the FPGA approach yields lower performance.
This is mainly due to significant memory access latencies and the relatively low level of FPGA resource utilization.

SYCL provides an important abstraction that simplifies development across heterogeneous architectures: the same C++ codebase can target CPUs, GPUs, or FPGAs interchangeably.
This “marketing promise” of code portability drastically reduces development complexity and time, as there is no need to maintain multiple codebases or master different languages (such as VHDL/Verilog, CUDA, or OpenCL).
However, in practice, code portability does not guarantee performance portability.
Without explicit optimizations and directives (such as pragmas, pipelining, dataflow, and others), FPGA kernels compiled from a generic SYCL codebase perform far below expectations.
In other words, “performance is portable, not the code”: while it is easy to port a codebase onto FPGA, fully exploiting its computational potential requires profiling and architecture-specific tuning.
This was precisely the case encountered in this project.

Several areas for improvement were identified to unlock the full potential of FPGA acceleration.
Most critically, memory access should be optimized by grouping transfers to DDR, thereby significantly reducing off-chip access latency.
Another key strategy is reducing the initiation interval (II) of critical loops by adding compilation directive, enabling more effective pipelining than what is achieved through compiler pragmas alone.
Furthermore, replicating the compute units of the core algorithms would increase throughput by allowing multiple kernel instances to run concurrently.

In conclusion, SYCL enables a unified implementation of Levenshtein distance across CPU, GPU, and FPGA, achieving a recall of 99% with OneJoin and DNA Tag Matcher.
While the GPU remains better for massive computing, the FPGA architecture offers significant potential if it is well optimized (memory access, pipelining, core duplication) to reduce latencies and increase the use of hardware resources.

