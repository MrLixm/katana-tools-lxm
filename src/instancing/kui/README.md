# Katana Uber Instancing (kui)

![lua](https://img.shields.io/badge/type-lua-blue)

Lua scripts designed for Katana OpScript feature. Trying to provide a flexible
solution for instancing based on point-cloud locations. 

![cover](./cover.png)

# Features

- Hierarchical and Array instancing.
- Logging and error handling.
- Minimal performance loss compared to more straightforward solutions.


# Setup

## Source Attributes

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
  - `[1]` = target attribute path relative to the instance.
  - `[2]` = value grouping : how much value belongs to an individual point.
  - `[3]` = value multiplier : quick way to multiply values.
  - `[4]` = additional attributes that must be created on instance. Defined as a Lua table.

See under for detailed explanations.

### instancing.data.sources

#### column 2

TODO, see if this is keeped.


### instancing.data.common

List of supported tokens for column `[1]`

```
$points
$index
$matrix
$scale
$translation
$rotation
$rotationX
$rotationY
$rotationZ
```

#### points

Is mandatory.

Only used to determine the number of individuals points using :
```python
length(points.values) / points.grouping * points.multiplier
```


#### index

- `Grouping` can be any. (excepted to be usually 3 or 1 thought)

Must correspond to the index values used in `instancing.data.sources`.
If you need to offset these values you can offset `instancing.data.sources` 
indexes instead by specifying `instancing.settings.index_offset`.


#### matrix

- `Grouping` must be 16 (4*4 matrix).

I specified, take over all the other transforms attributes.


#### scale

- `Grouping` can be any.

Source attribute is excepted to store values in X-Y-Z order.


#### translation

- `Grouping` must be 3.

Source attribute is excepted to store values in X-Y-Z order.

You can of course specify the same attribute used for `$points`.


#### rotation

- `Grouping` must be 3 .

Source attribute is excepted to store values in X-Y-Z order.

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
If you would look to change the axis you have to use the `$rotationX/Y/Z` tokens.


#### rotation X/Y/Z

- `Grouping` can only be 4 :

Values on source attributes are excepted to be as : `rotation value, X axis, Y axis, Z axis.`

If `$rotation` is specified, these attributes will be overriden by it.


### instancing.data.arbitrary

#### column 4

Arbitrary attributes might require to not only set the value but also its `scope`,  `inputType`, ... attributes. To do so you can provide a Lua-formatted table that describe how they must be created :
```lua
{"target path"=DataAttribute(value)}
```
Here is an example for an arbitrary `randomColor` attribute:
```lua
{
    ["geometry.arbitrary.randomColor.inputType"]=StringAttribute("color3"),
    ["geometry.arbitrary.randomColor.scope"]=StringAttribute("primitive"),
}
```

⚠ You must now that this parameter has a potential security flaw as everything inside is compiled to Lua code using `loadstring("return "..content)` where `content` is the string submitted.


#### User Arguments

##### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)

##### `user.instance_name`

Naming template used for instances. 3 tokens available :

- `$id` _(mandatory)_: replaced by point number
  - can be suffixed by a number to add a digit padding, ex: `$id3` can give `008`
- `$sourcename` : basename of the instance source location used
- `$sourceindex` : index attribute that was used to determine the instance
source to pick.

## Misc

The code use Lua tables that cannot store more than 2e27 (134 million) values.
I hope you never reach this amount of values. (something like 44mi points
with XYZ values).


# Performances

TODO


# Development

## Comments

Docstrings can be a bit confusing as sometimes `instance` is referring to the Lua class object that is instanced, and sometimes to the Katana instance object.

When you see `-- /!\ perfs` means the bloc might be run a heavy amount of time and
had to be written with this in mind.

## PointCloudData

Here is a look at what some attributes looks like

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

### sources
```lua
  sources = {
    "indexN"={
      ["path(str)"]="scene graph location of the instance source",
      ["index(num)"]="index it's correspond to on the pointCloud (offset has been applied), same as the parent key.",
      ["proxy(Optional[str])"]="proxy geometry location",
      ["attrs(table)"] =  
    }
	...
  }
```
### arbitrary
```lua
  arbitrary = {
    ["target attribute path"]={
      ["path(str)"]= "attribute path relative to the source.",
      ["grouping(num)"]= "how much value belongs to an individual point.",
      ["multiplier(num)"]= "quick way to multiply values.",
      ["values(table)"]= "table of value gathered on the source using the above path",
      ["type(DataAttribute)"]= "DataAttribute class not instanced that correspond to values",
      ["processed(DataAttribute)"] = "DataAttribute class INSTANCED that correspond to <values> * <multiplier>"
      ["additional(str)"]= "lua table stored in a string that contains aditional attributes to create on instance"
    }
    ...
  }
```
### common
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