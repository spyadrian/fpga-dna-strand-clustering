// this variable will contains the configuration
#let conf(

  // parameters
  doc,

) = {

  // Document style
  set page(
    margin: 2.5cm,
    numbering: "1 / 1",
  )

  // Paragraph style
  set par(
    justify: true,
    leading: 1.5em,
  )

  // Default Fonts and Styles
  set text(font: "Times New Roman", size: 12pt)
  show raw: set text(font: "Courier New", size: 10pt)

  // Heading Styles
  show heading.where(level: 1): set text(font: "Times New Roman", weight: "bold", size: 16pt)
  show heading.where(level: 2): set text(font: "Times New Roman", weight: "bold", size: 14pt)
  show heading.where(level: 3): set text(font: "Times New Roman", weight: "bold", size: 12pt)

  // Caption Style
  // show figure-caption:  text(size: 10pt, italic: true)

  doc
}

