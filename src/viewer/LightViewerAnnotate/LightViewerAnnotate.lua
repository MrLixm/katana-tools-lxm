--[[
version=10
author=Liam Collod
last_modified=05/03/2022

OpScript for Foundry's Katana software
This script is compatible with Arnold but can be modified to others.

Annotate (& color) lights in the viewer using their attributes.

[OpScript setup]
parameters:
    location:  /root/world/lgt//*{@type=="light"}
    applyWhere: at locations matching CEL
user(type)(default_value):
  user.annotation_color_gamma(float)(2): gamma controler for the color if lights and annotations
  user.annotation_colored(bool)(true): true to colro the annotation in the viewer
  user.lights_colored(bool)(true): true to color the light in the viewer
  user.annotation_template(str)("<name>"): Use tokens to build the annotation for each light.
     tokens are defined in Light.attributes and are surrounded with <>

[License]
Copyright 2022 Liam Collod

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]


--[[ __________________________________________________________________________
  LUA UTILITIES
]]

local split
local round
local table2string
local stringify

split = function(str, sep)
  --[[
  Source: https://stackoverflow.com/a/25449599/13806195
  ]]
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
     table.insert(result, each)
  end
  return result
end


round = function(num, numDecimalPlaces)
  -- Source: http://lua-users.org/wiki/SimpleRound
  -- Returns: number
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


table2string = function(tablevalue)
    --[[
  Convert a table to a one line string.
  If the key is a number, only the value is kept.
  If the key is something else, it is formatted to "tostring(key)=tostring(value),"

  Parameters:
    tablevalue(table): table to convert to string

  Returns:
    str:
  ]]

  local outtable = {"{"}
  local ctable = {} -- to avoid string concatenation in loop

  for k, v in pairs(tablevalue) do
    -- to avoid string concatenation in loop
    if (type(k) == "number") then
      table.insert(outtable, stringify(v)..", ")
    else
      ctable[1] = stringify(k)
      ctable[2] = "="
      ctable[3] = stringify(v)
      ctable[4] = ", "
      table.insert(outtable,tostring(table.concat(ctable)))
    end
  end

  table.insert(outtable, "}")

  return table.concat(outtable)

end


stringify = function(source)
    --[[ Convert the source to a readable string , based on it's type.
    All numbers are rounded to 3 decimals.
    ]]
    local number_round = 3  -- number of decimals to keep.

    if (type(source) == "table") then
      if #source == 1 then
        return source[1]
      end
      source = table2string(source)

    elseif (type(source) == "number") then
      source = tostring(round(source, number_round))

    else
      source = tostring(source)

    end

  return source

end



--[[ __________________________________________________________________________
  API UTILITIES
]]


local function color_gamma(color, gamma)
  --[[
  Change the gamma of the given color value (float3)

  Args:
    color(table): table of float
    gamma(float): gamma value to apply
  ]]
  local out = color
  for index, color_channel in pairs(color) do
    out[index] = color_channel ^ gamma
  end
  return out

end

local function get_user_attr(name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value

    Args:
        name(str): attribute location (don't need the <user.>
        default_value(any): value to return if user attr not found
    Returns:
        type depends of input
    ]]
    local argvalue = Interface.GetOpArg("user."..name)
    if argvalue then
        return argvalue:getValue()
    else
      return default_value
    end

end


local Light = {}
function Light:new(location)
  --[[
  This is the classes that will allow to query a light attributes.
  The system was designed to be flexible(render-agnostic) but this example
  if for Arnold.

  Customization is performed through self.attributes which is a table:
    - each table key is an abitrary string representing the attribute name
      - its value is a table of 2 fixed items:
        - key:func = function to execute that will return the value querried.
        - key:params = table of arguments to pass to the above function (with unpack())

  You can of course create any method here that can be then used in self.attributes.

  ]]

  local attrs = {
    location = location,
    attributes = {}
  }

  function attrs:get(attr_name)
    --[[
    Return the light attribute value for the given attribute name

    Returns:
      type depends of what's queried, can be nil
    ]]
    local attr = self.attributes[attr_name]
    return attr.func(self, unpack(attr.params))
  end

  function attrs:get_attr(attr_name, default_value)
  --[[
    Args:
        attr_name(str): name of the attribute to get
        default_value(any): value to return if attr not found
    Returns:
        type depends of input
    ]]
    local attr = Interface.GetAttr(attr_name)
    if attr then
      return attr:getNearestSample(0)
    else
      return default_value
    end
  end

  function attrs:get_name()
    --[[
    Returns:
      str: name of the light based on its scene graph location.
    ]]
    local name = split(self.location, "/")
    return name[#name]  -- return the last element of the list
  end

  -- post process the attrs for the one requiring the methods to be created.

  attrs.attributes = {
      aov = {
        func = attrs.get_attr,
        params = {"material.arnoldLightParams.aov", "default"},
      },
      name = {
        func = attrs.get_name,
        params = {},
      },
      color = {
        func = attrs.get_attr,
        params = {"material.arnoldLightParams.color", {1,1,1}},
      },
      samples = {
        func = attrs.get_attr,
        params = {"material.arnoldLightParams.samples", 1},
      },
      exposure = {
        func = attrs.get_attr,
        params = {"material.arnoldLightParams.exposure", 0.0},
      },
      intensity = {
        func = attrs.get_attr,
        params = {"material.arnoldLightParams.intensity", 1.0},
      },
  }

  return attrs

end

local function process_annotation(annotation, light)
  --[[
  Args:
    annotation(str): annotation template submitted by the user (with tokens)
    light(table): currently processed light object.
  Returns:
    str: annotation with the tokens replaced
  ]]
  for attr_name, attr_getter in pairs(light.attributes) do
    local token = "<"..attr_name..">"
    local value = stringify(light:get(attr_name))
    annotation = string.gsub(annotation, token, value)
  end

  return annotation

end


local function run()

  local annotation_template = get_user_attr("annotation_template", "<name>")
  local annotation_color_gamma = get_user_attr("annotation_color_gamma", 1)
  local annotation_colored = get_user_attr("annotation_colored", 1)
  local lights_colored = get_user_attr("lights_colored", 1)


  local light = Light:new(Interface.GetInputLocationPath())
  local annotation = process_annotation(annotation_template, light)
  local color = light:get("color") -- table of float or nil
  if color then
     color = color_gamma(color, annotation_color_gamma)
  end

  if annotation_colored==1 then
    Interface.SetAttr(
        "viewer.default.annotation.color",
        FloatAttribute(color or {0.1, 0.1, 0.1})
    )
  end

  if lights_colored==1 then
    Interface.SetAttr(
        "viewer.default.drawOptions.color",
        FloatAttribute(color or {0.1, 1.0, 1.0})
    )
  end

  Interface.SetAttr("viewer.default.annotation.text", StringAttribute(annotation))

  --print("[LightViewerAnnotate][run] Finished. Annotation set to <"..annotation..">")

end

-- execute
run()