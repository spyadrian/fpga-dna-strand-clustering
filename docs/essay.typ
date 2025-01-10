#import "conf.typ": *

#show: conf.with(
  title: "TITRE DE VOTRE MÉMOIRE DE PROJET DE SEMESTRE",
  authors: "Adrian Spycher",
  orientation: "Informatique en science de l'information",
  teachers: "Thomas Perrot",
  client: "My client",
  illustration: image("figure/default_illustration.png", width: 50%),
  source_illustration: "source here"
)

#show: apply_intro_style

#outline(title: "Table des matières")

#include "chapter/A_acknowledgements.typ"

#include "chapter/B_statement.typ"

#include "chapter/C_brief.typ"

#include "chapter/D_acronym.typ"

#include "chapter/E_figure.typ"

#include "chapter/F_table.typ"

#include "chapter/G_appendix.typ"

#show: apply_chapter_style

#include "chapter/00_introduction.typ"

#include "chapter/01_chapter-title.typ"

#include "chapter/02_chapter-title.typ"

#include "chapter/03_chapter-title.typ"

#include "chapter/04_conclusion.typ"

#show: apply_annexe_style

#include "chapter/05_appendix.typ"

#bibliography(style: "ieee", "main.bib")

