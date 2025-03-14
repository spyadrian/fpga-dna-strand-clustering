#import "conf.typ": *

#show: conf.with(
  title: "FPGA Acceleration of DNA Strand Clustering",
  authors: "Adrian Spycher",
  orientation: "embedded computer systems",
  teachers: "Laurent Gantel",
  client: "DNAMIC; UNIGE, Pierre-Yves Burgi, \n Deputy Director at DiSTIC, Head of the RISe Department",
  illustration: image("figure/illusatration.jpg", width: 77%),
  source_illustration: link("https://www.the-scientist.com/making-dna-data-storage-a-reality-30218", "Making DNA Data Storage a Reality, Catherine Offord, Oct 1, 2017")
)

#show: apply_intro_style

#{
  show outline: set heading(outlined: false)
  outline(title: "Table of Contents")
}

#include "chapter/A_acknowledgements.typ"

#include "chapter/B_statement.typ"

#include "chapter/C_brief.typ"

#include "chapter/D_acronym.typ"

#include "chapter/E_figure.typ"

#include "chapter/F_table.typ"

#include "chapter/G_code.typ"

#include "chapter/H_appendix.typ"

#show: apply_chapter_style

#include "chapter/00_introduction.typ"

#include "chapter/01_algorithms.typ"

#include "chapter/02_implementation.typ"

#include "chapter/03_circuits.typ"

#include "chapter/04_conclusion.typ"

#show: apply_annexe_style

#include "chapter/05_appendix.typ"

#bibliography(style: "ieee", "main.bib")

