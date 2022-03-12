# ![OpScript](https://img.shields.io/badge/OpScript-4f4f4f?labelColor=blueviolet) attrMath

![lua](https://img.shields.io/badge/Lua-any-4f4f4f?labelColor=000090&logo=lua&logoColor=white)
![katana version](https://img.shields.io/badge/Katana-any-4f4f4f?labelColor=111111&logo=katana&logoColor=FCB123)

Apply basic math operation on attributes values.

# Features

- math operations :
  - multiplication
  - addition
  - changes operation order
- skip indexes
- motion blur support

## Installation

You can use the [createOpScript.py](createOpScript.py) file to quickly 
install the script, ready for use.

> ❕ check that the SCRIPT variable at the top of the file use the latest version
> of the [attrTypeSwap.lua](attrTypeSwap.lua) script.

To use it copy-paste the content of [createOpScript.py](createOpScript.py)
in the Python tab and execute it.

An OpScript node named `OpScript_attrMath_1` should be created at the top-left 
of the nodegraph.

## Use

First set the scene-graph location where you want to modify some of its attributes
in the `location` parameter at top.

You can then modify the `user.attributes` parameter to add attribute to modify.
Each row corresponds to an attribute to modify where :

- column [1*n] = path of the attribute relative to the location
- column [2*n] = expression to specify indesx to skip like :
  Every X indexes, skip indexes N[...] == `N,N,.../X` == `(%d+,*)+/%d+`
  ex: skip 2/3/4th index every 4 index == `2,3,4/4` (so process only 1/4)


# Dev

Tested on Katana 4.5v1

Ideas :
- add clamp option
- convert to input/output like "ranges" node : `in.multiply`, `out.multiply`, ...