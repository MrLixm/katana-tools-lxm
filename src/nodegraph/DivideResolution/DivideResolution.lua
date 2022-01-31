--[[
VERSION = 0.0.5

OpScript for Foundry's Katana software

Divide the current render resolution by the given amount.
The divider amount can be supplied or by creating an OpArg (user.divider) or by creating a gsv "resolution_divider".

Author: Liam Collod
Last Modified: 19/10/2021

[OpScript setup]
parameters:
    location: /root
    applyWhere: at specific location
user:
    divider: (int)

[License]
Copyright 2022 Liam Collod

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]



local round = function(a, prec)
    -- source: https://stackoverflow.com/questions/9654496/lua-converting-from-float-to-int
    return math.floor(a + 0.5*prec) -- where prec is 10^n, starting at 0
end


function get_divider(frame)
    --[[
    Return the resolution divider from a graphstatevariable named 'resolution_divider' if it exists, else from the OpArg user.divider

    Args:
        frame(int): current frame
    Returns:
        int: resolution divider
    ]]
    local gsv_value = Interface.GetGraphStateVariable("resolution_divider")
    if gsv_value then
       return tonumber(gsv_value:getValue())
    end

    local argvalue = Interface.GetOpArg("user.divider")
    if argvalue then
        return argvalue:getNearestSample(frame)[1]
    end
    
end


function run()

    local frame = Interface.GetCurrentTime() -- int
    local divider = get_divider(frame)

    -- divider == 0 or 1 means we doesn't want to apply any resolution reformating.
    if divider == 0 or divider==1 then
        return
    end

    local resolution = Interface.GetAttr("renderSettings.resolution"):getNearestSample(frame)[1]
    resolution = ResolutionTable.GetResolution(resolution)
    if not resolution then
        print("[DivideResolution][run] renderSettings.resolution has an issue.  ResolutionTable.GetResolution() returned nil.")
        return
    end

    local new_resolution_x = round(resolution:getXRes() / divider, 0)
    local new_resolution_y = round(resolution:getYRes() / divider, 0)
    local new_resolution =  tostring(new_resolution_x) .. "x" .. tostring(new_resolution_y) -- str

    Interface.SetAttr("renderSettings.resolution", StringAttribute(new_resolution))

end

-- execute
run()