--[[
version=0.0.16
todo
]]


local logging = require("lllogger")
local logger = logging:new("kui.hierarchical")
logger:set_level("debug")
logger.formatting:set_tbl_display_functions(false)
logger.formatting:set_str_display_quotes(true)


local function run()

-- 95% of the code is wrapped in this condition as it's absolutely not
-- needed when not at "AtRoot", dirty but works.
-- run-time won is negligable (~7%), memory not measured.
if Interface.AtRoot() then

local PointCloudData = require("kui.PointCloudData")
local utils = require("kui.utils")

local OPARG = Interface.GetOpArg()

-- we make some global functions local as this will improve performances in
-- heavy loops
local tostring = tostring
local stringformat = string.format


--[[ __________________________________________________________________________
  API
]]


-- // Used by InstanceHierarchical
-- key is the token to query and value is the target attribute path
-- if the token doesnt have any value on point_data it will not be added.
-- order is important
local token_target = {
  { ["token"]="translation", ["target"]="xform.group0.translate" },
  -- if the pdata was validated, we for sure have rotationX/Y/Z
  { ["token"]="rotationZ", ["target"]="xform.group0.rotateZ" },
  { ["token"]="rotationY", ["target"] = "xform.group0.rotateY" },
  { ["token"]="rotationX", ["target"] = "xform.group0.rotateX" },
  { ["token"]="scale", ["target"]="xform.group0.scale" },
  { ["token"]="matrix", ["target"]="xform.group0.matrix" },
}


local InstanceHierarchical = {}
function InstanceHierarchical:new(name, id)
  --[[
  A single hierarchical instance location represented as a class.

  /!\ All operations has to be as light-weight as possible as this can be
  instanced thousands of times.

  Args:
    name(str): name template to give to the instance (with tokens)
    id(int):
      !! starts at 0 !!
      unique identifier for the instance, usually the loop current index

  Attributes:
    __hidden(bool):
      true will not create the instance as it means it's hidden
    data(table):
      store attributes progressively set on the instance to
      be reused at build time for the instance name.
    gb(GroupBuilder):
    id(int):
      !! starts at 0 !!
      unique identifier for the instance, usually the loop current index
    nametmp(str):
      name template to give to the instance (so with tokens)
  ]]

  local attrs = {
    ["__hidden"] = false,
    ["nametmp"] = name,
    ["id"] = id,
    ["gb"] = GroupBuilder(),
    ["data"] = {
      ["instance_source"] = false,
      ["source_index"] = false
    }
  }

  attrs.gb:update(OPARG)

  function attrs:add(attr_path, attr_value)
    --[[
    Args:
      attr_path(str): where the attribute should live on the instance.
        Path relative to the instance.
      attr_value(DataAttribute or nil): Katana DataAttribute instance with the data
    ]]
    if attr_value == nil then
      return
    end

    self.gb:set(
        utils:conkat("childAttrs.", attr_path),
        attr_value
    )
  end

  function attrs:build_from_pdata(point_data)
    --[[
    Convenient method to build the instance from a PointCloudData instance
    at the current point index (id attribute).
    ]]

    if point_data:is_point_hidden(self.id) == true then
      self.__hidden = true
      return
    end

    -- 1. PROCESS INSTANCE SOURCE SETUP
    -- had to be first for childAttrs to not override previously set
    local isrc_data = point_data:get_instance_source_data(self.id)
    -- must really be first
    self.gb:set("childAttrs", isrc_data["attrs"])
    self:set_instance_source(
        isrc_data["path"],
        isrc_data["index"]
    )

    -- 2. PROCESS COMMON ATTRIBUTES
    for _, tt in ipairs(token_target) do
      -- add() handle nil value by himself
      self:add(tt["target"], point_data:get_attr_value(tt["token"], self.id))
    end

    -- 3. PROCESS ARBITRARY ATTRIBUTES
    for target, arbtr_data in pairs(point_data["arbitrary"]) do
      -- 1. first process the additional table
      -- we only use arbtr_data for the <additional> key yet so we can do this
      arbtr_data = arbtr_data["additional"]  -- type: table
      for addit_target, addit_value in pairs(arbtr_data) do
        self:add(addit_target, addit_value)
      end
      -- 2. Add the arbitrary attribute value
      -- add() handle nil value by himself
      self:add(target,  point_data:get_attr_value(target, self.id))
    end

    -- end function
  end

  function attrs:set_instance_source(instance_source, index)
    --[[
  Args:
  instance_source(str): existing scene graph location
  index(str or int): index on source from which this instance has been
  computed.
  ]]
    self.data.instance_source = instance_source
    self.data.source_index = index
    self:add(
      "geometry.instanceSource",
      StringAttribute(instance_source)
    )
  end

  function attrs:get_name()
    --[[
    Compute the instance location name from the given template (self.nametmp)
     based on its attributes.

    TODO some perfs might be gained here, see later.

    Returns:
      str: final instance name
    ]]
    local out = self.nametmp

    -- safety check that $id is present
    if not out:match("%$id") then
      utils:logerror(
          "[InstanceHierarchical][get_name] Passed name template <",
          out,
          "> doesn't have the mandatory <$id> token."
      )
    end

    -- extract the number of digit that must be used for the id
    local digits = out:match("%$id(%d*)")
    if not digits then
      digits = 0
    end

    -- create the token values
    local sourcename local sourceindex

    if self.data.instance_source then
      sourcename = tostring(self.data.instance_source:gsub(".+/", ""))
    else
      sourcename = ""
    end

    if self.data.source_index then
      sourceindex = tostring(self.data.source_index)
    else
      sourceindex = ""
    end

    -- Assign the tokens to their value
    -- key is a regex, value must be a string
    local tokens  = {
      ["%$id%d*"] = stringformat(utils:conkat("%0", digits, "d"), self.id),
      ["%$sourcename"] = sourcename,
      ["%$sourceindex"] = sourceindex
    }

    -- replace token on name template
    for token, value in pairs(tokens) do
      out = tostring(out:gsub(token, value))
    end

    return out

  end

  function attrs:finalize()
    --[[
    Last method to call once you finish building the Instance.
    ]]

    -- check if this instance must be rendered first
    if self.__hidden == true then
      return
    end

    self:add("type", StringAttribute("instance"))
    Interface.CreateChild(
      self:get_name(),
      Interface.GetOpType(),
      self.gb:build()
    )
  end

  return attrs

end


-- InstancingMethod -----------------------------------------------------------

local InstancingHierarchical = {}
function InstancingHierarchical:new(point_data)
  --[[

  Made the link between PointCloudData and instance creation.

  Args:
    point_data(PointCloudData) : PointCloudData instance that has been built.

  Attributes:
    pdata(PointCloudData): PointCloudData instance
    name_tmp(str): name to give to the instances, with tokens.

  ]]

  local attrs = {
    pdata = point_data,
    name_tmp = false,
  }

  function attrs:build()

    local instance
    -- /!\ perfs
    for pid=0, self.pdata.point_count - 1 do
      instance = InstanceHierarchical:new(self.name_tmp, pid)
      instance:build_from_pdata(self.pdata)
      instance:finalize()
    end

  end

  function attrs:set_name_template(name)
    self["name_tmp"] = name
  end

  return attrs
end


-- processes ------------------------------------------------------------------

local function create_instances()
  --[[
  When Interface at root
  ]]
  local stime = os.clock()
  local time = Interface.GetCurrentTime() -- int

  local u_pointcloud_sg = utils:get_user_attr( time, "pointcloud_sg", "$error" )[1]
  local u_instance_name = utils:get_user_attr( time, "instance_name", "$error" )[1]

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
  instance = InstancingHierarchical:new(pointdata)
  instance:set_name_template(u_instance_name)
  instance:build()

  stime = os.clock() - stime
  logger:info("Finished in ",stime,"s for pointcloud <",u_pointcloud_sg,">.")

end

print("\n")
create_instances()

--end first condition of <if Interface.AtRoot()>
-------------------------------------------------------------------------------
else
  -- when we are not at root :

  local function finalize_instances()
    --[[
    When Interface is not at root.
    Only usefull for hierarchical but still called for array.

    Not recommended to log anything here as the message will be repeated times
    the number of instances (so can be thousands !)
    ]]

    -- attributes created for a single instance
    local childAttrs = Interface.GetOpArg("childAttrs")  -- type: GroupAttribute

    for i=0, childAttrs:getNumberOfChildren() - 1 do

      Interface.SetAttr(
          childAttrs:getChildName(i),
          childAttrs:getChildByIndex(i)
      )

    end

  end

  finalize_instances()

--end if Interface.AtRoot()
end

--end run()
end

local function test(level)
  logger:set_level(level)
end

return {
  ["run"] = run,
  ["set_logger_level"] = test
}