import std/[strutils, sequtils]
import morph_types

proc renderTable*(tableLines: seq[string], cfg: MorphConfig): seq[string] =
  result = @[]
  if tableLines.len < 2: return tableLines # Not a valid table

  # Check for separator line
  let separator = tableLines[1]
  if not separator.contains("-"): return tableLines # Simple check

  # Parse columns
  var parsedRows: seq[seq[string]] = @[]
  var colWidths: seq[int] = @[]

  for line in tableLines:
    let stripped = line.strip()
    if not stripped.startsWith("|"): continue
    
    # Split by pipe
    var row: seq[string] = @[]
    # Remove outer pipes if present
    var content = stripped
    if content.startsWith("|"): content = content[1..^1]
    if content.endsWith("|"): content = content[0..^2]
    
    for cell in content.split("|"):
      row.add(cell.strip())
    
    parsedRows.add(row)

  if parsedRows.len == 0: return tableLines

  # Initialize colWidths based on first row
  for _ in parsedRows[0]: colWidths.add(0)

  for i, row in parsedRows:
    if i == 1: continue # Skip MD separator row
    for j, cell in row:
      if j < colWidths.len:
        colWidths[j] = max(colWidths[j], cell.len)

  # Draw Table
  # Top Border
  var topBorder = cfg.headerBoxCornerTL
  for w in colWidths:
    topBorder &= cfg.headerBoxHorizontal.repeat(w + 2) & cfg.headerBoxHorizontal
  # Adjust corners (lazy way, just replace last char)
  topBorder = topBorder[0..^2] & cfg.headerBoxCornerTR
  result.add(topBorder)

  for i, row in parsedRows:
    if i == 1: continue # Skip separator
    
    var lineStr = cfg.headerBoxVertical
    for j, cell in row:
      if j < colWidths.len:
        let padding = colWidths[j] - cell.len
        lineStr &= " " & cell & " ".repeat(padding) & " " & cfg.headerBoxVertical
    result.add(lineStr)
    
    # Add separator after header
    if i == 0:
      var sepLine = cfg.headerBoxCornerTL # Actually should be T-junctions
      for w in colWidths:
         sepLine &= cfg.headerBoxHorizontal.repeat(w + 2) & cfg.headerBoxHorizontal
      sepLine = sepLine[0..^2] & cfg.headerBoxCornerTR
      result.add(sepLine)

  # Bottom Border
  var botBorder = cfg.headerBoxCornerBL
  for w in colWidths:
    botBorder &= cfg.headerBoxHorizontal.repeat(w + 2) & cfg.headerBoxHorizontal
  botBorder = botBorder[0..^2] & cfg.headerBoxCornerBR
  result.add(botBorder)

proc transformLines*(lines: seq[string], cfg: MorphConfig): seq[string] =
  result = @[]
  var i = 0
  
  # Frontmatter Handling
  var inFrontmatter = false
  if lines.len > 0 and lines[0].strip() == "---":
    inFrontmatter = true
    # Process opening fence
    if cfg.frontmatterAlignment == "right":
       let padding = max(0, cfg.documentWidth - 3)
       result.add(" ".repeat(padding) & "---")
    elif cfg.frontmatterAlignment == "center":
       let padding = max(0, (cfg.documentWidth - 3) div 2)
       result.add(" ".repeat(padding) & "---")
    else:
       result.add("---")
    i += 1
  
  while i < lines.len:
    if inFrontmatter:
      var line = lines[i]
      if line.strip() == "---":
        inFrontmatter = false
        if cfg.frontmatterAlignment == "right":
           let padding = max(0, cfg.documentWidth - 3)
           result.add(" ".repeat(padding) & "---")
        elif cfg.frontmatterAlignment == "center":
           let padding = max(0, (cfg.documentWidth - 3) div 2)
           result.add(" ".repeat(padding) & "---")
        else:
           result.add("---")
      else:
        # Align content
        if cfg.frontmatterAlignment == "right":
           let padding = max(0, cfg.documentWidth - line.len)
           result.add(" ".repeat(padding) & line)
        elif cfg.frontmatterAlignment == "center":
           let padding = max(0, (cfg.documentWidth - line.len) div 2)
           result.add(" ".repeat(padding) & line)
        else:
           result.add(line)
      i += 1
      continue

    var line = lines[i]
    
    # Headers
    var level = 0
    if line.startsWith("###### "): level = 6
    elif line.startsWith("##### "): level = 5
    elif line.startsWith("#### "): level = 4
    elif line.startsWith("### "): level = 3
    elif line.startsWith("## "): level = 2
    elif line.startsWith("# "): level = 1
    
    var handledHeader = false
    if level > 0:
      let style = case level
        of 1: cfg.header1Style
        of 2: cfg.header2Style
        of 3: cfg.header3Style
        of 4: cfg.header4Style
        of 5: cfg.header5Style
        of 6: cfg.header6Style
        else: "prefix"
        
      let text = line[level + 1 .. ^1]
      
      if style == "box":
        let borderTop = cfg.headerBoxCornerTL & cfg.headerBoxHorizontal.repeat(text.len + 2) & cfg.headerBoxCornerTR
        let middle = cfg.headerBoxVertical & " " & text & " " & cfg.headerBoxVertical
        let borderBottom = cfg.headerBoxCornerBL & cfg.headerBoxHorizontal.repeat(text.len + 2) & cfg.headerBoxCornerBR
        
        # Center H1 logic for Box
        if level == 1 and cfg.header1Alignment == "center":
           let padding = max(0, (cfg.documentWidth - borderTop.len) div 2)
           result.add(" ".repeat(padding) & borderTop)
           result.add(" ".repeat(padding) & middle)
           result.add(" ".repeat(padding) & borderBottom)
        else:
           result.add(borderTop)
           result.add(middle)
           result.add(borderBottom)
        
        handledHeader = true
      elif style == "underline":
        result.add(text)
        result.add(cfg.headerUnderlineChar.repeat(text.len))
        handledHeader = true
      else: # prefix
        let prefix = case level
          of 1: cfg.header1
          of 2: cfg.header2
          of 3: cfg.header3
          of 4: cfg.header4
          of 5: cfg.header5
          of 6: cfg.header6
          else: ""
        
        var processed = prefix & " " & text
        if level == 1 and cfg.header1Alignment == "center":
           let padding = max(0, (cfg.documentWidth - processed.len) div 2)
           processed = " ".repeat(padding) & processed
           
        line = processed
        # Continue to standard processing for inline styles within the header text
        
    if handledHeader:
      i += 1
      continue

    # Tables
    if line.strip().startsWith("|"):
       # Look ahead to see if it's a table (next line must be separator)
       if i + 1 < lines.len and lines[i+1].strip().startsWith("|") and lines[i+1].contains("-"):
         var tableLines: seq[string] = @[]
         var k = i
         while k < lines.len and lines[k].strip().startsWith("|"):
           tableLines.add(lines[k])
           k += 1
         
         let rendered = renderTable(tableLines, cfg)
         for l in rendered: result.add(l)
         i = k
         continue

    # Ordered Lists (e.g., "1. Item")
    var isOrderedList = false
    let strippedLine = line.strip()
    if strippedLine.len > 0 and strippedLine[0].isDigit:
      # echo "DEBUG: Found digit line: ", strippedLine
      let dotPos = strippedLine.find(".")
      if dotPos > 0 and strippedLine[0..<dotPos].allCharsInSet(Digits):
         let number = strippedLine[0..<dotPos]
         let rest = strippedLine[dotPos+1..^1]
         if rest.startsWith(" "):
           let indent = line.find(strippedLine)
           let newMarker = cfg.orderedListPrefix & number & cfg.orderedListSuffix
           line = line[0..<indent] & newMarker & rest
           isOrderedList = true
           # echo "DEBUG: Transformed to: ", line

    # Lists
    if not isOrderedList:
      if line.strip().startsWith("- "):
        let indent = line.find("- ")
        if indent >= 0:
          line = line[0..<indent] & cfg.listDash & " " & line[indent+2..^1]
      elif line.strip().startsWith("* "):
        let indent = line.find("* ")
        if indent >= 0:
          line = line[0..<indent] & cfg.listAsterisk & " " & line[indent+2..^1]
      elif line.strip().startsWith("+ "):
        let indent = line.find("+ ")
        if indent >= 0:
          line = line[0..<indent] & cfg.listPlus & " " & line[indent+2..^1]

    # Blockquotes
    if line.strip().startsWith(">"):
      let indent = line.find(">")
      if indent >= 0:
        line = line[0..<indent] & cfg.blockquote & line[indent+1..^1]

    # Code Blocks
    if line.strip().startsWith("```"):
      line = line.replace("```", cfg.codeBlock)

    # Horizontal Rules
    let strippedHR = line.strip()
    if strippedHR == "---" or strippedHR == "***" or strippedHR == "___":
      result.add(line.replace("-", cfg.hrDash).replace("*", cfg.hrAsterisk).replace("_", cfg.hrUnderscore))
      i += 1
      continue

    # Inline
    line = line.replace("**", cfg.bold) 
    line = line.replace("__", cfg.bold)
    line = line.replace("*", cfg.italic)
    line = line.replace("`", cfg.inlineCode)
    
    # Links: [text](url) -> ⟦text⟧⟮url⟯
    # We need to handle ]( specifically
    line = line.replace("[", cfg.linkOpen).replace("]", cfg.linkClose)
    if cfg.linkUrlOpen != "(" or cfg.linkUrlClose != ")":
       # Since we already replaced ] with linkClose, we look for linkClose & "("
       line = line.replace(cfg.linkClose & "(", cfg.linkClose & cfg.linkUrlOpen).replace(")", cfg.linkUrlClose)
    
    result.add(line)
    i += 1
