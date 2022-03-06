--[[
version=8
author=Liam Collod
last_modified=05/03/2022

OpScript for Foundry's Katana software.

  Allow merging xform transformations on a pointcloud to
  the geometry.point.P attribute. (so translate+rotate only).

  ! If your xform transform is interactive, think to disable
  this ops before trying to move it in the viewer.

  Supports motion blur.

[OpScript setup]
- OpArg:
    /
- parameters:
    location: pointcloud scene graph location(s)
    applyWhere: at specific location OR at locations matching CEL

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

-- make a global local to improve perfs in big loops
local v3d = Imath.V3d

local function run()

  print("[PointcloudXform2P][run] Started for location="..Interface.GetInputLocationPath())
  local stime = os.clock()

  local points_attr = Interface.GetAttr("geometry.point.P")

  local xform = Interface.GetGlobalXFormGroup(Interface.GetInputLocationPath(), 0)
  local matrix_attr = XFormUtils.CalcTransformMatrixAtExistingTimes(xform)  -- DoubleAttribute

  local matrix
  local points
  local points_new = {}
  local pvector local pnew

  for smplindex=0, matrix_attr:getNumberOfTimeSamples() do
    pnew = {}
    smplindex = matrix_attr:getSampleTime(smplindex)
    points = points_attr:getNearestSample(smplindex)
    matrix = Imath.M44d(matrix_attr:getNearestSample(smplindex))

    for i=0, #points/3-1 do

      pvector = v3d(points[i*3+1], points[i*3+2], points[i*3+3]) * matrix

      pnew[#pnew + 1] = pvector.x
      pnew[#pnew + 1] = pvector.y
      pnew[#pnew + 1] = pvector.z

    end

    points_new[smplindex] = pnew

  end

  Interface.SetAttr("geometry.point.P", FloatAttribute(points_new, 3))
  Interface.DeleteAttr("xform")

  print("[PointcloudXform2P][run] Finished in "..os.clock()-stime.."s")
  return

end

run()