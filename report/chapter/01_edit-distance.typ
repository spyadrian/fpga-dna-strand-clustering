#import "../conf.typ": *

= The Edit Distance Algorithm


== The distance of Levenshtein
// - briefly explain what the Levenshtein distance is and why it’s necessary for DNA strand clustering

In computer science, the edit distance is a metric that measures the difference between two strings.
This is done by counting the minimum number of operations needed to transform one string $a$ into another string $b$.
This metric is commonly applied in spelling correction tools, where it helps identify and suggest the closest correct word when a misspelling is detected.
Above all, the edit distance plays an important role in bioinformatics, where it is essential for comparing different RNA or DNA sequences.
By doing so, it enables researchers to detect, analyze and study mutations.

There are several types of editing distance that can be categorized according to the operations they support and allow.
You can see some of those different types on the @fig_tab_edit_distance_types.

// source: link("https://en.wikipedia.org/wiki/Edit_distance", [from en.wikipedia.org, ref. URL04]),
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

As mentioned in the introduction, DNA is subject to three types of operations: insertion, deletion and substitution.
These are due to the variability introduced throughout the DNA processing pipeline.
Only two of these last edit distances achieve the desired result, the Levenshtein distance and the Damerau-Levenshtein distance.
These two differ by the fact that the Damerau-Levenshtein include transpositions in addition to the classical edit operations.
An operation that does not appear in the modifications that a DNA strands can suffer.
Thus, it goes without saying that Levenshtein distance is the most appropriate for our project.

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
That the $op("head")$ function return the first character of a string, and that the $op("tail")$ function return the remaining part of a string after removing the first character.

#todo[illustrate the example]

As an example, let's consider the following task : correct the word "kitten" to form the word "sitting".
One can easily notice that the Levenshtein distance between these two words is three, meaning it takes three operations to convert one word into the other.
Here's a breakdown :
 - The first operation is substituting the "k" in "kitten" with an “s”, changing "kitten" to "sitten".
 - The second operation is substituting the “e” in "sitten" with an "i", transforming "sitten" to "sittin".
 - The final operation is inserting an “g” at the end of "sittin", resulting in "sitting".
In total, three operations (two substitutions and one insertion) are required to transform "kitten" into "sitting", which makes the Levenshtein distance between them equal to three.


== The Myers' Bit-parallel Algorithm <chap_myers_algo>

#todo[maybe add logical gate schema from other paper]

Myers’ bit-parallel algorithm is an efficient method for computing the Levenshtein distance between two sequences.
Unlike traditional dynamic programming approaches which rely on filling a two-dimensional matrix, Myers’ algorithm optimizes this process using bit-parallelism.
Myers’ bit-parallel algorithm represents the state of the computation using bit vectors.
Each bit vector compactly encodes whether a match, substitution, insertion, or deletion is needed at each position in the pattern.
By leveraging bitwise operations, the algorithm efficiently simulates the dynamic programming table updates.

To explain Myers’ algorithm, it is helpful to start with the Wagner-Fischer algorithm.
The Wagner-Fischer algorithm is the standard dynamic programming technique for calculating the edit distance.
It works by breaking the problem into smaller sub-problems and solving them one after the other to retrieve the solution from the original problem.
A matrix is used to store every Levenshtein distance between all prefixes of the string $a$ and $b$, the last computation being the distance between the two full string.

#todo[add wagner_fischer code in annexex]

The matrix in the @fig_grid_wagner-fischer represents the matrix filled by the Wagner-Fischer algorithm between the words "sitting" and "kitten".
The highlighted path shows the most optimized path for moving from one string to the other.
If we want to correct the word "sitting" to "kitten", we can think of a diagonal movement as a substitution (or no operation if the letters are identical), movements to the right as an insertion, and movements downward as a deletion.

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
This can be optimized to $Omicron(n)$ by storing only the current and previous rows of the matrix.
Note that the memory will, in any case, become significant when comparing a lot of data simultaneously.

Now, let's look at how Myers went from computing the $n times m$ Wagner-Fischer matrix, to computing five bit vectors in parallel: $\Eq$, $\Pv$, $\Ph$, $\Mv$, and $\Mh$.
To do this, we need to understand several key principles derived from the traditional $n$ by $m$ matrix.
In the Wagner-Fischer algorithm, when optimizing memory space, we note that a column $C_j$ of the matrix can be computed using only the column $C_(j-1)$ that precedes it.
A related observation is that the difference between adjacent entries in any row or column is either $+1$, $0$, or $-1$.
There is a more general way to present this, found in the 4-Russians algorithm for string comparison.
Formally, we have the _horizontal delta_ $Delta h[i, j]$ as $C[i, j] - C[i, j - 1]$ and the _vertical delta_ $Delta v[i, j]$ as $C[i, j] - C[i - 1, j]$ for all $(i, j) in [1, m] times [1, n]$.
$Delta v$ and $Delta h$ are matrices that represent the traditional Wagner-Fischer matrix, but relative to the preceding cells, vertically or horizontally.
Using several theorems, Myers manages to transform the problem of calculating the Wagner-Fischer matrix into the calculation of the matrix $Delta v$ except for the last step where $Delta h$ is necessary.
But this can be calculated using a simple product on a part of $Delta v$.

// source: link("https://www.gersteinlab.org/courses/452/09-spring/pdf/Myers.pdf", [from gersteinlab.org, ref. URL09]),
#figure(
  caption: [Myers' bit-parallel algorithm dynamic programming (d.p.) matrices],

  image("../figure/myers_matrices.png"),
) <fig_img_myers_matrices>

The @fig_img_myers_matrices shows, on the left, the traditional matrix found in Wagner-Fischer and, on the right, the $Delta v$ matrix and the first and last rows of the $Delta h$ matrix.
The illustration shows that the data in the $Delta v$ matrix are Boolean variables $M$ or $P$.
They represent whether an addition (P) or subtraction (M) of $1$ occurs on a cell.
They cannot both be true (be equal to $1$) at the same time.
To represent a row, simply create a bit vector, hence the bit vectors $\Pv$, $\Ph$, $\Mv$, and $\Mh$, where $v$ and $h$ represent the axes where the operation is performed (vertical or horizontal).
To correctly calculate these bit vectors, it is necessary to know whether the current characters are similar or not.
$\Eq$, a bit vector, is responsible for doing so.
It represents equality between the characters.
$\Eq$ can be calculated with a simple comparison, but to save time on the computation of a column of $Omicron(1)$, it is clever to precompile it into a matrix named $P\eq[sigma]$, with $sigma$ being the alphabet over which the two strings originate.

#align(center)[
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
]

Myers' bit-parallel algorithm has a very good time complexity of $Omicron(n times m/w)$, with $w$ being the length of a machine word, and a space complexity of $Omicron(n)$.
As FPGA don't really have limit about the length of a machine word, `w` can be set to the value of `m`, letting the time complexity of the algorithm to $Omicron(n)$.
This value is one of the reason we used this algorithm.
Another reason is the use of binary operations which simplify the complexity of the implementation on FPGA.
And which speeds up computations since these operations can generally be performed in a single clock cycle.

