import std/[strutils, sequtils, algorithm]
import morph_types

proc untransformLines*(lines: seq[string], cfg: MorphConfig): seq[string] =
  result = @[]
  var i = 0
  
  # Helper to find which level uses a specific style
  proc getLevelForStyle(style: string): int =
    if cfg.header1Style == style: return 1
    if cfg.header2Style == style: return 2
    if cfg.header3Style == style: return 3
    if cfg.header4Style == style: return 4
    if cfg.header5Style == style: return 5
    if cfg.header6Style == style: return 6
    return 0

  while i < lines.len:
    var line = lines[i]
    var handled = false
    
    # Reverse Box Style
    # Check for top border
    if line.strip().startsWith(cfg.headerBoxCornerTL) and line.strip().endsWith(cfg.headerBoxCornerTR):
      # Look ahead for middle and bottom
      if i + 2 < lines.len:
        let middle = lines[i+1]
        let bottom = lines[i+2]
        if middle.strip().startsWith(cfg.headerBoxVertical) and bottom.strip().startsWith(cfg.headerBoxCornerBL):
          # Extract text: │ Text │ -> Text
          # We expect format: VERTICAL + SPACE + TEXT + SPACE + VERTICAL
          let prefixLen = cfg.headerBoxVertical.len + 1 # +1 for space
          let suffixLen = cfg.headerBoxVertical.len + 1 # +1 for space
          
          if middle.strip().len > prefixLen + suffixLen:
            let strippedMiddle = middle.strip()
            let content = strippedMiddle[prefixLen ..< strippedMiddle.len - suffixLen].strip()
            
            # Determine level (default to H1 if multiple use box)
            let level = getLevelForStyle("box")
            if level > 0:
              result.add("#".repeat(level) & " " & content)
              i += 3
              handled = true
              continue
    
    # Reverse Underline Style
    if not handled and i + 1 < lines.len:
      let nextLine = lines[i+1].strip()
      if nextLine.len > 0 and nextLine.startsWith(cfg.headerUnderlineChar) and nextLine == cfg.headerUnderlineChar.repeat(nextLine.len):
        # Ensure it matches length somewhat (allow flexibility)
        if nextLine.len >= line.strip().len:
          let level = getLevelForStyle("underline")
          if level > 0:
            result.add("#".repeat(level) & " " & line)
            i += 2
            handled = true
            continue

    if handled: continue

    # Standard replacements
    
    # Headers (Prefix)
    # Sort prefix headers by length descending to ensure we match the longest prefix first
    type HeaderMatch = tuple[level: int, prefix: string]
    var prefixes: seq[HeaderMatch] = @[]
    
    if cfg.header1Style == "prefix": prefixes.add((1, cfg.header1))
    if cfg.header2Style == "prefix": prefixes.add((2, cfg.header2))
    if cfg.header3Style == "prefix": prefixes.add((3, cfg.header3))
    if cfg.header4Style == "prefix": prefixes.add((4, cfg.header4))
    if cfg.header5Style == "prefix": prefixes.add((5, cfg.header5))
    if cfg.header6Style == "prefix": prefixes.add((6, cfg.header6))
    
    # Sort descending by length
    prefixes.sort(proc (x, y: HeaderMatch): int = cmp(y.prefix.len, x.prefix.len))
    
    var matchedHeader = false
    for p in prefixes:
      if line.startsWith(p.prefix):
        var content = line[p.prefix.len..^1]
        if content.startsWith(" "): content = content[1..^1]
        result.add("#".repeat(p.level) & " " & content)
        matchedHeader = true
        break
    
    if matchedHeader:
      # Apply H1 alignment if configured
      if i < result.len:
        let lastLine = result[^1]
        # Only align if it was H1 (check if it starts with pattern)
        # Re-check what style was used for H1 to align correctly
        if cfg.header1Style == "box" and lastLine.strip().endsWith(cfg.headerBoxCornerBR):
          # Box alignment is tricky, maybe skip for now or implement later
          discard
        elif cfg.header1Style == "prefix" and lastLine.strip().startsWith(cfg.header1):
           if cfg.header1Alignment == "center":
             let padding = (cfg.documentWidth - lastLine.len) div 2
             if padding > 0:
               result[^1] = " ".repeat(padding) & lastLine
      
      i += 1
      continue

    # Ordered Lists (Reverse)
    var isOrderedList = false
    let strippedLine = line.strip()
    # Check if we have prefix + number + suffix
    # First, handle prefix
    var possibleList = false
    if cfg.orderedListPrefix == "" or strippedLine.startsWith(cfg.orderedListPrefix):
      possibleList = true
    
    if possibleList:
      let afterPrefix = if cfg.orderedListPrefix == "": strippedLine else: strippedLine[cfg.orderedListPrefix.len..^1]
      let suffixPos = afterPrefix.find(cfg.orderedListSuffix)
      
      if suffixPos > 0:
        let numberStr = afterPrefix[0..<suffixPos]
        if numberStr.len > 0 and numberStr.allCharsInSet(Digits):
           let indent = line.find(strippedLine)
           let content = afterPrefix[suffixPos + cfg.orderedListSuffix.len .. ^1]
           if content.startsWith(" "):
             line = " ".repeat(indent) & numberStr & "." & content
             isOrderedList = true
    
    # Lists
    if not isOrderedList:
      if line.strip().startsWith(cfg.listDash & " "):
        let indent = line.find(cfg.listDash & " ")
        if indent >= 0:
          line = line[0..<indent] & "- " & line[indent+cfg.listDash.len+1..^1]
      elif line.strip().startsWith(cfg.listAsterisk & " "):
        let indent = line.find(cfg.listAsterisk & " ")
        if indent >= 0:
          line = line[0..<indent] & "* " & line[indent+cfg.listAsterisk.len+1..^1]
      elif line.strip().startsWith(cfg.listPlus & " "):
        let indent = line.find(cfg.listPlus & " ")
        if indent >= 0:
          line = line[0..<indent] & "+ " & line[indent+cfg.listPlus.len+1..^1]

    # Blockquotes
    if line.strip().startsWith(cfg.blockquote):
      let indent = line.find(cfg.blockquote)
      if indent >= 0:
        line = line[0..<indent] & ">" & line[indent+cfg.blockquote.len..^1]

    # Code Blocks
    if line.strip().startsWith(cfg.codeBlock):
      line = line.replace(cfg.codeBlock, "```")

    # Horizontal Rules
    let stripped = line.strip()
    if stripped.replace(cfg.hrDash, "") == "" and stripped.len >= 3:
      result.add("---")
      i += 1
      continue
    if stripped.replace(cfg.hrAsterisk, "") == "" and stripped.len >= 3:
      result.add("***")
      i += 1
      continue
    if stripped.replace(cfg.hrUnderscore, "") == "" and stripped.len >= 3:
      result.add("___")
      i += 1
      continue
    
    # Inline
    line = line.replace(cfg.bold, "**")
    line = line.replace(cfg.italic, "*")
    line = line.replace(cfg.underscore, "_")
    line = line.replace(cfg.inlineCode, "`")
    line = line.replace(cfg.linkOpen, "[").replace(cfg.linkClose, "]")
    if cfg.linkUrlOpen != "(" or cfg.linkUrlClose != ")":
       line = line.replace(cfg.linkUrlOpen, "(").replace(cfg.linkUrlClose, ")")
    
    result.add(line)
    i += 1
