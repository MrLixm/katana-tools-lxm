--[[
VERSION = 7
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
  local buf = {}
  buf[#buf + 1] = "%."
  buf[#buf + 1] = (numDecimalPlaces or 0)
  buf[#buf + 1] = "f"
  return tonumber(string.format(table.concat(buf), num))
end

function stringify(source, index)
    --[[
    Convert the source to a readable string , based on it's type.
    All numbers are rounded to 3 decimals.

    Args:
      source(any): any type
      index(int): recursive level of stringify
    ]]
  local number_round = 3  -- number of decimals to keep.
  if not index then
    index = 0
  end

  if (type(source) == "table") then
    if #source == 1 then
      return stringify(source[1], index+1)
    end
    source = table2string(source, index)

  elseif (type(source) == "number") then
    source = tostring(round(source, number_round))

  else
    source = tostring(source)

  end

  return source

end

function table2string(tablevalue, index)
    --[[
  Convert a table to a one line string.
  If the key is a number, only the value is kept.
  If the key is something else, it is formatted to "stringify(key)=stringify(value),"

  Args:
    tablevalue(table): table to convert to string
    index(int): recursive level of stringify
  Returns:
    str:

  ]]

  -- check if table is empty
  if next(tablevalue) == nil then
   return "{}"
  end

  local indent = 4
  -- avoid flooding the terminal with lines for very long tables
  local max_length = 50
  local linebreak = "\n"
  local inline_indent = string.rep(" ", index * indent + indent)
  local inline_indent_end = string.rep(" ", index * indent)
  if not index then
    index = 0
  end
  if #tablevalue > max_length then
    linebreak = ""
    inline_indent = ""
    inline_indent_end = ""
  end

  -- to avoid string concatenation in loop using a table
  local outtable = {}
  outtable[#outtable + 1] = "{\n"

  for k, v in pairs(tablevalue) do
    if (type(k) == "number") then
      outtable[#outtable + 1] = inline_indent
      outtable[#outtable + 1] = stringify(v, index+1)
      outtable[#outtable + 1] = ","
      outtable[#outtable + 1] = linebreak
    else
      outtable[#outtable + 1] = inline_indent
      outtable[#outtable + 1] = stringify(k, index+1)
      outtable[#outtable + 1] = "="
      outtable[#outtable + 1] = stringify(v, index+1)
      outtable[#outtable + 1] = ","
      outtable[#outtable + 1] = linebreak
    end
  end
  outtable[#outtable + 1] = inline_indent_end
  outtable[#outtable + 1] = "}"
  return tostring(table.concat(outtable))

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

  function attrs:_log(level, messages, context)
    --[[
    Args:
      level(table): level object as defined in self.levels
      messages(table): list of object to display
      context(str): from where the log function is executed.
        Usually you can pass the function's name
    ]]

    if level.weight < self.level.weight then
      return
    end
    -- avoid string conact in loops using a table buffer
    local outbuf = {}
    -- make sure messages is always a table to iterate later
    if (type(messages)~="table") then
      messages = {messages}
    end

    outbuf[#outbuf + 1] = "[OpScript]["
    outbuf[#outbuf + 1] = level.name
    outbuf[#outbuf + 1] = "]["
    outbuf[#outbuf + 1] = self.name
    outbuf[#outbuf + 1] = "]"
    if context then
      outbuf[#outbuf + 1] = "["
      outbuf[#outbuf + 1] = stringify(context)
      outbuf[#outbuf + 1] = "] "
    end
    for mindex, mvalue in ipairs(messages) do
      outbuf[#outbuf + 1] = stringify(mvalue)
      outbuf[#outbuf + 1] = " "
    end

    -- concatenate the buffer to string
    print(table.concat(outbuf))

  end

  function attrs:debug(...)
    self:_log(self.levels.debug, { ... }, debug.getinfo(2).name)
  end

  function attrs:info(...)
    self:_log(self.levels.info, { ... }, debug.getinfo(2).name)
  end

  function attrs:warning(...)
    self:_log(self.levels.warning, { ... }, debug.getinfo(2).name)
  end

  function attrs:error(...)
    self:_log(self.levels.error, { ... }, debug.getinfo(2).name)
  end

  return attrs

end


local logger = logging:new("GiveMeAName")