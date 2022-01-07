# llloger

![lua](https://img.shields.io/badge/type-lua-blue)

A simple lua logging module based on Python one. 
Originaly made for use with Foundry's Katana software, OpScript feature.

## Installation & Use

### Insert inline

Paste the code of the [./lllogger.lua](./lllogger.lua) at
the top of your OpScript code.

Rename the logger by changing the string passed to `new()` (last line).

You can then use the following functions :

```lua

logger:debug("any object")
logger:info("any object")
logger:warning("any object")
logger:error("any object")

-- functions used by the logger but that you could use for other reasons
stringify()
round()
table2string()

```

The `LOG_LEVEL` variable can have the following values :
```lua

local LOG_LEVEL = "debug"
local LOG_LEVEL = "info" 
local LOG_LEVEL = "warning"
local LOG_LEVEL = "error"

```

### Module

Save the [./lllogger.lua](./lllogger.lua) file somewhere.

**Replace** the last line that declare the logger variable with :

```lua
return logging
```

Add the location of the `lllogger.lua` to the Katana `LUA_PATH` env variable.

Example for windows batch file :

```batch
set "LUA_PATH=%LUA_PATH%;Z:\somedir\katana\lllogger.lua"
```

In your OpScript you can then do :

```lua
local logging = require "llloger"
local logger = logging:new("Test")

logger:debug("this is a debug message")

logger:set_level("error")

logger:info("this is an info message")
logger:error("this is an error message")
```

## About

The message will be printed only if the `LOG_LEVEL` variable has a lower 'weight'
than the level used.

As at the end, `llloger` use `print()` to display the content. 
You should remember that in Katana, printing in the console has a latency cost. 
So having just 3 message log times the number of location the script is excuted
to can lead to crappy pre-render performance.

To avoid this you can abuse of `logger:debug` during development and then switch
`LOG_LEVEL` to `info` at publish time and make sure there is only a few 
`logger:info` calls. (or use `logger:set_level()`)

## Development

empty
