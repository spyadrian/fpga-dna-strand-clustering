# Week 10

### Table of contents

1. [Monday 21 July](#monday--21-july)

### Tasks

- [x] Launch oneoligo on FPGA

### Links




## Monday : 28 July

I have the same problems with the LICENSE.
Last time using the `questa_fe` and not `questa_fse` worked but on the Quartus 23.2 there is no `questa_fe`...
I had to install it via the setup, and everything was good.

compilation foireuse pour deux device en meme temps.
faire séparer et apres link

ca marche avec vector add en emu

j'arrive pas a avoir le sycl-ls -> simulator device
j'imagine car il manque un fichier dans le vendors mais va savoir.
peux être que je relance l'install. mais si le hardware fonctionne je skip cette étape puisque je peux checker le bon fonctionnement du code avec l'emulator.

ca fonctionne pas en hardware, error tcl je sais pas quoi

j'ai pu compile un .a d'un autre code.
Le problème doit venir du code.


## Tuesday : 29 July

-> fix bug separate compilation
-> finnish implementation of oneMyers

-> add link

-> make the myers code, clean it
-> can't compile it on hardware, same errors as the other (compile multi thing); quite nice because it mean it's not the multicompilation that sucks
-> I can't compile hardware anymore, idk why ?
-> I dont remember installing or doing something weird on it, even reading my log I can't tell...
-> maybe uninstall everything and reinstall
-> I might be just need to flash it, (not in lspci)
-> trying to remove some var env add by questa (only thing I add to the config (as I remember))
-> it might be the lspci, let's wait tomorrow after the compilation

-> parler utilisation ia lors du projet ? (aujourdhui c'est un sujet qui reviens bla bla bla)


## Wednesday : 30 July

-> lancer plein de compilation :

```bash
icpx -fintelfpga -DFPGA_HARDWARE myers.cpp -Xshardware -Xstarget=a7sk_usm -o myers.fpga ; \
icpx -fintelfpga -DFPGA_HARDWARE onemyers.cpp -Xshardware -Xstarget=a7sk_usm -o onemyers.fpga ; \
icpx -fintelfpga -DFPGA_HARDWARE onemyers-mem.cpp -Xshardware -Xstarget=a7sk_usm -o onemyers-mem.fpga ; \
icpx -fintelfpga -DFPGA_HARDWARE onemyers-mem-dna.cpp -Xshardware -Xstarget=a7sk_usm -o onemyers-mem-dna.fpga ; \
icpx -fintelfpga -DFPGA_HARDWARE onemyers-mem-dna-opti.cpp -Xshardware -Xstarget=a7sk_usm -o onemyers-mem-dna-opti.fpga ; \
icpx -fintelfpga -DFPGA_HARDWARE onemyers-mem-dna-opti-clean.cpp -Xshardware -Xstarget=a7sk_usm -o onemyers-mem-dna-opti-clean.fpga ; \
icpx -fsycl -fintelfpga -fsycl-link=image -DFPGA_HARDWARE -Xshardware -Xstarget=a7sk_usm ../vector-add-sep/kernel-fpga.cpp -o kernel-fpga-hw.a
```

-> résumé :

- `myers.fpga` : memory leaks
- `onemyers.fpga` : memory leaks
- `onemyers-mem.fpga` : memory leaks
- `onemyers-mem-dna.fpga` : worked
- `onemyers-mem-dna-opti.fpga` : worked
- `onemyers-mem-dna-opti-clean.fpga` : worked
- `kernel-fpga-hw.a` (vector-add separate compile) : worked

memory leaks message :

```bash
aoc: Warning RAM Utilization is at 139%!
Error (170019): Project requires 13809 RAM blocks, but the selected device can contain only 13272 RAM blocks
```

`vector-add-sep` worked, it was an issue with the code.
Here are the compile line :

```bash
icpx -fsycl -fPIC -fsycl-targets=spir64 -c kernel-cpu.cpp -o kernel-cpu.o
icpx -fsycl -fintelfpga -fsycl-link=image -DFPGA_HARDWARE -Xshardware -Xstarget=a7sk_usm kernel-fpga.cpp -o kernel-fpga-hw.a 
icpx -fsycl -fintelfpga -o vector-add-sep main.cpp kernel-cpu.o kernel-fpga-hw.a
```

-> work on clean onemyers

-> compile for better one


## Thursday : 31 July

-> add extract + bucket + verif

ok except verif

prepare rapport

new toc : inspire of two sources (add after)

- Introduction
- The Edit Distance Algorithm
  - The distance of Levenshtein
  - The Myers algorithm
- OneAPI
  - oneAPI Overview
  - DPC++ Overview / SYCL
  - Programming with DPC++
- Algorithms: How to solve this problems
  - Original though
  - OneJoin
    - parameters
    - time per steps
  - OneMyers
-> SMID and problem #unroll
-> barrier and the speed improvement
  - (Generation of dataset)
- FPGA : Hardware Architecture and Programming
  - The Agilex 7 Starter Kits
    - description détaillée
    - Séparation région statique / dynamique sur le FPGA
  - The HLS paradigm
    - Usage d’HLS (Vitis) pour générer du RTL à partir de C/C++ ; rôle des pragmas DATAFLOW et PIPELINE.
    - Stratégies de parallélisation : tâches dataflow et pipelinage boucle pour atteindre II = 1.
    - Paramètres de tuning : longueur de séquence, nombre de canaux mémoire, fréquence cible, architecture (PIPELINE vs DATAFLOW), SLR, II.
    - Gestion des transferts PCIe via XRT et buffers DMA.
    - Compression des séquences d’ADN sur 2 bits/base pour optimiser mémoire et bande passante.
  - OFS, OPAE ect...
  - Setup
  - (Dataset used)
- Programming for Mixed Code with CPU and FPGA (maybe before Hardware archit...)
  - Key issues for mixed device
  - FPGA compile feature
  - Compilation flow
- Implementation details
- Problems encountered
  TO REMOVE AND PUT IN CHAP
  - oneAPI Base Toolkit 2025.0 is the last version that support FPGA (week 2)
  - finding right parameters for oneJoin (week 3)
  - PC lock by the dsi (week4)
  - Bucket converging to 0 (week4-5)
  - Silent crash of library (week5)
  - questa fe and fse (week6)
  - problems gcc and libc (week7)
  - simulator mode really slow
  - no .deb -> change to RHEL 8.8, recomended on OFS (week8)
  - Quartus file was generated with 23.2 not 24.x (week9)
  - PC no SRIOV -> change PC (week9)
  - SSD kaput when changing PC -> reinstall (week9)
- Performance model and metrics
  - performance theorique
  - vtune ?
- Experimental Results
  - recall function and precision function
- Conclusions and ...

Est-ce que je parle du projet de semestre ?

Est-ce que je fais une partie ou je dis ce que j'ai du apprendre et comment ?
- C++
- Syclacademi
- OneAPI
- OneJoin


## Friday : 01

Writing some report.


## Saturday : 02

Writing some report.


## Sunday : 03

Same as last day.

