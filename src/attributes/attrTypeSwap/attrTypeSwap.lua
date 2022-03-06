--[[
version=7
author=Liam Collod
last_modified=06/03/2022

[OpScript setup]
parameters:
  location: location where attribute must be modified
  applyWhere: at specific location
user:
  attributes(string array): array of string where:
    - [1*n] = path of the attribute relative to the location
    - [2*n] = new DataAttribute type to use, ex: StringAttribute
]]

local function get_loc_attr(attr_path)
  --[[
  Get the given attribute on the location.
  Raise an error is nil result is found.

  Args:
    attr_path(str): path of the attribute on the location
  Returns:
    DataAttribute:
  ]]

  local lattr = Interface.GetAttr(attr_path)

  if not lattr then

    error(
      "[get_loc_attr] Attr <",attr_path,"> not found on source <",
      Interface.GetInputLocationPath(),">."
    )

  end

  return lattr

end

local function get_attribute_class(class_name)
  --[[
  Returned a non-instanced version of the DataAttribute given in arg.

  Args:
    class_name(str): name of the DataAttribute class
  Returns:
    table: DataAttribute
  ]]
  if class_name == "IntAttribute" then
    return IntAttribute
  elseif class_name == "FloatAttribute" then
    return FloatAttribute
  elseif class_name == "DoubleAttribute" then
    return DoubleAttribute
  elseif class_name == "StringAttribute" then
    return StringAttribute
  else
    error(
      "[get_attribute_class] passed class name <",
      class_name,
      "> is not supported."
    )
  end
end


local function run()

  local attr_list = Interface.GetOpArg("user.attributes")
  if attr_list then
    return attr_list:getNearestSample(0)
  else
    error("[run] User Argument <user.attributes> not found.")
  end

  local attr
  local value
  local attr_type
  local new_value
  for i=0, #attr_list / 2 - 1 do

    attr = attr_list[i*2+1]
    attr_type = get_attribute_class(attr_list[i*2+2])
    value = get_loc_attr(attr)
    new_value = {}

    for smplindex=0, value:getNumberOfTimeSamples() - 1 do
      -- convert the smplindex to sampletime (shutterOpen/Close values)
      smplindex = value:getSampleTime(smplindex)
      new_value[smplindex] = value:getNearestSample(smplindex)
    end

    Interface.SetAttr(attr, attr_type(new_value, value:getTupleSize()))

  end

end

run()