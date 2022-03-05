# Pointcloud Width

![lua](https://img.shields.io/badge/Lua-any-4f4f4f?labelColor=000090&logo=lua&logoColor=white)
![katana version](https://img.shields.io/badge/Katana-any-4f4f4f?labelColor=FCB123&logo=katana&logoColor=black)

Add a `geometry.point.width` attribute to control the size of the points in
the viewer or scale the existing one.

![demo](./demo.gif)


## Installation

### .lua

Create a new OpScript node and copy/paste the content of the .lua script inside.
Follow the instructions on the top comment to config the node.

## Guide

The default point size is `1` 

If there is already a `geometry.point.width` attribute the `user.point_size`
parameter will be multiplied to the existing values.

