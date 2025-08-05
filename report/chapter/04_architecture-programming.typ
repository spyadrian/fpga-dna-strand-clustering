#import "../conf.typ": *

= FPGA : Hardware Architecture and Programming


== The Agilex 7 Starter Kits

The Agilex 7 Starter Kit, abbreviated as A7SK, is a development board created by Terasic.
It leverages the latest Intel (formerly Altera) Agilex 7 SoC FPGA F-Series device, featuring 2.7 million logic elements.
The board offers multiple interfaces including PCI Express 4.0 x8 and up to 16GB of DDR4 memory to provide optimal acceleration.
Additionally, the board includes an FMC+ expansion connector, enabling compatibility with a variety of daughter cards for extended functionality.

The Agilex 7 FPGA fabric delivers 50% higher performance and 40% lower power consumption compared to previous generation devices, making it ideal for demanding workloads.
The board also supports Intel's oneAPI and OpenCL frameworks, allowing developers to easily customize hardware acceleration workloads.
Below is a block diagram showing all the peripherals of the A7SK :

#sourced_figure(
  source: link("https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=142&No=1295&PartNo=2", [Agilex 7 FPGA Starter Kit Specification]),
  fig : [
    #figure(
      caption: [Block diagram of The Agilex 7 Starter Kits],

      image("../figure/a7sk_blockdiagram.jpg", width: 100%)
    )
  ]
)


== OFS, OPAE ect...

Séparation région statique / dynamique sur le FPGA;

presenter OFS OPAE; a quoi ca sert; OPAE C API Library - bibliothèque principale pour l'accès aux FPGA; OPAE SDK - kit de développement avec outils et exemples; Linux DFL Driver - pilote noyau upstream pour la gestion des FPGA; AFU Simulation Environment (ASE) - environnement de simulation; outils (fpgainfo ect...); FIM; AFU; BMC; PIM; avantage developper; platforme


== Setup

partager ma config pc + outils; parler best config donner par ofs; donner les critères pour les version; dépendance; arret FPGA truc oneAPI;
