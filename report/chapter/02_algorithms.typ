#import "../conf.typ": *

= Algorithms: How to solve this Problem

#todo[Params OneJoin, talk more about important param and consequence]

#todo[make OneMyers]

#todo[Change link between OneJoin and OneMyers]


== Original Thoughs

The first solution considered was to compare all the DNA sequences against each other.
To do this, Myers' algorithm would be used to obtain the Levenshtein distance.
If it was below a certain threshold, the two DNA strands being compared would be considered identical (from the same original strand).
This would group the copies together.

The problem with this approach is that, despite the speed of each comparisons, it still requires performing $(n times (n-1))/2$ pairwise evaluations.
This is not scalable, because when working with a gigabytes of data, the number of evaluations would explode becoming approximately $5 times 10^14$.

Let's say we run at $200"Mhz"$, an average FPGA speed, and compute each comparison in $Omicron(n)$ using the Myers' algorithm.
If one comparison takes $250$ clock cycles, then processing all pairs would require $1.25 * 10^17$ clock cycles.
It would take : $625'000'000$ seconds, $10'416'666$ minutes, $173'611$ hours, $7'233$ days or about $20$ years.
Even by parallelizing this with a factor of $5$, we would still have to wait $4$ years, which is far too long.


== OneJoin

OneJoin is an edit similarity join algorithm designed to efficiently handle very large sets of sequences, such as DNA-encoded data.
Unlike traditional approaches, which rely on exact calculations of the Levenshtein distance between all pairs of sequences.
OneJoin relies on advanced embeddings and Locality Sensitive Hashing (LSH) techniques to drastically reduce the number of required comparisons.
OneJoin operates in three main stages: Embedding, LSH and the verification.

=== CGK Embedding

The appropriate edit distance for this context is the Levenshtein distance; however, its calculation is costly.
The Hamming distance only counts the number of substitutions, but unlike the Levenshtein distance, it is very efficient to compute.

The CGK embedding, developed by Chakraborty et al., is a method that transforms strings into a different metric space.
When applied to DNA sequence datasets, the algorithm takes as input a string of length $N$ composed of the four nucleotides $A$, $C$, $G$, and $T$.
The output of the CGK embedding is a new string three times longer, with length $3N$, containing the original nucleotide characters along with multiple occurrences of a special padding character $P$.

#figure(
  caption: [CGK Embedding Example],

  image("../figure/cgk-embedding-example.png", width: 75%),
)

At each step of the process, the algorithm appends either a character from the input string or the padding character to the output.
As a result, some input characters appear only once in the output, while others may be repeated randomly several times.
Using random walk theory, Chakraborty et al. demonstrated that the CGK embedding guarantees that the Hamming distance between the embedded strings is bounded by the square of the edit distance between the original strings.


=== Locality Sensitive Hashing (LSH)

An important benefit of edit-to-Hamming embedding is that algorithmic tools, like Locality Sensitive Hashing (LSH), well defined for Hamming, can now be used to identify similar strings without doing an exhaustive pair wise search.

Locality-Sensitive Hashing (LSH) for Hamming distance is a technique that efficiently groups similar strings by mapping them to the same “buckets”.
The technique relies on bit-sampling: specific bit positions are selected from each string to generate hash values.
In practice, this means that two strings with a low Hamming distance, meaning differ in only a few positions, are more likely to be hashed into the same bucket.
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
  caption: [LSH example],

  image("../figure/lsh-schema.png", width: 95%),
)

The figure above show how the LSH algorithm works.
A embedded DNA is hash multiple time (AND) giving subsequence of the strand.
These are compare to others subsequence from other strand, if one of them are equal (OR), the algorithm call a match and put them inside the same bucket.

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
If the computed distance is below the user-defined threshold, the pair is included in the final output set.
The verification phase is executed in a straightforward, sequential manner, with each thread or process handling a subset of the candidate list.


=== Parameters

OneJoin effectiveness depends heavily on several configurable parameters that influence key tradeoffs between performance, accuracy, and coverage.
The table below summarizes these parameters, their effects on critical metrics, and their default values on the OneJoin paper.

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
)

The next table show their effects on critical metrics.
It table serves as a reference for tailoring OneJoin to specific datasets, balancing speed and reliability according to application needs (e.g., large-scale DNA storage).

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
)

// Talk here about the params

// The parameters mainly act on two mechanisms:
//
// - CGK Embedding (via NUM_STR, SHIFT, NUM_REP): Transforms sequences into numeric representations to reduce the complexity of edit comparisons.
// - LSH (via NUM_HASH, NUM_BITS, --samplingrange): Probabilistic hashing to quickly group potentially similar sequences.
//
// The K_INPUT threshold and filters (--countfilter) adjust the strictness of the final check. The --batch_size optimizes hardware usage (CPU/GPU).


=== Times per steps

présenter steps concret; tableau; partie que j'ai reprise sur FPGA que j'ai juger importante;

#figure(
  caption: [Breakdown of computation steps of OneJoin],

  table(
    columns: 4,
    align: (center, left, left, center),
    table.header([*\#*], [*Step name*], [*What it does*], [*total time*]),
    [1], [Initialization], [Parses CLI-params, builds LSH tables, allocates host/device buffers and seeds RNGs], [*≈ 3 %*],
    [2], [Embedding], [CGK-embeds every read (many replicas) in parallel on all available SYCL queues], [*≈ 12 %*],
    [3], [Bucket creation], [Hashes each embedded vector, materialises and sorts (randStr, hashFn, hashID) tuples to form LSH buckets], [*≈ 20 %*],
    [4], [Init for candidate generation], [Scans the bucket array once to pre-size the candidate vector and record bucket boundaries], [*≈ 5 %*],
    [5], [Candidate generation], [Enumerates every unique pair inside each bucket in a GPU/CPU kernel and writes compact candidate tuples], [*≈ 20 %*],
    [6], [Candidate processing], [Filters impossible pairs, parallel-sorts & de-duplicates the list, preparing it for verification], [*≈ 15 %*],
    [7], [Counting frequencies], [Counts how many times each unique pair appears so low-support pairs can be pruned], [*≈ 10 %*],
    [8], [Edit distance verification], [Multi-threaded Levenshtein verification emits the finally similar read pairs], [*≈ 15 %*],
  )
)

/*
The time was generated by chatGPT and is therefore indicative ("Percentages sum to ~100 % and come from the profiling numbers in the GEN-470 KS experiment").
From paper in reality
*/

== OneMyers

- present onemyers
- plus value
- rapidité théorique
- ressemblance avec onejoin
- étapes (extraction bucket ID, find nearest, bucket creation, verification)
