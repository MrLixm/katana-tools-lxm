# Katana Uber Instancing (kui)

![Lua](https://img.shields.io/badge/Lua-000090?logo=lua&logoColor=white) ![Katana version](https://img.shields.io/badge/Katana-4.0+-FCB123?colorA=2e3440&logo=katana&logoColor=white) ![maintained - yes](https://img.shields.io/badge/maintained-yes-blue)

Lua scripts designed for Katana OpScript feature. Trying to provide a flexible
solution for instancing based on point-cloud locations. 

![cover](./cover.png)

# Features

- Hierarchical and Array instancing.
- Very flexible
  - Quick Multiplication / offset
  - Add arbitrary attributes on the fly
- Logging and error handling.
- Minimal performance loss compared to more straightforward solutions.


# Use

Kui is meant to be used in an OpScript.

See [User Arguments](#user-arguments) to see how to configure the OpScript
parameters. The [Source Attributes](#source-attributes) detailed how you need
to configure the instacing source (point-cloud).
And the Installation section just under explain how to set the script.

## Installation

Kui is shipped as a lua module but also as an "all in one file" script.

### As module

To register the kui module, you need to put the [kui](kui) directory in a 
location registered by the `LUA_PATH` environment variable.

For exemple we put the `kui` directory in :

```
Z:\config\katana
└── kui
    ├── array.lua
    ├── hierarchical.lua
    └── ...
```

then our variable will be

```batch
set "LUA_PATH=%LUA_PATH%Z:\config\katana\?.lua"
```

See [Lua | 8.1 – The require Function](https://www.lua.org/pil/8.1.html) for 
more details.

Lastly you can put the content of [opscript.kui.hierarchical.lua](opscript.kui.hierarchical.lua)
in the OpScript's node `script.lua` parameter.

## As one file script.

TODO not build yet.


## Source Attributes

The script is able to support a lot of point-cloud configurations thanks to
pre-defined attributes that must be created on the source location 
(the point-cloud) :

- `instancing.data.sources` (string array) :
  - `[0]` = instance source location.
  - `[1]` = instance source index.
- `instancing.data.common` (string array) :
  These attributes are the most common ones like rotation, matrix, scale, ...
  - `[0]` = attribute path relative to the source.
  - `[1]` = token to specify what kind of data [0] corresponds to.
  - `[2]` = value grouping : how much value belongs to an individual point.
  - `[3]` = value multiplier : quick way to multiply all values.
  - `[4]` = value add : quick way to offset all values by adding/subtracting a value.
- `instancing.data.arbitrary` (string array) :
  Only you know why this attribute will be useful, they will just be transfered
  to the instance for whatever you need them for.
  - `[0]` = attribute path relative to the source.
  - `[1]` = target attribute path relative to the instance.
  - `[2]` = value grouping : how much value belongs to an individual point.
  - `[3]` = value multiplier : quick way to multiply values.
  - `[4]` = value add : quick way to offset all values by adding/subtracting a value.
  - `[5]` = (optional) additional attributes that must be created on instance. Must be a valid Lua table.

*See under for detailed explanations.*

### values quick modification

When using the multiplier, or additive attribute, final value is processed as such :

```
value = value * multiplier + additive
```

So basic maths, use 1 for multiplier and 0 for additive if no modification is needed.



### instancing.data.sources

#### column 0

Instance Source's scene graph location to use.

#### column 1 
Instance Source's corresponding index.

**Index is excepted to start at 0 (mostly for `array` method)**


### instancing.data.common

List of supported tokens for column `[1]`

```
$points
$index
$skip
$hide
$matrix
$scale
$translation
$rotation
$rotationX
$rotationY
$rotationZ
```

#### points

 ![mandatory](https://img.shields.io/badge/mandatory-f03e3e)

Only used to determine the number of individuals points using :
```python
length(points.values) / points.grouping * points.multiplier + points.additive
```

This mean you could use any attribute to determine how many points there is (but usually it is `geometry.point.P`)

As we saw above, in this case the multiplier increase the number of points (to use in case of `$points` differs with the length of other tokens).

If you use this feature on attribute like `rotationX` token, the math will be applied
on all values, including the axis ones, which will led to weird results.

#### index

- `Grouping` can be any. (excepted to be usually 3 or 1 thought). (The values are converted to `grouping=1` internally anyway.)

**Index is excepted to start at 0 (mostly for `array` method)**

If you need to offset the index you can specify it in the `[5]` column. `-1` to substract 1 or `1` to add 1. (`0` if not needed)

Final processed value must correspond to the index values used in `instancing.data.sources`.


#### skip

- `Grouping` can be any. (excepted to be usually 3 or 1 thought).
   (The values are converted to `grouping=1` internally anyway.)

List of points index to skip (don't render). 
For *hierarchical* the instance location is just not generated while for
*array* the values are copied to the `geometry.instanceSkipIndex` attribute.


#### hide

- `Grouping` must be 1.

Table where each index correspond to a point and the value wheter it's hiden
or not. Where 1=hidden, 0=visible. Similar to $skip but have a value for every
point.

_Multiplier and additive are ignored._


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
If you'd like to change the axis you have to use the `$rotationX/Y/Z` tokens.


#### rotation X/Y/Z

- `Grouping` can only be 4 :

Values on source attributes are excepted to be as : `rotation value, X axis, Y axis, Z axis.`

If `$rotation` is specified, these attributes will be overriden by it.


### instancing.data.arbitrary

First 4 columns are similar to `common`.

#### column 4

Arbitrary attributes might require to not only set the value but also its
`scope`,  `inputType`, ... attributes. To do so you can provide a
Lua-formatted table that describe how they must be created :

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

⚠ You must now that this parameter has a potential security flaw as everything
inside is compiled to Lua code using `loadstring("return "..content)` where
`content` is the string submitted.

### instancing.settings

#### instancing.settings.convert_degree_to_radian

- (optional)(int) : 
  - `0` to disable any conversion.  
  - `1` to convert degree to radian.
  - `-1` to convert radian to degree.
  
Internally the conversion is applied only on the `processed`'s key values and
happens **after** the initial values have been _multiplied/offseted_.


## User Arguments

### Hierarchical

- `location` = target group location for instances 
- `applyWhere` = at specific location

#### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)

#### `user.instance_name`

Naming template used for instances. 3 tokens available :

- `$id` _(mandatory)_: replaced by point number
  - can be suffixed by a number to add a digit padding, ex: `$id3` can give `008`
- `$sourcename` : basename of the instance source location used
- `$sourceindex` : index attribute that was used to determine the instance
source to pick.

### Array

- `location` = target location for the instance array location (include its name)
- `applyWhere` = at specific location

#### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)


## Misc

The code use Lua tables that cannot store more than 2^27 (134 million) values.
I hope you never reach this amount of values. (something like 44mi points
with XYZ values and 8,3 mi points for a Matrix attribute). A fix would be
to instead use Katana's `Array` attribute class.


# Performances

TODO


# Development

Code mostly try to follow Python standards (PEP). "Docstrings" (multi-line comments)
are formatted as they were Python's Google docstring. 

## Comments

- Docstrings can be a bit confusing as sometimes `instance` is referring to 
the Lua class object that is instanced, and sometimes to the Katana instance object.

- When you see `-- /!\ perfs` means the bloc might be run a heavy amount of time and
  had to be written with this in mind.

### Implementing a new attribute

Everything will be mostly be done in [PointCloudData](./kui/PointCloudData.lua).

TODO

## [PointCloudData](./kui/PointCloudData.lua)

Here is a look at what some attributes look like. There is no difference 
between hierarchical and array for attributes stored. Only methods varies.

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
    ["arbitrary"]=false,
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