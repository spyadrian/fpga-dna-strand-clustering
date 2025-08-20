#let conf(

  title: none,
  authors: (),
  orientation: none,
  teachers: none,
  client: none,
  illustration: none,
  source_illustration: [],
  date: (),

  doc,
) = {


  // -------------------------------------------------------------------------
  // GENERAL DOCUMENT STYLE
  // -------------------------------------------------------------------------

  // font
  set text(font: "Times New Roman", size: 12pt, lang: "en")
  show raw: set text(font: "Consolas", size: 11pt, lang: "en")
  show raw.where(block: true): set par(justify: false, spacing: 1em, leading: 1em)
  set raw(tab-size: 4)

  let current-chapter-title() = context {
    let headings = query(heading.where(level: 1).before(here()))
    if headings != () {headings.last().body}
  }

  // document
  set page(
    margin: 2.5cm,
    header: text(size: 8pt, fill: color.gray, [#authors – #title #h(1fr)]) // #current-chapter-title()
  )

  // paragraph
  set par(
    justify: true,
    leading: 1.5em,
    spacing: 2.5em,
    // first-line-indent: 2em,
  )


  // -------------------------------------------------------------------------
  // HEADING STYLES
  // -------------------------------------------------------------------------

  show heading: set text(weight: "bold")
  show heading.where(level: 1): set align(center)
  show heading.where(level: 1): set text(size: 16pt)
  show heading.where(level: 2): set text(size: 14pt)
  show heading.where(level: 3): set text(size: 12pt)

  show heading.where(level: 1): it => {

    pagebreak(weak: true)
    it
    v(weak: true, 2.5em)
  }

  show heading.where(level: 2): it => {

    v(weak: true, 2.5em)
    block(counter(heading).display(it.numbering) + h(weak: true, 1.5em) + it.body)
    v(weak: true, 1.5em)
  }

  show heading.where(level: 3): it => {

    v(weak: true, 2.5em)
    block(counter(heading).display("1.1.a )").split(".").last() + h(weak: true, 1.5em) + it.body)
    v(weak: true, 1.5em)
  }

  show heading.where(level: 4): it => {
    set heading(numbering: none)

    v(weak: true, 2.5em)
    block(it.body)
    v(weak: true, 1.5em)
  }


  // -------------------------------------------------------------------------
  // OUTLINE STYLES
  // -------------------------------------------------------------------------

  set outline(depth: 3, indent: 2em)
  show outline: set heading(outlined: true)
  show outline.entry.where(level: 1): set text(weight: "bold")


  // -------------------------------------------------------------------------
  // FIGURE AND OTHERS
  // -------------------------------------------------------------------------

  // figure
  set figure(gap: 1.5em)
  show figure.caption: emph
  show figure.where(kind: image) : set figure(supplement: "Figure")
  show figure.where(kind: raw) : set figure(supplement: "Code")

  // show figure: it => {
  //   v(1em)
  //   it.body
  //
  //   set align(left)
  //   it.caption
  // }

  // grid
  set grid(row-gutter: 1.5em)
 
  // math
  set math.equation(numbering: "(1)", supplement: [Eq.])
  set math.cases(gap: 0.5em)

  // table
  show table: set par(justify: false, spacing: 0.5em, leading: 0.5em)
  set table(stroke: 0.5pt)
  set list(marker: [--], indent: 1.5em)
  set enum(indent: 1.5em)

  // -------------------------------------------------------------------------
  // COVER PAGE
  // -------------------------------------------------------------------------

  {
    set page(numbering: none, header: none)
    set par(leading: 0.5em, spacing: 2em)
    set align(center)

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

    // illustration
    v(1fr)
    if illustration != none [#illustration #v(1fr)]

    // authors, orientation & date
    text(size: 14pt, [Bachelor project presented by])
    v(0em)
    text(size: 16pt, weight: "bold", authors)
    v(1em)
    text(size: 14pt, weight: "bold", [Computer science and communication systems with orientation in #orientation])
    v(0em)
    text(size: 14pt, weight: "bold", date)
    v(1em)

    // teachers and client
    grid(
      columns: (1fr, 1fr),
      [Teacher HES in charge #v(0em) *#teachers*],
      if client != none [Client #v(0em) *#client*]
    )

    pagebreak()

    set align(left)
    v(1fr)
    text("Source of cover illustration :\n")
    text(style: "italic", source_illustration)
  }

  // document
  doc
}


// -------------------------------------------------------------------------
// NEW COMPONENTS
// -------------------------------------------------------------------------

// #let sourced_figure(source: [], fig: figure) = {
//   set par(first-line-indent: 0em)
//   fig
//
//   emph[_Source_ : #source]
// }

#let todo(body) = {
  set text(fill: red, weight: "bold", style: "italic")

  highlight(upper(body))
}

// -------------------------------------------------------------------------
// INTRODUCTION STYLE
// -------------------------------------------------------------------------

#let introduction(body) = {
  set page(numbering: "I")
  set heading(numbering: none)

  body
}


// -------------------------------------------------------------------------
// CHAPTER STYLE
// -------------------------------------------------------------------------

#let chapter(body) = {

  set page(numbering: "1")
  show heading: set heading(numbering: "1.1.a")

  show heading.where(level: 1): set heading(
    numbering: num => "Chapter " + numbering("1 : ", num),
    supplement: "Chapter"
  )

  show ref: it => {
    let el = it.element
    if el == none or el.func() != heading or el.level != 1 { return it }

    let heading-levels = counter(heading).at(el.location())
    let body = numbering(n => [#el.supplement #n], ..heading-levels)

    link(el.location(), body)
  }

  counter(page).update(1)
  counter(heading).update(0)

  pagebreak()
  body
}


// -------------------------------------------------------------------------
// APPENDIX STYLE
// -------------------------------------------------------------------------

#let appendix(body) = {

  show heading.where(level: 1): set heading(
    numbering: num => "Appendix " + numbering("1 :", num),
    supplement: "Appendix",
  )

  show ref: it => {
    let el = it.element
    if el == none or el.func() != heading or el.level != 1 { return it }

    let heading-levels = counter(heading).at(el.location())
    let body = numbering(n => [#el.supplement #n], ..heading-levels)

    link(el.location(), body)
  }

  counter(heading).update(0)

  body
}


// -------------------------------------------------------------------------
// BIBLIOGRAPHY STYLE
// -------------------------------------------------------------------------

#let bibli(body) = {
  set heading(supplement: [heading])
  show heading: set heading(numbering: none, supplement: [Chapter])

  body
}


// -------------------------------------------------------------------------
// SUMMARY
// -------------------------------------------------------------------------

#let summary(
  img: none,
  content: [],
  appliant: [],
  teacher: [],
  company: [],
  internship_agreement: bool,
  confidentiality_agreement: bool,

) = {
  set par(leading: 0.5em)

  content

  v(1fr)
  align(center, img)
  v(1fr)

  set text(size: 10pt)

  table(
    columns: (2fr, 2fr),
    align: (left, left),
    stroke: none,
    gutter: 0.1em,

    let str_inter_agr = if internship_agreement == true [yes] else [no],
    let str_conf_agr = if confidentiality_agreement == true [yes] else [no],

    [Applicant :], [Teacher in charge :],
    [#text(size: 12pt, weight: "bold", appliant)], [#text(size: 12pt, weight: "bold", teacher)],
    [Study area : ISC], [In collaboration with : #company],
    [], [Work subject to a company internship agreement : #str_inter_agr],
    [], [Work subject to a confidentiality agreement : #str_conf_agr],
  )
}

