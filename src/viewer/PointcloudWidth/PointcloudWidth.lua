--[[
VERSION = 0.0.5

OpScript for Foundry's Katana software.

Add a geometry.point.width attribute to control the viewer's size of the points.

Author: Liam Collod
Last Modified: 18/10/2021

[OpScript setup]
- OpArg(type)(default_value):
    user.point_size(float)(15): size of the points in the viewer
- parameters:
    location: pointcloud scene graph location
    applyWhere: at specific location

]]



function run()

  -- check the attribute doesn't already exists
  if Interface.GetAttr("geometry.point.width") then
    return
  end

  -- get OpArg
  local point_scale = Interface.GetOpArg("user.point_size")
  if not point_scale then
    point_scale = 15.0
  else
    point_scale = point_scale:getValue()
  end

  local points = Interface.GetAttr("geometry.point.P"):getNearestSample(Interface.GetCurrentTime())

  local point_scales = {}
  for i=1, #points do
    point_scales[i] = point_scale
  end

  Interface.SetAttr("geometry.point.width", FloatAttribute(point_scales, 3))
  return

end

run()