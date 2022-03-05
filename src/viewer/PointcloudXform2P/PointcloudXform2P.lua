--[[
version=7
author=Liam Collod
last_modified=05/03/2022

OpScript for Foundry's Katana software.

Allow merging xform transformations on a pointcloud to
the geometry.point.P attribute. (so translate+rotate only).

! If your xform transform is interactive, think to disable
this ops before trying to move it in the viewer.

[OpScript setup]
- OpArg:
    /
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

  print("[PointcloudXform2P][run] Started for location="..Inteface.GetInputLocationPath())
  local stime = os.clock()

  local points = Interface.GetAttr("geometry.point.P"):getNearestSample(0)

  local xform = Interface.GetGlobalXFormGroup(Interface.GetInputLocationPath(), 0)
  local matrix = XFormUtils.CalcTransformMatrixAtTime(xform, 0):getNearestSample(0)
  matrix = Imath.M44d(matrix)

  local points_new = {}

  for i=0, #points/3-1 do

    local pvector = Imath.V3d(points[i*3+1], points[i*3+2], points[i*3+3])
    local pnew = pvector * matrix

    points_new[#points_new + 1] = pnew.x
    points_new[#points_new + 1] = pnew.y
    points_new[#points_new + 1] = pnew.z

  end

  Interface.SetAttr("geometry.point.P", FloatAttribute(points_new, 3))
  Interface.DeleteAttr("xform")

  print("[PointcloudXform2P][run] Finished in "..os.clock()-stime.."s")
  return

end

run()