--[[
VERSION = 0.0.6

OpScript for Foundry's Katana software.

Allow merging xform transformations on a pointcloud to
the geometry.point.P attribute. (so translate+rotate only).

! If your xform transform is interactive, think to disable
this ops before trying to move it in the viewer.

Author: Liam Collod
Last Modified: 18/10/2021

[OpScript setup]
- OpArg:
    /
- parameters:
    location: pointcloud scene graph location
    applyWhere: at specific location
]]


local LOG_LEVEL = "info" -- debug, info, warning, error


function table2string(tablevalue)
    --[[
  Convert a table to a one line string.
  If the key is a number, only the value is kept.
  If the key is something else, it is formatted to "tostring(key)=tostring(value),"

  Parameters:
    tablevalue(table): table to convert to string

  Returns:
    str:
  ]]

  local outtable = {"{"}
  local ctable = {} -- to avoid string concatenation in loop

  for k, v in pairs(tablevalue) do
    -- to avoid string concatenation in loop
    if (type(k) == "number") then
      table.insert(outtable, stringify(v)..", ")
    else
      ctable[1] = stringify(k)
      ctable[2] = "="
      ctable[3] = stringify(v)
      ctable[4] = ", "
      table.insert(outtable,tostring(table.concat(ctable)))
    end
  end

  table.insert(outtable, "}")

  return table.concat(outtable)

end


function round(num, numDecimalPlaces)
  -- Source: http://lua-users.org/wiki/SimpleRound
  -- Returns: number
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


function stringify(source)
    --[[ Convert the source to a readable string , based on it's type.
    All numbers are rounded to 3 decimals.
    ]]
    local number_round = 3  -- number of decimals to keep.

    if (type(source) == "table") then
      if #source == 1 then
        return source[1]
      end
      source = table2string(source)

    elseif (type(source) == "number") then
      source = tostring(round(source, number_round))

    else
      source = tostring(source)

    end

  return source

end


logging = {}


function logging:new(name)
  --[[
  Simple logging system.

  Parameters:
	  name(str): name of the logger to be displayed on every message
  ]]

  local attrs = {
    name = name,
    levels = {
      debug = {
        name = "  DEBUG",
        weight = 10
      },
      info = {
        name = "   INFO",
        weight = 20
      },
      warning = {
        name = "WARNING",
        weight = 30
      },
      error = {
        name = "  ERROR",
        weight = 40,
      }
    },
    level = nil
  }

  attrs["level"] = attrs["levels"][LOG_LEVEL]

  function attrs:_log(level, message)

    if level.weight < self.level.weight then
      return
    end

    message = stringify(message)

    print("[OpScript]["..level.name.."]["..self.name.."] "..message)

  end

  function attrs:debug(message)
    self:_log(self.levels.debug, message)
  end

  function attrs:info(message)
    self:_log(self.levels.info, message)
  end

  function attrs:warning(message)
    self:_log(self.levels.warning, message)
  end

  function attrs:error(message)
    self:_log(self.levels.error, message)
  end

  return attrs

end


logger = logging:new("PointcloudXform2P")


function run()

  logger:info("[run] Started")
  local stime = os.clock()

  local time = Interface.GetCurrentTime()

  local points = Interface.GetAttr("geometry.point.P"):getNearestSample(time)
  logger:debug(points)

  local xform = Interface.GetGlobalXFormGroup(Interface.GetInputLocationPath(), 0)
  local matrix = XFormUtils.CalcTransformMatrixAtTime(xform, time):getNearestSample(0)
  matrix = Imath.M44d(matrix)
  logger:debug(matrix)

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

  logger:info("[run] Finished in "..os.clock()-stime.."s")
  return

end

run()