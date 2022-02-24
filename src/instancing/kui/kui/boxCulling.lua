--[[
version=0.0.1
todo
]]

local logging = require("lllogger")
local logger = logging:new("kui.boxCulling")
logger.formatting:set_tbl_display_functions(false)
logger.formatting:set_str_display_quotes(true)

local PointCloudData = require("kui.PointCloudData")
local utils = require("kui.utils")


--[[ __________________________________________________________________________
  API
]]


local function is_point_in_boundingbox(bounding_box, point)
  --
  --
  -- Parameters:
  --  bounding_box:  DoubleAttribute({{xMin, xMax}, {yMin, yMax}, {zMin, zMax}})
  --  point: a 3d point stored in a table. with {x,y,z}
  --
  -- Returns:
  --  bool: true if inside the bounding box else false
  local bb = bounding_box:getNearestSample(Interface.GetCurrentTime())

  -- X values
  if not (point[1] > bb[1]) or not (point[1] < bb[2]) then
    return false

  -- Y values
  elseif not (point[2] > bb[3]) or not (point[2] < bb[4]) then
    return false

  -- Z values
  elseif not (point[3] > bb[5]) or not (point[3] < bb[6]) then
    return false

  end

  return true

end


local function locations_to_bounds(meshs_locations)
  --[[
  Iterate through all the meshs_locations to return their bounding boxes

  Parameters:
    meshs_locations(table): {"CEL","CEL",...}

  Returns:
    table:
      {{mesh bb},...}
  ]]

  local cullingMeshsBounds = {}
  --  Loop variables
  local cullingMeshXformAttr
  local cullingMeshBound
  local cullingMesh_transformedBounds

  for i=0, #meshs_locations-1 do
    -- Get the bounding_box of the culling mesh.
    --    cullingMeshXform: GroupAttribute
    cullingMeshXformAttr = Interface.GetGlobalXFormGroup(meshs_locations[i+1])
    cullingMeshBound = Interface.GetBoundAttr(meshs_locations[i+1], 0)
    cullingMesh_transformedBounds = XFormUtils.CalcTransformedBoundsAtExistingTimes(
        cullingMeshXformAttr, cullingMeshBound)
    -- add the bb to the table
    cullingMeshsBounds[i+1] = cullingMesh_transformedBounds
  end

  return cullingMeshsBounds
end



-- Script ---------------------------------------------------------------------


local function run()
  --[[
  First function executed
  ]]

  local time = Interface.GetCurrentTime()

  local u_pointcloud_sg = utils:get_user_attr(
    time,
    "pointcloud_sg",
    "$error"
  )[1]  -- type: str
  -- culling_locations(table): {"CEL","CEL",...}
  local culling_locations = utils:get_user_attr(
    time,
    "culling_locations",
    "$error"
  )

  -- process the source pointcloud
  logger:info("Started processing source <", u_pointcloud_sg, ">.")
  local pointdata
  pointdata = PointCloudData:new(u_pointcloud_sg, time)
  pointdata:build()
  logger:info(
      "Finished processing source <", u_pointcloud_sg, ">.",
      pointdata.point_count, " points found."
  )
  logger:debug("pointdata = \n", pointdata, "\n")

  -- Iterate through all the culling mesh locations to get their bounding boxes
  -- cullingMeshsBounds(table): {{mesh bb},...}
  local cullingMeshsBounds = locations_to_bounds(culling_locations)


  -- Loop trough all the points of the pointcloud
  --  loop variables:
  local current_point = {}
  local point_visibility

  for i=0, pointdata.point_count - 1 do

    point_visibility = 1  -- the point is visible by default

    current_point[1] = points[i*3+1]
    current_point[2] = points[i*3+2]
    current_point[3] = points[i*3+3]

    -- If the point is in one of the culling mesh set its visibility to 0
    for cmi=0, #cullingMeshsBounds-1 do
      if is_point_in_boundingbox(cullingMeshsBounds[cmi+1], current_point) then
        point_visibility = 0
      end
    end

    -- Iterate trough each pointcloud attribute to only copy the current value
    -- if the point is visible.
    for attr_name, attrClass in pairs(pointcloud_attributes) do
      if point_visibility == 1 then
        attrClass:setValue_toCopy(i)
      else
        --
      end
    end

  end

  -- set all the pointcloud attributes to their new value with removed indexes
  for attr_name, attrClass in pairs(pointcloud_attributes) do
    Interface.SetAttr(attrClass.path, attrClass:getCopyAttr())
  end

end

-- execute
run()