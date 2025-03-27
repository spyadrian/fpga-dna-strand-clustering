#import "../conf.typ": *

= Implementation and Benchmarking in C
// - explain the purpose of implementing the algorithms in C as a precursor to hardware implementation

It is important to start by understanding and seeing a C implementation of the Wagner-Fischer and Myers algorithm.
First, it allows familiarization with the implemented algorithm, while also providing a better understanding of the data dependencies and links operations that are important during the VHDL implementation.
This also allowed us to compare the speed of these two algorithms on the DNA inputs available in the project.
These implementations also created a database allowing for future testing of the VHDL implementation.


== Implementation Details
// - describe the implementation process for both Wagner–Fischer and Myers algorithms
// - highlight key design decisions, optimizations, and data structures used
// - talk about uint256_t and dockerfile

The Wagner-Fischer and Myers implementations are taken from a study by Fujimoto Seiji, author of Polyleven, a Python library used to calculate the Levenshtein distance.
In this 2020 study, Fujimoto Seiji implements both algorithms in order to compare them, as in this project.
The implementations below are therefore based on these implementations.

=== Wagner-Fischer <chap_wagner-fischer_imp>

The Wagner-Fischer implementation includes several optimizations.
The first is a simple optimization of the space that use the algorithm.
Indeed, in this algorithm, the task is to calculate an $n times m$ matrix, more specifically, the cell located at the bottom right of the matrix.
However, since only the column preceding the one being calculated is required to advance through the matrix, it is not necessary to store the entire matrix.
With this technique, the algorithm goes from using a memory space of $n times m$ to a size of $n$.

A second optimization is the Ukkonen optimization.
It reduces the complexity from $Omicron(n times m)$ to $Omicron(n times k)$, where $k$ is the maximum tolerated distance.
It works by excluding certain cells from the table which are sure to be above $k$.
Normally, cells in the upper-right or lower-left corner.
Making the algorithm compute at most $n(2k + 1)$ cells.
This is well illustrated in the @fig_grid_ukkonen.

#sourced_figure(
  source: link("https://ceptord.net/wagner-fischer/index.html", [Can We Optimize the Wagner-Fischer Algorithm ?, Polyleven, February 2025]),
  fig: [#figure(
    caption: [Wagner-Fischer matrix with Ukkonen optimization],
    grid(
      fill: (x, y) => rgb(
        if x == 0 or y == 0 { "#E0E0E0" }
        else { "#FFFFFF" }
      ),
      columns: (1.3em, ) * 6,
      rows: 1.3em,
      row-gutter: 0em,
      align: center + horizon,

      [],  [],       [*p*],      [*q*],      [*r*],      [*s*],
      [],  [0],      [1],      $ast.op$, $ast.op$, $ast.op$,
      [*a*], [1],      [1],      [2],      $ast.op$, $ast.op$,
      [*b*], $ast.op$, [2],      [2],      [3],      $ast.op$,
      [*c*], $ast.op$, $ast.op$, [3],      [3],      [4],
      [*d*], $ast.op$, $ast.op$, $ast.op$, [4],      [4],
    )
  ) <fig_grid_ukkonen>]
)

On the example between "abdc" and "pqrs" in @fig_grid_ukkonen, we can see that the Ukkonen optimization remove the computation of 12 cells.
So we only need to fill the remaining 13 cells to compute the distance of Levenshtein of the two strings.
The implementation with both optimizations is available in @app_wagner-fischer.


=== Myers' Bit-parallel Algorithm

Myers' algorithm has remained unchanged, so there isn't much to add.
In its implementation, available in @app_myers, we can still notice the use of variables of type `uint256_t`.
Indeed, the DNA strands used are character strings of more than 200 characters and must be represented by bit vectors of the same length, i.e., `uint256_t`.
These caused a problem because, given that a machine word generally does not exceed 64 bits, it is difficult for the _gcc-13_ compiler to handle them.
However, _gcc-14_ offers an extension to the C standard that provides greater flexibility in handling custom-sized integers.
This extension allows the representation of integers of arbitrary width.
The creation of `uint256_t` was therefore possible using the @fig_code_uint256.

#figure(
  caption: [Definition of a 256-bit unsigned integer type using the `_BitInt` keyword.],
  ```C
typedef unsigned _BitInt(256) uint256_t;
  ```,
) <fig_code_uint256>

Since the machine used doesn't run _gcc-14_ by default, it was necessary to create a Docker container.
This approach simplifies the setup process.


== Testing and Benchmarking
// - detail your testing methodology, datasets used, and performance metrics (execution time, memory usage, etc.)
// - present and explain the benchmark results, including graphs and tables

In order to test the two C implementations, a database containing words and their Levenshtein distance is, unfortunately, as necessary as it is difficult to find.
So creating one was more convenient.
To populate the database, a Python script was developed to generate synthetic data.
This script creates two random character strings and calculates their corresponding Levenshtein distance, providing the necessary data for the database.
The first part of this database is filled with the Faker library, which provides random words from a chosen language.
The second part is filled with false strands DNA (_ACGT_) of variable length.
To calculate their Levenshtein distances, the Python library "Levenshtein" was used.
This reliable library is open-source and used by over 11,000 users.
An example of the data in @fig_tab_data_test.

#figure(
  caption: [Example of synthetic data generated for testing C implementations],

  table(
    columns: (1fr, 1fr, auto),
    align: (left, left, center),
    table.header(align(center)[*Text*], align(center)[*Pattern*], [*Levenshtein Distance*]),
    [sometimes], [she], [7],
    [kelm], [hello], [3],
    [CTGACCAG ... ATACGTTG], [GTTAGCCG ... GCGGACCT], [153],
    [TCATTTGC ... CCGTTAGA], [CAGACGGA ... AAGCGACT], [93],
  )
) <fig_tab_data_test>

The test program is a very naive C code.
It retrieves the data and prepares it so it can be used by the two algorithms.
It then feeds it to the algorithm, testing its results against the results contained in the data.
If an error occurs, it reports it.
With more then 1'000 database entries, the programs didn't notice even one error.
*Both implementation were correct*.

The benchmark is a simple C code that calculates the time it takes for the Myers algorithm and the Wagner-Fischer algorithm to compare $n$ data points.
The data it compares are fixed-length strings containing random characters from the following list: "0123456789abcdef". #footnote[A text with only "ACGT" shouldn't change anything.]
The first benchmark launched tested the time it took the algorithms to compare eight data sets of different sizes : 64, 128, 256, 1024, 2048, 4096, 8192 and 32728.
This benchmark was clearly enough to know which algorithm was the most efficient, the data are regrouped on the @fig_img_graph_benchmark.

#figure(
  caption: [Example of synthetic data generated for testing C implementations],

  image("../figure/graph_benchmark.png")
) <fig_img_graph_benchmark>

The graph in @fig_img_graph_benchmark shows the execution time in seconds of the two algorithms to compare a given number of inputs.
Although the spacing between the Wagner-Fischer and Myers bars appears identical across groups of inputs, the scale is actually logarithmic.
This means that for a number of 32,768, there is a factor of $6.82$ between Wagner-Fischer and Myers.
This places Myers far ahead of Wagner-Fischer in terms of speed, which was expected given their time complexity.

#todo[add more]

// - analyze the results to compare the algorithms in terms of performance and resource usage
// - discuss how these results influenced your choice for FPGA implementation


