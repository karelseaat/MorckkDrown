import std/[parsecfg, strutils]

type
  MorphConfig* = object
    header1*: string
    header2*: string
    header3*: string
    header4*: string
    header5*: string
    header6*: string
    # Styles per level: "prefix" (default), "underline", "box"
    header1Style*: string
    header2Style*: string
    header3Style*: string
    header4Style*: string
    header5Style*: string
    header6Style*: string
    
    # Decoration characters
    headerUnderlineChar*: string
    headerBoxVertical*: string
    headerBoxHorizontal*: string
    headerBoxCornerTL*: string
    headerBoxCornerTR*: string
    headerBoxCornerBL*: string
    headerBoxCornerBR*: string
    
    listDash*: string
    listAsterisk*: string
    listPlus*: string
    blockquote*: string
    codeBlock*: string
    hrDash*: string
    hrAsterisk*: string
    hrUnderscore*: string
    bold*: string
    italic*: string
    underscore*: string
    inlineCode*: string
    linkOpen*: string
    linkClose*: string
    linkUrlOpen*: string
    linkUrlClose*: string
    
    # Ordered Lists
    orderedListPrefix*: string
    orderedListSuffix*: string
    
    # Layout
    documentWidth*: int
    header1Alignment*: string # "left", "center", "right"
    frontmatterAlignment*: string # "left", "right"

const defaultCfg* = MorphConfig(
    header1: "§",
    header2: "§§",
    header3: "§§§",
    header4: "§§§§",
    header5: "§§§§§",
    header6: "§§§§§§",
    listDash: "•",
    listAsterisk: "‣",
    listPlus: "⁃",
    blockquote: "»",
    codeBlock: "|||",
    hrDash: "—",
    hrAsterisk: "∗",
    hrUnderscore: "–",
    bold: "«",
    italic: "‹",
    underscore: "≋",
    inlineCode: "│",
    linkOpen: "⟦",
    linkClose: "⟧",
    linkUrlOpen: "(",
    linkUrlClose: ")",
    orderedListPrefix: "",
    orderedListSuffix: ".",
    documentWidth: 80,
    header1Alignment: "left",
    frontmatterAlignment: "left"
)
