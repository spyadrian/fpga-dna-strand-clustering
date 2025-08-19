#import "../conf.typ": *

= Results and Performance


== DNA Tag Matcher

The tests were conducted on two main aspects: the accuracy of the algorithm and its speed.
They were performed on a dataset of $897'249$ reference tags.
To simulate the tags obtained from DNA sequencing, $100,000$ tags were generated from these references.
These simulated tags were then subjected to $2%$ insertions, $4%$ deletions, and $4%$ substitutions.

The total theoretical number of comparisons to perform amounts to $879'249'000'000$ (almost $9 times 10^11$).
In practice, however, this number is lower, thanks to optimizations added to the algorithm, such as early-stopping.

=== Precision

A good way to measure the accuracy of an algorithm is to use a confusion matrix.
This matrix shows the number of True Positives (TP), False Positives (FP), True Negatives (TN), and False Negatives (FN).
In our context, they represent the following:

- True Positive (TP): A pair correctly predicted
- False Positive (FP): A pair incorrectly predicted
- False Negative (FN): A pair with no prediction
- True Negative (TN): A pair absent from both the predicted and the expected results

In practice, within this context, it is rare to encounter FNs or TNs.
FNs may occur when none of the tag-to-reference comparisons result in a Levenshtein distance below `MAX_LEVENSHTEIN_DISTANCE`.
TNs are even rarer, as they correspond to pairs completely missing from both the predictions and the expected results.
In such cases, it is more relevant to focus primarily on TP and FP.

To obtain a more balanced indicator of performance, it is common to use derived metrics.
Precision is the proportion of correctly identified pairs among all the predicted pairs.
#align(center)[$"Precision" = "TP"/("TP" + "FP")$]
Recall is the model’s ability to retrieve all the relevant pairs present in the expected results.
#align(center)[$"Recall" = "TP"/("TP" + "FN")$]
The F1-score is the harmonic mean of precision and recall, useful when seeking a trade-off between the two.
#align(center)[$"F1" = 2 times ("Precision" times "Recall")/("Precision" + "Recall")$]
The divers results are displayed in the table below.

#figure(
  caption: [DNA Matcher Dataflow],

  image("../figure/dna-matcher-precision-res.png", width: 90%),
)

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
Using the same dataset, the following chart illustrates the performance of the DNA Tag Matcher algorithm.

#figure(
  caption: [Average time per comparison of DNA Tag Matcher across CPU, GPU and FPGA],

  image("../figure/comparison-per-us.png", width: 90%),
)

The GPU significantly outperforms both the CPU and especially the FPGA for the task of DNA tag comparison, achieving each comparison about 6 times faster than the CPU and nearly 50 times faster than the FPGA.
In this context, the GPU demonstrates an extremely favorable performance-to-cost-to-time ratio.
The CPU remains a versatile solution, but it falls far short of the GPU’s efficiency for this kind of large-scale operation.

The FPGA result, however, is quite surprising.
This type of hardware, when combined with such algorithms, would normally be expected to deliver solid performance.
This outcome highlights a critical point: the FPGA implementation and hardware optimization are not yet properly refined.

=== FPGA Usage <chap_res-dna-tag-usage>

The report generated during the FPGA compilation of the DNA Tag Matcher algorithm provides various insights into the FPGA’s utilization.
The key pieces of information we are interested in are:
1. the utilization of FPGA resources
2. the memory access latency
3. the optimizations that may have been applied

#figure(
  caption: [],

  table(
    columns: (1fr, 2fr, 2fr, 2fr),
    align: (left, right, right, right),
    table.header([], align(center)[*Device*], align(center)[*Static Partition*], align(center)[*Kernel System*]),
    [*ALUTs*], [$1'825'600$], [$561'690$ ($31%$)], [$59'211$ ($3%$)],
    [*FFs*], [$5'568'080$], [$2'246'760$ ($40%$)], [$137'172$ ($2%$)],
    [*RAMs*], [$13'272$], [$3'500$ ($26%$)], [$973$ ($7%$)],
    [*MLABs*], [$45'640$], [$0$ ($0%$)], [$932$ ($1%$)],
  )
)

// guide FPGA Optimization Guide for Intel® oneAPI Toolkits + https://arxiv.org/pdf/2208.13364
The table above shows the resources utilized by the DNA Tag Matcher algorithm on the FPGA.
A rather surprising observation is that the available resources are never fully used.
The design only occupies a small portion of the total resources, which suggests that the algorithm is not well optimized for FPGA and that there is still room to increase parallelism or further improve pipelining.
It can also be observed that the number of compute units for the kernels is one.
This lack of parallelism may partly explain the resource utilization rate.

Unlike fixed architectures (CPU/GPU), FPGAs require specific manual optimizations that are not automatically performed by the compiler.
Generally, manual interventions like pragmas or other attributes are needed to guide the compiler.
Furthermore, contextual analysis by the compiler is limited.
It cannot always determine the best optimization strategies for a given algorithm, nor balance the trade-offs between latency, throughput, power consumption, and resource utilization.
These trade-offs also require manual tuning.

It should also be noted that the Intel oneAPI DPC++ compiler tends to adopt a conservative approach.
It prioritizes stability, favoring a design that reliably works over one that might be faster but less reliable.
In addition, the compiler may sometimes infer false loop-carried dependencies, leading it to serialize certain operations unnecessarily.

#figure(
  caption: [],

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
)

This table illustrates the efficiency of some of the main loops in the DNA Tag Matcher implementation.
It originally also included all the loops for which the `#pragma unroll` directive was used.
These loops were all correctly unrolled and optimized without latency.
Since they are too numerous, they do not appear in this version of the table.

Except for the initialization loops, all the loops shown in this table exhibit very high latency.
This latency is primarily explained by their dependence on the FPGA’s external Global Memory, namely, the DDR connected through the AXI controller.
Each memory access (“Global Memory Load”) requires a full round trip to the DDR, including burst phases and the serialization/deserialization of data.
This typically results in several cycles of delay.
Moreover, given the implementation of the algorithm and the absence of explicit grouping directives, these loops generate scattered memory accesses rather than optimized bursts, further worsening the latency.

Regarding clock frequency, all elements operate at the same $480"MHz"$, indicating that none of the loops constitute a bottleneck in terms of frequency.
In fact, since the final kernel clock is set at $400"MHz"$, we can see that all loops could theoretically go beyond this frequency, meaning that the actual bottleneck lies elsewhere.


== OneJoin

Like DNA Tag Matcher, OneJoin was evaluated for its accuracy and speed.
These metrics were already tested in the paper #emph[OneJoin: Cross-Architecture, Scalable Edit Similarity Join for DNA Data Storage Using oneAPI], but it is important to validate them again on the project’s data.

Ideally, this algorithm would have been tested on a dataset of $65'000$ entries, since the project’s pipeline, using DNA Tag Matcher, initially divides the inputs into groups of $65'000$.
Unfortunately, as highlighted in @cha_algo-onejoin, this was not possible.
Instead, a dataset of $7'500$ entries was used.
@fig_tab-dataset-param lists all the parameters of this dataset.

=== Accuracy

To analyze the accuracy of OneJoin, it was necessary first to evaluate the algorithm’s output and adjust its parameters accordingly.
Below is a summary of the most important parameter values that were finally selected.

#figure(
  caption: [],

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
)

OneJoin is divided into three main stages: Embedding, LSH, and Verification.
At each of these stages, the number of input DNA strands changes.
It is therefore interesting to observe how this number evolves depending on the chosen input parameters.

The number of DNA strands is equal to $7'500$.
These originally came from $250$ DNA strands containing data, each duplicated $30$ times and subsequently modified with a $10%$ error rate.
At the end of OneJoin, the goal is to obtain enough pairs to reconstruct the $250$ groups corresponding to the original strands.

During the Embedding stage, the input strands are transformed into encoded sequences that can then be processed by LSH.
The total number generated at this stage is calculated as: $"number of inputs" times "NUM_STR" times "K_INPUT" / "SHIFT"$, which in our case give:

#align(center)[$7'500 times 24 times 3 = 540000$]

After applying LSH and a preliminary filtering, $1'522'811$ buckets were generated.
From these buckets, $23'025$ final pairs were obtained.

By combining these pairs with the input DNA strands, it is possible to apply Density-Based Spatial Clustering of Applications with Noise (DBSCAN).
DBSCAN is an algorithm that, building a graph where the pairs are represented as nodes, create clusters formed based on the proximity of the inputs.
After applying DBSCAN, exactly $250$ groups were successfully identified.
Since this procedure was repeated across multiple datasets of 7,500 inputs, these results confirm the accuracy of OneJoin.

=== Speed

On our dataset, the average runtime of this algorithm on CPU, GPU, and FPGA is about $3.5$ seconds.
However, this measure is not very relevant to the objectives of this project.
In our case, it is more meaningful to compare the execution speed of the parallelized part, in order to obtain a better comparison of device utilization, here, the bucket generation.

#figure(
  caption: [Time to compute the parallel buckets generation across CPU, GPU and FPGA],

  image("../figure/time-buckets-generation.png", width: 90%),
)

On our dataset, the CPU generates the buckets in $0.598$ seconds, outperforming the GPU, which takes $0.874$ seconds.
The FPGA, however, is noticeably slower, with a runtime of $3.743$ seconds.

The CPU proves to be the fastest for this specific task.
This result may seem surprising, since one would usually expect a GPU or an FPGA to outperform the CPU on parallelized tasks.
It suggests that, in our implementation and for this type of data, bucket generation leverages the CPU architecture more effectively than that of the GPU or FPGA.
This difference may come from either the code optimization or the intrinsic architectural characteristics of the devices.

=== FPGA Usage

In the same way as for DNA Tag Matcher, this section examines FPGA resource usage, latency, and the application of optimizations.
Both sections share many common aspects, including the explanation of the results, which will therefore not be repeated here.

#figure(
  caption: [],

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
  caption: [],

  table(
    columns: 4,
    align: (left, left, right, right),
    table.header(align(center)[*Loop Description*], align(center)[*Pipelined*], align(center)[*fMAX (MHz)*], align(center)[*Latency*]),

    [(line 96)], [No], [480.00], [1618],
  )
)

The generation part contains only one loop, in this case, it could not be optimized.
As with DNA Tag Matcher, the latency observed is due to inefficient memory access management, specifically at the DDR level.
The latency of 1618 cycles occurs because there are two memory accesses of approximately 800 clock cycles each, with one depending on the other.

// https://elib.uni-stuttgart.de/server/api/core/bitstreams/e2ff588a-6336-4f43-be8a-5243c10bfff5/content
The OneJoin code was designed with two types of devices in mind: CPUs and GPUs.
It was not originally intended to be used with FPGAs, which require particular attention to memory accesses as well as optimization strategies.
It has been shown that SYCL code optimized for one platform often performs poorly on different architectures.
As noted by Franquinet (2023) in his analysis of SYCL performance portability : “As a result, the performance of the FPGA is not as good as on the CPU and GPU.”
This highlights the low level of performance portability and underlines the need for architecture-specific optimizations.

// https://arxiv.org/pdf/2208.13364
The performance portability challenges between GPUs and FPGAs stem from their different optimization strategies.
First, while both architectures support multiple forms of parallelism, they emphasize different approaches.
FPGAs excel at deep pipelining and spatial parallelism through custom hardware layouts, whereas GPUs prioritize massively parallel SIMT execution with thousands of concurrent threads.
Second, memory bandwidth and access patterns differ significantly.
Current FPGA boards typically offer lower off-chip bandwidth but provide flexible, custom memory hierarchies, while GPUs offer high bandwidth optimized for regular access patterns.
Third, synchronization mechanisms have different performance characteristics.
While GPUs handle synchronization primitives efficiently through dedicated hardware, FPGAs may require custom synchronization logic that can introduce stalls, though modern implementations provide optimized solutions.

== Proposed Improvements

The low resource utilization and high latencies observed in the main loops indicate that the current designs do not efficiently exploit the capabilities of FPGA hardware.
This section proposes targeted optimization strategies based on Intel oneAPI best practices.
These could not be implemented within the scope of this project due to limited availability of resources.

=== Memory Access Optimizations

The observed latencies (802–1618 cycles) are primarily caused by inefficient accesses to the external DDR memory.
As suggested in the #emph[FPGA Optimization Guide for Intel oneAPI Toolkits], restructuring memory access patterns to favor contiguous rather than scattered accesses would reduce the design’s latency.
Another approach would be to leverage local memory.
Moving critical data from DDR to on-chip memory using local buffers avoids the performance penalty of slow memory transactions.
This method can reduce access latency by several orders of magnitude.

=== Improving the Initiation Interval (II)

Non-pipelined loops represent the main bottleneck.
To reduce the II, one effective technique is to eliminate false dependencies.
The attribute `[[intel::ivdep]]` can be used to instruct the compiler to ignore unnecessary dependencies between loop iterations, thereby enforcing pipelining.

=== Resource Utilization

Given the currently low utilization of FPGA resources, an obvious strategy would be to replicate the Myers compute unit to process multiple sequences in parallel, thus exploiting a greater share of the FPGA’s available resources.
In this way, several instances of the main kernel could be executed concurrently, each handling a different portion of the input data.

