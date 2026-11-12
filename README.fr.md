# Tri de brins d’ADN pour le projet DNAMICS

## Contexte du projet

Le projet DNAMICS vise à explorer le stockage et la récupération d’informations sous forme de brins d’ADN, une approche prometteuse pour réduire l’espace de stockage et la consommation énergétique.
Dans le cadre de ce projet de Bachelor, l'accent est mis sur l’étape de regroupement des brins d’ADN après leur relecture, laquelle implique la duplication des brins afin de limiter les erreurs dues à des insertions, suppressions ou substitutions de nucléotides.
Pour ce regroupement, l’algorithme OneJoin [MA21] a été retenu pour sa faible latence, et l’objectif est d’en accélérer le traitement via une implémentation sur FPGA.
Afin de garantir une meilleure maintenabilité, l’implémentation du cœur de calcul devrait idéalement être réalisée en HLS (High-Level Synthesis), de préférence avec le standard SYCL du groupe Khronos, qui facilite le déploiement multiplateforme (CPU, GPU, FPGA).
Étant donné que SYCL n’est pas officiellement supporté par les outils AMD, le choix s’est porté sur les FPGA d’Altera (Intel), compatibles avec le framework oneAPI et son compilateur DPC++, permettant de cibler efficacement les dispositifs Intel.

## Définition du sujet

Le projet vise à implémenter un algorithme de regroupement de brins d’ADN sur FPGA.
Deux approches ont été envisagées.
La première consiste à utiliser l’implémentation existante en SYCL de l’algorithme OneJoin [MA21], disponible en open source sur le dépôt [Mar25].
Cette solution permettrait de se concentrer sur l’exploration architecturale en jouant sur les paramètres de l’algorithme pour optimiser les performances en termes de latence et de ressources.
La seconde approche propose d’implémenter l’algorithme de Rashtchian et al. [RMR+17], qui ne fournit cependant aucun code source.
Après lecture des deux publications, cette seconde solution apparaît plus floue.
Il est donc préférable de s’orienter vers OneJoin.

Pour son implémentation, le framework oneAPI d’Intel propose deux flots de conception.
Le premier, appelé Acceleration Flow, compile le code SYCL directement en VHDL.
Il génère automatiquement l’ensemble de la plateforme : le kernel de calcul, les interfaces mémoire (DDR), PCIe, ainsi que le firmware du processeur embarqué.
Ce flot est destiné aux développeurs logiciels.
Il est moins flexible et nécessite de longues compilations.
Il est donc mieux adapté au déploiement de kernels déjà validés.
Le second, SYCL HLS Flow, est plus proche du matériel.
Il permet de découper l’algorithme en plusieurs kernels SYCL, intégrés progressivement à une plateforme conçue avec les outils classiques de Quartus.
Cette méthode offre un meilleur contrôle sur les optimisations et facilite l’adaptation au modèle dataflow.
Elle favorise l’utilisation de la mémoire interne du FPGA et limite les accès à la DDR.
Une fois tous les kernels validés, rien n’empêche de basculer vers le Acceleration Flow pour une meilleure maintenabilité.

## Planning prévisionnel

Le planning du projet serait le suivant:
- S1: [12.05 - 23.05]:
  * Analyse détaillé de l’algorithme OneJoin
  * Familiarisation avec les outils OneAPI de Intel et du langage SYCL
- S2: [19.05 - 23.05]:
  * Schéma dataflow de l’algorithme OneJoin
  * Tutoriaux et tests de parallélisation d’un cœur de calcul (Myers par exemple)
- S3: [26.05 - 30.05]: Implémentation et évaluation des différents blocs
- S4: [02.06 - 06.06]: Implémentation et évaluation des différents blocs
- S5: [09.06 - 13.06]: Implémentation et évaluation des différents blocs
- S6: [16.06 - 20.06]: Implémentation et évaluation des différents blocs
- S7: [23.06 - 27.06]: Intégration des blocs dans Quartus
- S8: [30.06 - 04.07]: Intégration des blocs dans Quartus
- S9: [07.07 - 11.07]: Mesure des performances (Latence, consommation)
- S10: [14.07 - 18.07]: Congés (peut être déplacé ailleurs)
- S11: [21.07 - 25.07]: Congés (peut être déplacé ailleurs)
- S12: [28.07 - 01.08]: Déploiement des kernels avec le flot Acceleration F low
- S13: [04.08 - 08.08]: Semaine tampon - à définir suivant l’avancé du projet
- S14: [11.08 - 15.08]: Finalisation de la rédaction de la thèse
- S15: [18.08 - 22.08]: 20 août - Rendu de la thèse de Bachelor
