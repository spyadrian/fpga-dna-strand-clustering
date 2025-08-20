#import "../conf.typ": *

= Algorithms: How to Solve this Problem


== Original Thoughts

The first solution considered was to compare all the DNA sequences against each other.
To do this, Myers' algorithm would be used to obtain the Levenshtein distance.
If it was below a certain threshold, the two DNA strands being compared would be considered identical (from the same original strand).
This would group the copies together.

The problem with this approach is that, despite the speed of each comparison, it still requires performing $(n times (n-1))/2$ pairwise evaluations.
This is not scalable, because when working with a gigabyte of data, the number of DNA strands ($32$ bytes) explodes to $31$ million, leading to approximately  $5 times 10^14$ comparisons.

Let's say the algorithm runs at $200"Mhz"$, an average FPGA speed, and compute each comparison in $Omicron(n)$ using the Myers' algorithm.
If one comparison takes $250$ clock cycles, then processing all pairs would require around $10^17$ clock cycles.
It would take $7'233$ days or about $20$ years to compute all the comparisons.
Even with good parallelization, it would be very difficult to achieve a reasonable time.


== OneJoin <cha_algo-onejoin>

OneJoin is an edit similarity join algorithm designed to efficiently handle very large sets of sequences, such as DNA-encoded data.
Unlike traditional approaches, which rely on exact calculations of the Levenshtein distance between all pairs of sequences.
OneJoin relies on advanced embeddings and Locality Sensitive Hashing (LSH) techniques to drastically reduce the number of required comparisons.
Its goal is to find similar strands using the Hamming distance, and not the Levenshtein distance, in order to cluster them into buckets.
These buckets then contain DNA strands that are potentially close in terms of Levenshtein distance, thereby allowing comparisons to be performed on subsets (buckets) of the dataset.
OneJoin operates in three main stages: embedding, LSH, and the verification @marinelli_onejoin_nodate.

=== CGK Embedding

The appropriate edit distance for this context is the Levenshtein distance; however, its calculation is costly.
The Hamming distance only counts the number of substitutions, but unlike the Levenshtein distance, it is very efficient to compute.

The CGK embedding, developed by Chakraborty et al. @chakraborty_streaming_2016, is a method that transforms strings into a different metric space.
When applied to DNA sequence datasets, the algorithm takes as input a string of length $N$ composed of the four nucleotides $A$, $C$, $G$, and $T$.
The output of the CGK embedding is a new string three times longer, with length $3N$, containing the original nucleotide characters along with multiple occurrences of a special padding character $P$.

#figure(
  caption: [CGK embedding example],

  image("../figure/cgk-embedding-example.png", width: 75%),
)

At each step of the process, the algorithm appends either a character from the input string or the padding character to the output.
As a result, some input characters appear only once in the output, while others may be repeated randomly several times.
Using random walk theory, Chakraborty et al. demonstrated that the CGK embedding guarantees that the Hamming distance between the embedded strings is bounded by the square of the edit distance between the original strings.


=== Locality Sensitive Hashing (LSH)

An important benefit of edit-to-Hamming embedding is that algorithmic tools, like Locality Sensitive Hashing (LSH), well defined for Hamming, can now be used to identify similar strings without doing an exhaustive pairwise search @noauthor_locality_nodate.

Locality-Sensitive Hashing (LSH) for Hamming distance is a technique that efficiently groups similar strings by mapping them to the same “buckets”.
The technique relies on bit-sampling: specific bit positions are selected from each string to generate hash values.
In practice, this means that two strings with a low Hamming distance, meaning they differ in only a few positions, are more likely to be hashed into the same bucket.
For instance :

- Consider two 8-bit DNA sequences: $x = "ATCGATCG"$, $y = "ATCGATCA"$ (differs only in the last character).
- A hash function sampling bit position 7 would place both in the same bucket since bit 7 is 1 in both.

To balance precision and recall, LSH typically uses an AND-OR composition: the AND construction reduces false positives by requiring agreement on multiple sampled bits, while the OR construction reduces false negatives by considering multiple independent hashes.

The AND construction requires agreement on multiple sampled bits.
For example :

- Define a hash function $H_1(x) = ("bit"_3, "bit"_7)$.
- $x$ and $y$ collide only if they match at both positions.

The OR construction uses multiple independent hashes.
For example:

- Employ three hash tables: [g₁, g₂, g₃], each sampling different bits.
- Strings collide if they match in any table (g₁ OR g₂ OR g₃).

This approach allows scaling from $Omicron(N^2)$ to near-linear comparisons, as more than 90% of dissimilar pairs are efficiently filtered out before expensive edit-distance calculations are performed.
This synergy between embedding and LSH makes large-scale sequence analysis manageable.

#figure(
  caption: [LSH example with two DNA strands],

  image("../figure/lsh-schema.png", width: 95%),
) <fig_img_lsh-schema>

The @fig_img_lsh-schema shows how the LSH algorithm works.
An embedded DNA strand is hashed multiple times (AND) giving subsequences of the strand.
These subsequences are then compared to those from other strands, and if some of them are equal (OR), the algorithm identifies a match and places them in the same bucket.

=== EmbedJoin

EmbedJoin is a CPU-based, sequential algorithm designed for edit similarity joins that uses CGK embedding and locality-sensitive hashing (LSH) to minimize the number of expensive pairwise edit distance calculations.

==== Filtering

The filtering phase is the first and most computationally intensive stage of the algorithm.
It begins by sorting the input strings according to their lengths.
This step allows EmbedJoin to quickly eliminate unlikely candidate pairs by leveraging the fact that two strings with a significant length difference cannot be within the specified edit distance threshold.

Each input string is then embedded using the CGK embedding technique.
The embedded strings are subsequently hashed into buckets using Locality-Sensitive Hashing (LSH) for Hamming distance.
For each string, the algorithm checks all other strings in the same bucket.
If the length difference between the current string and a candidate is less than the edit threshold, the pair is added to a candidate list for further verification.
Otherwise, the candidate is removed from the bucket to optimize subsequent comparisons.
This process is repeated for all input strings, and duplicate pairs are eliminated to avoid redundant computations.

==== Verification

After the filtering phase, EmbedJoin has generated a candidate list of string pairs that are likely to be within the specified edit distance.
The verification phase then computes the exact edit distance for each candidate pair.
This step is much less computationally demanding than filtering, as the number of candidate pairs is typically only a small fraction of all possible pairs due to the effectiveness of the embedding and LSH-based filtering.

For each candidate pair, EmbedJoin employs a standard dynamic programming algorithm to compute the distance of Levenshtein.
If the computed distance is below the user-defined threshold, the pair is included in the final output buckets.
The verification phase is executed in a straightforward, sequential manner, with each thread or process handling a subset of the candidate list.


=== Parameters

OneJoin effectiveness depends heavily on several configurable parameters that influence key tradeoffs between performance, accuracy, and coverage.
@fig_tab_description-onejoin-parameters summarizes these parameters, their effects on critical metrics, and their default values from the OneJoin paper.

#figure(
  caption: [Description of the OneJoin algorithm parameters],

  table(
    columns: (auto, auto, auto),
    align: (center + horizon, center + horizon, left),
    table.header([*Parameter*], [*Symbol*], align(center)[*Brief description*]),
    [NUM\_STR], [$r$], [independent CGK embeddings per read],
    [NUM\_HASH], [$z$], [hash functions (OR-construction) per embedding],
    [NUM\_BITS], [$m$], [bits sampled inside each hash (AND-construction)],
    [NUM\_CHAR], [], [alphabet size of the dataset],
    [K\_INPUT], [$K$], [edit-distance threshold passed to the verifier],
    [SHIFT], [], [edit-band stride used when slicing strings during embedding],
    [NUM\_REP], [$⌈K/"SHIFT"⌉$], [replicated sub-strings embedded per read],
    [samplingrange], [$s$], [highest character position inspected by LSH; determines embedded length],
    [countfilter], [$c$], [min occurrences of the same candidate pair before verification],
    [batch\_size], [$B$], [reads processed together; limited by GPU / RAM]
  )
) <fig_tab_description-onejoin-parameters>

@fig_tab_impacts-onejoin-parameters shows their effects on critical metrics.
It serves as a reference for tailoring OneJoin to specific datasets, balancing speed and reliability according to application needs (e.g., large-scale DNA storage).

#figure(
  caption: [Impacts of parameters on algorithm performance and quality],

  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: center + horizon,
    table.header([*Parameter*], [*Speed impact*], [*Recall impact*], [*Precision impact*], [*False positives impact*], [*True positives impact*]),
    [NUM\_STR], [↑], [↑], [↓], [↑], [↑],
    [NUM\_HASH], [↑], [↑], [↓], [↑], [↑],
    [NUM\_BITS], [↑], [↓], [↑], [↓], [↓],
    [NUM\_CHAR], [↔], [↔], [↔], [↔], [↔],
    [K\_INPUT], [↑], [↑], [↓], [↑], [↑],
    [SHIFT], [↓], [↑], [↔], [↔], [↑],
    [NUM\_REP], [↑], [↑], [↔], [↔], [↑],
    [samplingrange], [↑], [↑], [↔], [↔], [↑],
    [countfilter], [↓], [↓], [↑], [↓], [↓],
    [batch\_size], [↑ or ↓], [↔], [↔], [↔], [↔])
) <fig_tab_impacts-onejoin-parameters>

The choice of parameters depends largely on the dataset. In this project, the dataset-generator script was used to create multiple datasets containing mutated DNA strands.
The dataset used for algorithm testing was a relatively small set of $7'500$ DNA strands.
The details of this dataset are presented in @fig_tab_dataset-params.

#figure(
  caption: [Sequencing parameters for `dna-little-processed.txt`],

  table(
    columns: (150pt, 150pt),
    align: (left, right),
    table.header(align(center)[*Parameter*], align(center)[*dna-little-processed.txt*]),

    [Clusters (-n)],             [250],
    [Strands / cluster (-c)],    [30],
    [*Total strands*],           [$7'500$],
    [Length strands],            [207],
    [*Avg. error %*],            [10.32],
    [Substitution %],            [4.63],
    [Deletion %],                [4.22],
    [Insertion %],               [1.47],
  )
) <fig_tab_dataset-params>

According to the parameters of this dataset, several parameters of the algorithm were defined, such as NUM_CHAR and $K$.
The choice of $K$ is critical:
- If $K$ is too small, true duplicates may be missed.
- If $K$ is too large, the risk of accepting false positives increases.
For our $207$-nucleotide strands, the error rate is around $10%$ ($~21$ characters).
On average, the edit distance between two reads is therefore about $42$.
Adding a small margin of 6 led us to choose $K = 48$, which provided good results in practice.

The remaining parameters were determined empirically, through trial-and-error, based on their impact on the final results after several tests.
The compilation command used for the experiments is given in @fig_cod_compilation-line-params.

#figure(
  caption: [Compilation line with good parameters for the `dna-little-processed.txt` dataset],

  ```bash
make update PARAMS="-DDEF_NUM_STR=24 -DDEF_NUM_HASH=28 -DDEF_NUM_BITS=11 -DDEF_NUM_CHAR=4 -DDEF_K_INPUT=48 -DDEF_SHIFT=16"
./onejoin -r test/dna-little-processed.txt -a 2 -d 1 -s 300 -c 1 -b 30
  ```
) <fig_cod_compilation-line-params>

#emph[Note] : It is worth mentioning that some tests were also performed on larger datasets.
However, when using the original #emph[oneoligo] code, these attempts systematically resulted in one of the following outcomes, suggesting that the work should be limited to the `dna-little-processed` dataset at this stage :
- Extremely low coverage
- No buckets generated
- System crash, potentially due to an out-of-memory condition
This is a known issue, and the authors have been contacted.

== Tag Matcher

Despite the acceleration provided by OneJoin, it was observed during the project that it is not fast enough when it comes to clustering large volumes of data.
An idea emerged during discussions with the DNAMIC team at UNIGE: namely, to add a large pre-filtering step to the data, in order to divide it into several groups, each containing up to $65'280$ distinct strands.
These groups would generally contain data originating from the same file, archived in DNA format.

To achieve this pre-division, the technique involves adding tags at the beginning of the DNA strands.
These tags must be sufficiently separated in terms of Levenshtein distance so that they can still be identified even in the presence of DNA sequencing errors.
The creation of these tags represented a significant effort by one of the UNIGE collaborators.

To cluster the data, the first step is to isolate the tag.
In practice, this step is fairly complex due to the characteristic of the Levenshtein distance.
Given the time constraints of the project, it was difficult to address it comprehensively.
To bypass this step, we used a list of noisy tags generated using a Python script.
This script is designed in accordance with the error rate that can be encountered in nanopore DNA sequencing.

The second and final step involves matching each noisy tag to its reference tag, thereby creating a tag pair.
This comparison is performed between the noisy tag and all reference tags using a SYCL implementation of the Myers’ algorithm.
During this process, it is possible for a noisy tag to be equidistant from several reference tags.
To avoid losing information in such cases, all equidistant reference tags are considered as potential candidates.
Several pairs are thus created and forwarded to the next processing stage.
Incorrect pairs are generally filtered out later by the OneJoin algorithm.

The final pipeline, combining the Tag Matcher and OneJoin, is illustrated in @fig_img_algo-diagram.
Note that the clustering and data recovery steps are not discussed in this project.

#figure(
  caption: [Tag Matcher algorithm pipeline],

  image("../figure/algo-diagram.png", width: 50%),
) <fig_img_algo-diagram>

