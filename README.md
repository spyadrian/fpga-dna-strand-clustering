# FPGA Acceleration of DNA Strand Clustering

(French version below)

## Statement

Storing information in DNA is a very active field.
However, decoding algorithms to convert nucleotides into binaries are faced with scalability issues.
One of the crucial steps in error correction during decoding is the grouping of DNA strands according to their similarity.
To increase error correction, which is particularly important during sequencing, DNA strands are amplified using the PCR technique to produce several copies of the same strand, which will be subject to mutations.
The clustering technique is also used to bring together strands from the same initial strand.
Since strands are subject to 3 types of error, namely substitution, deletion and insertion, a distance measure such as Hamming is not sufficient to calculate the similarity between 2 strands and the Levenshtein distance must be used.
The latter can be determined according to the iterative Wagner–Fischer algorithm or the recursive implementation in Haskell, or others.

The work will have to focus on two main aspects:
1) Determine the most suitable algorithm for an FPGA architecture to implement the Levenshtein distance measure
2) Parallelize on FPGA the grouping of strands in order to be able to extend their number by a factor of 100 (300 to 500 million) while guaranteeing reasonable computation times, of the order of a few hours

This project will be carried out at the University of Geneva, in the context of the European DNAMIC project (dnamic.org).
Client: Pierre-Yves Burgi, Deputy Director at DiSTIC, Head of the RISe Department.

## How to build Typst PDF

Install Typst:
```
    sudo apt install typst
```

Compile the PDF:
```
    typst compile doc.typ
```

## Link and Reference

- DNA :
    - https://en.wikipedia.org/wiki/DNA

- Nucleotide :
    - https://en.wikipedia.org/wiki/Nucleotide

- Levenshtein distance
    - https://en.wikipedia.org/wiki/Levenshtein_distance

- Hamming distance
    - https://en.wikipedia.org/wiki/Hamming_distance

- Wagner–Fischer algorithm
    - https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm

- Haskell
    - https://en.wikipedia.org/wiki/Haskell


# Accélération par FPGA du Regroupement de Brins d'ADN

## Énoncé

Le stockage de l’information dans l’ADN est un domaine très actif.
Cependant les algorithmes pour le décodage permettant de convertir les nucléotides en binaires sont confrontés à des questions de scalabilité.
Une des étapes cruciales pour la correction des erreurs lors du décodage est le regroupement des brins d’ADN selon leur similarité. En effet, pour augmenter la correction des erreurs, qui sont nombreuses particulièrement lors du séquençage, une amplification des brins d’ADN par la technique du PCR permet d’avoir plusieurs copies d’un même brin, qui sera sujet à des mutations.
Aussi, la technique de regroupement va permettre de rassembler les brins issus d’un même brin initial.
Cependant, à un fichier de 2 MB correspond environ 3 millions de brins qu’il faut regrouper.
Du fait que les brins sont sujets à 3 types d’erreur, à savoir, substitution, délétion et insertion, une mesure de distance telle que Hamming ne suffit pas pour calculer la similarité entre 2 brins et il faut utiliser la distance de Levenshtein.
Cette dernière peut être déterminée selon l’algorithme itératif de Wagner–Fischer ou l’implémentation récursive en Haskell, ou d’autres.

Le travail devra se concentrer sur deux aspects principaux :
   1) Déterminer l’algorithme le plus adapté à une architecture FPGA pour implémenter la mesure de distance de Levenshtein
   2) Paralléliser sur FPGA le regroupement des brins afin de pouvoir étendre par un facteur de 100 leur nombre (300 à 500 millions) tout en garantissant des temps de calcul raisonnables, de l’ordre de quelques heures

Ce projet sera réalisé à l’Université de Genève, dans le contexte du projet européen DNAMIC (dnamic.org).
Mandant : Pierre-Yves Burgi, directeur adjoint à la DiSTIC, responsable du service RISe.

