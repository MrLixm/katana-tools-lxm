--[[
VERSION=1.0.0

OpScript for Foundry's Katana software
This script is compatible with Arnold but can be modified to others.

Annotate (& color) lights in the viewer using their attributes.

Author: Liam Collod
Last Modified: 18/10/2021

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
]]


local LOG_LEVEL = "info" -- debug, info, warning, error


--[[ __________________________________________________________________________
  LUA UTILITIES
]]


function split(str, sep)
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


function round(num, numDecimalPlaces)
  -- Source: http://lua-users.org/wiki/SimpleRound
  -- Returns: number
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


function table2string(tablevalue)
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


function stringify(source)
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


logging = {}


function logging:new(name)
  --[[
  Simple logging system.

  Parameters:
    name(str): name of the logger to be displayed on every message
  ]]

  local attrs = {
    name = name,
    levels = {
      debug = {
        name = "  DEBUG",
        weight = 10
      },
      info = {
        name = "   INFO",
        weight = 20
      },
      warning = {
        name = "WARNING",
        weight = 30
      },
      error = {
        name = "  ERROR",
        weight = 40,
      }
    },
    level = nil
  }

  attrs["level"] = attrs["levels"][LOG_LEVEL]

  function attrs:_log(level, message)

    if level.weight < self.level.weight then
      return
    end

    message = stringify(message)

    print("[OpScript]["..level.name.."]["..self.name.."] "..message)

  end

  function attrs:debug(message)
    self:_log(self.levels.debug, message)
  end

  function attrs:info(message)
    self:_log(self.levels.info, message)
  end

  function attrs:warning(message)
    self:_log(self.levels.warning, message)
  end

  function attrs:error(message)
    self:_log(self.levels.error, message)
  end

  return attrs

end


logger = logging:new("LightViewerAnnotate")



--[[ __________________________________________________________________________
  API UTILITIES
]]


local time = Interface.GetCurrentTime() -- int


function color_gamma(color, gamma)
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

function get_user_attr(frame, name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value

    Args:
        frame(int): current frame
        name(str): attribute location (don't need the <user.>
        default_value(any): value to return if user attr not found
    Returns:
        type depends of input
    ]]
    local argvalue = Interface.GetOpArg("user."..name)
    if argvalue then
        return argvalue:getNearestSample(frame)[1]
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
      return attr:getNearestSample(time)
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

function process_annotation(annotation, light)
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


function run()

  local annotation_template = get_user_attr(time, "annotation_template", "<name>")
  local annotation_color_gamma = get_user_attr(time, "annotation_color_gamma", 1)
  local annotation_colored = get_user_attr(time, "annotation_colored", 1)
  local lights_colored = get_user_attr(time, "lights_colored", 1)


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

  logger:debug("[run] Finished. Annotation set to <"..annotation..">")

end

-- execute
run()