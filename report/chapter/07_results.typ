#import "../conf.typ": *

= Results and Performance


== DNA Tag Matcher

The tests were conducted on two main aspects: the accuracy of the algorithm and its speed.
They were performed on a dataset of $897'249$ reference tags.
To simulate the tags obtained from sequencing DNA strands, $100,000$ tags were generated from these references.
These simulated tags were then subjected to $2%$ insertions, $4%$ deletions, and $4%$ substitutions.

The total theoretical number of comparisons to perform amounts to $879'249'000'000$ (almost $9 times 10^11$).
In practice, however, this number is lower, thanks to optimizations added to the algorithm, such as early-stopping.

=== Precision

A good way to measure the accuracy of an algorithm is to use a confusion matrix.
This matrix shows the number of True Positives (TP), False Positives (FP), True Negatives (TN), and False Negatives (FN).
In our context, they represent the following:

- True Positive (TP): A pair correctly predicted
- False Positive (FP): A pair incorrectly predicted
- False Negative (FN): A pair with no prediction
- True Negative (TN): A pair absent from both the predicted and the expected results

In practice, within this context, it is rare to encounter FNs or TNs.
FNs may occur when none of the tag-to-reference comparisons result in a Levenshtein distance below `MAX_LEVENSHTEIN_DISTANCE`.
TNs are even rarer, as they correspond to pairs completely missing from both the predictions and the expected results.
In such cases, it is more relevant to focus primarily on TP and FP.

To obtain a more balanced indicator of performance, it is common to use derived metrics.
Precision is the proportion of correctly identified pairs among all the predicted pairs.
#align(center)[$"Precision" = "TP"/("TP" + "FP")$]
Recall is the model’s ability to retrieve all the relevant pairs present in the expected results.
#align(center)[$"Recall" = "TP"/("TP" + "FN")$]
The F1-score is the harmonic mean of precision and recall, useful when seeking a trade-off between the two.
#align(center)[$"F1" = 2 times ("Precision" times "Recall")/("Precision" + "Recall")$]
The divers results are displayed in the table above.

#figure(
  caption: [DNA Matcher Dataflow],

  image("../figure/dna-matcher-precision-res.png", width: 90%),
)

#todo[discutter resultas]

=== Speed

Pour ce qui est de la rapidité de l’algorithme, trois devices ont été testés et comparés afin de mettre en évidence les différences de performance et d’identifier lequel offre le meilleur rapport comparaison par seconds.
En utilisant toujours le même ensemble de données, voici un graphique représentant la rapidité de l'algorithm DNA Tag Matcher.

#figure(
  caption: [Average time per comparison of DNA Tag Matcher across CPU, GPU and FPGA],

  image("../figure/comparison-per-us.png", width: 90%),
)

#todo[discutter resultats]

- performance with vector-add example
- performance with OneJoin and OneMyers
  - specific programs

=== FPGA Usage <chap_res-dna-tag-usage>

#todo[see report]


== OneJoin

=== Accuracy

...

=== Speed

...

=== FPGA Usage

...

