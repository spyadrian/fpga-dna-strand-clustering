#import "../conf.typ": *

= VHDL Implementation and hardware Optimization
// - introduce the challenges of implementing string-matching algorithms on FPGAs
// - state the motivation for hardware acceleration and its potential benefits

Implementing a Levenshtein distance calculation algorithm presents several challenges.
Indeed, these types of algorithms are very resource-intensive.
In an FPGA, this translates into a limited number of LUTs.
Even after thoroughly understanding the algorithm and implementing it in C, translating it into VHDL remains a challenging task, as C and VHDL are two very different languages, where certain methods and logic do not work in both.
However, programs exist for translating them, but they are not used in this project. To maximize the speed of the Myers algorithm, it was preferable to do it manually in order to have complete control over the VHDL implementation.

The greatest added value offered by VHDL is the parallelization it provides, but it is also one of the biggest challenges of this project. Performing multiple comparisons simultaneously allows the computation to be divided across multiple logical units, thus optimizing execution time.
Furthermore, the use of pipelining allows processing steps to be chained together without waiting for previous calculations to complete, thus improving throughput and reducing overall system latency.


== Architecture Overview
// - present the overall architecture of the VHDL implementation
// - use a block diagram to illustrate the major components and how they interact
// - describe the data flow, pipelining strategies, and parallelization techniques used.

The project architecture is divided into seven modules, each with its own responsibilities.
A very general diagram can be found in Figure X.

#todo[add diagram]

Each module communicates via well-defined interfaces, allowing for efficient and parallel execution of different tasks.
Some modules operate in a pipeline, allowing for continuous data processing and better overall throughput.
The architecture was also designed to ensure a good scalability, as it might be change during the bachelor's project.


== Module Description
// - explain the different VHDL modules you designed, including their purpose and interaction
// - include key components such as distance calculation, input handling, and output processing

=== File Loader

#todo[add schema]

The file loader is responsible for reading the input file.
This file contains all the DNA strands to be sorted.
In other words, the ones to be used to calculate the Levenshtein distance.
In the received file, each line corresponds to a DNA strand, as represented in @fig_txt_DNA.

#sourced_figure(
  source: link("", []),
  fig: [
    #figure(
      caption: [],
      kind: "File",
      supplement: "File",

      ```txt
ATCTGATGTTACGCGCGACATAATCGCCGAGAAGTGC [...] CAGTCCAAGGCACCGGTAATAGCGAGATGACTGGAG
ATCTGATGTTACGCGCGATAGTAGACACCGCGCCGTT [...] TAGAGAGTACTGAGCGACATAGCGAGATGACTGGAG
ATCTGATGTTACGCGCGACGACTACGTAGATCTATGT [...] TACCTGTATCTGGAGATCATAGCGAGATGACTGGAG
ATCTGATGTTACGCGCGACTCAGACTGCGTTCGGTAA [...] CACCGTAGACAGATCTGTATAGCGAGATGACTGGAG
ATCTGATGTTACGCGCGAGCTCGAGCGACGTCTGCTA [...] CGTCCTCGTTGCTGCAACATAGCGAGATGACTGGAG
                                       ...
      ```
    ) <fig_txt_DNA>
  ]
)

This module is possible in VHDL using file management libraries such as `std` or `ieee`.
As output, this module provides the inputs to the encoder as an array of text.
It's important to note that this module can only be used in simulation.
In a real-life scenario, the data connection would be made using a PCI connection, but this only appears later in the project.


=== Encoder and Decoder

#todo[add schema]

This encoder is a combinational circuit that converts an array containing all text entries representing DNA strands into an array with the same strands but encoded using two bits.
It is used to reduce data complexity by assigning a unique code to each active entry.

#figure(
  caption: [Binary encoding of nucleotides for FPGA processing],

  table(
    columns: (auto, auto),
    align: (center, center),
    inset: (x: 1em),
    table.header([*Nucleotide*], [*Encoding*]),

    [A], [$00$],
    [C], [$01$],
    [G], [$10$],
    [T], [$11$],
  )
) <fig_tab_alphabet_encoding>

Working with bits allows for faster computations and, more importantly, reduces the amount of memory used to store bits.
With a four-character alphabet let each character to be represented by two bits as show in the encoding in the @fig_tab_alphabet_encoding.
A conversion example is available in @fig_img_DNA_to_binary.

#sourced_figure(
  source: link("", []),
  fig: [
    #figure(
      caption: [],

      image("../figure/conversion_ACGT-BIN.png")
    ) <fig_img_DNA_to_binary>
  ]
)

DNAMIC uses a different encoding called CODEC.
It is not used in this case because it is designed to maintain data integrity.
In our case, the two-bit encoding is designed for hardware use.


=== Myers Controller

#todo[add schema]

The Myers controller is only used to manage the Myers Core module.
It manages the inputs and outputs provided to Myers core component, as well as the various timings that must be respected.
In the second part of this project, it will also handle the parallelization of the Myers core module.


=== Myers Core

#todo[add schema]

Myers Core is the heart of the Myers algorithm.
It handles the fundamental Myers calculations, those included in the algorithm loop seen in the @fig_code_myers.
It is detailed in the @chap_core_component.


=== Clustering

#todo[add schema]

The Clustering module assembles DNA strands based on their Levenshtein distance.
It groups together the strands closest to each other, this creates groups in which we assume that each strand comes from the same original strand.
To store these groups, it uses BRAM, which offers fast dual-port access.
When all the groups have been evaluated, it will provide the sorted strands to the decoder.


== Core Component of Myers' Algorithm <chap_core_component>
// - briefly recall the Myers algorithm and its role in calculating the Levenshtein distance
// - describe the structure of the core component, including input, processing, and output
// - discuss how the component handles parallelism or pipelining to maximize throughput
// - go through the critical parts of the VHDL code, explaining how you mapped the algorithm to hardware
// - highlight key optimizations, such as reducing computation cycles or leveraging FPGA-specific features
// - explain how you verified the correctness of the core component through simulations and testbenches

#todo[talk about FPGA characteristique, isolate better the problem and what we are resolving and chaining bloc]

As stated previously, the Myers core component plays a very important role in the system.
It handles the core calculation of the Myers algorithm.
This consists of managing the evolution of the bit vectors as the algorithm progresses until the final score is obtained, i.e., the Levenshtein distance between two strands.
To achieve this, the Myers core is composed of two separate blocks: one for updating the bit vectors, while the other for updating the score.
The reason for separating the component into two blocks is due to the fact that there is a dependency between the calculation of the score and two of the bit vectors.
Those bits vectors must be stable in order to ensure that the score is correctly computed.
To ensure this and maintain a clock frequency as high as possible, a pipelined architecture was developed.

#todo[add schema pipelining]

#todo[explain schema]

To manage the two separate blocks, the VHDL code manages them on two separate processes, respectively, `proc_core` and `proc_score` available in the @app_vhdl_myers.

In normal operation, this process updates the vectors according to the current index `idx_i`, which is used to traverse the sequence.
If `idx_i` is not equal to one, shift operations are applied to `ph` and `mh` to simulate progress in the alignment.
Then, the new vectors `pv` and `mv` are calculated based on the previous states and the results of the `peq_i` operation, which stores information about the character matches between the sequences `s1_i` and `s2_i`.
Finally, the `ph_o` and `mh_o` values are updated to reflect the new vector states, and the score update signals (`add_score_o`, `sub_score_o`) are calculated based on the last element of the `ph_o` and `mh_o` vector.

The `proc_score` process is responsible for managing the evolution of the edit score based on the operations performed by the `proc_core` process. Each clock cycle, this process checks whether either the `add_score_i` or `sub_score_i` signals are active.
If `add_score_i` is 1, then `score_o` is incremented by 1.
Conversely, if `sub_score_i` is active, score_o is decremented by 1.
