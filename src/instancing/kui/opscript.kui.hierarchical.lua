
local hier = require("kui.hierarchical")

if Interface.AtRoot() then
  hier:set_logger_level("debug")
  hier:run_root()
else
  hier:run_not_root()
end