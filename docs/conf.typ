// this variable will contains the configuration
#let conf(

  // Parameters
  title: none,
  authors: (),
  orientation: none,
  teachers: none,
  client: none,
  illustration: none,
  source_illustration: [],
  date: datetime.today(),

  doc,
) = {

  // --- GENERAL STYLE ---

  // Default Fonts and Styles
  set text(font: "Times New Roman", size: 12pt, lang: "fr")
  show raw: set text(font: "Courier New", size: 10pt, lang: "fr")


  // Document style
  set page(
    margin: 2.5cm,
    header: text(size: 8pt, fill: color.gray,
      authors + " – " + title + " – " + "Projet de semestre – " + date.display("[month repr:long], [year]"))
  )


  // Paragraph style
  set par(
    justify: true,
    leading: 1.5em,
    spacing: 1.5em,
    first-line-indent: 2em,
  )


  // Grid Styles
  set grid(row-gutter: 1.5em)


  // Heading Styles
  show heading: {
    set text(weight: "bold")
    smallcaps
  }

  show heading.where(level: 1): set align(center)
  show heading.where(level: 1): set text(size: 16pt)
  show heading.where(level: 2): set text(size: 14pt)
  show heading.where(level: 3): set text(size: 12pt)

  show heading.where(level: 1): it => {
    pagebreak(weak: true)

    v(weak: true, 2em)
    block[#it.body]
    v(1.75em)
  }

  show heading.where(level: 2): it => {
    v(weak: true, 2em)
    block(counter(heading).display(it.numbering) + h(2em) + it.body)
    v(1em)
  }

  show heading.where(level: 3): it => {
    v(weak: true, 2em)
    block(h(1em) + counter(heading).display("1.1.a )").split(".").last() + h(4em) + it.body)
    v(1em)
  }


  // Outline Styles
  set outline(depth: 3, indent: auto)
  show outline.entry.where(level: 1): set text(weight: "bold")


  // Figure Style
  set figure(gap: 1.5em)
  show figure.caption: emph
  show figure: it => {
    v(1em)
    it.body
    it.caption
  }


  // --- COVER PAGE ---

  {
    set align(center)
    set text(font: "Arial")
    set page(numbering: none, header: none)
    set par(justify: false, leading: 0.5em)

    // logos
    grid(
      columns: (1fr, 1fr),
      align: (left, right),
      {image("figure/hepia_logo.png", width: 60%)},
      {image("figure/hes-so_logo.png", width: 60%)}
    )

    // title
    v(4em)
    text(size: 16pt, weight: "bold", title)
    v(1em)

    // illustration
    if illustration == none {
      v(25em)
    } else {
      illustration
      v(2em)
    }

    // authors, orientation & date
    text(size: 14pt, "Projet de semestre présenté par")
    v(1em)
    text(size: 16pt, weight: "bold", authors)
    v(2em)
    text(size: 14pt, weight: "bold", "Informatique et systèmes de communication avec orientation en " + orientation)
    v(1.5em)
    text(size: 14pt, weight: "bold", date.display("[month repr:long], [year]"))
    v(2em)

    // teachers and client
    if client == none {

      text("Professeur-e HES responsable \n" + teachers)
    } else {

      grid(
        columns: (1fr, 1fr),
        {
          text(size: 12pt, "Professeur-e HES responsable")
          v(0.5em)
          text(size: 12pt, weight: "bold", teachers)
        },
        {
          text(size: 12pt, "Mandant")
          v(0.5em)
          text(size: 12pt, weight: "bold", client)
        }

      )
    }

    pagebreak()

    set align(left)
    v(1fr)
    text("Caption and source of cover illustration :\n")
    text(style: "italic", source_illustration)
  }

  // --- DOCUMENT ---
  doc
}

#let apply_intro_style(doc) = {
  set page(numbering: "I")

  doc
}

#let apply_chapter_style(doc) = {
  set page(numbering: "1")
  set heading(numbering: "1.1.a")

  show heading.where(level: 1): it => {
    pagebreak(weak: true)

    v(weak: true, 2em)
    if it.numbering != none {block[Chapitre #counter(heading).display("1. ") #it.body]}
    else {block[#it.body]}
    v(1.75em)
  }

  pagebreak()
  pagebreak()
  counter(page).update(1)

  doc
}

#let apply_annexe_style(doc) = {
  show heading.where(level: 1): it => {
    pagebreak(weak: true)

    v(weak: true, 2em)
    block[#it.body]
    v(1.75em)
  }

  doc
}

#let add_brief(
  img: none,
  content: [],
  applicant: [],
  teacher: [],
  entreprise: [],
  internship_agreement: bool,
  confidentiality_agreement: bool,

) = {
  set par(leading: 0.5em)

  content

  align(center, img)

  table(
    columns: (2fr, 3fr),
    align: (left, left),
    stroke: none,
    gutter: 0.5em,

    let str_inter_agr = if internship_agreement == true [oui] else [non],
    let str_conf_agr = if confidentiality_agreement == true [oui] else [non],

    [Candidat-e :], [Professeur-e(s) responsable(s) :],
    [#text(weight: "bold", applicant)], [#text(weight: "bold", teacher)],
    [Filière d'études : ISC], [En collaboration avec : #entreprise],
    [], [Travail soumis à une convention de stage en entreprise : #str_inter_agr],
    [], [Travail soumis à un contrat de confidentialité : #str_conf_agr],
  )
}

