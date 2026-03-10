import std/[strutils, parseopt, os]
import morph_types
import morph_config
import morph_transform
import morph_reverse

proc main() =
  var 
    filename = ""
    outputFilename = ""
    configFilename = "config.ini" # Default config file
    reverseMode = false
  
  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "out" or p.key == "output":
        outputFilename = p.val
      elif p.key == "c" or p.key == "config":
        configFilename = p.val
      elif p.key == "r" or p.key == "reverse":
        reverseMode = true
    of cmdArgument:
      filename = p.key
    
  if filename == "":
    echo "Usage: md_morph <filename.md> [-o:output.txt] [-c:config.ini] [-r/--reverse]"
    return
  
  if not fileExists(filename):
    echo "Error: File not found: ", filename
    quit(1)

  # Load config
  let cfg = loadMorphConfig(configFilename)
  if fileExists(configFilename) and not reverseMode:
    echo "Loaded config from ", configFilename
  elif reverseMode:
    echo "Reverse mode: Transforming back to Markdown using config ", configFilename

  try:
    let content = readFile(filename)
    let lines = content.splitLines()
    var outputLines: seq[string] = @[]
    
    if reverseMode:
      outputLines = untransformLines(lines, cfg)
    else:
      outputLines = transformLines(lines, cfg)
      
    let output = outputLines.join("\n")

    if outputFilename != "":
      writeFile(outputFilename, output)
      echo "Saved to ", outputFilename
    else:
      echo output
  except IOError as e:
    echo "Error reading/writing file: ", e.msg
    quit(1)
  except Exception as e:
    echo "An unexpected error occurred: ", e.msg
    quit(1)

if isMainModule:
  main()
