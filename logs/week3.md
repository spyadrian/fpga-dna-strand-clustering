# Week 3

### Table of contents

1. [Tuesday 10 June](#tuesday--10-june)

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

| Parameter                | Default value (code)    | Impact in the algorithm                                                                                                                                                   | Paper symbol |
| ------------------------ | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| **DEF\_NUM\_STR**        | `7`                     | Number `r` of CGK-Embedding strings generated per read. More embeddings give additional parallel “views” of a sequence, raising recall but also memory use and embedding time. | `r`        |
| **DEF\_NUM\_HASH**       | `16`                    | Number `z` of LSH hash functions applied to each embedded string. A larger `z` improves filtering selectivity (fewer false positives) at the cost of longer embedding time.    | `z`        |
| **DEF\_NUM\_BITS**       | `12`                    | Number `m` of bit positions sampled by each LSH function. A higher `m` produces finer (smaller) buckets.                                                                       | `m`        |
| **DEF\_NUM\_CHAR**       | `4` (DNA), `26`, `37` … | Alphabet size (e.g. A,C,G,T → 4 for DNA). Used to index characters in the embedding lookup tables.                                                                               | \|Σ\|        |
| **DEF\_K\_INPUT**        | `150`                   | Maximum edit-distance threshold `K` used in the exact verification stage; governs error tolerance.                                                                             | `K`        |
| **DEF\_SHIFT**           | `50`                    | Length (in bases) of one embedded “block”. Determines `NUM_REP = ceil(K/SHIFT)` (number of substrings per read).                                                                 | SHIFT        |
| **--samplingrange (-s)** | — (required)            | Highest character index that is embedded. Sets the sliding window examined in each read and sizes all dependent structures (p-matrix, random strings, etc.).                     | —            |
| **--countfilter (-c)**   | — (required)            | Frequency filter `T`: a read pair becomes a candidate only if it co-occurs in at least `T+1` buckets; applied during the `remove_if` on the candidate vector.                  | `T`        |
| **--batch\_size (-b)**   | — (required)            | Maximum number of reads processed per batch. Affects buffer size and the host/device parallelism granularity.                                                                    | —            |

### Memory

OneJoin store `z × m` char (1B) for `r` embeddings.
The memory is then driven by the equation `N × r × z × m`, `N` being the number of reads.
Since buffers must fit into GPU/CPU memory, OneJoin splits the input into **batches**.
Each batch allocates `batch\_size × r × z × m` bytes for embedding plus space for buckets.
The code creates these buffers in batches to avoid exceeding hardware limits.

### Precision

`r` is the number of embeddings (Hamming sequence).
Decreasing `r` reduces coverage but greatly speeds up the embedding step.
`z` is the number of AND-hashes performed on an embedding.
The higher `z`, the less likely two different strings share all their hashes, hence false positives go down and precision go up.
Each hash observes `m` positions in the embedding.
A larger `m` means: lucky collision ↓, precision ↑, but the size of the buckets increases because the key is longer.

### In Practice

Finding “the” right setting comes down to balancing these levers:

1. set the memory target (GPU/CPU),
2. choose the triplet (`r`, `z`, `m`) according to the desired precision,
3. adapt **batch\_size** and **countfilter** to respect memory and time limits.


