--[[
version=0.0.1
todo
]]

local logging = require "lllogger"
local logger = logging:new("kui.array")
logger:set_level("debug")
logger.formatting:set_tbl_display_functions(false)
logger.formatting:set_str_display_quotes(true)

local PointCloudData = require "PointCloudData"


--[[ __________________________________________________________________________
  LUA UTILITIES
]]
-- we make some global functions local as this will improve performances in
-- heavy loops
local tostring = tostring
local stringformat = string.format
local select = select
local tableconcat = table.concat

local function conkat(...)
  --[[
  The loop-safe string concatenation method.
  ]]
  local buf = {}
  for i=1, select("#",...) do
    buf[ #buf + 1 ] = tostring(select(i,...))
  end
  return tableconcat(buf)
end

local function logerror(...)
  --[[
  log an error first then stop the script by raising a lua error()

  Args:
    ...(any): message to log, composed of multiple arguments that will be
      converted to string using tostring()
  ]]
  local logmsg = conkat(...)
  logger:error(logmsg)
  error(logmsg)

end

local function logassert(toassert, ...)
  --[[
  Check is toassert is true else log an error.

  Args:
    ...(any): arguments used for log's message. Converted to string.
  ]]
  if not toassert then
    logerror(...)
  end
  return toassert
end

--[[ __________________________________________________________________________
  Katana UTILITIES
]]

local OPARG = Interface.GetOpArg()

local function get_attribute_class(kattribute)
  --[[
  Returned a non-instanced version of the class type used by the given arg.

  Args:
    kattribute(IntAttribute or FloatAttribute or DoubleAttribute or StringAttribute)
  Returns:
    table: DataAttribute
  ]]
  if Attribute.IsInt(kattribute) == true then
    return IntAttribute
  elseif Attribute.IsFloat(kattribute) == true then
    return FloatAttribute
  elseif Attribute.IsDouble(kattribute) == true then
    return DoubleAttribute
  elseif Attribute.IsString(kattribute) == true then
    return StringAttribute
  else
    logerror(
      "[get_attribute_class] passed attribute <",
      kattribute,
      ">is not supported."
    )
  end
end

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
        table: Katana DataAttribute or default value wrap in a table
    ]]
    local argvalue = Interface.GetOpArg(conkat("user.",name))

    if argvalue then
      return argvalue:getNearestSample(time)

    elseif default_value=="$error" then
      logerror("[get_user_attr] user attribute <",name,"> not found.")

    else
      return { default_value }

    end

end

local function get_loc_attr(location, attr_path, time, default)
  --[[
  Get the given attribute on the location at given time.
  Raise an error is nil result I found or return <default> if specified.

  If default is not nil and the attribute is not found, it is instead returned.

  Args:
    location(str): scene graph location to extract teh attribute from
    attr_path(str): path of the attribute on the location
    time(int): frame to extract the value from
    default(any or nil): value to return if attribute not found.
  Returns:
    table: table of 2: {value table, table representing the original data type}
  ]]

  local lattr = Interface.GetAttr(attr_path, location)

  if not lattr then

    if default ~= nil then
      return default
    end

    logerror(
      "[get_loc_attr] Attr <",attr_path,"> not found on source <",location,">."
    )

  end

  local lattr_type = get_attribute_class(lattr)

  lattr = lattr:getNearestSample(time)

  if not lattr then

    if default ~= nil then
      return default
    end

    logerror(
      "[get_loc_attr] Attr <", attr_path, "> is nil on source <", location,
      "> at time=", time
    )

  end

  return lattr, lattr_type

end

--[[ __________________________________________________________________________
  CONSTANTS
]]


-- // Used by InstancingArray
-- key is the token to query and value is the target attribute path
-- if the token doesnt have any value on point_data it will not be added.
-- order is important
local token_target = {
  { ["token"]="sources", ["target"]="geometry.instanceSource" },
  { ["token"]="index", ["target"]="geometry.instanceIndex" },
  { ["token"]="translation", ["target"]="geometry.instanceTranslate" },
  -- if the pdata was validated, we for sure have rotationX/Y/Z
  { ["token"]="rotationZ", ["target"]="geometry.instanceRotateZ" },
  { ["token"]="rotationY", ["target"]="geometry.instanceRotateY" },
  { ["token"]="rotationX", ["target"]="geometry.instanceRotateX" },
  { ["token"]="scale", ["target"]="geometry.instanceScale" },
  { ["token"]="matrix", ["target"]="geometry.instanceMatrix" },
}


--[[ __________________________________________________________________________
  API
]]


local InstancingArray = {}
function InstancingArray:new(point_data)
  --[[

  Made the link between PointCloudData and instance creation.

  Args:
    point_data(PointCloudData) : PointCloudData instance that has been built.

  Attributes:
    pdata(PointCloudData): PointCloudData instance

  ]]

  local attrs = {
    pdata = point_data,
  }

  function attrs:add(target, value)
    --[[
    Args:
      target(str):
      value(DataAttribute or nil):
    ]]
    if value == nil then
      return
    end

    Interface.SetAttr(target, value)

  end

  function attrs:build()
    --[[
    Build the array instance from PointCloudData
    ]]

    -- 1. PROCESS COMMON & SOURCES ATTRIBUTES
    for _, tt in ipairs(token_target) do
      self:add(tt["target"], self.pdata:get_attr_value(tt["token"]))
    end

    -- 2. PROCESS ARBITRARY ATTRIBUTES
    for target, arbtr_data in pairs(self.pdata["arbitrary"]) do
      -- 1. first process the additional table
      -- we only use arbtr_data for the <additional> key yet so we can do this
      arbtr_data = arbtr_data["additional"]  -- type: table
      for addit_target, addit_value in pairs(arbtr_data) do
        self:add(addit_target, addit_value)
      end
      -- 2. Add the arbitrary attribute value
      self:add(target,  self.pdata:get_attr_value(target))
    end

  end

  return attrs
end


-- processes ------------------------------------------------------------------

local function run()
  --[[
  Create the instance
  ]]
  local stime = os.clock()
  local time = Interface.GetCurrentTime() -- int

  local u_pointcloud_sg = get_user_attr( time, "pointcloud_sg", "$error" )[1]

  -- process the source pointcloud
  logger:info("Started processing source <", u_pointcloud_sg, ">.")
  local pointdata
  pointdata = PointCloudData:new(u_pointcloud_sg, time)
  pointdata:build()
  logger:info("Finished processing source <", u_pointcloud_sg, ">.",
      pointdata.point_count, " points found.")

  logger:debug("pointdata = \n", pointdata, "\n")
  -- start instancing
  local instance
  instance = InstancingArray:new(pointdata)
  instance:build()

  stime = os.clock() - stime
  logger:info("Finished in ",stime,"s for pointcloud <",u_pointcloud_sg,">.")

end

print("\n")
run()