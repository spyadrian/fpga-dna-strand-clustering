#import "conf.typ": *

#show: conf.with(
  title: [FPGA Acceleration of DNA Strand Clustering],
  authors: [Adrian Spycher],
  orientation: [embedded computer systems],
  teachers: [Laurent Gantel],
  client: [UNIGE, Pierre-Yves Burgi, \ Deputy Director at DiSTIC, Head of the RISe Department],
  date: [Mars, 2025],
  illustration: image("figure/illusatration.jpg", width: 80%),
  source_illustration: link("https://www.the-scientist.com/making-dna-data-storage-a-reality-30218", "Making DNA Data Storage a Reality, Catherine Offord, Oct 1, 2017"))

#show: introduction

#include "chapter/A_list-of-contents.typ"

#include "chapter/B_dedication.typ"

#include "chapter/C_acknowledgements.typ"

#include "chapter/D_summary.typ"

#include "chapter/E_list-of-acronyms.typ"

#include "chapter/F_list-of-figures.typ"

#include "chapter/G_list-of-tables.typ"

#include "chapter/H_list-of-appendices.typ"

#show: chapter

#include "chapter/00_introduction.typ"

#include "chapter/01_algorithms.typ"

#include "chapter/02_implementation.typ"

#include "chapter/03_circuits.typ"

#include "chapter/04_conclusion.typ"

#show: appendix

#include "chapter/05_appendix_1.typ"

#include "chapter/05_appendix_2.typ"

#include "chapter/05_appendix_3.typ"

#show: bibli

#include "chapter/I_bibliography.typ"

