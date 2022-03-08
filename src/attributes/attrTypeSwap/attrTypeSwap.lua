--[[
version=12
author=Liam Collod
last_modified=08/03/2022

[OpScript setup]
parameters:
  location: location where attribute must be modified
  applyWhere: at specific location
user:
  attributes(string array): array of string where:
    - [1*n] = path of the attribute relative to the location
    - [2*n] = new DataAttribute type to use, ex: StringAttribute
  method(string)(optional): which method to use to get data:
    - table : max of 2^27 (134 million) values per attribute
    - array (default): a bit slower, no limit
]]


local function err(...)
  --[[
  Raise an error.
  Concat the given arguments to string and pass them as the error's message.
  ]]

  local buf = {"[attrTypeSwap]["}
  buf[ #buf + 1 ] = Interface.GetInputLocationPath()
  buf[ #buf + 1 ] = "]"

  for i=1, select("#",...) do
    buf[ #buf + 1 ] = tostring(select(i,...))
  end

  error(table.concat(buf))

end


local function get_user_attr(name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value. (unless asked to raise an error)

    Args:
        name(str): attribute location (don't need the <user.>)
        default_value(any): value to return if user attr not found
          you can use the <error> builtin to raise an error instead
    Returns:
        table or any: table of value on attribute or default value
    ]]
    local argvalue = Interface.GetOpArg("user."..name)

    if argvalue then
      return argvalue:getNearestSample(0)

    elseif default_value==error then
     err("[get_user_attr] user attribute <",name,"> not found.")

    else
      return default_value

    end

end


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

    err(
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
    err(
      "[get_attribute_class] passed class name <",
      class_name,
      "> is not supported."
    )
  end
end


local function run()

  local u_attr_list = get_user_attr("attributes", error)
  local method_table = "table"
  local method_array = "array"
  local u_method = get_user_attr("method", method_array)[1]

  local attr
  local data
  local attr_type
  local new_value
  local sample
  local samples

  for i=0, #u_attr_list / 2 - 1 do

    attr = u_attr_list[i*2+1]
    attr_type = get_attribute_class(u_attr_list[i*2+2])
    data = get_loc_attr(attr)
    new_value = {}

    if u_method == method_table then

      samples = data:getNumberOfTimeSamples()

      for smplindex=0, samples - 1 do
        -- convert the smplindex to sampletime (shutterOpen/Close values)
        sample = data:getSampleTime(smplindex)
        new_value[sample] = data:getNearestSample(sample)
      end

    elseif u_method == method_array then

      samples = data:getSamples()

      for smplindex=0, #samples - 1 do
        sample = samples:get(smplindex)
        new_value[sample:getSampleTime()] = sample:toArray()
      end

    else
      err("[run] method <", u_method, "> not supported.")
    end

    Interface.SetAttr(attr, attr_type(new_value, data:getTupleSize()))

  end

end

run()