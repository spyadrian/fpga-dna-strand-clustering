#import "../conf.typ": *

= Results and Performance


== Hardware Used

The tests were carried out using three different devices: a CPU, a GPU, and an FPGA.
The #emph[CPU is an Intel(R) Core(TM) i7-1065G7 CPU \@ 1.30GHz] with an x86_64 architecture.
It includes 8 threads distributed across 4 physical cores (2 threads per core).
Its base frequency is 1.30 GHz, with a maximum frequency of up to 3.9 GHz.

The GPU is an #emph[NVIDIA GeForce GTX 1660 Ti Mobile].
It comes with 6 GB of dedicated video memory.
This GPU is designed for 3D graphics tasks as well as for parallel computations using CUDA.
It is intended for use in a mobile environment.

The FPGA has already been presented in @chap_fpga-hardware.


== Tag Matcher

The tests were conducted on two main aspects: the accuracy of the algorithm and its speed.
They were performed on a dataset of $897'249$ reference tags.
To simulate the tags obtained from DNA sequencing, $100'000$ tags were generated from these references.
These simulated tags were then subjected to $2%$ insertions, $4%$ deletions, and $4%$ substitutions.

The total theoretical number of comparisons to perform amounts to $879'249'000'000$ (almost $9 times 10^11$).
In practice, however, this number is lower, thanks to optimizations added to the algorithm, such as early-stopping.

=== Precision

A good way to measure the accuracy of an algorithm is to make a confusion matrix.
This matrix shows the number of True Positives (TP), False Positives (FP), True Negatives (TN), and False Negatives (FN).

Within this context, it is rare to encounter FNs and impossible to encounter TNs.
FNs may occur when none of the tag-to-reference comparisons result in a Levenshtein distance below `MAX_LEVENSHTEIN_DISTANCE`.
However, the way tags are generated, combined with the chosen value of `MAX_LEVENSHTEIN_DISTANCE`, makes such cases impossible.
Therefore, it is more relevant to focus primarily on TPs and FPs, which can be regarded as correct predictions and incorrect predictions, respectively.
Those numbers are displayed in @fig_img_confusion-matrix.

#figure(
  caption: [Confusion matrix of the Tag Matcher algorithm],

  image("../figure/dna-matcher-precision-res.png", width: 90%),
) <fig_img_confusion-matrix>

To obtain a more balanced indicator of performance, it is common to use derived metrics.
Precision is the proportion of correctly identified pairs among all the predicted pairs.
#align(center)[$"Precision" = "TP"/("TP" + "FP")$]
Recall is the model’s ability to retrieve all the relevant pairs present in the expected results.
#align(center)[$"Recall" = "TP"/("TP" + "FN")$]
The F1-score is the harmonic mean of precision and recall, useful when seeking a trade-off between the two.
#align(center)[$"F1" = 2 times ("Precision" times "Recall")/("Precision" + "Recall")$]

Here, a precision of $0.8860$ means that $88.6%$ of the positive predictions are correct.
A recall of $1.0000$ ($100%$) indicates that the algorithm produced a prediction for every input, which can also be observed from the fact that there are no false negatives (FN).
An F1-score of $0.9396$ reflects a good balance between the high precision ($88.6%$) and the perfect recall ($100%$), demonstrating very strong overall performance.

It is also worth noting that with $100'000$ inputs, we end up with $111'391$ outputs.
This increase of $11'391$ outputs (approximately $11%$) is explained by the equidistant references discussed in @chap_imp-levenshtein-dist.
When a tag generates multiple outputs in this way, all but one of these outputs are false predictions, which then make up the majority of the false positives (FP).

Nevertheless, this approach still allows us to recover $98'733$ of the $100'000$ original tags.
This corresponds to nearly $99%$ tag recovery, which is a remarkable result.

=== Speed

Regarding the speed of the algorithm, three devices were tested and compared in order to highlight performance differences and determine which one offers the best average time per comparison.
Using the same dataset, the chart in @fig_img_comparison-per-us illustrates the performance of the Tag Matcher algorithm.

#figure(
  caption: [Average time per comparison of the Tag Matcher algorithm across three devices],

  image("../figure/comparison-per-us.png", width: 90%),
) <fig_img_comparison-per-us>

The GPU significantly outperforms both the CPU and especially the FPGA for the task of tag comparison, achieving each comparison about 6 times faster than the CPU and nearly 50 times faster than the FPGA.
In this context, the GPU demonstrates an extremely favorable performance-to-cost-to-time ratio.
The CPU remains a versatile solution, but it falls far short of the GPU’s efficiency for this kind of large-scale operation.

The FPGA result, however, is quite surprising.
This type of hardware, when combined with such algorithms, would normally be expected to deliver solid performance.
This outcome highlights a critical point: the FPGA implementation and hardware optimization are not yet properly refined.

=== FPGA Resource Usage <chap_res-dna-tag-usage>

The report generated during the FPGA compilation of the Tag Matcher algorithm provides various insights into the FPGA’s utilization.
The key metrics we are interested in are :
1. the utilization of FPGA resources
2. the memory access latency
3. the optimizations that may have been applied

#figure(
  caption: [Tag Matcher FPGA resource usage],

  table(
    columns: (1fr, 2fr, 2fr, 2fr),
    align: (left, right, right, right),
    table.header([], align(center)[*Device*], align(center)[*Static Partition*], align(center)[*Kernel System*]),

    [*ALUTs*], [$1'825'600$], [$561'690$ ($31%$)], [$59'211$ ($3%$)],
    [*FFs*], [$5'568'080$], [$2'246'760$ ($40%$)], [$137'172$ ($2%$)],
    [*RAMs*], [$13'272$], [$3'500$ ($26%$)], [$973$ ($7%$)],
    [*MLABs*], [$45'640$], [$0$ ($0%$)], [$932$ ($1%$)],
  )
) <fig_tab_tag-matcher-fpga-ressources>

@fig_tab_tag-matcher-fpga-ressources shows the resources utilized by the Tag Matcher algorithm on the FPGA.
A rather surprising observation is that the available resources are never fully used.
The design only occupies a small portion of the total resources, which suggests that the algorithm is not well optimized for FPGA and that there is still room to increase parallelism or further improve pipelining.
It can also be observed that the kernels use a single compute unit.
This lack of parallelism may partly explain the low resource utilization rate.

Unlike fixed architectures (CPU/GPU), FPGAs require specific manual optimizations that are not automatically performed by the compiler.
Generally, manual interventions like pragmas or other attributes are needed to guide the compiler @noauthor_fpga_nodate.
Furthermore, contextual analysis by the compiler is limited.
It cannot always determine the best optimization strategies for a given algorithm, nor balance the trade-offs between latency, throughput, power consumption, and resource utilization @liang_using_2024.
These trade-offs also require manual tuning.

It should also be noted that the Intel oneAPI DPC++ compiler tends to adopt a conservative approach.
It prioritizes stability, favoring a design that reliably works over one that might be faster but less reliable.
In addition, the compiler may sometimes infer false loop-carried dependencies, leading to unnecessary serialization of certain operations.

#figure(
  caption: [Tag Matcher loops details],

  table(
    columns: 4,
    align: (left, left, right, right),
    table.header(align(center)[*Loop Description*], align(center)[*Pipelined*], align(center)[*fMAX (MHz)*], align(center)[*Latency*]),

    [Decoding Queries (line 499)], [No], [480.00], [802],
    [Initialisation of the best match indices (line 355)], [No], [480.00], [13],
    [Myers main loop (line 531)], [No], [480.00], [871],
    [Loop to decode references (line 434)], [Yes], [480.00], [804],
    [Initialisation of `Peq` (line 440)], [Yes], [480.00], [19],
    [Construction of `Peq` (line 462)], [Yes], [480.00], [818]
  )
) <fig_tab_tag-matcher-loops>

@fig_tab_tag-matcher-loops illustrates the efficiency of some of the main loops in the Tag Matcher implementation.
It originally also included all the loops for which the `#pragma unroll` directive was used.
These loops were all correctly unrolled and optimized without latency.
Since they are too numerous, they do not appear in this version of the table.

Except for the initialization loops, all the loops shown in @fig_tab_tag-matcher-loops exhibit very high latency.
This latency is primarily explained by their dependence on the FPGA’s external global memory, namely, the DDR connected through the AXI controller.
Each memory access (“Global Memory Load”) requires a full round trip to the DDR, including burst phases and the serialization/deserialization of data.
This typically results in several cycles of delay.
Moreover, given the implementation of the algorithm and the absence of explicit grouping directives, these loops generate scattered memory accesses rather than optimized bursts, further worsening the latency.

Regarding clock frequency, all elements operate at the same $480"MHz"$, indicating that none of the loops were a frequency bottleneck.
In fact, since the final kernel clock is set at $400"MHz"$, all loops could theoretically go beyond this frequency, meaning that the actual bottleneck lies elsewhere.


== OneJoin

Like Tag Matcher, OneJoin was evaluated for its accuracy and speed.
These metrics were already tested in the paper #emph[OneJoin: Cross-Architecture, Scalable Edit Similarity Join for DNA Data Storage Using oneAPI], but it is important to validate them again on the project’s data.

Ideally, this algorithm would have been tested on a dataset of $65'280$ entries, since the project’s pipeline, using Tag Matcher, initially divides the inputs into groups of $65'280$.
Unfortunately, as highlighted in @cha_algo-onejoin, this was not possible.
Instead, a dataset of $7'500$ entries was used.
@fig_tab_dataset-params lists all the parameters of this dataset.

=== Accuracy

To analyze the accuracy of OneJoin, it was first necessary to evaluate the algorithm’s output and adjust its parameters accordingly.
@fig_tab_summary-important-parameters summarizes the most important parameter values that were finally selected.

#figure(
  caption: [Recall of the most important OneJoin parameters],

  table(
    columns: (auto, auto, auto),
    align: (left, center, left),
    table.header(align(center)[*Parameter*], align(center)[*Value*], align(center)[*Brief Description*]),

    [NUM_STR],  [24], [independent CGK embeddings per read],
    [NUM_HASH], [28], [hash functions (OR-construction) per embedding],
    [NUM_BITS], [11], [bits sampled inside each hash (AND-construction)],
    [K_INPUT],  [48], [edit-distance threshold passed to the verifier],
    [SHIFT],    [16], [edit-band stride used when slicing strings during embedding],
  )
) <fig_tab_summary-important-parameters>

To compute the accuracy of OneJoin, several datasets with the parameters presented in @fig_tab_dataset-params were generated.
The total number of DNA strands, equal to $7'500$, was obtained from $250$ original DNA strands, each duplicated $30$ times and subsequently modified with a $10%$ error rate.
To achieve full accuracy, the algorithm should be able to re-identify the $250$ groups corresponding to the original strands in each dataset.

In practice, this is exactly what was observed: OneJoin successfully recovered all $250$ groups corresponding to the original strands in every dataset.
Therefore, the algorithm achieved $100%$ accuracy.

=== Speed

On our dataset, the average runtime of this algorithm on CPU, GPU, and FPGA is approximately $3.5$ seconds.
However, this measure is not very relevant to the objectives of this project.
In our case, comparing the execution speed of the parallelized part (specifically, the bucket generation) provides a more informative basis for evaluating device utilization.

#figure(
  caption: [Execution time for parallel bucket generation across three devices],

  image("../figure/time-buckets-generation.png", width: 90%),
)

On our dataset, the CPU generates the buckets in $0.598$ seconds, outperforming the GPU, which takes $0.874$ seconds.
The FPGA, however, is noticeably slower, with a runtime of $3.743$ seconds.

The CPU proves to be the fastest for this specific task.
This result may seem surprising, since one would usually expect a GPU or an FPGA to outperform the CPU on parallelized tasks.
It suggests that, in our implementation and for this type of data, bucket generation leverages the CPU architecture more effectively than that of the GPU or FPGA.
This difference may come from either the code optimization or the intrinsic architectural characteristics of the devices.

=== FPGA Resource Usage

Similar to the Tag Matcher, this section examines FPGA resource usage, latency, and applied optimizations.
Both sections share many common aspects, including the explanation of the results, which are therefore not repeated here.

#figure(
  caption: [OneJoin FPGA resource usage],

  table(
    columns: (1fr, 2fr, 2fr, 2fr),
    align: (left, right, right, right),
    table.header([], align(center)[*Device*], align(center)[*Static Partition*], align(center)[*Kernel System*]),
    [*ALUTs*], [$1'825'600$], [$561'690$ ($31%$)], [$68'982$ ($4%$)],
    [*FFs*], [$5'568'080$], [$2'246'760$ ($40%$)], [$106'675$ ($2%$)],
    [*RAMs*], [$13'272$], [$3'500$ ($26%$)], [$538$ ($4%$)],
    [*MLABs*], [$45'640$], [$0$ ($0%$)], [$81$ ($<1%$)],
  )
)

Since the FPGA and the platform used for compiling both algorithms presented in this chapter are identical, it can be observed that the resources as well as for the static partition, are the same for both algorithms.
The resource usage by the kernels here is also very minimal.
The report further indicates that the number of compute units is one.

#figure(
  caption: [OneJoin loops details],

  table(
    columns: 4,
    align: (left, left, right, right),
    table.header(align(center)[*Loop Description*], align(center)[*Pipelined*], align(center)[*fMAX (MHz)*], align(center)[*Latency*]),

    [(line 96)], [No], [480.00], [1618],
  )
)

The generation stage contains only one loop, in this case, it could not be optimized.
As with the Tag Matcher algorithm, the latency observed is due to inefficient memory access management, specifically at the DDR level.
The latency of 1618 cycles occurs because there are two memory accesses of approximately 800 clock cycles each, with one depending on the other.

The OneJoin code was designed with two types of devices in mind: CPUs and GPUs.
It was not originally intended to be used with FPGAs, which require particular attention to memory accesses as well as optimization strategies.
It has been shown that SYCL code optimized for one platform often performs poorly on different architectures.
As noted by Franquinet (2023) in his analysis of SYCL performance portability : “As a result, the performance of the FPGA is not as good as on the CPU and GPU.” @franquinet_performance_nodate
This highlights the low level of performance portability and underlines the need for architecture-specific optimizations.

The performance portability challenges between GPUs and FPGAs stem from their different optimization strategies.
First, while both architectures support multiple forms of parallelism, they emphasize different approaches.
FPGAs excel at deep pipelining and spatial parallelism through custom hardware layouts, whereas GPUs prioritize massively parallel SIMT execution with thousands of concurrent threads.
Second, memory bandwidth and access patterns differ significantly.
Current FPGA boards typically offer lower off-chip bandwidth but provide flexible, custom memory hierarchies, while GPUs offer high bandwidth optimized for regular access patterns.
Third, synchronization mechanisms have different performance characteristics.
While GPUs handle synchronization primitives efficiently through dedicated hardware, FPGAs may require custom synchronization logic that can introduce stalls, though modern implementations provide optimized solutions @zarch_improving_nodate.

== Proposed Improvements

The low resource utilization and high latencies observed in the main loops indicate that the current designs do not efficiently exploit the capabilities of FPGA hardware.
This section proposes targeted optimization strategies based on Intel oneAPI best practices.
These could not be implemented within the scope of this project due to limited availability of resources.

=== Memory Access Optimisations

The observed latencies (802–1618 cycles) are primarily caused by inefficient accesses to the external DDR memory.
As suggested in the #emph[FPGA Optimization Guide for Intel oneAPI Toolkits], restructuring memory access patterns to favor contiguous rather than scattered accesses would reduce the design’s latency.
Another approach would be to leverage local memory.
Moving critical data from DDR to on-chip memory using local buffers avoids the performance penalty of slow memory transactions.
This method can reduce access latency by several orders of magnitude.

A model proposed in the paper #emph[Improving the Efficiency of OpenCL Kernels through Pipes] @zarch_improving_nodate suggests splitting the computation into two separate kernels: one dedicated to memory access and the other to computations.
To communicate, these two kernels would use pipes.
In the paper, this model leads to performance improvements, in some cases significant.
This could be a solution to the memory access problems.

=== Improving the Initiation Interval (II)

Non-pipelined loops represent the main bottleneck.
To reduce the II, one effective technique is to eliminate false dependencies.
The attribute `[[intel::ivdep]]` can be used to instruct the compiler to ignore unnecessary dependencies between loop iterations, thereby enforcing pipelining.

=== Resource Utilization

Given the currently low utilization of FPGA resources, an obvious strategy would be to replicate the Myers compute unit to process multiple sequences in parallel, thus exploiting a greater share of the FPGA’s available resources.
In this way, several instances of the main kernel could be executed concurrently, each handling a different portion of the input data.

