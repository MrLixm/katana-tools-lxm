Welcome on the D2gt documentation.

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-blue?labelColor=blue)](INDEX.md)

# Installation

D2gt is meant to be use as a python module or just runned quickly in the script
editor so nothing special to install.

# Use

Concept is simple, create a dictionary with the proper syntax. Load it into
the `GafferDict` class, create a new `D2gtGaffer` with the
previous `GafferDict`
and build the node.

```python
token = {
    "__type": "d2gt_token",
    "lg_hdri_dome": "ArnoldHDRISkydomeLightPackage",
}
td = TokenDict(token)

scene = {
    "__type": "d2gt_gaffer",
    "name": "GafferThree_studio",
    "rootLocation": "/root/world/lgt/gaffer",
    "syncSelection": 1,
    "children": {
        "lg_hdri": {
            "parent": "/rig",
            "class": "<lg_hdri_dome>",
            "params": {}
        },

    }
}
gd = GafferDict(scene, tokendict=td)
gaffer = D2gtGaffer(gafferdict=gd)
gaffer_node = gaffer.build()
```

The above code will create a GafferThree node with a single Arnold HDRI Dome
light under a `/rig` location.

As you can notice we made use of 2 dictionary. A Token dict and a Gaffer dict.
There is usually one different Token dict per render-engine ,and it allows you
to have a render-engine agnostic Gaffer dict. Token can also be for anything
else that will be repeated multiple time in your GafferDict, up to you.

> token are only strings

I should mention that of course, you can use a `.json` to build your dict and
then convert it to python.

# GafferDict

Root keys correspond to the GafferThree node itself.

Light, rigs, ... are build in the `children` root key dictionary. The values in
the `children` key is the only place where tokens are parsed.

## `/__type`

> `mandatory` `str`

Required key with the value `d2gt_gaffer`. Just to make sure you are not
loading a random dict.

## `/name`

> `mandatory` `str`

Name must be unique in scene. If another node with the same name is found, this
node will be considered as previous version and updated. Updated means the
found version is deleted and a new version is created but this one will keep
the nodegraphs connections and position.

## `/rootLocation`

> `optional` `str` `default="/root/world/lgt/gaffer"`

Parameter of the same name on the GafferThree. Control what the root scene
graph location for all the light.

## `/syncSelection`

> `optional` `int` `default=1`

Parameter of the same name on the GafferThree.

## `/children`

> `mandatory` `dict`

Each key/value pair represents a Package to create in the GafferThree. Where
key = package scene graph name, Value = dict representing the Package structure

### `/children/K`

> `optional` `str`

Name of the package to create (used in the scenegraph location)

### `/children/K:V`

> `mandatory if K` `dict`

Package structure.

This is where you can use token. (in keys or values).

Tokens are always wrapped between `<>` like `<mytoken>`.

#### `/children/K:V/parent:V`

> `optional` `str` `default= root of the GafferThree`

CEL like path representing the location of the package relative to the
GafferThree one.

You can specify location that need to be created (RigPackage by default) or
specify another package actually specified in the GafferDict.

`/` is the separator. If at root use `""` or `"/"`.

Example with 2 packages :

```json
{
  "lg_area_A": {
    "parent": "/rig/foo",
    "class": "<lg_hdri_quad>",
    "params": {
      "material.<exposure>.value": 2
    }
  },
  "foo": {
    "parent": "/rig",
    "class": "RigPackage",
    "params": {
      "create.transform.translate.X": 15
    }
  }
}
```

In the above, `/rig` will be created automatically as a RigPackage, then
`/rig/foo` is created as specified in the dict, and then `lg_area_A` will be 
parented to `/rig/foo`.


#### `/children/K:V/class:V`

> `mandatory` `str`

Name of the Package's class to use. Depends on your render-engine. This is
recommended to use a token here.

Ex: `ArnoldHDRISkydomeLightPackage` that you can replace with the
token `<lg_hdri_dome>`

#### `/children/K:V/params:V`

> `optional` `dict`

Dictionnary where each key represent the path to a parameter to modify, and the
value, the parameter value to set.

##### `/children/K:V/params:V/K`

> `mandatory` `str`

Path on the package of the parameter to modify. Dot delimited path.
**Always start with the context node** to grab the parameter from.

Context node availables with their resolved function are :

```yaml
"create": getCreateNode()  # for any packages
"material": getMaterialNode()
"shadowlinking": getShadowLinkingNode()  # for light packages
"linking": getLinkingNodes()  # for light packages
"orientconstraint": getOrientConstraintNode()  # for rig packages
"pointconstraint": getPointConstraintNode()   # for rig packages
```

So to modify a parameter on the `create` node you prefix your path as
`create.path.to.param`.

Other example :

```python
# modify the exposure parameter on a LightPackage from Arnold:

"material.<exposure>.value"

# where the token <exposure> resolve to :

"exposure": "shaders.arnoldLightParams.exposure"

```

##### `/children/K:V/params:V/K:V`

> `mandatory` `any`

Value to set on the parameter specified by the key.

## example

```json
{
  "__type": "d2gt_gaffer",
  "name": "GafferThree_studio",
  "rootLocation": "/root/world/lgt/gaffer",
  "syncSelection": 1,
  "children": {
    "lg_hdri": {
      "parent": "/rig",
      "class": "<lg_hdri_dome>",
      "params": {
        "material.<filepath>.value": "C:/test.tx",
        "material.<filepath>.enable": 1,
        "material.<exposure>.value": 1,
        "material.<exposure>.enable": 1
      }
    },
    "lg_quad": {
      "parent": "",
      "class": "<lg_hdri_quad>",
      "params": {
        "material.<exposure>.value": 15,
        "material.<exposure>.enable": 1
      }
    }
  }
}
```

# TokenDict

Recommended having one per render-engine to keep the GafferDict agnostic.

"Flat" dictionnary where each key = a token

## `/__type`

> `mandatory` `str`

Required key with the value `d2gt_token`. Just to make sure you are not loading
a random dict.

## `/K`

> `optional` `str`

Token can only be strings. Here, they are without the `<>` around.

## `/K:V`

> `mandatory` `any`

Any type of value that must replace the token. Note that the value will always
be converted to a string at the end.

## example

```json
{
  "__type": "d2gt_token",
  "lg_hdri_dome": "ArnoldHDRISkydomeLightPackage",
  "lg_hdri_quad": "ArnoldQuadLightPackage",
  "exposure": "shaders.arnoldLightParams.exposure",
  "filepath": "shaders.arnoldSurfaceParams.filename"
}
```

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-blue?labelColor=blue)](INDEX.md)