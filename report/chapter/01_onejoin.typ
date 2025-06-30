#import "../conf.typ": *

= A Primer on the OneJoin Algorithm

OneJoin is an edit similarity join algorithm designed to efficiently handle very large sets of sequences, such as DNA-encoded data.
Unlike traditional approaches, which rely on exact calculations of the edit distance (Levenshtein distance) between all pairs of sequences.
OneJoin relies on advanced embeddings and Locality Sensitive Hashing (LSH) techniques to drastically reduce the number of comparisons required.
OneJoin works in three main stages: Embedding, LSH and the verification.


== Introduction Levenshtein Distance
// - briefly explain what the Levenshtein distance is and why it’s necessary for DNA strand clustering

In computer science, the edit distance is a metric that measures the difference between two strings.
This is done by counting the minimum number of operations needed to transform one string $a$ into another string $b$.
This metric is commonly applied in spelling correction tools, where it helps identify and suggest the closest correct word when a misspelling is detected.
Above all, the edit distance plays an important role in bioinformatics, where it is essential for comparing different RNA or DNA sequences.
By doing so, it enables researchers to detect, analyze and study mutations.

There are several types of editing distance that can be categorized according to the operations they support and allow.
On this table, you can see different types on the @fig_tab_edit_distance_types.

#sourced_figure(
  source: link("https://en.wikipedia.org/wiki/Edit_distance", [from en.wikipedia.org, ref. URL04]),
  fig: [
    #figure(
      caption: [Different types of edit distance and which operations they allowed],

      table(
        columns: (1fr, auto, auto, auto, auto),
        align: (left, center, center, center, center),
        table.header(align(center)[*Algorithm*], table.cell(colspan: 4)[*Operations Allowed*],
                     [], [*Insertions*], [*Deletions*], [*Substitutions*], [*Transpositions*]),
        [Hamming Distance],             [],  [],  [✓], [],
        [Longest Common Subsequence],   [✓], [✓], [],  [],
        [Levenshtein Distance],         [✓], [✓], [✓], [],
        [Damerau-Levenshtein Distance], [✓], [✓], [✓], [✓],
        [Jaro Distance],                [],  [],  [],  [✓],
      ),
    ) <fig_tab_edit_distance_types>
  ]
)

As mentioned in the introduction, DNA is subject to three types of operations: insertion, deletion and substitution.
These are due to the variability introduced throughout the DNA processing pipeline.
Only two of these last edit distances achieve the desired result, the Levenshtein distance and the Damerau-Levenshtein distance.
These two differ by the fact that the Damerau-Levenshtein include transpositions in addition to the classical edit operations.
An operation that does not appear in the modifications that DNA strands can suffer.
Thus, it goes without saying that Levenshtein distance is the most appropriate for our project.

#todo[illustrate the example]

As an example, let's consider the following task : correct the word "kitten" to form the word "sitting".
One can easily notice that the Levenshtein distance between these two words is three, meaning it takes three operations to convert one word into the other.
Here's a breakdown :
 - The first operation is substituting the "k" in "kitten" with an “s”, changing "kitten" to "sitten".
 - The second operation is substituting the “e” in "sitten" with an "i", transforming "sitten" to "sittin".
 - The final operation is inserting an “g” at the end of "sittin", resulting in "sitting".
In total, three operations (two substitutions and one insertion) are required to transform "kitten" into "sitting", which makes the Levenshtein distance between them equal to three.


== CGK Embedding

The appropriate edit distance for this context is the Levenshtein distance; however, its calculation is costly.
The Hamming distance only counts the number of substitutions, but unlike the Levenshtein distance, it is very efficient to compute.

// from paper, maybe change for my own words
The CGK embedding, introduced by Chakraborty et al., is a technique that maps strings into a different metric space.
When applied to DNA read datasets, the algorithm takes as input a string of length $N$ composed of the four nucleotides ($A$, $C$, $G$, $T$).
The result of the CGK embedding is a new string of length $3N$, which contains the original four characters and may include several instances of a padding character ($P$).
During each step of the algorithm, either a character from the input sequence or the pad character is appended to the output string.
This process causes some input characters to appear only once in the output, while others may be repeated multiple times at random.
Chakraborty et al. showed, using random walk theory, that the CGK embedding ensures the Hamming distance between embedded strings does not exceed the square of the edit distance between the original strings.


== Locality Sensitive Hashing (LSH)

An important benefit of edit-to-Hamming embedding is that algorithmic tools, like Locality Sensitive Hashing (LSH), that are well defined for Hamming distance but not edit distance, can now be used to identify similar strings without doing an exhaustive pair wise search.

Locality-Sensitive Hashing (LSH) for Hamming distance is a technique that efficiently groups similar strings by mapping them to the same “buckets”.
The technique relies on bit-sampling: specific bit positions are selected from each string to generate hash values.
In practice, this means that two strings with a low Hamming distance—meaning they differ in only a few positions—are more likely to be hashed into the same bucket.
For instance : #todo[make an illustration of this example]

- Consider two 8-bit DNA sequences: $x = "ATCGATCG"$, $y = "ATCGATCA"$ (differs only in the last character).
- A hash function sampling bit position 7 would place both in the same bucket since bit 7 is 1 in both.

#todo[Clarify AND-OR]

To balance precision and recall, LSH typically uses an AND-OR composition: the AND construction reduces false positives by requiring agreement on multiple sampled bits, while the OR construction reduces false negatives by considering multiple independent hash tables.

The AND construction requires agreement on multiple sampled bits.
For example :

- Define a hash function $f_1(x) = ("bit"_3, "bit"_7)$.
- $x$ and $y$ collide only if they match at both positions.

It reduces false positives (dissimilar strings rarely match multiple bits).

The OR construction uses multiple independent hash tables.
For example:

- Employ three hash tables: [g₁, g₂, g₃], each sampling different bits.
- Strings collide if they match in any table (g₁ OR g₂ OR g₃).

It reduces false negatives (similar strings likely collide in at least one table).

LSH combines both strategies:

- AND within tables: Each hash table g_j requires matches across k bits (e.g., k=2 → g_j(x) = (bitᵢ, bitⱼ)).
- OR across tables: Strings collide if they match in any of L tables.

This balances sensitivity and specificity, ensuring:

- High recall: Similar strings (e.g., Hamming distance ≤ d) collide with tunable probability P ≥ 1 - (1 - (1 - d/n)^k)^L.
- Low computational cost: Only colliding pairs undergo exact distance verification.

In DNA sequence analysis (e.g., OneJoin), this allows scaling from O(N²) to near-linear comparisons, as >90% of dissimilar pairs are filtered before costly edit-distance calculations.


== EmbedJoin

// rewrite this
EmbedJoin is a sequential, CPU-based algorithm for edit similarity joins, leveraging CGK embedding and locality-sensitive hashing (LSH) to reduce the need for costly pairwise edit distance computations.

=== Filtering

The filtering phase is the first and most computationally intensive stage of the algorithm.
It begins by sorting the input strings according to their lengths.
This step allows EmbedJoin to quickly eliminate unlikely candidate pairs by leveraging the fact that two strings with a significant length difference cannot be within the specified edit distance threshold.

Each input string is then embedded using the CGK embedding technique.
The embedded strings are subsequently hashed into buckets using Locality-Sensitive Hashing (LSH) for Hamming distance.
For each string, the algorithm checks all other strings in the same bucket.
If the length difference between the current string and a candidate is less than the edit threshold, the pair is added to a candidate list for further verification.
Otherwise, the candidate is removed from the bucket to optimize subsequent comparisons.
This process is repeated for all input strings, and duplicate pairs are eliminated to avoid redundant computations.

#todo[add schema filtering]

=== Verification

After the filtering phase, EmbedJoin has generated a candidate list of string pairs that are likely to be within the specified edit distance.
The verification phase then computes the exact edit distance for each candidate pair.
This step is much less computationally demanding than filtering, as the number of candidate pairs is typically only a small fraction of all possible pairs due to the effectiveness of the embedding and LSH-based filtering.

For each candidate pair, EmbedJoin employs a standard dynamic programming algorithm to compute the Levenshtein (edit) distance.
If the computed distance is below the user-defined threshold, the pair is included in the final output set.
The verification phase is executed in a straightforward, sequential manner, with each thread or process handling a subset of the candidate list.

Despite the simplicity of the verification step, the true power of EmbedJoin lies in its ability to drastically reduce the number of expensive edit distance computations through its efficient filtering mechanism.
As a result, the verification phase contributes only a small fraction of the total execution time, making EmbedJoin highly effective for large-scale string similarity joins.


== OneJoin

OneJoin is a data-parallel redesign of EmbedJoin using oneAPI and SYCL, enabling execution across multicore CPUs, integrated GPUs, and discrete GPUs from multiple vendors, which results in significant performance improvements (up to 21x faster) and scalability for DNA read consensus tasks.


== Parameters

OneJoin effectiveness depends heavily on several configurable parameters that influence key tradeoffs between performance, accuracy, and coverage.
The table below summarizes these parameters, their effects on critical metrics, and their default values on the OneJoin paper.

#figure(
  caption: [Description of the OneJoin algorithm parameters],

  table(
    columns: (auto, auto, auto, auto),
    align: (center, center, center, left),
    table.header([*Parameter*], [*Symbol*], [*Default value*], align(center)[*Brief description*]),
    [NUM\_STR], [_r_], [$5$], [independent CGK embeddings per read],
    [NUM\_HASH], [_z_], [$7$], [hash functions (OR-construction) per embedding],
    [NUM\_BITS], [_m_], [$12$], [bits sampled inside each hash (AND-construction)],
    [NUM\_CHAR], [], [$4$], [alphabet size of the dataset],
    [K\_INPUT], [_K_], [$6$], [edit-distance threshold passed to the verifier],
    [SHIFT], [], [$6$], [edit-band stride used when slicing strings during embedding],
    [NUM\_REP], [⌈K/SHIFT⌉], [$1$ ($6/6$)], [replicated sub-strings embedded per read],
    [samplingrange], [_s_], [], [highest character position inspected by LSH; determines embedded length],
    [countfilter], [_c_], [$1$], [min occurrences of the same candidate pair before verification],
    [batch\_size], [_B_], [], [reads processed together; limited by GPU / RAM]
  )
)

The parameters mainly act on two mechanisms:

- CGK Embedding (via NUM_STR, SHIFT, NUM_REP): Transforms sequences into numeric representations to reduce the complexity of edit comparisons.
- LSH (via NUM_HASH, NUM_BITS, --samplingrange): Probabilistic hashing to quickly group potentially similar sequences.

The K_INPUT threshold and filters (--countfilter) adjust the strictness of the final check. The --batch_size optimizes hardware usage (CPU/GPU).

The next table show their effects on critical metrics.
It table serves as a reference for tailoring OneJoin to specific datasets, balancing speed and reliability according to application needs (e.g., large-scale DNA storage).

#figure(
  caption: [Impacts of parameters on algorithm performance and quality],

  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: center,
    table.header([*Parameter*], [*Speed impact*], [*Recall impact*], [*Precision impact*], [*False positives impact*], [*True positives impact*]),
    [NUM\_STR], [↑ (linear cost)], [↑], [slight ↓], [slight ↑], [↑],
    [NUM\_HASH], [slight ↑], [↑], [↓], [↑], [↑],
    [NUM\_BITS], [↑ (sparse buckets) ⇒ faster], [↓], [↑], [↓], [↓ (if too large)],
    [NUM\_CHAR], [↔ (negligible)], [—], [—], [—], [—],
    [K\_INPUT], [↑ (large DP cost)], [↑], [↓], [↑], [↑],
    [SHIFT], [↓ if smaller], [↑], [—], [—], [↑],
    [NUM\_REP], [↑], [↑], [—], [—], [↑],
    [samplingrange], [↑ (longer strings)], [↑], [—], [—], [↑],
    [countfilter], [↓ (filters early)], [slight ↓], [↑], [↓], [mild ↓],
    [batch\_size], [↑ or ↓ (tune GPU)], [—], [—], [—], [—])
)

#todo[plus parler des param que je juge important]
#todo[add OneJoin vs Myers' (C implementation)]
