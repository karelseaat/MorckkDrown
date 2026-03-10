import std/[parsecfg, strutils, os]
import morph_types

proc loadMorphConfig*(filename: string): MorphConfig =
  result = defaultCfg
  if filename == "":
    return # Use defaults
    
  if not fileExists(filename):
    echo "Warning: Config file '", filename, "' not found. Using defaults."
    return

  var dict = loadConfig(filename)
  let sect = "mappings"
  
  proc get(key: string, default: string): string =
    let val = dict.getSectionValue(sect, key)
    if val == "": return default
    return val.strip(chars={'"'}) # Remove surrounding quotes if present

  result.header1 = get("header1", result.header1)
  result.header2 = get("header2", result.header2)
  result.header3 = get("header3", result.header3)
  result.header4 = get("header4", result.header4)
  result.header5 = get("header5", result.header5)
  result.header6 = get("header6", result.header6)
  
  # Default styles based on old global setting or defaults
  let globalStyle = get("header_style", "prefix")
  var h1Def, h2Def, h3Def, h4Def, h5Def, h6Def = "prefix"
  
  if globalStyle == "box":
    h1Def = "box"
    h2Def = "underline"
    # others remain prefix
  elif globalStyle == "underline":
    h1Def = "underline"
    h2Def = "underline"
  
  result.header1Style = get("header1_style", h1Def)
  result.header2Style = get("header2_style", h2Def)
  result.header3Style = get("header3_style", h3Def)
  result.header4Style = get("header4_style", h4Def)
  result.header5Style = get("header5_style", h5Def)
  result.header6Style = get("header6_style", h6Def)
  
  result.headerUnderlineChar = get("header_underline_char", "=")
  result.headerBoxVertical = get("header_box_vertical", "│")
  result.headerBoxHorizontal = get("header_box_horizontal", "─")
  result.headerBoxCornerTL = get("header_box_corner_tl", "┌")
  result.headerBoxCornerTR = get("header_box_corner_tr", "┐")
  result.headerBoxCornerBL = get("header_box_corner_bl", "└")
  result.headerBoxCornerBR = get("header_box_corner_br", "┘")
  
  result.listDash = get("list_dash", result.listDash)
  result.listAsterisk = get("list_asterisk", result.listAsterisk)
  result.listPlus = get("list_plus", result.listPlus)
  result.blockquote = get("blockquote", result.blockquote)
  result.codeBlock = get("code_block", result.codeBlock)
  result.hrDash = get("hr_dash", result.hrDash)
  result.hrAsterisk = get("hr_asterisk", result.hrAsterisk)
  result.hrUnderscore = get("hr_underscore", result.hrUnderscore)
  result.bold = get("bold", result.bold)
  result.italic = get("italic", result.italic)
  result.underscore = get("underscore", result.underscore)
  result.inlineCode = get("inline_code", result.inlineCode)
  result.linkOpen = get("link_open", result.linkOpen)
  result.linkClose = get("link_close", result.linkClose)
  result.linkUrlOpen = get("link_url_open", result.linkUrlOpen)
  result.linkUrlClose = get("link_url_close", result.linkUrlClose)
  
  result.orderedListPrefix = get("ordered_list_prefix", "")
  result.orderedListSuffix = get("ordered_list_suffix", ".")
  
  try:
    result.documentWidth = parseInt(get("document_width", "80"))
  except ValueError:
    result.documentWidth = 80
    
  result.header1Alignment = get("header1_alignment", "left")
  result.frontmatterAlignment = get("frontmatter_alignment", "left")
