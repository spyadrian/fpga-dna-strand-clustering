# FPGA Acceleration of DNA Strand Clustering

Bachelor thesis – hepia (HES-SO Geneva), BSc in IT & Communication Systems, embedded systems track, 2025.
Supervisor: Laurent Gantel · In collaboration with UNIGE and the European project **DNAMIC**.

## Context

DNAMIC aims to store digital data in synthetic DNA. After sequencing, reads contain errors (substitutions, insertions, deletions), so strands are amplified by PCR and the copies must be **clustered** back to their original strand. Clustering relies on the **Levenshtein (edit) distance**, which is expensive to compute at scale.

The goal of this thesis is to use an **FPGA** to accelerate this step, using the **OneJoin** and **Tag Matcher** algorithms written in **SYCL / DPC++** (Intel oneAPI) and synthesised with High-Level Synthesis for Intel/Altera FPGAs.

## What's inside

| Folder | Content |
|---|---|
| `programs/` | SYCL implementations of the DNA matcher (buffer and USM versions), Makefile targeting CPU, NVIDIA GPU, FPGA emulator, simulator and hardware, plus a Python results analyser |
| `external/oneoligo-a7sk/` | Fork of the OneJoin SYCL implementation adapted for this work (submodule) |
| `external/dataset-generator/` | DNA dataset generator from UNIGE (submodule) |
| `dataset/` | Small datasets and expected results (the large datasets are not versioned) |
| `semester-project/` | Preliminary semester project: Levenshtein distance on FPGA |
| `report/` | Thesis sources (Typst) |
| `resources/` | Final thesis, summary, poster and project statement (PDF) |
| `logs/` | Weekly work logs |

## Build

Requires the Intel oneAPI Base Toolkit (`icpx`) and, for hardware targets, the FPGA support package.

```bash
git clone --recursive https://github.com/spyadrian/fpga-dna-strand-clustering.git
cd fpga-dna-strand-clustering/programs
make cpu          # run on CPU
make gpu          # NVIDIA GPU (CUDA backend)
make help         # other targets: FPGA emulator / simulator / hardware
```

## Tech

C++17 · SYCL / DPC++ · Intel oneAPI · HLS · Quartus · Python (analysis) · Typst

📄 Full report: [`resources/ISC_EMB_memoire_diplome_Spycher_Gantel_2025.pdf`](resources/ISC_EMB_memoire_diplome_Spycher_Gantel_2025.pdf) · French version of this README: [README.fr.md](README.fr.md)
