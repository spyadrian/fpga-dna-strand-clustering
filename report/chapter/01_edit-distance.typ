#import "../conf.typ": *

= The Edit Distance Algorithm


== The distance of Levenshtein
// - briefly explain what the Levenshtein distance is and why it’s necessary for DNA strand clustering

In computer science, the edit distance is a metric used to measure the difference between two strings by counting the minimum number of operations required to transform one string $a$ into another string $b$.
This metric is commonly applied in spelling correction tools, where it helps identify and suggest the closest correct word when a misspelling is detected.
Above all, the edit distance plays an important role in bioinformatics, where it is essential for comparing different RNA or DNA sequences.
By doing so, it enables researchers to detect, analyze and study mutations.

There are several types of edit distance that can be categorized according to the operations they support and allow.
Some of these types are shown in @fig_tab_edit_distance_types.

// source: link("https://en.wikipedia.org/wiki/Edit_distance", [from en.wikipedia.org, ref. URL04]),
#figure(
  caption: [Different types of edit distance and which operations they allow],

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

As mentioned in the introduction, DNA is subject to three types of operations: insertion, deletion and substitution.
These are due to the variability introduced throughout the DNA processing pipeline.
Only two of these edit distances produce the desired result, the Levenshtein distance and the Damerau-Levenshtein distance.
These two differ by the fact that the Damerau-Levenshtein include transpositions in addition to the classical edit operations.
An operation that does not occur in the modifications DNA strands can undergo.
Therefore, the Levenshtein distance is the most appropriate edit distance for our project.

The naive recursive approach for computing the Levenshtein distance is given by the @eq_lev_naive.

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

Here, $n$ and $m$ are the length of the strings $a$ and $b$, respectively.
The $op("head")$ function returns the first character of a string, while the $op("tail")$ function returns the remaining part of a string after removing the first character.

// is switching a good word ?
As an example, let's consider the following task : switching the word "party" to form the word "park".
The Levenshtein distance between these two words is two, meaning it takes two operations to convert one word into the other.
In this case, we substitute the "t" in "party" with a "k" and delete the "y" in "parky".
The figure below illustrates this process.

// https://www.scaler.com/topics/levenshtein-distance-python
#figure(
  caption: [Calculate the Levenshtein Distance Example],

  image("../figure/lev-dist-example.png", width: 50%),
)


== The Myers' Bit-parallel Algorithm <chap_myers_algo>

Myers’ bit-parallel algorithm is an efficient method for computing the Levenshtein distance between two sequences.
Unlike traditional dynamic programming approaches which rely on filling a two-dimensional matrix, Myers’ algorithm optimizes this process using bit-parallelism.
Myers’ bit-parallel algorithm represents the state of the computation using bit vectors.
Each bit vector compactly encodes whether a match, substitution, insertion, or deletion is needed at each position in the pattern.
By leveraging bitwise operations, the algorithm efficiently simulates the dynamic programming table updates.

To explain Myers’ algorithm, it is helpful to start with the Wagner-Fischer algorithm.
The Wagner-Fischer algorithm is the standard dynamic programming technique for calculating the edit distance.
Dynamic programming works by breaking the problem into smaller sub-problems and solving them one after the other to retrieve the solution from the original problem.
In Wagner-Fischer, a matrix is used to store every Levenshtein distance between all prefixes of the string $a$ and $b$, the last computation being the distance between the two full strings.

The matrix in @fig_grid_wagner-fischer shows the result of the Wagner-Fischer algorithm applied to the words "sitting" and "kitten".
The highlighted path shows the most optimized path for transforming one string into the other.
If we want to correct the word "sitting" to "kitten", a diagonal movement represents substitutions (or no operation if the letters are identical), movements to the right represents insertions, and movements downward represent deletions.

#let path_color = rgb("#C6DBEF");
// source: link("https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm", [from en.wikipedia.org, ref. URL05]),
#figure(
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
) <fig_grid_wagner-fischer>

One of the key strengths of the Wagner-Fischer algorithm lies in its simplicity.
But, unfortunately, when dealing with long strings, this algorithm is not very efficient.
With some optimization, Wagner-Fischer has a time complexity of $Omicron(n times k)$, $n$ being the length of the query (string $a$) and $k$ the maximum tolerated distance.
Another drawback is the memory requirement, as the algorithm needs to store a matrix of size $Omicron(n times m)$.
This can be optimized to $Omicron(n)$ by storing only the current and previous columns of the matrix.
Note that the memory will, in any case, become significant when comparing a lot of data simultaneously.

Now, let's look at how Myers went from computing the $n times m$ Wagner-Fischer matrix, to computing five bit vectors in parallel: $\Eq$, $\Pv$, $\Ph$, $\Mv$, and $\Mh$, which encodes the divers operation.
To do this, we need to understand several key principles derived from the traditional $n times m$ matrix.
In the Wagner-Fischer algorithm, when optimizing memory space, we note that a column $C_j$ of the matrix can be computed using only the column $C_(j-1)$ that precedes it.
A related observation is that the difference between adjacent entries in any row or column is either $+1$, $0$, or $-1$.
Those two observations present a new way of approaching the problem : storing the differences between the columns instead of the values themselves.
This approach originates from the 4-Russians algorithm for string comparison.

Formally, we have the _horizontal delta_ $Delta h[i, j]$ as $C[i, j] - C[i, j - 1]$ and the _vertical delta_ $Delta v[i, j]$ as $C[i, j] - C[i - 1, j]$ for all $(i, j) in [1, m] times [1, n]$, $C$ being the dynamic programming matrix $C[0 ... m, 0 ... n]$.
$Delta v$ and $Delta h$ are matrices that represent the traditional Wagner-Fischer matrix, but relative to the preceding cells, vertically or horizontally.
Using several theorems, Myers manages to transform the problem of calculating the Wagner-Fischer matrix into the calculation of the matrix $Delta v$.

// source: link("https://www.gersteinlab.org/courses/452/09-spring/pdf/Myers.pdf", [from gersteinlab.org, ref. URL09]),
#figure(
  caption: [Myers' bit-parallel algorithm dynamic programming (d.p.) matrices],

  image("../figure/myers_matrices.png"),
) <fig_img_myers_matrices>

To understand the origin of the bit vectors, let's look at @fig_img_myers_matrices.
On the left, the traditional matrix from the Wagner-Fischer algorithm, and on the right the $Delta v$ matrix and the first and last rows of the $Delta h$ matrix.
The illustration shows that the data in the $Delta v$ matrix are Boolean variables $M$ or $P$, which indicated whether a cell's value should be increased (P) or decreased (M) by $1$.
They cannot both be true (be equal to $1$) at the same time.
To represent a row, a bit vector is created resulting in the bit vectors $\Pv$, $\Ph$, $\Mv$, and $\Mh$, where $v$ and $h$ represent the axes where the operation is performed (vertical or horizontal).
To correctly calculate these bit vectors, it is necessary to know whether the current characters are similar or not.
The bit vector $\Eq$ is responsible for this, representing equality between characters.
While $\Eq$ can be obtained through a simple comparison, it is more efficient to precompute it in $Omicron(1)$ time for each column by storing it in a matrix $P\eq[sigma]$, where $sigma$ is the alphabet from which the two strings originate.

#figure(
  caption: [Myers' bit-parallel algorithm pseudo-code JS style],

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
)

Since the algorithm only contains bitwise operations, it can be easily represented using an actual electric schematic, which helps in understanding its operation.
Below is a figure showing the schematic of Myers' algorithm.
This comes from the paper #emph[High throughput edit distance computation on FPGA-based accelerators using HLS] and differs slightly from the implementation described above, like the naming conventions.
It is presented here primarily to give an idea of the components that the FPGA will recreate.

// High throughout edit distance computation on FPGA-based accelerators using HLS
#figure(
  caption: [Schematic blocks diagram of Myers' algorithm],

  image("../figure/myers-schematics.png", width: 75%),
)

Myers' bit-parallel algorithm has a very good time complexity of $Omicron(n times m/w)$, where $w$ is the length of a machine word, and a space complexity of $Omicron(n)$.
Since FPGA do not have strict limits on the length of a machine word, `w` can be set to the value of `m`, reducing the time complexity to $Omicron(n)$.
This value is one of the reason we used this algorithm.
Another reason is the use of binary operations which simplify the implementation on FPGA.
And speed up computations, as these operations can generally be performed in a single clock cycle.

