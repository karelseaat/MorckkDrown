import std/parsecfg, std/strutils

let cfgContent = """
[mappings]
key1 = val1
key2 = "val2"
"""
let cfg = loadConfig(newStringStream(cfgContent))
echo "key1: ", cfg.getSectionValue("mappings", "key1")
echo "key2: ", cfg.getSectionValue("mappings", "key2")
