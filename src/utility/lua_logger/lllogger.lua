--[[
VERSION = 2
llloger

A simple logging module based on Python one. Originaly made for use with
Foundry's Katana software, OpScript feature.

This is the inline version to be be inserted at tje top of your current OpScript.
To turn it into the module version, replace the last line with:
<return logging>

Author: Liam Collod
Last-Modified: 07/01/2022


]]

local LOG_LEVEL = "debug" -- debug, info, warning, error

function round(num, numDecimalPlaces)
  --[[
  Source: http://lua-users.org/wiki/SimpleRound
  Parameters:
    num(number): number to round
    numDecimalPlaces(number): number of decimal to keep
  Returns: number
  ]]
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function stringify(source)
    --[[
    Convert the source to a readable string , based on it's type.
    All numbers are rounded to 3 decimals.

    Parameters:
      source(any): any type
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

function table2string(tablevalue)
    --[[
  Convert a table to a one line string.
  If the key is a number, only the value is kept.
  If the key is something else, it is formatted to "stringify(key)=stringify(value),"

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

local logging = {}

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

  function attrs:set_level(level)
    -- level(string): see self.levels keys for value
    self.level = attrs["levels"][level]
  end

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


local logger = logging:new("GiveMeAName")