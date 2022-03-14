# Pointcloud Xform to P

![lua](https://img.shields.io/badge/Lua-any-4f4f4f?labelColor=000090&logo=lua&logoColor=white)
![katana version](https://img.shields.io/badge/Katana-any-4f4f4f?labelColor=111111&logo=katana&logoColor=FCB123)

Allow merging `xform` transformations on a pointcloud or any location to the 
`geometry.point.P` attribute.

Supports motion-blur.

![demo](./demo.gif)


## Installation

### .lua

Create a new OpScript node and copy/paste the content of the .lua script inside.
Follow the instructions on the top comment to config the node.

## Guide

> ⚠ If your `xform` is interactive, you need to disable this Op before trying to
move it in the viewer as the xform attribute is deleted.

If the locations matched by CEL doesn't have a `geometry.point.P` it will yield
an error so check your CEL.
