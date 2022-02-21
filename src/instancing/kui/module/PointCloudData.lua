--[[
version=0.0.1
todo
]]

local logging = require "lllogger"
local logger = logging:new("kui.PointCloudData")
logger:set_level("debug")
logger.formatting:set_tbl_display_functions(false)
logger.formatting:set_str_display_quotes(true)


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


local function get_loc_attr(location, attr_path, time, default)
  --[[
  Get the given attribute on the location at given time.
  Raise an error is nil result is found or return <default> if specified.

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


-- list of supported tokens with useful info used internally
-- <is_transform==true> force use of DoubleAttribute for values.
local Tokens = {
      ["points"]       = { ["is_transform"]=false },
      ["index"]        = { ["is_transform"]=false },
      ["skip"]         = { ["is_transform"]=false },
      ["hide"]         = { ["is_transform"]=false },
      ["matrix"]       = { ["is_transform"]=true },
      ["translation"]  = { ["is_transform"]=true },
      ["scale"]        = { ["is_transform"]=true },
      ["rotation"]     = { ["is_transform"]=true },
      ["rotationX"]    = { ["is_transform"]=true },
      ["rotationY"]    = { ["is_transform"]=true },
      ["rotationZ"]    = { ["is_transform"]=true }
}

-- expected number of value per different attribute on source
local AttrGrp = {
  ["common"] = 5,
  ["arbitrary"] = 6,
  ["sources"] = 2
}


local function build_attr_structure(
    path, grouping, multiplier, additive, values, type, processed
)
  --[[
  Build the table for a <common> or an <arbitrary> attribute

  Might not respresent the final structure (arbitrary add an <additional> key)

  Args:
    path(str):
    grouping(num):
    multiplier(num): multiplier to apply to values
    additive(num): offset to apply to values
    values(table): value should always be a numerical index table
    type(DataAttribute): with what Data type values must be encoded
    processed(table or nil): optional, usually build in finalize()
  ]]

  if path == nil or grouping==nil or multiplier==nil or additive==nil or
  values==nil or type==nil then
    -- shittiest error message but don't want to complexify the function
    logerror("[build_attr_structure] One of the supplied arguments is nil")
  end

  return {
    ["path"] = path,
    ["grouping"] = grouping,
    ["multiplier"] = multiplier,
    ["additive"] = additive,
    ["values"] = values,
    ["type"] = type,
    ["processed"] = processed,
  }

end



local PointCloudData = {}
function PointCloudData:new(location, time)
  --[[
  Represents attribute data holded on a pointcloud location. (or actually
  any locations with the supported <instancing> attributes).

  Notes:
    Once validated, <rotation> attribute is splitted to its
     <rotationX/Y/Z> brothers (if only <rotation> was specified first)

  Args:
    location(str): scene graph location of the pointcloud
    time(int): time at which attributes must be queried

  Attributes:
    time(int): time at which attributes must be queried
    location(str): scene graph location of the pointcloud
    common(table): keys are supported token value (+$)
    sources(table): num keys
    arbitrary(table): keys are instance target attribute path
    __attrdata(table or false):
      set by __get_attr_data(), make sure the method has been called before use
    __buffer2(any or false):
      used to store value without having to create a new local variable

  See ./README.md for detailed structure.
  ]]

  local attrs = {
    ["__attrdata"]=false,
    ["__buffer2"]=false,
    ["time"]=time,
    ["location"]=location,
    ["common"]={},
    ["sources"]=false,
    ["arbitrary"]=false,
    ["point_count"]=false
  }

  -- build the common key with all the supported tokens
  for token_name, _ in pairs(Tokens) do
    self["common"][token_name] = false
  end

  function attrs:check_token(token)
    --[[
    Check if the given token is a valid token and if so return it without the $

    Args:
      token(str): string that should start with <$>
      source(str): scene graph location where this token is stored
    Returns:
      str: token without the <$>
    ]]
    for token_supported, _ in pairs(Tokens) do
      -- add the <$> in font of the known token for comparison with the arg
      token_supported = conkat("$", token_supported)
      -- if similar retur the arg token without the <$>
      if token_supported == token then
        return token:gsub("%$", "")
      end
    end

    logerror(
      "[PointCloudData][check_token] invalid token <",
        token,"> on source <",self.location,">."
    )

  end

  function attrs:__get_attr_data(attr_name)
    --[[
    Get the attribute data table for the given <attr_name>.
    Table looks like this :
    {"path":"...", "grouping":"...", "multiplier":"...", "values":"...",
    "type":"...", "processed":"..."}

    Must be loop safe.

    Args:
      attr_name(str): common or arbiratry attribute name to query

    Returns:
      str table or nil:
        table of data for the given attr_name.
        You can also use __attrdata attribute instead.
    ]]
    self.__attrdata = self["common"][attr_name]
    if self.__attrdata == nil then
      self.__attrdata = self["arbitrary"][attr_name]
      if self.__attrdata == nil then
        logerror(
          "[PointCloudData][get_value4index]",
          "Can't find attribute <",
          attr_name,
          "> on instance for location <",
          self.location,
          ">."
        )
      end
    end

    -- chek if buffer was set from an uninitialized attribute
    if self.__attrdata == false then
      return nil
    end

    return self.__attrdata

  end

  function attrs:get_attr_value(attr_name, pindex)
  --[[
  Return the value for the given attribute.
  It can be a slice for the given pindex, or the entire values.
  The value has already been processed and is a DataAttribute instance.

  Must be loop safe.

  Args:
    attr_name(str):
      name for the key to query.
      Can be one of <common>/<arbiratry> or just <sources>.

    pindex(int or nil):
      point index: which point to use. If not specified return
      the whole table. !! starts at 0 !!

  Returns:
    DataAttribute or nil:
      DataAttribute instance or nil if <attr_name> is empty (=false).
  ]]

  if attr_name == "sources" then
    self.__buffer2 = {}
    for index, source_data in pairs(self.sources) do
      -- index should start counting at 0
      self.__buffer2[tonumber(index) + 1] = source_data.path
    end
    return StringAttribute(self.__buffer2)
  end

  -- this set self.__attrdata
  self:__get_attr_data(attr_name)
  if not self.__attrdata then
    --logger:debug("attr_name<", attr_name, "> is not initialized. (false)")
    return nil
  end

  -- no point specified, return all the values
  if pindex == nil then
    self.__buffer2 = self.__attrdata["processed"]  -- table
  -- else return a slice of the table
  else
    self.__buffer2 = {}
    -- grouping usually vary between 1 and 16(matrices), so small loop.
    for i=1, self.__attrdata["grouping"] do
      self.__buffer2[#self.__buffer2 + 1] = self.__attrdata["processed"][self.__attrdata["grouping"] * pindex + i]
    end
  end

  -- return as Katana DataAttribute, with the tuple size specified from grouping
  return self.__attrdata["type"](self.__buffer2, self.__attrdata["grouping"])

end

  function attrs:get_index_at_point(pindex)
    --[[
    Return the index used at the given point.

    Returns:
      num:
    ]]
    local index = self:get_attr_value("index", pindex)  -- DataAttribute
    -- TODO I don't trust getValue to return only a num, test this.
    index = index:getValue()
    return index
  end

  function attrs:is_point_hidden(pindex)
    --[[
    Return false is the point at given index must not be created (hidden).
    This is determined by using the <hide> token.

    Args:
      pindex(int): point index: which point to use. !! starts at 0 !!

    Returns:
      bool: true if the point is hidden and thus should not be created
    ]]

    local data = self:get_attr_value("hide") -- table of 0/1
    if not data then
      return false
    end

    if data[pindex + 1] == 1 then
      return true
    end

    return false

  end

  function attrs:get_instance_source_data(pindex)
    --[[
    Return the instance source data to use at the given point.
    Looks like this:
    {"path":"scene graph location"}

    Must be loop safe.

    Args:
      pindex(int): point index: which point to use. !! starts at 0 !!

    Returns:
      table:
    ]]
    local index = self:get_index_at_point(pindex)
    local out = self["sources"][tostring(index)]
    if out == nil then
      logerror(
        "[PointCloudData][get_instance_source_data] An error occured when getting index for current point <",
        pindex,
        ">. Corresponding index found was <",
        index,
        "> and return nil on self['sources']."
      )
    end
    return out

  end

  function attrs:convert_rotation2rotationaxis()
    --[[
    As rotationX/Y/Z should always exists, use the <rotation> one to build them

    Execute after self:validate
    ! heavy ! Process through all the rotation points
    ]]

    -- check of course if the attribute is built before starting anything
    if not self.common.rotation then
      return
    end

    local rx = {}
    local ry = {}
    local rz = {}

    local rall_data = {
      { rx, {1.0, 0.0, 0.0} }, -- x
      { ry, {0.0, 1.0, 0.0} }, -- y
      { rz, {0.0, 0.0, 1.0} }  -- z
    }
    local rvalues local raxis

    -- /!\ Perfs
    -- iterate trough all rotation values with are assumed to be in x,y,z order
    -- grouping can only be 3
    for i=0, #self.common.rotation.values / self.common.rotation.grouping - 1 do

      -- iterate trough each axis x,y,z
      for rindex, rdata in ipairs(rall_data) do
        -- rindex=[1,2,3] ; rdata=[{ {}, {1.0, 0.0, 0.0} }, ...]
        rvalues, raxis = rdata[1], rdata[2]

        rvalues[#rvalues + 1] = self.common.rotation.values[i*self.common.rotation.grouping + rindex]
        rvalues[#rvalues + 1] = raxis[1]
        rvalues[#rvalues + 1] = raxis[2]
        rvalues[#rvalues + 1] = raxis[3]
      end

    end

    for i, token in ipairs({"rotationX", "rotationY", "rotationZ"}) do
      self["common"][token] = build_attr_structure(
        "$rotation",
        4,
        self.common.rotation.multiplier,
        self.common.rotation.additive,
        rall_data[i][1],
        self.common.rotation.type,
        nil
      )
    end

  end

  function attrs:convert_skip_n_hide()
    --[[
    Both token should always be defined or none of them. So if <hide> is
    specified, convert it to <skip>. If only <skip> is specified convert it
    to <hide>.

    So the <hide> token take over the <skip> token if both specified !

    Execute after the <self:validate> method.
    ]]

    local pcvalues = {}

    if self.common.hide then

      for i, hidden in ipairs(self.common.hide.values) do
        if hidden == 1 then
          pcvalues[#pcvalues + 1] = i
        end
      end

      self["common"]["skip"] = build_attr_structure(
        self.common.hide.path,
        1,
        1,
        0,
        pcvalues,
        IntAttribute,
        pcvalues
      )

    elseif self.common.skip then

      -- build a first time the hide table, all points are visible
      for i=1, self.point_count do
        pcvalues[i] = 0
      end
      -- iterate through point to skip and set them on <pcvalues>
      for _, to_hide in ipairs(self.common.skip.values) do
        pcvalues[to_hide] = 1
      end

      self["common"]["hide"] = build_attr_structure(
        self.common.skip.path,
        1,
        1,
        0,
        pcvalues,
        IntAttribute,
        -- can be nil so not created
        pcvalues
      )

    end


  end

  function attrs:build()
    -- query data on source to build the table
    self:build_common()
    self:build_arbitrary()
    self:build_sources()
    -- check that the data queried above is valid
    self:validate()
    -- then modify this data for final use
    self:finalize()
  end

  function attrs:build_sources()
    --[[
    Build the <sources> key from the <instancing.data.sources> attribute
     on source location.

    This source attribute is a X*3 string array as:
      [0] instance source location,
      [1] instance source index,

    ]]

      -- get the attribute on the pc
    local data_sources = get_loc_attr(
        self.location,
        "instancing.data.sources",
        self.time
    )

    local path
    local index
    self["sources"] = {}

    -- start building the sources key ------------------------------------------
    for i=0, #data_sources / AttrGrp.sources - 1 do

      path = data_sources[AttrGrp.sources*i+1]
      index = tonumber(data_sources[AttrGrp.sources*i+2])

      -- process special cases here --------------------
      -- none yet

      self["sources"][tostring(index)] = {
        ["path"] = path,
        -- even if the key already use the index, respecify it here as num
        ["index"] = index,
        ["attrs"] = Interface.GetAttr("", path)
      }

    end

  end

  function attrs:build_arbitrary()
    --[[
    Build the <arbitrary> key from the <instancing.data.arbitrary>
      attribute on source location
    ]]

      -- get the attribute on the pc
    local data_arbtr = get_loc_attr(
        self.location,
        "instancing.data.arbitrary",
        self.time
    )
    local target
    local grouping
    local multiplier
    local additive
    local path
    local pcvalues
    local value_type
    local additional
    self["arbitrary"] = {}

    -- start building the arbitrary key ------------------------------------------
    for i=0, #data_arbtr / AttrGrp.arbitrary - 1 do

      path = data_arbtr[AttrGrp.arbitrary*i+1]
      target = data_arbtr[AttrGrp.arbitrary*i+2]
      grouping = tonumber(data_arbtr[AttrGrp.arbitrary*i+3])
      multiplier = tonumber(data_arbtr[AttrGrp.arbitrary*i+4])
      if not multiplier then
        multiplier = 1
      end
      additive = tonumber(data_arbtr[AttrGrp.arbitrary*i+5])
      if not additive then
        additive = 0
      end
      additional = data_arbtr[AttrGrp.arbitrary*i+6]
      if additional then
        additional = logassert(
            loadstring(conkat("return ", additional)),
            "Error while converting <instancing.data.arbitrary> column 5/5 to Lua.",
            " Issue in: ",
            additional
        )
        additional = additional()  -- this should be a table
      end
      pcvalues, value_type = get_loc_attr(self.location, path, self.time)

      -- process special cases here --------------------
      -- none yet

      self["arbitrary"][target] = build_attr_structure(
        path,
        grouping,
        multiplier,
        additive,
        pcvalues,
        value_type,
        nil
      )
      self["arbitrary"][target]["additional"] = additional

    end

  end

  function attrs:build_common()
    --[[
    Build the <common> key from the <instancing.data.common>
      attribute on source location.
    The attribute is a X*4 string array as :
      [0] attribute path relative to the source.
      [1] token to specify what kind of data [0] corresponds to.
      [2] value grouping : how much value belongs to an individual point.
      [3] value multiplier : quick way to multiply values.

    The $points token require a special processing.
    ]]

      -- get the attribute on the pc
    local data_common = get_loc_attr(
        self.location,
        "instancing.data.common",
        self.time
    )

    local token
    local grouping
    local multiplier
    local additive
    local path
    local pcvalues
    local value_type
    local processed
    local pointsvalue = {}

    -- start building the common key ------------------------------------------
    for i=0, #data_common / AttrGrp.common - 1 do

      path = data_common[AttrGrp.common*i+1]
      token = self:check_token(data_common[AttrGrp.common*i+2]) -- return without the "$" !
      grouping = tonumber(data_common[AttrGrp.common*i+3])
      multiplier = tonumber(data_common[AttrGrp.common*i+4])
      if not multiplier then
        multiplier = 1
      end
      additive = tonumber(data_common[AttrGrp.common*i+5])
      if not additive then
        additive = 0
      end
      pcvalues, value_type = get_loc_attr(self.location, path, self.time)
      processed = nil

      -- process special cases here --------------------
      if token == "points" then
        -- TODO Should we let the original values/grouping/mult and
        -- only set  point_count or is the current solution of
        -- cleaning the array good ?
        --
        -- <values> key should always be a table so just fill it with 0 here
        for pointindex=1, #pcvalues / grouping * multiplier do
          pointsvalue[pointindex] = 0
        end
        pcvalues = pointsvalue
        processed = pointsvalue
        grouping = 1
        multiplier = 1
        self["point_count"] = #pointsvalue + additive
        additive = 0

      elseif token == "index" or token == "skip" then
        -- for <index> and <skip> token, make sure to convert grouping to 1
        -- the last index from the group is used ({2,2,<2>})
        for pointindex=1, #pcvalues / grouping do
          pointsvalue[pointindex] = pcvalues[pointindex * grouping]
        end
        pcvalues = pointsvalue
        grouping = 1

      end
      -- force transform token to use doubles
      if Tokens[token].is_transform == true then
        value_type = DoubleAttribute
      end

    self["common"][token] = build_attr_structure(
      path,
      grouping,
      multiplier,
      additive,
      pcvalues,
      value_type,
      -- can be nil so not created
      processed
    )

    end

    -- end build_common
  end

  function attrs:validate()
    --[[
    To call after built operations.
    Verify that self table is properly built.
    Also clean the unusable attributes.
    TODO see if arbitrary is also needed to be validated
    TODO add hide and skipe verification
    ]]

    -- attr points must always exists
    if not self.common.points then
      logerror(
          "[PointCloudData][validate] Missing token $points on source <",
          self.location,
          ">."
      )
    end

    -- we need at least one instance source
    if not self.sources then
      logerror(
          "[PointCloudData][validate] No instance sources specified \z
           for source <",
          self.location,
          ">."
      )
    end

    -- instance sources index must start at 0
    if self.sources["0"] == nil then
      logerror(
        "[PointCloudData][validate] No index 0 found in <sources> attributes."
      )
    end

    -- every instance source need the index to be declared
    for _, isource_data in ipairs(self.sources) do
      if not isource_data["index"] then
        logerror(
            "[PointCloudData][validate] No index specified for \z
            instance source <",
            self.isource_data["path"],
            "> for source location <",
            self.location,
            ">."
        )
      end
    end

    -- it's best to only specify one if needed, warn user
    if self.common.hide and self.common.skip then
      logger:warning(
          "[PointCloudData][validate] Source <", self.location,
          "> declare a <$hide> token but also the <$skip> one.\z
           In that case $hide will override $skip."
      )
    end

    -- there is no point to have the matrix token + one of the trs so warn
    -- and reset the trs attributes
    if self.common.matrix and (
        self.common.translation or
        self.common.rotation or
        self.common.scale or
        self.common.rotationX
    ) then
      logger:warning(
          "[PointCloudData][validate] Source <", self.location,
          "> declare a $matrix token but also one of the trs. In that case \z
           $matrix take the priority."
      )
      self.common.translation = false
      self.common.rotation = false
      self.common.scale = false
      self.common.rotationX = false
      self.common.rotationY = false
      self.common.rotationZ = false
    end

    -- verify that if one rotationX/Y/Z is declared, all other 2 also are
    if not (
        self.common.rotationX and
        self.common.rotationY and
        self.common.rotationZ
    ) then
      if (
          self.common.rotationX or
          self.common.rotationY or
          self.common.rotationZ
      ) then
        logerror(
          "[PointCloudData][validate] Source <", self.location,
          "> doesn't have all the <rotationX/Y/Z> tokens declared \z
          (but declare currently at least one)."
        )
      end
    end

    -- verify that if $rotation is declared no rotationX/Y/Z is also declared
    if self.common.rotation and (
        self.common.rotationX or
        self.common.rotationY or
        self.common.rotationZ
    ) then
      logger:warning(
          "[PointCloudData][validate] Source <", self.location,
          "> declare a rotation token but also one of the $rotationX/Y/Z.\z
           In that case $rotation take the priority."
      )
    end

    -- verify grouping values
    if self.common.rotation then
      if self.common.rotation.grouping ~= 3 then
        logerror(
          "[PointCloudData][validate] Source <", self.location,
          "> $rotation token only accepts 3 as grouping, not ",
          self.common.rotation.grouping
        )
      end
    end
    if self.common.matrix then
      if self.common.matrix.grouping ~= 16 then
        logerror(
          "[PointCloudData][validate] Source <", self.location,
          "> $matrix token only accepts 16 as grouping, not ",
          self.common.matrix.grouping
        )
      end
    end
    if self.common.translation then
      if self.common.translation.grouping ~= 3 then
        logerror(
          "[PointCloudData][validate] Source <", self.location,
          "> $translation token only accepts 3 as grouping, not ",
          self.common.translation.grouping
        )
      end
    end

    local attrlength
    for attrname, attrdata in pairs(self.common) do
      -- attrdata can be <false> if not built so skip if so, I wish lua has a
      -- "continue" keyword like in python !
      if attrdata then
        --we check first that the <grouping> and <points> attribute seems valid
        attrlength = #(attrdata.values) / attrdata.grouping
        if attrlength ~= self.point_count then
          logerror(
          "[PointCloudData][validate] Common attribute <", attrname,
          "> as an odd number of values : ", tostring(#(attrdata.values)),
          " / ", tostring(attrdata.grouping), " = ", attrlength,
          " while $points=", self.point_count
          )
        end
        -- end if attrdata is not false/nil
      end
      -- end for attrname, attrdata
    end

    -- end for validate()
  end

  function attrs:finalize()
  --[[
  Last method executed to build this instance.
  - convert_rotation2rotationaxis
  - For each attribute in common and arbitrary, create the "processed"
    key that hold the values but multiplied.

  Must be executed after <validate>
  ]]

    -- rebuild rotation attributes
    self:convert_rotation2rotationaxis()
    self:convert_skip_n_hide()

    local value
    local stime = os.clock()

    -- we build the <processed> key
    for _, source in pairs({"common", "arbitrary"}) do

      for token, attr_data in pairs(self[source]) do
        -- attr_data can be false and not be built,
        -- also check that there is not already the processed key
        if attr_data and self[source][token]["processed"] == nil then
          value = attr_data["values"]
          for i, v in ipairs(value) do
            value[i] = v * attr_data["multiplier"] + attr_data["additive"]
          end
          -- create the new <processed> key.
          self[source][token]["processed"] = value
        end

      end

    end

    stime = os.clock() - stime
    logger:debug("[PointCloudData] Finished in ",stime,"s for pointcloud <",self.location,">.")

  end

  return attrs

end

return PointCloudData
