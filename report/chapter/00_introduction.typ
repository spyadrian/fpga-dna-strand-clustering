#import "../conf.typ": *

#heading(level: 1, numbering: none, [Introduction])

// --- Contextualize the Field ---
// - general problem
// - introduce project
// - why is DNA strand clustering important?

In recent years, the amount of data has continued to increase to the point where, today, we have huge infrastructures dedicated to information storage.
These infrastructures are the cause of enormous energy waste.
However, it's difficult to eliminate them given that sectors such as education, medicine, and others depend on them.
With today's technology, we are now capable of storing data in synthetic Deoxyribonucleic acid (DNA).
This method overcomes many of the problems that come with traditional data storage, especially knowing that all data on earth can be stored in a small test tube.

A European project called DNAMIC aims to replace these infrastructures by a mobile, self-contained, future-proof microfactory for DNA data archiving.
This microfactory would only be finished after implementing the six steps that constitute it, that is, encoding, synthesis, amplification, storage, sequencing and finally, decoding.

// source: link("https://www.youtube.com/watch?app=desktop&v=gNv72a1ugiA", [from youtube.com, ref. URL02]),
#figure(
  caption: [Schema of the six steps constituting the micro-factory of the DNAMIC project],

  image("../figure/micro-factory_steps.png")
)

The first goal of DNAMIC is to archive some of the data from Yareta, the archive portal for Geneva's institutions of higher learning.
It provides a comprehensive solution for archiving, preserving, and sharing research data for researchers from all Geneva's higher education institutions, including the University of Geneva (UNIGE) and HES-SO Geneva.
As they are archive and preserve data in the long term, stocking their data in the DNA would be a more sustainable and environmentally friendly solution, replacing much of the energy waste caused by their current data center.

One of many difficulties this project encounters is located at a sub-step between the sequencing and decoding steps, that we can call the sequence assembly.
The reading of DNA strands is performed using a nanopore device, such as the MinION shown in @fig_img_MinION, a technology capable of reading 100 to 200 DNA strands simultaneously with an error rate of about 10 percent.
In addition to those errors, DNA can also undergo mutations.
These errors must then be corrected to maintain data integrity.

// source: link("https://nanoporetech.com/products/sequence/minion", [from nanoporetech.com, ref. URL03]),
#figure(
  caption: [The MinION nanopore sequencer by Oxford Nanopore Technology],

  image("../figure/minION_nanopore.png", width: 50%)
) <fig_img_MinION>

To address this issue, engineers of DNAMIC have chosen to use the PCR technique to generate multiple copies of each DNA strand, enabling error correction in subsequent steps.
At this stage of the project, sequence assembly becomes essential.
This seemingly small but crucial step is responsible for clustering strands originating from the same initial sequence.

// --- Define the Specific Problem ---
// - state problem address
// - why traditional methods (like Hamming distance) are insufficient
// - how Levenshtein distance is better
// - mention the goal of the project

DNA strand clustering is a well-known problem that generates a lot of scientific debate due to its complexity and importance in the field of DNA data storage and sequencing.
To achieve clustering, researchers draw parallels with techniques used in spell-checking tools, where differences between two text entries are calculated.
This metric can be viewed as a score, where a lower value indicates a closer match.
Unlike spell-checking tools, where simple differences can be sufficient, DNA strand clustering faces other challenges.
Due to the variability introduced throughout the pipeline, DNA strands are not only prone to substitution errors (where one nucleotide is replaced by another) but also to deletion (where one or more nucleotides are missing) and insertion (where extra nucleotides are added).
To address these alterations, more advanced distance measures must be employed, in our case, the Levenshtein distance.
Today, and especially in our context, the question is no longer how to calculate this metric but how to succeed in calculating it in the shortest possible time.
This project aims to support DNAMIC by exploring hardware acceleration techniques with Field-Programmable Gate Arrays (FPGAs) to optimize the calculation of the Levenshtein distance in order to efficiently manage large volumes.
Increasing the number of DNA strands managed by a factor of 100 (between 300 and 500 million) while ensuring reasonable computation times of around a few hours.

The successful implementation of these improvements could have a significant impact on the DNAMIC project and the broader field of DNA data storage.
By leveraging FPGA-based acceleration, large-scale DNA clustering will be feasible within practical time constraints.
This advancement would enable researchers to process and classify vast datasets without compromising accuracy.

// --- Old and New Approach ---
// - define what was the goal of my semester project
// - define my new goals/approach

During my semester project, the goal was to find and start implementing the most relevant algorithms for this problem in Very High Speed Integrated Circuit (VHSIC) Hardware Description Language (VHDL).
To achieve this, we began with an initial research phase, which allowed us to identify the most suitable algorithm for calculating the Levenshtein distance: Myers' Bit-parallel Algorithm.
After fully understanding the algorithm and implementing it in C, the next objective was to implement it in VHDL as part of my Bachelor’s project.

However, one of the main problems with this approach was that, regardless of how fast the algorithm ran, with the number of DNA strands $N$, we would always need to perform $N^2$ comparisons.
This poses a significant issue, because as the number of DNA strands $N$ grows large, it quickly becomes impossible to carry out this many comparisons.
In other words, this approach does not scale well.
Therefore, another method was implemented instead: the approach used in the OneJoin algorithm, which utilizes a pre-processing step to limit the number of comparisons.

// --- State Objectives or Contributions ---
// - clearly define the main objectives
// - increase the number of strands handled

This document is organized into three main parts.
The first part introduces the key technical concepts needed to understand the project.
The first chapter covers fundamental algorithms like the Levenshtein edit distance and Myers’ Bit-parallel algorithm while the second chapter presents the theoretical solutions for the DNAMIC challenges, including the OneJoin and OneMyers approaches.

The second part focuses on the technologies used.
The Chapter three and four details the FPGA hardware architecture and setup, and explains the OneAPI programming framework, highlighting SYCL and the Data Parallel C++.
A dedicated chapter discusses the practical usage, and the program’s compilation process involving both CPU and FPGA.

The final part presents the project’s implementation and performance results.
Those last two chapters describe how the algorithms were applied, optimized and analyze.
The results are discussed in detail and illustrated with graphs to clearly demonstrate the impact of the various optimizations.

