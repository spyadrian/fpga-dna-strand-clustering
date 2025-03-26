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
In the received file, each line corresponds to a DNA strand, as represented in #todo[image X].

#todo[add text entry]

This module is possible in VHDL using file management libraries such as #todo[insert library].
As output, this module provides the inputs to the encoder as an array of text.


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
A conversion example is available in #todo[figure X].

#todo[add example conversion]


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
//(- present performance results compared to the C implementation)

// ...


