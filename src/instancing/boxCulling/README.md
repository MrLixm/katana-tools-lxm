# boxCulling

![Lua](https://img.shields.io/badge/Lua-000090?logo=lua&logoColor=white) ![Katana version](https://img.shields.io/badge/Katana-4.0+-FCB123?colorA=2e3440&logo=katana&logoColor=white) ![maintained - yes](https://img.shields.io/badge/maintained-yes-blue)

Lua script designed for Katana OpScript feature. Used on point-cloud location 
to "remove" points using meshs locations.

![cover](./cover.png)

# Features


# Use

## OpScript Config

- location: point-cloud scene graph location
- applyWhere: at specific location
- User Arguments :
  - `user.culling_locations`(string array): list of scene graph locations whomse bounding box shall be used to prune points
