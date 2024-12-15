= Notes

== Wagner–Fischer algorithm

- dynamic programming -> déconstruit un problème en sous problème qui mis ensemble donne le meme resultats
- calcul la distance de Levenshtein
- rapidité de |a|x|b|

- x-axis -> destination
- y-axis -> sources

== Myers' algorithm

- bit vector
- bit operation
- utilise toute une variété d'optimisation (Ukkonen -> keep track of active column to avoid working on subsequent cells)
- rapidité max (km), m destination, k Levenshtein max

The main idea of following the bit-vector algorithm is to parallelize the dynamic programming matrix.
We will compute the column as a whole in a series of bit-level operations. In order to do so, we need to

    1. encode the dynamic programming matrix using bit vectors
        - créer 3 tableau contenant la différence consecutive des cases du tableau de base (adj, vert, diagonal)
        - en tirer 5 variable qui definisse le tableau
    2. resolve the dependencies (especially within the columns)

The binary encoding is done by considering the differences between consecutive rows and columns instead of their absolute values.

== Notes

sequencage :

- ilumina -> sequence de 100 a 200 nucleotide
- nanoport -> sequence plus que 200, mais 10% d'erreur

coverage :

- 40 - 50 copie,
- PCR pas la meme proba de dupliqué tous les brins

- clustering avec flux d'information (plus tard)

