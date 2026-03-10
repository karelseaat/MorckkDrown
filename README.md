# MorckkDrown (Markdown Obfuscator)

A Nim-based CLI tool to transform Markdown files into "custom" text formats using configurable character mappings and styles, with reverse transformation capability.

## Features

- **Configurable Mappings**: Define replacements for headers, lists, blockquotes, code blocks, and inline styles in `config.ini`.
- **Granular Header Styles**: Configure each header level (H1-H6) with:
  - `prefix`: Replace `#` with custom characters (e.g., `$` for H1).
  - `box`: Wrap header text in an ASCII box.
  - `underline`: Underline header text with custom characters.
- **Ordered Lists**: Customize numbering styles (e.g., `(1)` instead of `1.`).
- **Link Obfuscation**: Wrap link text and URLs with custom characters (e.g., `⟦Text⟧⟮URL⟯`).
- **Document Layout**:
  - Center H1 headers.
  - Align YAML frontmatter (right/center).
- **ASCII Tables**: Automatically convert Markdown tables into ASCII box-drawing tables.
- **Reverse Mode**: Restore obfuscated text back to standard Markdown.

## Usage

### Transform (Markdown -> Custom)
```bash
src/md_morph input.md -c:config.ini -o:output.txt
```

### Restore (Custom -> Markdown)
```bash
src/md_morph input.txt -c:config.ini -r -o:restored.md
```

## Configuration (`config.ini`)

The tool uses an INI file for all settings. See `config.ini` for a complete example.

```ini
[mappings]
# Document Layout
document_width = 80
header1_alignment = "center"      # left, center, right
frontmatter_alignment = "right"   # left, right

# Per-header styles: "prefix", "box", "underline"
header1_style = "box"
header2_style = "underline"
header3_style = "prefix"

# Ordered Lists
ordered_list_prefix = "("
ordered_list_suffix = ")"

# Links
link_open = "⟦"
link_close = "⟧"
link_url_open = "⟮"
link_url_close = "⟯"

# Custom characters for prefix style
header1 = "$"
header2 = "@"
header3 = "&"

# Box drawing characters
header_box_vertical = "│"
header_box_horizontal = "─"
header_box_corner_tl = "┌"
# ... and more
```

## Build

```bash
nim c -d:release src/md_morph.nim
```
