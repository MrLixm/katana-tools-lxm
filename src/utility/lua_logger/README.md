# llloger

![lua](https://img.shields.io/badge/Lua-any-000090?logo=lua&logoColor=white)
![katana version](https://img.shields.io/badge/Katana-any-FCB123?logo=katana&logoColor=white)
[![License](https://img.shields.io/badge/license-Apache_2.0-blue)](LICENSE.md)

A simple lua logging module based on Python one. 
Originaly made for use with Foundry's Katana software, OpScript feature.

![cover](./cover.png)

# Features

- Log level system where you can define what level of message is allowed to be displayed.
- Multiples logger with different log level can be created in the same script.
- Convert tables and nested tables to a human-readable string (see settings).
- Multiples arguments can be passed : `logger:debug("text", 69, {"table"})`
- Should be loop safe (no string concatenation)
- String formatting settings class with options to format the displayed output:
  - number : round decimals
  - string : display literal quotes around strings
  - tables : display tables with line breaks or as one-line
  - tables : indent amount for multi-line tables
  - tables : toggle display of tables indexes
  - tables : maximum table length allowed before the table is forced to one-line
- Options for avoiding message flooding where the same message is repeated a lot of time

# Installation & Use

You have 2 options to install the script :

## Insert inline

Paste the code of the [./lllogger.lua](./lllogger.lua) at
the top of your OpScript code.

Create a new logger instance :

- Delete the `return logging` on last line
- Swap it with `local logger = logging:new("YourLoggerName")`

You can then use the following functions :

```lua

logger:debug("any object")
logger:info("any object")
logger:warning("any object")
logger:error("any object")

```

By default, the logger level is set to `debug`.

To change it you can use :

```lua

logger:set_level("debug")
logger:set_level("info") 
logger:set_level("warning")
logger:set_level("error")

```

## Module

Save the [./lllogger.lua](./lllogger.lua) file somewhere.

Add the location of the `lllogger.lua` to the Katana `LUA_PATH` env variable.
See [8.1 – The require Function](https://www.lua.org/pil/8.1.html) for more details.

Example for windows batch file :

```batch
:: the ? will be replaced by the string in `require("...")`
set "LUA_PATH=%LUA_PATH%;Z:\somedir\katana\?.lua"
```

In your OpScript you can then do :

```lua
local logging = require("lllogger")
local logger = logging:new("Test")

logger:debug("this is a debug message")

logger:set_level("error")

logger:info("this is an info message")
logger:error("this is an error message")
```

## Formatting

version 9+ include some formatting options to customize the displayed result.
These settings are stored on the logger in the `formatting` key. You can then 
use the functions or directly override the keys :

```lua
local logging = require("lllogger")
local logger = logging:new("TestFmt")

-- these 2 lines does the same thing
logger.formatting:set_tbl_linebreaks(true)
logger.formatting.tables.linebreaks = true

-- all function, arg is the default value
logger.formatting:set_num_round(3)
logger.formatting:set_str_display_quotes(false)
logger.formatting:set_tbl_display_indexes(false)
logger.formatting:set_tbl_linebreaks(true)
logger.formatting:set_tbl_length_max(50)
logger.formatting:set_tbl_indent(4)
logger.formatting:set_tbl_display_functions(true)
logger.formatting:set_blocks_duplicate(true)
logger.formatting:set_display_line(true)

```

Example with a table containing lot of data, table is displayed as multiples
lines except for the tables with a lot of values.

![fomatting demo](./fmt-demo.png)

## About

The message will be printed only if the logger level has a lower 'weight'
than the message's level.

As at the end, `lllogger` use `print()` to display the content. 
You should remember that in Katana, printing in the console has a latency cost. 
So having just 3 message log times the number of location the script is excuted
to can lead to crappy pre-render performance.

To avoid this you can abuse of `logger:debug` during development and then switch
the logger's level to `info` at publish time and make
sure there is only a few `logger:info` calls.

## Licensing

Apache License 2.0

See [LICENSE.md](./LICENSE.md) for full licence.

- ✅ The licensed material and derivatives may be used for commercial purposes.
- ✅ The licensed material may be distributed.
- ✅ The licensed material may be modified.
- ✅ The licensed material may be used and modified in private.
- ✅ This license provides an express grant of patent rights from contributors.
- 📏 A copy of the license and copyright notice must be included with the licensed material.
- 📏 Changes made to the licensed material must be documented

You can request a specific license by contacting me at [monsieurlixm@gmail.com](mailto:monsieurlixm@gmail.com) .

# Development

## Using outside of Katana

You can remove the `"[OpScript]"` prefix by modifying the `_log` method of the
`logging` class.

Everything else should work outside of Katana and is compatible with the 
standard lua library.
