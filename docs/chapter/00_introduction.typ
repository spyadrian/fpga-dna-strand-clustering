#import "../conf.typ": *

#heading(level: 1, numbering: none, [Introduction])

// --- Contextualize the Field ---
// - general problem
// - introduce project
// - why is DNA strand clustering important?

In recent years, the amount of data has continued to increase to the point where, today we have huge infrastructures dedicated to information storage.
These infrastructures are the cause of enormous energy waste.
However, it's difficult to eliminate them given that sectors such as education, medicine, and others depend on them.
With today's technology, we are now capable to store data in synthetic DNA.
This methods overcome many of the problem that come with traditional data storing, especially knowing that all terrestrial data can be stored in a small test tube.

An European project called DNAMIC aims to replace these infrastructures by a mobile, self-contained, future-proof microfactory for DNA data archiving.
This microfactory would only be finished after implementing the six steps that constitute it, that is, encoding, synthesis, amplification, storage, sequencing and, finally, decoding.

#sourced_figure(
  source: link("https://www.youtube.com/watch?app=desktop&v=gNv72a1ugiA", [State of the Art DNA Data Storage | DigNA Webinar Series (Webinar 1), PEARL-DNA, Youtube, March 2025]),
  fig : figure(
    caption: [Schema of the six steps constituting the micro-factory of DNAMIC],

    image("../figure/micro-factory_steps.png")
  )
)

One of many difficulty that have this project is located at a sub-step between the sequencing and decoding steps, that we can call the sequence assembly.
After storing the synthetic DNA for the necessary time, it must be read.
This is done using a Nanoport, a technology that can read 100 to 200 strands of DNA simultaneously at a cost of 10 percent error.
After storing the synthetic DNA for the necessary time, it must be read.
In addition to read errors, DNA can also undergo mutations.
These errors must then be corrected to maintain data integrity.

To address this issue, engineers at Genomika, a biotechnology company, have chosen to use the PCR technique to generate multiple copies of each DNA strand, enabling error correction in subsequent steps.
At this stage of the project, sequence assembly becomes essential.
This seemingly small but crucial step is responsible for clustering strands originating from the same initial sequence.

// --- Define the Specific Problem ---
// - state problem address
// - why traditional methods (like Hamming distance) are insufficient
// - how Levenshtein distance is better
// -mention the goal of the project

DNA strand clustering is a well-known problem that generates a lot of scientific debate due to its complexity and importance in the field of DNA data storage and sequencing.
To achieve clustering, researchers draw parallels with techniques used in spell-checking tools, where differences between two text entries are calculated.
This metric can be viewed as a score, where a lower value indicates a better result.
Unlike spell-checking tools where simple differences can be sufficient, DNA strand clustering faces other challenges.
Due to the variability introduced throughout the pipeline, DNA strands are not only prone to substitutions errors (where one nucleotide is replaced by another) but also to deletion (where one or more nucleotides are missing) and insertion (where extra nucleotides are added).
To address these alteration, more advanced distance measures must be employed, in our case, the Levenshtein distance which is capable to operate the three errors type.
Today, and especially in our context,, the question is no longer how to calculate this metric but how to succeed in calculating it in the shortest possible time.
This project aims to support DNAMIC by exploring hardware acceleration techniques to optimize the calculation of the Levenshtein distance.

// --- State Objectives or Contributions ---
// - clearly define the main objectives
// - increase the number of strands handled

To accomplish this goal, the first step is to make an initial research phase.
This phase will focus on investigating and analyzing various algorithms to determine which one is the most suitable for calculating the Levenshtein distance, taking into account the compatibility of the algorithm with hardware acceleration.

The second step involves parallelizing the DNA strand clustering process as much as possible on an FPGA in order to efficiently manage large volumes.
Increasing the number of DNA strands managed by a factor of 100 (between 300 and 500 million) while ensuring reasonable computation times of around a few hours.

// --- Significance of the Project ---
// - explain potential impact on DNAMIC

#todo[explain the potential impact on the DNAMIC project and how successfully implementing these improvements will advance DNA data storage technology.]

#todo[add methodology work]

// --- Outline the Paper Structure ---

#todo[outline Paper Structure]

