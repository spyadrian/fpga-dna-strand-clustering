# Accélération par FPGA du Regroupement de Brins d'ADN

## Énoncé

Le stockage de l’information dans l’ADN est un domaine très actif. Cependant les algorithmes pour le décodage permettant de convertir les nucléotides en binaires sont confrontés à des questions de scalabilité. Une des étapes cruciales pour la correction des erreurs lors du décodage est le regroupement des brins d’ADN selon leur similarité. En effet, pour augmenter la correction des erreurs, qui sont nombreuses particulièrement lors du séquençage, une amplification des brins d’ADN par la technique du PCR permet d’avoir plusieurs copies d’un même brin, qui sera sujet à des mutations. Aussi, la technique de regroupement va permettre de rassembler les brins issus d’un même brin initial. Cependant, à un fichier de 2 MB correspond environ 3 millions de brins qu’il faut regrouper. Du fait que les brins sont sujets à 3 types d’erreur, à savoir, substitution, délétion et insertion, une mesure de distance telle que Hamming ne suffit pas pour calculer la similarité entre 2 brins et il faut utiliser la distance de Levenshtein. Cette dernière peut être déterminée selon l’algorithme itératif de Wagner–Fischer ou l’implémentation récursive en Haskell, ou d’autres.

Le travail devra se concentrer sur deux aspects principaux :
   1) Déterminer l’algorithme le plus adapté à une architecture FPGA pour implémenter la mesure de distance de Levenshtein
   2) Paralléliser sur FPGA le regroupement des brins afin de pouvoir étendre par un facteur de 100 leur nombre (300 à 500 millions) tout en garantissant des temps de calcul raisonnables, de l’ordre de quelques heures

Ce projet sera réalisé à l’Université de Genève, dans le contexte du projet européen DNAMIC (dnamic.org).
Mandant : Pierre-Yves Burgi, directeur adjoint à la DiSTIC, responsable du service RISe.

## Liens et Références

- Levenshtein distance:
   - [https://en.wikipedia.org/wiki/Levenshtein_distance]

- Algorithme de Wagner-Fischer:
   - [https://fr.wikipedia.org/wiki/Algorithme_de_Wagner-Fischer]

