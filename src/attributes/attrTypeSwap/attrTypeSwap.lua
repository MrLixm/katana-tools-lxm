--[[
version=3
author=Liam Collod
last_modified=03/03/2022

[OpScript setup]
parameters:
  location: location where attribute must be modified
  applyWhere: at specific location
user:
  attributes(string array): array of string where:
    - [1*n] = path of the attribute relative to the location
    - [2*n] = new DataAttribute type to use, ex: StringAttribute
]]

local function get_user_attr(time, name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value. (unless asked to raise an error)

    Args:
        time(int): frame the attribute must be queried at
        name(str): attribute location (don't need the <user.>)
        default_value(any): value to return if user attr not found
          you can use the special token <$error> to raise an error instead
    Returns:
        table or any: table of value on attribute or default value
    ]]
    local argvalue = Interface.GetOpArg("user."..name)

    if argvalue then
      return argvalue:getNearestSample(time)

    elseif default_value=="$error" then
      error("[get_user_attr] user attribute <",name,"> not found.")

    else
      return default_value

    end

end

local function get_loc_attr(attr_path, time, default)
  --[[
  Get the given attribute on the location at given time.
  Raise an error is nil result is found or return <default> if specified.

  If default is not nil and the attribute is not found, it is instead returned.

  Args:
    attr_path(str): path of the attribute on the location
    time(int): frame to extract the value from
    default(any or nil): value to return if attribute not found.
  Returns:
    table, num: [1]:table of value, [2] tuple size for the attribute
  ]]

  local lattr = Interface.GetAttr(attr_path)

  if not lattr then

    if default ~= nil then
      return default
    end

    error(
      "[get_loc_attr] Attr <",attr_path,"> not found on source <",location,">."
    )

  end

  local lattr_tuple = lattr:getTupleSize()
  lattr = lattr:getNearestSample(time)

  if not lattr then

    if default ~= nil then
      return default
    end

    error(
      "[get_loc_attr] Attr <", attr_path, "> is nil on source <", location,
      "> at time=", time
    )

  end

  return lattr, lattr_tuple

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
      ">is not supported."
    )
  end
end


local function run()

  local time = Interface.GetCurrentTime()

  local attr_list = get_user_attr(time, "attributes", "$error")

  local attr local value local attr_type local tuple_size
  for i=0, #attr_list / 2 - 1 do

    attr = attr_list[i*2+1]
    attr_type = get_attribute_class(attr_list[i*2+2])

    value, tuple_size = get_loc_attr(attr, time, nil)
    Interface.SetAttr(attr, attr_type(value, tuple_size))

  end

end

run()