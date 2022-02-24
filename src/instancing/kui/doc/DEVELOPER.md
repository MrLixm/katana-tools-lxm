# Developer

[![previous](https://img.shields.io/badge/culling-◀_previous_page-fcb434?labelColor=4f4f4f)](CULLING.md)
[![root](https://img.shields.io/badge/back_to_root-536362)](../README.md)
[![index](https://img.shields.io/badge/back_to_index-blue)](INDEX.md)


Section related to code development.

Code mostly try to follow Python standards (PEP).
Indent used are `2` white-space

Code tests were made on Katana 4.5v1.

## Comments

"Docstrings" (multi-line comments) are formatted as they were Python's Google docstrings. 

- Docstrings can be a bit confusing as sometimes `instance` is referring to 
the Lua class object that is instanced, and sometimes to the Katana instance object.

- When you see `-- /!\ perfs` means the bloc might be run a heavy amount of time and
  had to be written with this in mind.

## Implementing a new attribute

Modifications will mostly be in [PointCloudData](../kui/PointCloudData.lua).

TODO

# Tests

You can use the 2 point-clouds in [./test-data](./test-data) to test KUI
while developing. They have all the TRS attributes + a randomColor one (
! actually name colorRandom on the 100k one 😬)

# API

## [PointCloudData.lua](../kui/PointCloudData.lua)

Here is a look at the table structure of a PointCloudData instance.

`common` and `arbitrary` share the same structure except `arbitrary` has an
additional attribute `additional` (and key is not a token).

### attrs

```lua
-- attributes at init time  
local attrs = {
    ["time"]=time,
    ["location"]=location,
    ["common"]={
      ["scale"]=false,
      ["rotation"]=false,
      ["translation"]=false,
      ["index"]=false,
      ["skip"]=false,
      ["hide"]=false,
      ["points"]=false,
      ["matrix"]=false,
      ["rotationX"]=false,
      ["rotationY"]=false,
      ["rotationZ"]=false
    },
    ["sources"]=false,
    ["arbitrary"]={},
    ["point_count"]=false
  }

```

### attrs.sources
```lua
  sources = {
    ["indexN"]={
      ["path(str)"]="scene graph location of the instance source",
      ["index(num)"]="index it's correspond to on the pointCloud, same as the parent key (indexN).",
      ["attrs(table)"] = "Group of local attribute from the instance source location to copy on the instance"
    },
	...
  }
```
### attrs.arbitrary
```lua
  arbitrary = {
    ["target attribute path"]={
      ["path(str)"]= "attribute path relative to the source.",
      ["grouping(num)"]= "how much value belongs to an individual point.",
      ["multiplier(num)"]= "quick way to multiply values.",
      ["additive(num)"]= "quick way to offset all values by adding/subtracting a value.",
      ["values(table)"]= "table of value gathered on the source using the above path",
      ["type(DataAttribute)"]= "DataAttribute class not instanced that correspond to values",
      ["processed(table)"] = "Values but processed. Correspond to <values> * <multiplier> + <additive>.",
      ["additional(str)"]= "lua table stored in a string that contains aditional attributes to create on instance"
    },
    ...
  }
```
### attrs.common
```lua
  common = {
    ["token (without the $)"]={
      ["path(str)"]= "attribute path relative to the source.",
      ["grouping(num)"]= "how much value belongs to an individual point.",
      ["multiplier(num)"]= "quick way to multiply values.",
      ["additive(num)"]= "quick way to offset all values by adding/subtracting a value.",
      ["values(table)"]= "table of value gathered on the source using the above path",
      ["type(DataAttribute)"]= "DataAttribute class not instanced that correspond to values",
      ["processed(table)"] = "Values but processed. Correspond to <values> * <multiplier> + <additive>."
    },
    ...
  }
```

---
[![previous](https://img.shields.io/badge/culling-◀_previous_page-fcb434?labelColor=4f4f4f)](CULLING.md)
[![root](https://img.shields.io/badge/back_to_root-536362)](../README.md)
[![index](https://img.shields.io/badge/back_to_index-blue)](INDEX.md)
