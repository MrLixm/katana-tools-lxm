# Index

Welcome on the `LightViewerAnnotate` module's documentation.

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)

# Installation

## .xml

Fastest and easiest way to create the setup !

Copy the content of the [LightViewerAnnotate.node.xml](../LightViewerAnnotate.node.xml)
file and paste it into the Katana Nodegraph.

## .lua

Create a new OpScript node and copy/paste the content of the .lua script inside.
You then need to set the following user arguments :

### user.annotation_color_gamma
`(float)` `(2)`: gamma controler for the color if lights and annotations
### user.annotation_colored
`(bool)` `(true)`: true to color the annotation in the viewer
### user.lights_colored
`(bool)` `(true)`: true to color the light in the viewer
### user.annotation_template
`(str)` `("<name>")`: Use tokens to build the annotation for each light.
tokens are defined in `Light.tokens` and are surrounded with `<>`

It is recommended then to set the CEL to match all light locations.
Usually this would work fine :

```
/root/world/lgt//*{@type=="light"}
```

You can of course modify the CEL to be more specific if you don't want to annotate 
all the lights.

# API

Listed are only objects useful for extend the script features/support.


## !["class"](https://img.shields.io/badge/"class"-6F5ADC) Light

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) `table` Light.tokens

#### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) `table` Light.tokens.$token

#### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) `table` Light.tokens.$token.$renderer

##### ![attribute](https://img.shields.io/badge/attribute-353535) `function` Light.tokens.$token.$renderer.func

optional if not `params`

##### ![attribute](https://img.shields.io/badge/attribute-353535) `table` Light.tokens.$token.$renderer.params

optional

### ![method](https://img.shields.io/badge/method-4f4f4f) Light:get
### ![method](https://img.shields.io/badge/method-4f4f4f) Light:to_annotation


### ![function](https://img.shields.io/badge/function-6F5ADC) get_light_renderer

Return a string identifying the render-engine used by the currently
visited light.

```
Raises:
    when a renderer can't be found for the current light location
Returns:
    str:
```


## ![function](https://img.shields.io/badge/function-6F5ADC) run

Create the annotation for the current light visited by the OpScript.

# Development

## New render-engine

_renderer=render-engine_

You will need to modify the `get_light_renderer()` function and
the `Light` table.

### ![function](https://img.shields.io/badge/function-4f4f4f) get_light_renderer

Must return a string identifying the current render-engine used by the light.
This string must then be used as a key for the `Light.tokens.$token.$renderer`.

To add a renderer, copy/paste the previous `elseif` line and then modify the
`string.find` pattern based on how the `material` shader's name start. Just have
a look at the attribute on your light located in the `material` group.

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) Light.tokens.$token.$renderer

You can then add a key for each token in the `Light.tokens` table that correspond
to your new renderer name returned in `get_light_renderer()`.

```lua

local Light = {
  
    ["tokens"] = {
      
      ["exposure"] = {
        ["myRenderer"] = {
          func = get_light_attr,
          params = { { "material.myRendererLightParams.exposure" }, 0 },
        },
        ["prman"] = {
          func = get_light_attr,
          params = { { "material.prmanLightParams.exposure" }, 0 },
        },
      },
      -- ... other tokens
      
    }
}
```

## New token

You will only need to modify the `Light` table.



---

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
