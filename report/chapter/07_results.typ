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

Here, a precision of $0.8860$ means that $88.6%$ of the positive predictions are correct.
A recall of $1.0000$ ($100%$) indicates that the algorithm produced a prediction for every input, which can also be observed from the fact that there are no false negatives (FN).
An F1-score of $0.9396$ reflects a good balance between the high precision ($88.6%$) and the perfect recall ($100%$), demonstrating very strong overall performance.

It is also worth noting that with $100'000$ inputs, we end up with $111'391$ outputs.
This increase of $11'391$ outputs (approximately $11%$) is explained by the equidistant references discussed in @chap_imp-levenshtein-dist.
When a tag generates multiple outputs in this way, all but one of these outputs are false predictions, which then make up the majority of the false positives (FP).

Nevertheless, this approach still allows us to recover $98'733$ of the $100'000$ original tags.
This corresponds to nearly $99%$ tag recovery, which is a remarkable result.

=== Speed

Regarding the speed of the algorithm, three devices were tested and compared in order to highlight performance differences and determine which one offers the best average time per comparison.
Using the same dataset throughout, the following chart illustrates the performance of the DNA Tag Matcher algorithm.

#figure(
  caption: [Average time per comparison of DNA Tag Matcher across CPU, GPU and FPGA],

  image("../figure/comparison-per-us.png", width: 90%),
)

The GPU significantly outperforms both the CPU and especially the FPGA for the task of DNA tag comparison, achieving each comparison about 6 times faster than the CPU and nearly 50 times faster than the FPGA.
In this context, the GPU demonstrates an extremely favorable performance-to-cost-to-time ratio.
The CPU remains a versatile solution, but it falls far short of the GPU’s efficiency for this kind of large-scale operation.

The FPGA result, however, is quite surprising.
This type of hardware, when combined with such algorithms, would normally be expected to deliver solid performance.
This outcome highlights a critical point: the FPGA implementation and hardware optimization are not yet properly refined.

=== FPGA Usage <chap_res-dna-tag-usage>

#todo[see report]

- add tableau system resource utilization summary
- add tableau loop

parler de la latence causé par les appel mémoire (global memory)


== OneJoin

Like DNA Tag Matcher, OneJoin was evaluated for its accuracy and speed.
These metrics were already tested in the paper #emph[OneJoin: Cross-Architecture, Scalable Edit Similarity Join for DNA Data Storage Using oneAPI], but it is important to validate them again on the project’s data.

Ideally, this algorithm would have been tested on a dataset of $65'000$ entries, since the project’s pipeline, using DNA Tag Matcher, initially divides the inputs into groups of $65'000$.
Unfortunately, as highlighted in @cha_algo-onejoin, this was not possible.
Instead, a dataset of $7'500$ entries was used.
@fig_tab-dataset-param lists all the parameters of this dataset.

=== Accuracy

To analyze the accuracy of OneJoin, it was necessary first to evaluate the algorithm’s output and adjust its parameters accordingly.
Below is a summary of the most important parameter values that were finally selected.

#figure(
  caption: [],

  table(
    columns: (auto, auto, auto),
    align: (left, center, left),
    table.header(align(center)[*Parameter*], align(center)[*Value*], align(center)[*Brief Description*]),

    [NUM_STR],  [24], [independent CGK embeddings per read],
    [NUM_HASH], [28], [hash functions (OR-construction) per embedding],
    [NUM_BITS], [11], [bits sampled inside each hash (AND-construction)],
    [K_INPUT],  [48], [edit-distance threshold passed to the verifier],
    [SHIFT],    [16], [edit-band stride used when slicing strings during embedding],
  )
)

OneJoin is divided into three main stages: Embedding, LSH, and Verification.
At each of these stages, the number of input DNA strands changes.
It is therefore interesting to observe how this number evolves depending on the chosen input parameters.

The number of DNA strands is equal to $7'500$.
These originally came from $250$ DNA strands containing data, each duplicated $30$ times and subsequently modified with a $10%$ error rate.
At the end of OneJoin, the goal is to obtain enough pairs to reconstruct the $250$ groups corresponding to the original strands.

During the Embedding stage, the input strands are transformed into encoded sequences that can then be processed by LSH.
The total number generated at this stage is calculated as: $"number of inputs" times "NUM_STR" times "K_INPUT" / "SHIFT"$, which in our case give:

#align(center)[$7'500 times 24 times 3 = 540000$]

After applying LSH and a preliminary filtering, $1'522'811$ buckets were generated.
From these buckets, $23'025$ final pairs were obtained.

By combining these pairs with the input DNA strands, it is possible to apply Density-Based Spatial Clustering of Applications with Noise (DBSCAN).
DBSCAN is an algorithm that, building a graph where the pairs are represented as nodes, create clusters formed based on the proximity of the inputs.
After applying DBSCAN, exactly $250$ groups were successfully identified.
Since this procedure was repeated across multiple datasets of 7,500 inputs, these results confirm the accuracy of OneJoin.

=== Speed

rapidité sur les trois différents devices

rapidité théorique avec 65000.

#figure(
  caption: [Time to compute the parallel buckets generation across CPU, GPU and FPGA],

  image("../figure/time-buckets-generation.png", width: 90%),
)


=== FPGA Usage

#todo[TODO]

- add tableau system resource utilization summary
- add tableau loop
