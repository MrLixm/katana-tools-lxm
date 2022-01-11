--[[
todo
]]

local logging = require "lllogger"
local logger = logging:new("kui.hierarchical")
logger:set_level("debug")

--[[ __________________________________________________________________________
  LUA UTILITIES
]]

function conkat(...)
  local buf = {}
  for i=1, select("#",...) do
    buf[ #buf + 1 ] = tostring(select(i,...))
  end
  return table.concat(buf)
end

function logerror(...)
  --[[
  log an error first then stop the script by raising a lua error()

  Args:
    ...(any): message to log, composed of multiple arguments
  ]]
  local logmsg = conkat(...)
  logger:error(logmsg)
  error(logmsg)

end

--[[ __________________________________________________________________________
  Katana UTILITIES
]]

function get_attribute_class(kattribute)
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

function get_user_attr(frame, name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value. (unless asked to raise an error)

    Args:
        frame(int): current frame (=time if you will)
        name(str): attribute location (don't need the <user.>)
        default_value(any): value to return if user attr not found
          you can use the special token <$error> to raise an error instead
    Returns:
        table: Katana DataAttribute or default value wrap in a table
    ]]
    local argvalue = Interface.GetOpArg(conkat("user.",name))

    if argvalue then
      return argvalue:getNearestSample(frame)

    elseif default_value=="$error" then
      logerror("[get_user_attr] user attribute <",name,"> not found.")

    else
      return { default_value }

    end

end

function get_loc_attr(location, attr_path, time)
  --[[
  Get the given attribute on the location at given time.
  Make sure no nil can be returned.

  Args:
    location(str): scene graph location to extract teh attribute from
    attr_path(str): path of the attribute on the location
    time(int): frame to extract the value from
  Returns:
    table: table of 2: {value table, table representing the original data type}
  ]]

  local logmsg
  local lattr = Interface.GetAttr(attr_path, location)

  if not lattr then
    logerror(
      "[get_loc_attr] Attr <",attr_path,"> not found on source <",location,">."
    )
  end

  local lattr_type = get_attribute_class(lattr)
  lattr = lattr:getNearestSample(time)

  if not lattr then
    logerror(
      "[get_loc_attr] Attr <", attr_path, "> is nil on source <", location,
      "> at time=", time
    )
  end

  return lattr, lattr_type

end

--[[ __________________________________________________________________________
  API
]]

local InstanceHierarchical = {}

function InstanceHierarchical:new(name)

  local attrs = {
    name = name,
    gb = GroupBuilder(),
    data = {}
  }

  self.gb:update(Interface.GetOpArg())
  self.gb:set("childAttrs.type", StringAttribute("instance"))

  function attrs:set_instance_source(instance_source)
    -- instance_source(str): existing scene graph location
    self.data.instance_source = instance_source
    self.gb:set(
        "childAttrs.geometry.instanceSource",
        StringAttribute(instance_source)
    )
  end

  function attrs:set_arbitrary(attr_path, attr_value)
    --[[
    Args:
      attr_path(str): where the attribute should live on the instance.
        Start at Instance root.
      attr_value(DataAttribute): Katana DataAttribute class
    ]]
    local buf = {"childAttrs."}
    table.insert(buf, attr_path)
    self.gb:set(table.concat(buf), attr_value)
  end

  function attrs:finalize()
    --[[
    Last method to call once you finish building the Instance.
    ]]
    Interface.CreateChild(
      self.name,
      Interface.GetOpType(),
      self.gb:build()
    )
  end

  return attrs

end

local pointcloudData = {}
function pointcloudData:new(location, time)
  --[[
  Args:
    location(str): scene graph location of the pointcloud
  ]]

  local attrs = {
    ["time"]=time,
    ["location"]=location,
    ["common"]={
      ["scale"]=false,
      ["rotation"]=false,
      ["translation"]=false,
      ["index"]=false,
      ["points"]=false,
      ["matrix"]=false,
      ["rotationX"]=false,
      ["rotationY"]=false,
      ["rotationZ"]=false
    },
    ["sources"]=false,
    ["arbitrary"]=false
  }

  function attrs:check_token(token)
    --[[
    Args:
      token(str): string that should start with <$>
      source(str): scene graph location where this token is stored
    Returns:
      str: token without the <$>
    ]]
    for token_supported, _ in pairs(self.common) do
      -- add the <$> in font of the known token for comparison with the arg
      token_supported = conkat("$", token_supported)
      -- if similar retur the arg token without the <$>
      if token_supported == token then
        return token:gsub("%$", "")
      end
    end

    logerror(
      "[check_token] invalid token <",token,"> on source <",self.location,">."
    )

  end

  function attrs:get_common_value_at_index(attr_name, index)
    --[[
    ]]
    local logmsg

    local attrdata = self.attrs[attr_name]

    if not attrdata then
      logerror(
        "[pointcloudData][get_common_value_at_index]",
        "attr <",
        attr_name,
        "> is nil for "
      ) -- TODO
    end
  end

  function attrs:build()
    self:build_common()
    self:build_arbitrary()
    self:build_sources()
  end

  function attrs:build_sources()

  end

  function attrs:build_arbitrary()

  end

  function attrs:build_common()

      -- get the attribute on the pc
    local data_common = get_loc_attr(
        self.location,
        "instancing.data.common",
        self.time
    )

    local token
    local grouping
    local multiplier
    local path
    local pcvalues
    local value_type

    -- start building the common key
    for i=0, #data_common / 4 - 1 do

      token = self:check_token(data_common[4*i+2])
      grouping = tonumber(data_common[4*i+3])
      multiplier = tonumber(data_common[4*i+4])
      path = data_common[4*i+1]
      pcvalues, value_type = get_loc_attr(self.location, path, self.time)

      -- process special cases here
      if token == "points" then
        -- <values> key should always be a table so just fill it with 0 here
        local pointsvalue = {}
        for pointindex=1, #pcvalues / grouping * multiplier do
          pointsvalue[pointindex] = 0
        end
        pcvalues = pointsvalue
        grouping = 1
      end

      self["common"][token] = {
        ["path"] = path,
        ["grouping"] = grouping,
        ["multiplier"] = multiplier,
        ["values"] = pcvalues,
        ["type"] = value_type
      }

    end
    -- now we do result validation
    local logmsg

    if not self.common.points then
      logerror(
        "[pointcloudData][build_common] Missing attribute $points on source <",
        self.location,
        ">."
      )
    end

    local pointsn = #self.common.points.values -- int: number of points
    local attrlength

    for attrname, attrdata in pairs(self.common) do
      -- attrdata can be <false> if not built
      if attrdata then
        attrlength = #(attrdata.values) / attrdata.grouping
        if attrlength ~= pointsn then
          logerror(
              "[pointcloudData][build_common] Common attribute <", attrname,
              "> as an odd number of values : ", tostring(#(attrdata.values)),
              " / ", tostring(attrdata.grouping), " = ", attrlength,
              " while $points=", pointsn
          )
        end
        -- if attrdata is not false/nil
      end
      -- end for attrname, attrdata
    end

  end

  return attrs

end

function create_instances()
  --[[
  When Interface at root
  ]]
  local stime = os.clock()
  local time = Interface.GetCurrentTime() -- int

  local u_pointcloud_sg = get_user_attr( time, "pointcloud_sg", "$error" )[1]
  local u_instance_name = get_user_attr( time, "instance_name", "$error" )[1]
  local u_index_offset = get_user_attr( time, "index_offset", 0 )[1]

  local data = pointcloudData:new(u_pointcloud_sg, time)
  data:build()
  logger:debug("pc_data = \n", data, "\n")

  local instance

  --for i=0, #data.points.values - 1 do
  --
  --  instance = InstanceHierarchical:new()
  --
  --end

  stime = os.clock() - stime
  logger:info(
      conkat("Finished in ",stime,"s for pointcloud <",u_pointcloud_sg,">.")
  )

end

function finalize_instances()
  --[[
  When Interface is not at root

  Not recommended to log anything here as the message will be repeated times
  the number of instances (so can be thousands !)
  ]]

  local childAttrs = Interface.GetOpArg("childAttrs")

  for i=0, childAttrs:getNumberOfChildren() - 1 do

    Interface.SetAttr(
        childAttrs:getChildName(i),
        childAttrs:getChildByIndex(i)
    )

  end

end

function run()
  --[[
  First function executed
  ]]

  print(string.rep("\n", 10))

  if Interface.AtRoot() then
    create_instances()
  else
    finalize_instances()
  end

end

-- execute
run()