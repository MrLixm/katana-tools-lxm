"""
version=6

Create the OpScript node for the attMath script.
Check that SCRIPT variable use the latest version of the .lua file that should
be shipped alongside this script.
"""
from Katana import NodegraphAPI, UI4

FRAME = NodegraphAPI.GetCurrentTime()

SCRIPT = r"""
--[[
version=5
author=Liam Collod
last_modified=08/03/2022

Supports for multiple time-samples.

[OpScript setup]
parameters:
  location: location where attribute must be modified
  applyWhere: at specific location OR at locations matching CEL
user:
  attributes(string array):
    list of attribute path to apply the same math operation
    - [1*n] = path of the attribute relative to the location
    - [2*n] = expression to specify indesx to skip like :
      Every X indexes, skip indexes N[...] == N,N,.../X == (%d+,*)+/%d+
      ex: skip 2/3/4th index every 4 index == "2,3,4/4"

  multiply(float):
    multiplier to apply on all value
  add(float):
    offset to apply on all the values
  op_order(string)(optional):
    use "add" if the offset need to be applied first or "multiply" for the inverse
]]

local function err(...)
  --[[
  Raise an error.
  Concat the given arguments to string and pass them as the error's message.
  ]]

  local buf = {"[attrMath]["}
  buf[ #buf + 1 ] = Interface.GetInputLocationPath()
  buf[ #buf + 1 ] = "]"

  for i=1, select("#",...) do
    buf[ #buf + 1 ] = tostring(select(i,...))
  end

  error(table.concat(buf))

end


local function get_user_attr(name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value. (unless asked to raise an error)

    Args:
        name(str): attribute location (don't need the <user.>)
        default_value(any): value to return if user attr not found
          you can use the <error> builtin to raise an error instead
    Returns:
        table or any: table of value on attribute or default value
    ]]
    local argvalue = Interface.GetOpArg("user."..name)

    if argvalue then
      return argvalue:getNearestSample(0)

    elseif default_value==error then
     err("[get_user_attr] user attribute <",name,"> not found.")

    else
      return default_value

    end

end


local function get_attr(attr_path)
  --[[
  Get the given attribute on the location.
  Raise an error is nil result is found.

  Args:
    attr_path(str): path of the attribute on the location
  Returns:
    DataAttribute:
  ]]

  local lattr = Interface.GetAttr(attr_path)

  if not lattr then
    err("[get_loc_attr] Attr <",attr_path,"> not found on location.")

  end

  return lattr

end


local function get_attribute_class(dataattribute)
  --[[
  Returned a non-instanced version of the DataAttribute given in arg.

  Args:
    dataattribute(str): DataAttribute instance
  Returns:
    table: DataAttribute class not instanced
  ]]
  if Attribute.IsInt(dataattribute) == true then
    return IntAttribute
  elseif Attribute.IsFloat(dataattribute) == true then
    return FloatAttribute
  elseif Attribute.IsDouble(dataattribute) == true then
    return DoubleAttribute
  elseif Attribute.IsString(dataattribute) == true then
    return StringAttribute
  else
    err("[get_attribute_class] passed class type <",dataattribute,"> is not supported.")
  end
end


local function get_skip_table(arguments)
  --[[
  Args:
    arguments(str): string formatted as [%d,]+%/%d+
  ]]

  -- if not specified
  if arguments == "" then
    return {["tuple"]=1, ["skip"]={}}
  end

  if not arguments:match("[%d,]+%/%d+") then
    err("[get_skip_table] Argument not formatted properly: ",arguments)
  end

  local out = {}
  out.tuple = tonumber(arguments:sub(-1))
  arguments = arguments:sub(1, -3) -- strip the 2 last characters (ex:/3)
  out.skip = {}
  -- split at the ,
  for each in arguments:gmatch("([^,]+)") do

    if tonumber(each) > out.tuple then
      err("[get_skip_table] Index <",each,"> to skip is bigger than \z
       the tuple size <",out.tuple,">")
    end

    out.skip[tonumber(each)] = true

  end

  return out

end


local function run()

  local u_attr_list = get_user_attr("attributes", error)
  local u_mult = get_user_attr("multiply", error)[1]
  local u_add = get_user_attr("add", error)[1]
  local u_order = get_user_attr("op_order", "add")[1]

  local order_add = "add"
  local order_mult = "multiply"

  local attr_skip
  local attr_path
  local attr_data
  local attr_type
  local new_value
  local new_value_smpls

  for iattr=0, #u_attr_list / 2 - 1 do

    attr_path = u_attr_list[iattr * 2 + 1]  -- string
    attr_skip = get_skip_table(u_attr_list[iattr * 2 + 2]) -- table
    attr_data = get_attr(attr_path)  -- DataAttribute
    attr_type =  get_attribute_class(attr_data)  -- DataAttribute

    -- check that the user specified tuple size seems valid
    new_value = attr_data:getNearestSample(0)
    if #new_value / attr_skip.tuple ~= math.floor(#new_value / attr_skip.tuple) then
      err(
        "[run] The skip tuple size specified <",attr_skip.tuple,">, divided by \z
        the number of value <",#new_value,"> is not an integer."
      )
    end

    new_value_smpls = {}

    for smplindex=0, attr_data:getNumberOfTimeSamples() - 1 do

      -- convert the smplindex to sampletime (shutterOpen/Close values)
      smplindex = attr_data:getSampleTime(smplindex)
      new_value = attr_data:getNearestSample(smplindex)

      for i=0, #new_value / attr_skip.tuple - 1 do
        -- /!\ performances

        for ii=1, attr_skip.tuple do

          -- if the index is not specified as skipable, do the math
          if not attr_skip.skip[ii] then

            if u_order==order_add then
              new_value[i*attr_skip.tuple + ii] = (new_value[i*attr_skip.tuple + ii] + u_add) * u_mult
            elseif u_order==order_mult then
              new_value[i*attr_skip.tuple + ii] = new_value[i*attr_skip.tuple + ii] * u_mult + u_add
            else
              err("[run] user argument <order> value <",u_order,"> is not supported.")
            end
            -- end if index not skipped
          end
          -- end tuple loop
        end
        -- end #new_value loop
      end

      new_value_smpls[smplindex] = new_value

      -- end smplidnex loop
    end

    Interface.SetAttr(
        attr_path,
        attr_type(new_value_smpls, attr_data:getTupleSize())
    )
    -- end attributes iterations
  end

end

run()

"""


def get_node_screen_pos(x_offset=0, y_offset=0):
    """
    Return the position from the top left corner of the nodegraph

    Args:
        x_offset:
        y_offset:

    Returns:
        tuple:

    """

    nodegraph_tab = UI4.App.Tabs.FindTopTab('Node Graph')
    nodegraph_widget = nodegraph_tab.getNodeGraphWidget()
    view_dimensions = nodegraph_widget.getVisibleArea()  # type: tuple

    return view_dimensions[0][0] + x_offset, view_dimensions[1][1] + y_offset


node = NodegraphAPI.CreateNode(
    "OpScript",
    NodegraphAPI.GetRootNode()
)
node.setName("OpScript_attrMath_1")

pos = get_node_screen_pos(350, -350)
NodegraphAPI.SetNodePosition(node, pos)

node.getParameter("applyWhere").setValue("at specific location", FRAME)
node.getParameter("script.lua").setValue(SCRIPT, FRAME)
userparam = node.getParameters().createChildGroup('user')
p = userparam.createChildStringArray("attributes", 2)
p.setTupleSize(2)
hint = {
    "resize": True,
    "tupleSize": 2,
    "help": """
    <p>n Rows of 2 columns:<br />- [1*n] = path of the attribute relative to the location<br />- [2*n] = expression to specify indesx to skip like :<br />&nbsp;&nbsp; Every X indexes, skip indexes N[...] == N,N,.../X == (%d+,*)+/%d+<br />&nbsp;&nbsp; ex: skip 2/4st index every 4 index == "2,4/4"</p>    
    """
}
p.setHintString(repr(hint))
userparam.createChildNumber("multiply", 1.0)
userparam.createChildNumber("add", 0.0)
p = userparam.createChildString("op_order", "add")
hint = {
    'widget': 'popup',
    'options': ['add', 'multiply'],
    "help": "Which operation should be applied first."
}
p.setHintString(repr(hint))

NodegraphAPI.SetAllSelectedNodes([node])
NodegraphAPI.SetNodeEdited(node, True, exclusive=True)
