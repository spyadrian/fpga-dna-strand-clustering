= Statement of the Subject

Storing information in DNA is a very active field.
However, decoding algorithms to convert nucleotides into binaries are faced with scalability issues.
One of the crucial steps in error correction during decoding is the grouping of DNA strands according to their similarity.
To increase error correction, which is particularly important during sequencing, DNA strands are amplified using the PCR technique to produce several copies of the same strand, which will be subject to mutations.
The clustering technique is also used to bring together strands from the same initial strand.
Since strands are subject to 3 types of error, namely substitution, deletion and insertion, a distance measure such as Hamming is not sufficient to calculate the similarity between 2 strands and the Levenshtein distance must be used.
The latter can be determined according to the iterative Wagner–Fischer algorithm or the recursive implementation in Haskell, or others.
The work will have to focus on two main aspects:

- Determine the most suitable algorithm for an FPGA architecture to implement the Levenshtein distance measure
- Parallelize on FPGA the grouping of strands in order to be able to extend their number by a factor of 100 (300 to 500 million) while guaranteeing reasonable computation times, of the order of a few hours

This project will be carried out at the University of Geneva, in the context of the European DNAMIC project (dnamic.org).
Client: Pierre-Yves Burgi, Deputy Director at DiSTIC, Head of the RISe Department.
