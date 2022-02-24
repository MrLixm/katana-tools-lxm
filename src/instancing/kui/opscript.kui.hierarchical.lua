
local hier = require("kui.hierarchical")

if Interface.AtRoot() then
  hier:set_logger_level("debug")
  hier:run_root()
else
  -- don't print/log anything here, repeated times number of points.
  hier:run_not_root()
end