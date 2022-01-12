--[[
VERSION = 10
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

local strFmtSettings = {}
function strFmtSettings:new()
  --[[
  A base class that hold configuration settings for string formatting used
  by stringify() and table2string()
  ]]

  -- these are the default values
  local attrs = {
    -- how much decimals should be kept for floating point numbers
    ["numbers"] = {
      ["round"] = 3
    },
    -- nil by default cause the table2string already have some defaults
    ["tables"] = {
      -- how much whitespaces is considered an indent
      ["indent"] = 4,
      -- max table size before displaying it as oneline to avoid flooding
      ["length_max"] = 50,
      -- true to display the table on multiples lines with indents
      ["linebreaks"] = true,
      ["display_indexes"] = false,
      ["display_functions"] = true
    },
    ["strings"] = {
      ["display_quotes"] = false
    }
  }

  function attrs:set_num_round(round_value)
    -- round_value(int):
    self.numbers.round = round_value
  end

  function attrs:set_str_display_quotes(display_value)
    -- display_value(bool):
    self.strings.display_quotes = display_value
  end

  function attrs:set_tbl_display_indexes(display_value)
    -- display_value(bool):
    self.tables.display_indexes = display_value
  end

  function attrs:set_tbl_linebreaks(display_value)
    -- display_value(bool):
    self.tables.linebreaks = display_value
  end

  function attrs:set_tbl_length_max(length_max)
    -- length_max(int):
    self.tables.length_max = length_max
  end

  function attrs:set_tbl_indent(indent)
    -- indent(int):
    self.tables.indent = indent
  end

  function attrs:set_tbl_display_functions(display_value)
    -- display_value(bool):
    self.tables.display_functions = display_value
  end

  return attrs

end

function stringify(source, index, settings)
  --[[
  Convert the source to a readable string , based on it's type.

  Args:
    source(any): any type
    index(int): recursive level of stringify
    settings(strFmtSettings or nil): configure how source is formatted
  ]]
  if not settings then
    settings = strFmtSettings:new()
  end

  if not index then
    index = 0
  end


  if (type(source) == "table") then
    source = table2string(source, index, settings)

  elseif (type(source) == "number") then
    source = tostring(round(source, settings.numbers.round))

  elseif (type(source) == "string") and settings.strings.display_quotes == true then
    local buf = {"\""}
    buf[#buf + 1] = source
    buf[#buf + 1] = "\""
    source = table.concat(buf)

  else
    source = tostring(source)

  end

  return source

end

function table2string(tablevalue, index, settings)
    --[[
  Convert a table to human readable string.
  By default formatted on multiples lines for clarity. Specify tdtype=oneline
    to get no line breaks.
  If the key is a number, only the value is kept.
  If the key is something else, it is formatted to "stringify(key)=stringify(value),"
  If the table is too long (max_length), it is formatted as oneline

  Args:
    tablevalue(table): table to convert to string
    index(int): recursive level of conversions used for indents
    settings(strFmtSettings or nil):
      Configure how table are displayed.

  Returns:
    str:

  ]]

  -- check if table is empty
  if next(tablevalue) == nil then
   return "{}"
  end

  -- if no index specified recursive level is 0 (first time)
  if not index then
    index = 0
  end

  local tsettings
  if settings and settings.tables then
    tsettings = settings.tables
  else
    tsettings = strFmtSettings:new().tables
  end

  local linebreak_start = "\n"
  local linebreak = "\n"
  local inline_indent = string.rep(
      " ", index * tsettings.indent + tsettings.indent
  )
  local inline_indent_end = string.rep(
      " ", index * tsettings.indent
  )

  -- if the table is too long make it one line with no line break
  if #tablevalue > tsettings.length_max then
    linebreak = ""
    inline_indent = ""
    inline_indent_end = ""
  end
  -- if specifically asked for the table to be displayed as one line
  if tsettings.linebreaks == false then
    linebreak = ""
    linebreak_start = ""
    inline_indent = ""
    inline_indent_end = ""
  end

  -- to avoid string concatenation in loop using a table
  local outtable = {}
  outtable[#outtable + 1] = "{"
  outtable[#outtable + 1] = linebreak_start

  for k, v in pairs(tablevalue) do
    -- if table is build with number as keys, just display the value
    if (type(k) == "number") and tsettings.display_indexes == false then
      outtable[#outtable + 1] = inline_indent
      outtable[#outtable + 1] = stringify(v, index+1, settings)
      outtable[#outtable + 1] = ","
      outtable[#outtable + 1] = linebreak
    else

      if (type(v) == "function") and tsettings.display_functions == false then
        outtable[#outtable + 1] = ""
      else
        outtable[#outtable + 1] = inline_indent
        outtable[#outtable + 1] = stringify(k, index+1, settings)
        outtable[#outtable + 1] = "="
        outtable[#outtable + 1] = stringify(v, index+1, settings)
        outtable[#outtable + 1] = ","
        outtable[#outtable + 1] = linebreak
      end

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
    level = nil,
    formatting = strFmtSettings:new()

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
      outbuf[#outbuf + 1] = stringify(mvalue, nil, self.formatting)
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