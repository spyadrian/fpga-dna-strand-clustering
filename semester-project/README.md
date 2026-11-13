# Semester Project – Levenshtein Distance on FPGA

Preliminary study for the bachelor thesis (hepia, spring 2025): choosing the edit-distance algorithm best suited to an FPGA, and a first hardware implementation of it.

📄 [Report (48 pages)](docs/report.pdf)

## Content

- **Algorithm study** – Levenshtein distance algorithms compared (Wagner–Fischer, Smith–Waterman, Bitap, BLAST, Myers' bit-parallel algorithm…). **Myers' bit-parallel algorithm** was selected: one of the fastest, and made of bitwise operations that map well to hardware.
- **C implementations and benchmark** (`programs/`) – Wagner–Fischer vs Myers on generated DNA data, run in Docker.
- **VHDL design** (`circuits/`) – architecture of the accelerator for a Digilent Nexys Video board, with the **Myers core** implemented first: file loader, Myers core, clustering logic and their testbenches.

## Structure

```
├── programs/   C implementations, benchmark, test bench, data generator (Python), Dockerfile
├── circuits/   VHDL sources, testbenches, constraints and Tcl scripts to create the Vivado project
├── data/       generated DNA datasets
└── docs/       report (PDF)
```

## Build

```bash
cd programs && make usage        # list the benchmark targets (make run: generate data + benchmark in Docker)
cd circuits && make create-project   # recreate the Vivado project
```

The Vivado Tcl helper scripts (`utils.tcl`, `prompt_colors.tcl`, and the base of `create_project.tcl`) are by Laurent Gantel (hepia).
