# Katana Uber Instancing (kui)

![lua](https://img.shields.io/badge/type-lua-blue)

Lua scripts designed for Katana OpScript feature. Trying to provide a flexible
solution for instancing based on point-cloud locations. 

![cover](./cover.png)

## Features

### Very flexible

The script is able to support a lot of point-cloud configurations thanks to
pre-defined attributes that must be created on the source location :

- `instancing.settings.index_offset` (int) : value that will be removed to the
`[1]` attribute of `instancing.data.sources`.

- `instancing.data.sources` (string array) :
  - `[0]` = instance source location.
  - `[1]` = instance source index.
  - `[2]` = proxy geometry location (optional).

- `instancing.data.common` (string array) :
    These attributes are the most common ones like rotation, matrix, scale, ...
  - `[0]` = attribute path relative to the source.
  - `[1]` = token to specify what kind of data [0] corresponds to.
  - `[2]` = value grouping : how much value belongs to an individual point.
  - `[3]` = value multiplier : quick way to multiply values.

- `instancing.data.arbitrary` (string array) :
    Only you know why this attribute will be useful, they will just be transfered
    to the instance for whatever you need them for.
  - `[0]` = attribute path relative to the source.
  - `[1]` = target attribute path realtive to the instance.
  - `[2]` = value grouping : how much value belongs to an individual point.
  - `[3]` = value multiplier : quick way to multiply values.

#### common tokens

- 


## Setup

#### User Arguments

##### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)

##### `user.instance_name`

Naming template used for instances. 3 tokens available :

- `$id` _(mandatory)_: replaced by point number
  - can be suffixe by a number to add a digit padding, ex: `$id3` can give `008`
- `$sourcename` : basename of the instance source location used
- `$sourceindex` : index attribute that was used to determine the instance
source to pick.

## About

The code use Lua tables that cannot store more than 2^27 (134 million) values.
I hope you never reach this amount of values. (something like 44mi points
with XYZ values).


When the `$rotation` token is declared, it is always converted to individuals
`$rotationX/Y/Z` attributes. These new attributes also specify the axis which
is assumed to be by default :
```lua
axis = {
    x = {1,0,0},
    y = {0,1,0},
    z = {0,0,1}
}
```
`$rotation` attribute is assumed to be in the X-Y-Z order in the case where
value grouping (`[2]`) = 3

## Development

### Comments

Docstrings can be a bit confusing as sometimes `instance` is referring to the 
lua class object that is instanced, and sometimes to the Katana instance object.

When you see `-- /!\ perfs` means the bloc might be run a havey amount of time and
has to be writen with this in mind.

### pointcloudData

Here is a look at what some attributes looks like

```lua
  local attrs = {
    ["time"]=time,
    ["location"]=location,
    ["common"]={
      ["scale"]=false,
      ["rotation"]=false,
      ["translation"]=false,
      ["index"]=false,
      ["points"]=false,
      ["matrix"]=false,
      ["rotationX"]=false,
      ["rotationY"]=false,
      ["rotationZ"]=false
    },
    ["sources"]=false,
    ["arbitrary"]=false,
    ["point_count"]=false
  }

```

#### sources
```lua
  sources = {
    "indexN"={
      ["path(str)"]="scene graph location of the instance source",
      ["index(num)"]="index it's correspond to on the pointCloud (offset has been applied), same as the parent key.",
      ["proxy(Optional[str])"]="proxy geometry location"
    }
    1: ...
  }
```
#### arbitrary
```lua
  arbitrary = {
    ["target attribute path"]={
      ["path(str)"]= "attribute path relative to the source.",
      ["grouping(num)"]= "how much value belongs to an individual point.",
      ["multiplier(num)"]= "quick way to multiply values.",
      ["values(table)"]= "table of value gathered on the source using the above path",
      ["type(DataAttribute)"]= "DataAttribute class not instanced that correspond to values",
      ["processed(DataAttribute)"] = "DataAttribute class INSTANCED that correspond to <values> * <multiplier>"
    }
    ...
  }
```
#### common
```lua
  common = {
    ["token (without the $)"]={
      ["path(str)"]= "attribute path relative to the source.",
      ["grouping(num)"]= "how much value belongs to an individual point.",
      ["multiplier(num)"]= "quick way to multiply values.",
      ["values(table)"]= "table of value gathered on the source using the above path",
      ["type(DataAttribute)"]= "DataAttribute class not instanced that correspond to values",
      ["processed(table)"] = "Values but processed. Correspond to <values> * <multiplier>."
    }
    ...
  }
```