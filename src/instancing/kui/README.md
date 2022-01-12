# Katana Uber Instancing (kui)

![lua](https://img.shields.io/badge/type-lua-blue)

Lua scripts designed for Katana OpScript feature. Trying to provide a flexible
solution for instancing based on point-cloud locations. 

![cover](./cover.png)

## Features

### Very flexible

The script is able to support a lot of point-cloud configurations thanks to
pre-defined attributes that must be created on the source location :

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
  

## Setup

#### User Arguments

##### user.pointcloud_sg

Scene graph location of the source (pointcloud)

##### user.instance_name

Naming template used for instances. 3 tokens available :

- `$id` _(mandatory)_: replaced by point number
  - can be suffixe by a number to add a digit padding, ex: `$id3` can give `008`
- `$sourcename` : basename of the instance source location used
- `$sourceindex` : index attribute that was used to determine the instance
source to pick.

## About

When the `$rotation` token is declared, it is always converted to individuals
`$rotationX/Y/Z` ones. This last one also specify the axis which is assumed to be :
```lua
axis = {
    x = {1,0,0},
    y = {0,1,0},
    z = {0,0,1}
}
```
`$rotation` attribute is assumed to be in the X-Y-Z order in the case where
`[2]` = 3

## Development

