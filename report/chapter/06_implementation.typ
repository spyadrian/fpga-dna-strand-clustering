#import "../conf.typ": *

= Implementation Details


== Tag Matcher

=== Dataflow and Parallelisation

The Tag Matcher algorithm is divided into four stages: decoding references (intact tags) and computing $P\eq$, decoding queries, computing Myers' algorithm, and collecting results.
These stages are organized to achieve the most optimal dataflow possible and to minimize data transfers between the device and the host.

In general, dataflow refers to a pragma that can be requested from the compiler.
For example, on AMD platforms this is achieved with `#pragma HLS dataflow`, placed at the beginning of a function that one wishes to optimize.
In DPC++, however, this is not the case: memory accesses via buffers and accessors automatically handle this optimization.
Nevertheless, this does not affect the logic of the code itself, which is why it is necessary to design the implementation with the goal of achieving the most efficient dataflow possible.

@fig_img_dna-matcher-dataflow lists the stages together with their respective dataflow:

#figure(
  caption: [Tag Matcher Dataflow],

  image("../figure/dna-matcher-dataflow.png", width: 100%),
) <fig_img_dna-matcher-dataflow>

In this dataflow, the data arrives in a compressed form using the encoding described in @chap_imp-myers-algorithm and is stored sequentially in a one-dimensional array.

The first stage performs two tasks: decoding the references and computing their corresponding Peq matrices.
- Decoding is the process of extracting and isolating the references from the one-dimensional array.
- Precomputing the $"Peq"$ matrices makes the subsequent stages more efficient. In Myers’ algorithm, the first string is reused in every iteration of the main loop, but this is not the case for the second string,in our case, the references. Instead, the references are only required during the creation of the $"Peq"$ table, which can therefore be precompiled before the main loop begins.

In our implementation, all references are sent once in order to compute their $"Peq"$ matrices.
These matrices are then reused in the following stages, such as during the comparison step.
This approach reduces data transfers, optimizes device memory usage, and avoids recomputing $"Peq"$ matrices multiple times, since only these precomputed matrices are kept in device memory.

The second stage, similarly to the first one with references, extracts the tags from the one-dimensional array to prepare them for the next step.
Once a tag is extracted, it is stored in cache, as it will be heavily used during the Levenshtein distance computation stage.
This caching accelerates subsequent accesses to the tag.

The third stage performs the computation of the Levenshtein distance using Myers’ bit-parallel algorithm.
This stage benefits from several optimizations, and its implementation is detailed later in @chap_imp-myers-algorithm.

The final stage processes the results obtained from the Levenshtein distance computation.
It checks whether the computed distance falls within the required thresholds.
This stage is discussed in more detail in @chap_imp-levenshtein-dist.

It should be noted that all these stages are executed on the device.
Specifically, the first stage is dispatched to the device using a `single_task`, while the remaining stages are dispatched using `parallel_for`.

=== The Myers' Bit-parallel Algorithm <chap_imp-myers-algorithm>

During the semester project, a C++ implementation of Myers’ algorithm was used.
This implementation was developed by Fujimoto Seiji, author of #emph[Polyleven], a Python library designed to compute the Levenshtein distance.
In his 2020 study, Fujimoto implemented both the Myers and Wagner–Fischer algorithms in order to compare them.
We reused his open-source implementation and adapted it to make it compatible with DPC++.
Please note that the website is currently down.

The DNA alphabet, and therefore the tags, is composed of the nucleotides $A$, $C$, $G$, and $T$.
To transfer this alphabet efficiently to the target device, it was preferable to create a dedicated encoding instead of directly passing characters of type `char`.
Since there are four possible values, the encoding can be represented on two bits, as follows:

#figure(
  caption: [Binary encoding of nucleotides for device processing],

  table(
    columns: (auto, auto),
    align: (center, center),
    inset: (x: 1em),
    table.header([*Nucleotide*], [*Encoding*]),

    [A], [$00$],
    [T], [$01$],
    [G], [$10$],
    [C], [$11$],
  )
)

This encoding is managed by the `DNAEncoding` class, which allows on-the-fly encoding and decoding of tags.

Tags are made up of $27$ nucleotides.
With this encoding, the bit length of a tag is $54$ bits.
A tag can therefore be stored and manipulated in a `uint64_t`, which is natively available in C++.
However, when DNA strands undergo mutations, there are cases where a tag may extend to more than $32$ nucleotides.
In this case, the encoding leads to an overflow of the `uint64_t` variable.

To address this issue, the `DNABitVector128` class was implemented.
This class relies on an array of two `uint64_t` values in order to store an entire tag in case of overflow.
To make the Myers algorithm compatible with this class, all the operations required by the algorithm had to be reimplemented.
Below is an example showing the overwritten bitwise OR operator:

#figure(
  caption: [Binary encoding of nucleotides for device processing],

  ```cpp
DNABitVector128 operator|(const DNABitVector128& other) const {
    DNABitVector128 result;

    #pragma unroll
    for (int i = 0; i < NUM_WORDS; i++) {
        result.words[i] = words[i] | other.words[i];
    }

    return result;
}
  ```
) <fig_overwritten-or>

=== Levenshtein Distance Consideration <chap_imp-levenshtein-dist>

During the comparisons between input tags and reference tags, an early-stopping mechanism was implemented.
When a comparison returns a Levenshtein distance lower than the threshold defined by the constant `MIN_LEVENSHTEIN_DISTANCE`, the tag is considered to have found its corresponding reference.
At this point, the algorithm stops checking the remaining references for that tag and proceeds to the next one.
This slightly speeds up the execution.

On the other hand, `MAX_LEVENSHTEIN_DISTANCE` is a constant that defines whether a Levenshtein distance is small enough to be considered valid.
In other words, if a tag is too distant (greater than `MAX_LEVENSHTEIN_DISTANCE`) from all references, it will not be assigned any reference.
As a consequence, the algorithm may drop tags that have undergone too many mutations.

A tag may sometimes be equidistant from several references.
In such cases, all these references are taken into account, creating multiple tag–reference pairs.
This ensures that the correct tag–reference pair is generated.
However, it also produces additional false pairs, which increases the number of wrong output pairs and thereby slightly decreases the precision of the algorithm.
This is not problematic, since these false pairs are removed in the subsequent processing steps.

=== FPGA Optimization

During the implementation of Tag Matcher, several optimizations were introduced for a FPGA device.
The two most important optimizations are the use of pragmas, to fully exploit the high parallelism offered by FPGAs.

In addition to the previously discussed dataflow, two pragmas were added in this implementation: unroll and pipeline.
The unroll pragma was applied to expand loops, such as those used in the DNAEncoding class.
An example of the use of `#pragma unroll` is shown in @fig_overwritten-or.

The pipeline pragma is very useful for reducing the latency of certain loops, as well as for optimizing hardware utilization.
By enabling pipelining on Non-task Kernels (parallel_for) using the -Xsauto-pipeline flag, several loops were successfully pipelined.
Those are listed in @chap_res-dna-tag-usage.


== OneJoin

=== oneoligo-a7sk

The OneJoin algorithm is available on GitHub under the repository name #emph[oneoligo], with two contributors: #emph[Eug9] and #emph[raja-appuswamy], who are respectively the authors of the paper, #emph[Eugenio Marinelli] and #emph[Raja Appuswamy] @marinelli_eug9oneoligo_2025.
This implementation served as the basis for our project.
However, some modifications were necessary.

Since running on an FPGA requires ahead-of-time (AOT) compilation, certain parts of the code needed to be adapted.
For example, the device selectors used for the queues or the Makefile had to be adjusted to properly target the chosen device during compilation.
At first, this was handled with a simple patch that could be applied directly to the existing code.

#figure(
  caption: [Code enabling selection of the appropriate queue],

  ```cpp
#if defined(FPGA_SIMULATOR)
  using DeviceSelector = sycl::ext::intel::fpga_simulator_selector;
#elif defined(FPGA_HARDWARE)
  using DeviceSelector = sycl::ext::intel::fpga_selector;
#else // if defined(FPGA_EMULATOR)
  using DeviceSelector = sycl::ext::intel::fpga_emulator_selector;
#endif
  ```
)

Another issue arose from the fact that the original implementation of #emph[oneoligo] grouped all the accelerated kernels together in the same source file, making it difficult to compile simultaneously for both CPU and FPGA.
To enable this, one of the stages of OneJoin, included in a kernel, was extracted from the main file and placed in an external file.
This allowed it to be compiled with FPGA-specific flags instead of CPU compilation flags.

Along with other FPGA related adaptations, this represented a significant enough change to justify creating a dedicated fork of #emph[oneoligo], named #emph[oneoligo-a7sk].
This fork enabled the development of a hybrid CPU–FPGA architecture, and is included as a sub-module within the GitLab repository of this project.

=== Parallelized Part

// onejoin.pdf
The part we decided to extract and parallelize was the kernel responsible for creating the buckets, namely the `create_buckets` function.
The main reason this part was chosen is that, within the OneJoin pipeline, LSH bucketing constitutes one of the main bottlenecks in the filtering phase.
Indeed, in OneJoin, the combination of the Embedding and LSH steps accounts for more than $90%$ of the total execution time, with LSH bucketing being the most computationally expensive component of the filtering process.

The `create_buckets` function iterates in parallel over each triplet (batch, string index, replication index) and each LSH hash function to transform the sampled positions of the “embedded” sequence into a bucket identifier.
For each element, it stores the tuple (replication index, hash function index, bucket ID, string index, replication index).
Each kernel instance performs exactly the same operations, without any dependencies between them.
It is therefore an ideal function to measure and demonstrate the impact of parallelism.

