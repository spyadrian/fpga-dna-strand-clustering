#import "../conf.typ": *

= Algorithm Selection and Theoretical Analysis

== Introduction to Levenshtein Distance
// - briefly explain what the Levenshtein distance is and why it’s necessary for DNA strand clustering
// - discuss why it’s better suited than simpler metrics like Hamming distance

In computer science, the edit distance is a metric that measures the difference between two strings.
This is done by counting the minimum number of operations needed to transform one string $a$ into another string $b$.
This metric is commonly applied in spelling correction tools, where it helps identify and suggest the closest correct word when a misspelling is detected.
Above all, the edit distance plays an important role in bioinformatics, where it is essential for comparing different RNA sequences.
By doing so, it enables researchers to detect, analyze and study mutations.

There are several types of editing distance that can be categorized according to the operations they support and allow.
On this table, you can see different types of edit distances :

#sourced_figure(
  source: link("https://en.wikipedia.org/wiki/Edit_distance", [Edit distance, Wikipedia, March 2025]),
  fig: {
    figure(
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
      caption: [Different types of edit distance and which operations they allowed],
    )
  }
)

As mentioned in the introduction, DNA is subject to three types of operation: insertion, deletion and substitution.
These are due to the variability introduce throughout the DNA processing pipeline.
Only two of these last edit distance achieve the desired result, the Levenshtein distance and the Damerau-Levenshtein distance.
These two differs by the fact that the Damerau-Levenshtein include transpositions in addition to the classical edit operations.
An operation that does not appear in the modifications that DNA strands can suffer.
Thus, it goes without saying, that Levenshtein distance is the most appropriate for our project.

The naive recursive approach to compute the Levenshtein distance is given by the @eq_lev_naive.

$
  op("lev")(a, b) = cases(

    n\, #h(13.4em) "if" m = 0,
    m\, #h(13.1em) "if" n = 0,
    op("lev")(op("tail")(a), op("tail")(b))\, #h(6.1em) "if" op("head")(a) = op("head")(b),
    1 + op("min") display(cases(

      op("lev")(op("tail")(a), b)\,,
      op("lev")(a, op("tail")(b))\,,
      op("lev")(op("tail")(a), op("tail")(b))\,,
    )) #h(1.8em) "otherwise"
  )
$ <eq_lev_naive>

Knowing that $n$ and $m$ are respectively the length of the strings $a$ and $b$.
That the $op("head")$ function return the first character of a string and that the $op("tail")$ function return the remaining part of a string after removing the first character.

As an example, let's consider the task of correct the word "kitten" to form the word "sitting".
One can easily notice that the Levenshtein distance between these two words is three, meaning it takes three operations to convert one word into the other.
Here's a breakdown :
 - The first operation is substituting the "k" in "kitten" with an “s”, changing "kitten" to "sitten".
 - The second operation is substituting the “e” in "sitten" with an "i", transforming "sitten" to "sittin".
 - The final operation is inserting an “g” at the end of "sittin", resulting in "sitting".
In total, three operations (two substitutions and one insertion) are required to transform "kitten" into "sitting", which makes the Levenshtein distance between them equal to three.


== Algorithm Choice
// - present the different algorithms available to compute the Levenshtein distance
// - compare them in terms of complexity, performance, and suitability for hardware acceleration
// - justify why you chose the algorithm you did, considering FPGA constraints and parallelization possibilities

=== Wagner-Fischer

The Wagner-Fischer algorithm builds upon the naive approach by incorporating dynamic programming.
It works by breaking the problem into smaller sub-problems, solving one after the other to retrieve the solution from the original problem.
In the case of the Wagner-Fischer algorithm, a matrix is used to store every Levenshtein distance between all prefixes of the string $a$ and $b$, the last computation being the edit distance between the two full string.

#sourced_figure(
  source: link("https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm", [Wagner-Fischer algorithm, Wikipedia, March 2025]),
  fig : figure(
    caption: [Pseudo code of the Wagner-Fischer algorithm],

    ```js
function wagner_fischer(char a[1..n], char b[1..m]):
  declare int d[0..n, 0..m]
 
  for i from 1 to n:
      d[i, 0] := i
 
  for j from 1 to m:
      d[0, j] := j
 
  for j from 1 to m:
      for i from 1 to n:
          if s[i] = t[j]:
            substitutionCost = 0
          else:
            substitutionCost = 1

          d[i, j] := minimum(d[i-1, j] + 1,                   // deletion
                             d[i, j-1] + 1,                   // insertion
                             d[i-1, j-1] + substitutionCost)  // substitution
 
  return d[n, m]
    ```
  )
)

The matrix in the @fig_grid_wagner-fischer represents the matrix filled by the Wagner-Fischer algorithm between the words "sitting" and "kitten".
The highlighted path shows the most optimized path for moving from one string to the other.
We can think of a diagonal movement as a substitution (or no movement if the letters are identical), movements to the right as an insertion and downward as a deletion.

#let path_color = rgb("#C6DBEF");
#sourced_figure(
  source: link("https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm", [Wagner-Fischer Algorithm, Wikipedia, March 2025]),
  fig: [#figure(
    caption: [Wagner-Fischer matrix between "sitting" and "kitten"],
    grid(
      fill: (x, y) => rgb(
        if x == 0 or y == 0 { "#E0E0E0" }
        else { "#FFFFFF" }
      ),
      columns: (1.3em, ) * 8,
      rows: 1.3em,
      row-gutter: 0em,
      align: center + horizon,

      [], [], [*k*], [*i*], [*t*], [*t*], [*e*], [*n*],
      [], [0], [1], [2], [3], [4], [5], [6],
      [*s*], [1], grid.cell(fill: path_color)[1], [2], [3], [4], [5], [6],
      [*i*], [2], [2], grid.cell(fill: path_color)[1], [2], [3], [4], [5],
      [*t*], [3], [3], [2], grid.cell(fill: path_color)[1], [2], [3], [4],
      [*t*], [4], [4], [3], [2], grid.cell(fill: path_color)[1], [2], [3],
      [*i*], [5], [5], [4], [3], [2], grid.cell(fill: path_color)[2], [3],
      [*n*], [6], [6], [5], [4], [3], [3], grid.cell(fill: path_color)[2],
      [*g*], [7], [7], [6], [5], [4], [4], grid.cell(fill: path_color)[3],
    )
  ) <fig_grid_wagner-fischer>]
)

One of the key strengths of the Wagner-Fischer algorithm lies in its simplicity.
But, unfortunately, when dealing with long strings, this algorithm is not very efficient.
Even with some optimization, Wagner-Fischer barely exceeds the time complexity of *$Omicron(n times m)$*, $n$ and $m$ being the length of the string of $a$ and $b$ respectively.
Another drawback is the memory requirement, as the algorithm needs to store a matrix of size $Omicron(n times m)$.
This can be optimized to $Omicron(n)$ by storing only the current and previous rows of the matrix.
Note that the memory will, in any case, become significant when comparing a lot of data simultaneously.


=== Bitap

The Bitap algorithm is one of the most widely used algorithms in search tools, partly because it is the underlying algorithm for the Unix utility _agrep_.
This algorithm does not directly calculate the Levenshtein distance, but it can indicate when a given string is sufficiently similar to another.
This similarity is said to be true if and only if the two strings have a Levenshtein distance less than $k$, a given threshold.

The Bitap algorithm works by pre-computing bitmasks where each bit corresponds to a letter in the search string.
It then proceeds by performing binary operations to efficiently compare patterns and text segments.
Originally, the Bitap algorithm allows you to find an exact pattern in a text, it is simple to implement.
But finding a pattern similar to a given threshold $k$, called Fuzzy searching, is much more complex.
The implementation in C can be found in the #todo[appendix X].

The Bitap algorithm does not surpass the *$Omicron(m times n)$* time complexity of the naive Wagner-Fischer algorithm, but it delivers excellent practical performance as it manage to do most of the work with bitwise operations, which are extremely fast.
It goes without saying that using binary operations is a major advantage when it comes to implementing the algorithm on FPGAs.

=== BLAST

The Basic Local Alignment Search Tool (BLAST) is one of the most popular algorithms for comparing biological sequences, particularly DNA, RNA, and protein sequences.
It is a local sequence alignment, meaning it finds the most similar sub-sequences between two strings rather than aligning the entire sequences.
BLAST works by breaking down a query sequence into small sub-sequences known as words.
It then searches a database for exact or near-exact matches to these words.
Once matches are found, BLAST extends them in both directions to determine the length and quality of the alignment.
If the extended alignment surpasses a predetermined score threshold $k$, it is reported as a match.
BLAST comes in several variations, each using specific types of data.
The most suitable algorithm for this project is BLASTN that compares nucleotide sequences.

BLAST have generally a time complexity of *$Omicron(D)$*, where $D$ is the size of the database used.
That made it one of the most efficient algorithm, but unlike exact string matching algorithms, BLAST is heuristics.
This means that instead comparing every possible alignment, it quickly identify regions that are likely to be similar, speeding up the search process at the cost of potentially missing some optimal alignments.
Above that, its complexness does not help its implementation in FPGAs.


=== Smith-Waterman & Needleman-Wunsch

Unlike BLAST, Smith-Waterman is not heuristic, which makes it more interesting depending on the context of the project, as in our case.
A bit like Wagner-Fischer, it works by using matrix where each cell contains a score representing the best possible alignment between prefixes of the two sequences.
The scoring is based on matches, mismatches, and gaps (insertions or deletions).

It works by filling a matrix comparing characters from both sequences and choosing the optimal score at each step.
The score representing the probability of a good alignment.
The higher the score, the better the alignment of the two substrings.
Smith-Waterman fills the matrix iteratively using a substitution matrix, often described as an $s$ function.
A trivial $s$ function could be as described in @eq_smith-waterman_s.
$
  s(a_i, b_j) = cases(
    + 1\, #h(1.5em) a_i = b_j,
    - 1\, #h(1.5em) a_i eq.not b_j
  )
$ <eq_smith-waterman_s>

The cell being processed takes the best score between:

+ The diagonal cell plus the match/mismatch score (representing a substitution).
+ The cell above minus a gap penalty $W_k$(representing a deletion).
+ The cell to the left minus a gap penalty $W_l$ (representing an insertion).
+ Zero, to indicate that starting a new alignment at this position is better than extending a poor one.

After filling the matrix, the algorithm traces back from the highest scoring cell to reconstruct the optimal local alignment.

#sourced_figure(
  source: link("https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm", [Smith-Waterman Algorithm, Wikipedia, March 2025]),
  fig: figure(
    caption: [Scoring method of the Smith–Waterman algorithm],
    image("../figure/smith-waterman_scoring.png", width: 45%)
  )
)

With Gotoh and Altschul's optimizations, the Smith-Waterman algorithm has a time complexity of $Omicron(n times m)$
The cost of this greater complexity than BLAST is due to the fact that this algorithm is not heuristic.
However, it poses some problems in our context, the algorithm performs local alignment when a global one is needed.
But there's a trick to fix this: the Needleman-Wunsch algorithm.

The Needleman-Wunsch algorithm is very similar to the Smith-Waterman algorithm.
It differs in a few ways, but the most important is that these scores are potentially negative.
This is one of the main reasons why this algorithm is capable of global alignment.
Like Smith-Waterman, Needleman-Wunsch has a complexity of $Omicron(n times m)$.
Unfortunately, it also requires a traceback at the end of the algorithm to find the alignment.
Tracing back this algorithm is not a simple matter in VHDL.
It is therefore possible but difficult to achieve hardware acceleration on this algorithm.


=== Myers' Bit-parallel Algorithm

Myers' Bit-parallel algorithm is a highly efficient method for approximate string matching.
Unlike traditional dynamic programming approaches (e.g., Wagner-Fischer), which rely on filling a two-dimensional matrix, Myers’ algorithm optimizes this process using bit-parallelism (a bit like Bitap).
Myers’ algorithm represents the state of the computation using bit vectors.
Each bit vector compactly encodes whether a match, substitution, insertion, or deletion is needed at each position in the pattern.
By leveraging bitwise operations, the algorithm efficiently simulates the dynamic programming table updates.

To better understand this concept, let's look at how Myers went from computing an n-times-m matrix to computing five bit vectors in parallel: $\Eq$, $\Pv$, $\Ph$, $\Mv$, and $\Mh$.
To do this, we need to understand several key principles derived from the traditional n-by-m matrix.
In the Wagner-Fischer algorithm, when optimizing memory space, we note that a column $C_j$ of the matrix can be computed using only the column $C_(j-1)$ that precedes it.
A related observation is that the difference between adjacent entries in any row or column is either $+1$, $0$, or $-1$. There is a more general way to present this, found in the 4-Russians algorithm for string comparison. Formally, we have: _horizontal delta_ $Delta h[i, j]$ as $C[i, j] - C[i, j - 1]$ and _the vertical delta_ $Delta v[i, j]$ as $C[i, j] - C[i - 1, j]$ for all $(i, j) in [1, m] times [1, n]$.
$Delta v$ and $Delta h$ are matrices that represent the traditional Wagner-Fischer matrix, but relative to the preceding cells, vertically or horizontally.
Using several theorems, Myers manages to transform the problem of calculating the Wagner-Fischer matrix into the calculation of the matrix $Delta v$ except for the last step where $Delta h$ is necessary.
But this can be calculated using a simple product on a part of $Delta v$.

#sourced_figure(
  source: link("https://www.gersteinlab.org/courses/452/09-spring/pdf/Myers.pdf", [A Fast Bit-Vector Algorithm for Approximate String
Matching Based on Dynamic Programming, Gene Myers, January 2025]),
  fig : [
    #figure(
      caption: [Myers' dynamic programming (d.p.) matrices],

      image("../figure/myers_matrices.png"),
    ) <fig_img_myers_matrices>
  ]
)

The @fig_img_myers_matrices shows, on the left, the traditional matrix found in Wagner-Fischer and, on the right, the $Delta v$ matrix and the first and last rows of the $Delta h$ matrix.
The illustration shows that the data in the $Delta v$ matrix are Boolean variables $M$ or $P$.
They represent whether or not an addition (P) or subtraction (M) of $1$ occurs on a cell.
They cannot both be true (be equal to 1) at the same time.
To represent a row, simply create a bit vector, hence the bit vectors $\Pv$, $\Ph$, $\Mv$, and $\Mh$, where $v$ and $h$ represent the axes where the operation is performed (vertical or horizontal).
To correctly calculate these bit vectors, it is necessary to know whether the current characters are similar or not.
$\Eq$, a bit vector, is responsible of doing so.
It represents equality between the characters.
$\Eq$ can be calculated with a simple comparison, but to save time on the computation of a column of $Omicron(1)$, it is clever to precompile it into a matrix named $P\eq[sigma]$, with $sigma$ being the alphabet over which the two strings originate.

#sourced_figure(
  source: link("https://www.gersteinlab.org/courses/452/09-spring/pdf/Myers.pdf", [A Fast Bit-Vector Algorithm for Approximate String Matching Based on Dynamic Programming, Gene Myers, January 2025]),
  fig : [
    #figure(
      caption: [Basic pseudo code of the Myers algorithm],

      ```js
  precompute Peq
  Pv = 1^m
  Mv = 0
  score = m
  for j from 1 to n:

      Eq = Peq[j]
      Xv = Eq | Mv
      Xh = (((Xv & Pv) + Pv) ^ Pv) | Xv

      if lsb(Ph) then score++
      if lsb(Mh) then score--

      Ph = Pv & Xh
      Mh = Mv | ~(Pv | Xh)
      Pv = (Mh << 1) | ~0
      Mv = (Ph << 1)
      ```
  ) <fig_code_myers>]
)

Myers' bit-parallel algorithm has a very good time complexity of $Omicron(n)$ and a space complexity of $Omicron(n)$.
The use of binary operations helps in several ways.
It significantly speeds up computations since these operations can generally be performed in a single clock cycle.
Furthermore, it greatly simplifies the hardware acceleration.


== Choice Justification
// - summarize the criteria for selecting the most suitable algorithm for FPGA implementation
// - introduce the algorithms you chose to implement and evaluate (Wagner–Fischer and Myers)

The algorithms presented in the previous section are all interesting, but they each come with their own strengths and weaknesses.
To make the following easier, @fig_tab_algo_recap summarizes their main features.

#figure(
  caption: [Comparison of sequence alignment and edit distance algorithms],
  table(
    columns: (10fr, auto, auto, 3fr, 4fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),

    table.header(align(center)[*Algorithms*], par(leading: 0.5em)[*Time \ Complexity*],
                 par(leading: 0.5em)[*Space \ complexity*], [*Range*], [*Suitability*]),
    [Wagner-Fischer],      [$Omicron(n times m)$], [$Omicron(n)$],                    [global], [good],
    [Bitap],               [$Omicron(n times m)$], [$Omicron(n)$],                    [global], [high],
    [BLAST],               [$Omicron(n)$],         [$Omicron(20^(256) + n times m)$], [local],  [bad],
    [Smith-Waterman],      [$Omicron(n times m)$], [$Omicron(n)$],                    [local],  [bad],
    [Needleman-Wunsch],    [$Omicron(n times m)$], [$Omicron(n)$],                    [global], [bad],
    [Myers' Bit-parallel], [$Omicron(n)$],         [$Omicron(n)$],                    [global], [high],
  )
) <fig_tab_algo_recap>

#todo[explain space complexity in all algorithm (in their chapter)]

A very important eliminatory criterion for this project is the algorithm's range.
Indeed, algorithms with a local range are not suitable for this project, as they do not allow for the evaluation of overall similarity between sequences.
They focus only on identifying the most similar subsequences, which can lead to fragmented results that are not representative of the entire sequence.
Therefore, the BLAST and Smith-Waterman algorithms cannot be used for this project.

Regarding the second most important criterion, time complexity, Myers wins hands down with a theoretical speed of $Omicron(n)$.
In order to compare this speed with another algorithm, it was necessary to choose another algorithm to implement.
Among the remaining algorithms, although Needleman-Wunsch and Bitap were good candidates, Wagner-Fischer was implemented. This is because it was the project's original proposed algorithm.
And in order to see how Myers's algorithm optimized the original proposed algorithm, it was chosen.
