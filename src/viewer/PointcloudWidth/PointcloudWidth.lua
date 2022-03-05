--[[
version=6
author=Liam Collod
last_modified=05/03/2022

OpScript for Foundry's Katana software.

Add a geometry.point.width attribute to control the viewer's size of the points
or scale the existing one.

[OpScript setup]
- OpArg(type)(default_value):
    user.point_size(float)(1): size of the points in the viewer
- parameters:
    location: pointcloud scene graph location
    applyWhere: at specific location

[License]
Copyright 2022 Liam Collod

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]


local function run()

  -- get OpArg
  local point_scale = Interface.GetOpArg("user.point_size")
  if not point_scale then
    point_scale = 1.0
  else
    point_scale = point_scale:getValue()
  end

  local points_width = Interface.GetAttr("geometry.point.width")
  if points_width then
    points_width = points_width:getNearestSample(0)
  end
  local points = Interface.GetAttr("geometry.point.P"):getNearestSample(0)

  local point_scaled = {}
  for i=1, #points do
    if points_width then
      point_scaled[i] = points_width[i] * point_scale
    else
      point_scaled[i] = point_scale
    end
  end

  Interface.SetAttr("geometry.point.width", FloatAttribute(point_scaled, 3))
  return

end

run()