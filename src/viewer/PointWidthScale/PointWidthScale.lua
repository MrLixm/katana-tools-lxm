--[[
VERSION = 0.0.2

OpScript for Foundry's Katana software.


Author: Liam Collod
Last Modified: 15/11/2021

[OpScript setup]
- OpArg(type)(default_value):
    user.scale(float)(10): scale of the points in the viewer (multiply factor)
- parameters:
    location: scene graph location with a geometry.point.width attribute
    applyWhere: at specific location

]]



function run()

  local time = Interface.GetCurrentTime()

  local pwidth = Interface.GetAttr("geometry.point.width"):getNearestSample(time)

  -- get OpArg
  local uscale = Interface.GetOpArg("user.scale")
  if not uscale then
    uscale = 10
  else
    uscale = uscale:getValue()
  end

  local new_pwidth = {}
  for i=1, #pwidth do
    new_pwidth[i] = pwidth[i] * uscale
  end

  Interface.SetAttr("geometry.point.width", FloatAttribute(new_pwidth, 1))
  return

end

run()