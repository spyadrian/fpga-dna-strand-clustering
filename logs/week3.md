# Week 3

### Table of contents

1. [Tuesday 10 June](#tuesday--10-june)
2. [Friday 13 June](#friday--13-june)
3. [Saturday 14 June](#saturday--14-june)

### Tasks

- [ ] Find proper parameters for the algorithm
- [ ] Perform an deep analysis on the algorithm with VTune Profiler
- [ ] Analyse OneJoin algorithm implementation
- [ ] Test the FPGA simulator of SYCL

### Links

- [FPGA Support Package for the Intel](https://www.intel.com/content/www/us/en/developer/articles/release-notes/intel-oneapi-compiler-fpga-add-on-release-notes.html)
- [Compare version Quartus](https://www.intel.com/content/dam/www/central-libraries/us/en/documents/quartus-prime-compare-editions-guide.pdf)
- [Download Quartus Prime Pro 24.2](https://www.intel.fr/content/www/fr/fr/software-kit/826843/intel-quartus-prime-pro-edition-design-software-version-24-2-for-linux.html)
- [OneJoin paper](https://adms-conf.org/2021-camera-ready/marinelli_adms21.pdf)
- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)
- [Altera University Program Teaching Materials](https://www.intel.com/content/www/us/en/developer/topic-technology/fpga-academic/materials.html)


## Tuesday : 10 June

I start by rerun the `dataset-generator` to create three different dataset with diverse data size.
I save the informations the script give on the following table :

| Parameter                          | dna-little-processed.txt | dna-big-processed.txt | dna-giant-processed.txt |
|------------------------------------|-------------------------:|----------------------:|------------------------:|
| Clusters (-n)                      |                     250  |               10 000  |               25 000    |
| Strands / cluster (-c)             |                      30  |                   30  |                   30    |
| **Total strands**                      |                   7 500  |              300 000  |              750 000    |
| Length strands                     |                     207  |                  207  |                  207    |
| **Avg. error %**                       |                   10.32  |                10.37  |                10.36    |
| Substitution %                     |                    4.63  |                 4.64  |                 4.63    |
| Deletion %                         |                    4.22  |                 4.25  |                 4.25    |
| Insertion %                        |                    1.47  |                 1.47  |                 1.47    |
| Avg. segment length (bp)           |                  199.00  |               198.87  |               198.87    |

Even if I understood the algorithm, it's a bit difficult to really sees how every parameters change the output and the behavior of the algorithm.
Here is a table talking about the many parameters there is on the OneJoin algorithm :

### Parameters

_See array below_

### Memory

OneJoin stores `z × m` bytes per embedding and maintains `r` independent embeddings for every read.
For a batch of `B` reads the embedding buffer therefore occupies `B × r × z × m  bytes`.
The implementation also holds the raw reads and the (`t`, `k`, `id`, `i`) tuples returned by the hashing kernels, which are often larger than the embedding payload.
Processing is done batch-by-batch so that the sum of these three buffers fits into accelerator memory.


## Friday : 13 June

As the OneJoin algorithm is probabilistic it's important to understand the *recall* and *precision* function.

### Recall Function

It asks : _"Out of all items that should have been found, how many did we actually retrieve?"_. 
The formula is so :

$$
\text{Recall} = \frac{\text{TP}}{\text{TP} + \text{FN}}
$$

- _True Positives (TP)_ – the items your algorithm got right
- _False Negatives (FN)_ – the missed items that belonged to the positive class but were not retrieved

A high recall (close to 1) means your method rarely misses relevant items, but it says nothing about how much irrelevant stuff you pulled in with them.

### Precision Function

It asks : _"Out of everything we claimed was positive, how many were actually correct?"_

$$
\text{Precision} = \frac{\text{TP}}{\text{TP} + \text{FP}}
$$

- _False Positives (FP)_ – the items your algorithm marked positive even though they were not

A high precision tells you your positive predictions are trustworthy, but it doesn’t guarantee you found them all.

### Pairs

The **pairs per bucket** is the number of unique strand–strand pairs within a bucket.
Each bucket (cluster) contains `s = 30` DNA strands.

$$
\text{Pairs\_per\_bucket} \;=\; \binom{s}{2} \;=\; \frac{s\,(s-1)}{2}
$$

The **real pais total** is the total number of true pairs the algorithm should output for the whole dataset.

$$
\text{Real\_pairs\_total} \;=\; \text{Pairs\_per\_bucket} \times b
$$

The number of real pairs total and pairs per bucket are summarize on this array for each dataset I use :

|                  | dna-little-processed.txt | dna-big-processed.txt | dna-giant-processed.txt  |
| ---------------- | ------------------------ | --------------------- | ------------------------ |
| Pairs per bucket | 435                      | 435                   | 435                      |
| Real pairs total | 108 750                  | 4 350 000             | 10 875 000               |


### Parameters

Here is a better array for all the parameters :

| parameter (Y)            | symbol (X₀) | default value                | brief description                                                       | impact on **speed**                                                                                  | impact on **coverage**<br/>(recall)                 | impact on **precision**      | impact on **false positives** | impact on **true positives** |
| ------------------------ | ----------- | ---------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ---------------------------- | ----------------------------- | ---------------------------- |
| **NUM\_STR**             | *r*         | 7                            | # independent CGK embeddings per read                                   | ↑ linear cost in embedding & LSH; more buckets to sort                                               | Better chance every real pair collides in ≥1 bucket | slight ↓ (more candidates)   | slight ↑ (extra collisions)   | ↑ (fewer FN)                 |
| **NUM\_HASH**            | *z*         | 16                           | # hash functions (OR-construction) per embedding                        | small ↑ (extra hash ops); more candidates                                                            | ↑ (larger OR fan-out)                               | ↓ (more spurious pairs)      | ↑                             | ↑                            |
| **NUM\_BITS**            | *m*         | 12                           | bits sampled inside each hash (AND-construction)                        | negligible per-pair cost; BUT larger *m* makes buckets sparser → ↓ candidate count  ⇒ overall faster | ↓ (over-selective buckets may drop good pairs)      | ↑ (fewer random bucket hits) | ↓                             | ↓ (if too large)             |
| **NUM\_CHAR**            |             | 4 (DNA) / 26 / 37            | alphabet size of the dataset                                            | very small effect (only dictionary lookup)                                                           | —                                                   | —                            | —                             | —                            |
| **K\_INPUT**             | *K*         | 150                          | edit-distance threshold passed to the verifier                          | large ↑ when K grows (verifier DP expands)                                                           | ↑ (accepts farther pairs)                           | ↓                            | ↑                             | ↑                            |
| **SHIFT**                |             | 50                           | edit-band stride used when slicing strings during embedding             | smaller SHIFT → more slices ⇒ slower                                                                 | ↑ (denser coverage of edits)                        | —                            | —                             | ↑                            |
| **NUM\_REP**             | ⌈K/SHIFT⌉   | 3 (150/50)                   | # replicated sub-strings embedded per read                              | ↑ (proportional to NUM\_REP)                                                                         | ↑                                                   | —                            | —                             | ↑                            |
| **--samplingrange (-s)** | *s*         | *required* (init 0)          | highest character position inspected by LSH; determines embedded length | ↑ when s grows (longer strings in GPU memory)                                                        | ↑                                                   | —                            | —                             | ↑                            |
| **--countfilter (-c)**   | *c*         | 1 (initial)                  | min occurrences of the same candidate pair before verification          | ↓ (filters low-support pairs early)                                                                  | slight ↓ (might drop rare true pairs)               | ↑ (keeps high-support pairs) | ↓                             | mild ↓                       |
| **--batch\_size (-b)**   | *B*         | *required* (0 if not given)  | # reads processed together; limited by GPU / RAM                        | can tune GPU occupancy: too small → under-utilised, too big → paging                                 | —                                                   | —                            | —                             | —                            |


## Saturday : 14 June

The choice of `K` is critical: too low and true copies are missed; too high and we accept False positives.
The error rate of our 207nt strands are around 10% (21 char).
Then, the edit-distance between two reads is in average of 42.
Adding a little margin of 6 lend me to get `K = 48` with who I get good result.
The result aren't optimal but for the moment my goal is to use the algorithm with FPGA not to fully optimize the parameters choice.

A good NUM\_REP is around 3.
So I took a SHIFT of 16 to get that.

Skipping the part where a I had a hard time finding those, here are a set of good parameters for the `dna-little-processed` dataset :

```
make update PARAMS="-DDEF_NUM_STR=24 -DDEF_NUM_HASH=28 -DDEF_NUM_BITS=11 -DDEF_NUM_CHAR=4 -DDEF_K_INPUT=48 -DDEF_SHIFT=16"
./onejoin -r test/dna-little-processed.txt -a 2 -d 1 -s 300 -c 1 -b 30
```

I would like to get a set of good parameters for every dataset but time is running so I'll look at it later.


