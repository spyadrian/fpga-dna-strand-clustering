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


= Remerciements

Formulez ici vos remerciements aux personnes qui vous ont aidé dans la réalisation de votre travail. Les remerciements sont rédigés dans le style "Corps de texte".

= Énoncé du sujet
#lorem(100)

= Résumé
#add_brief(
  teacher: "Spycher Adrian",
  applicant: "Spycher Adrian",
  entreprise: "Spycher SA",
  internship_agreement: false,
  confidentiality_agreement: false,

  img: image("figure/default_illustration.png", width: 45%),
  content: [

    #lorem(250)
  ],
)

= Liste des acronymes
#grid(
  columns: (1fr, 4fr),
  align: (left, left),

  [URL], [Uniform Resource Locator],
)

#outline(title: "Liste des illustration", target: figure.where(kind: image))

#v(5em)

#block[#text(weight: "bold", "Références des URL")]
#grid(
  columns: (1fr, 4fr),
  align: (left, left),

  [URL01], [#link("link")[link]],
)


#outline(title: "Liste des tableaux", target: figure.where(kind: table))

#v(5em)

#block[#text(weight: "bold", "Références des URL")]
#grid(
  columns: (1fr, 4fr),
  align: (left, left),

  [URL01], [#link("link")[link]],
  [URL02], [#link("link")[link]],
  [URL03], [#link("link")[link]],
  [URL04], [#link("link")[link]],
)

= Liste des annexes
#grid(
  columns: (1fr, 4fr),
  align: (left, left),

  [Annexe 1], [Helloworld.c],
)

#show: apply_chapter_style

#[
  #set heading(numbering: none)
  = Introduction
]
#lorem(300)


= Titre du chapitre

#lorem(10)

#lorem(30)

== Titre de niveau 2
#lorem(50)

#figure(
  image("figure/hepia_logo.png", width: 75%),
  caption: "Hepia logo"
)

=== Titre de niveau 3
#lorem(50)

=== Titre de niveau 3
#lorem(50)

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    [hahaha], [hahaha], [hahaha],
    [hahaha], [hahaha], [hahaha],
    [hahaha], [hahaha], [hahaha],
  ),

  caption: "it's a table !",
)

== Titre de niveau 2
#lorem(50)

=== Titre de niveau 3
#lorem(50)

=== Titre de niveau 3
#lorem(50)

== Titre de niveau 2
#lorem(50)

=== Titre de niveau 3
#lorem(50)

=== Titre de niveau 3
#lorem(50)

= Titre du chapitre
#lorem(50)

== Titre de niveau 2
#lorem(50)

= Titre du chapitre

== Titre de niveau 2
#lorem(50)

= Conclusion
#lorem(50)

#show: apply_annexe_style

= Annexes

== Annexe 1

== Annexe 2

== Annexe 3

= Références documentaires


/*
== What is my purpose ?
#lorem(50)

== Difference between DNA sequence alignment and finding the most similar sequences
I'm talking about that because I went the wrong way at first.
As Needleman-Wunsch algorithm or Smith-Waterman.

= Algorithms

== Wagner-Fischer
#lorem(25)

== Myers' Algorithm
#lorem(25)

= Optimization
Code example:
```
code {
    println("Hello World!");
}
```
*/
