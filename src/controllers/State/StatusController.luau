--[[ StatusController
    Create and check player statuses
    @author @NantesF
    @version 1.0.0
    @date 2025-04-09
]]

local StatusController = {}

local HttpService = game:GetService("HttpService")

type Info = {
    Connection: boolean,
    Exclude: {string}?
}

StatusController.Modules= {
    "Status"
}

local Controllers
local Modules

function StatusController:Init(controllers, modules)
	Controllers = controllers
    Modules = modules
    return true
end

function StatusController:CheckStatus(Humanoid: Humanoid, Info: Info): {} | boolean
    local Results = {}
    local Active = false
    
    local Exclusions = {}
    if Info.Exclude then
        for _, exclusion in ipairs(Info.Exclude) do
            Exclusions[exclusion] = true
        end
    end
    
    for Category, Actions in pairs(Modules.Status) do
        if Category ~= "Cooldown" then
            Results[Category] = {}
            
            for _, Action in ipairs(Actions) do
                local Value = Humanoid[Category] and Humanoid[Category]:GetAttribute(Action)
                Results[Category][Action] = Value
                
                if Info.Connection and Value == true and not Exclusions[Action] then
                    Active = true
                end
            end
        end
    end
    
    if Info and Info.Connection then
        return Active
    end
    
    return Results
end

function StatusController:CheckSpecific(Humanoid: Humanoid, Info: Info, ...: string): {} | boolean
	local Requests = {...}
	local Results = {}

	for Category, Actions in pairs(Modules.Status) do
		for _, Action in ipairs(Actions) do
			for _, Requested in ipairs(Requests) do
				if Action == Requested then
					local Specific = Humanoid[Category]:GetAttribute(Action)
					Results[Action] = Specific
				end
			end
		end
	end

	if Info.Connection then
		for _, Value in pairs(Results) do
			if Value ~= true then
				return false
			end
		end
		return true
	end

	return Results
end

function StatusController:CheckCooldowns(Humanoid: Humanoid, Info: Info, ...: string): {} | boolean
	local Requests = {...}
	local Results = {}
    
    local Actions = Modules.Status.Cooldown
    if Actions then
        for _, Action in ipairs(Actions) do
            if #Requests > 0 then
                for _, Requested in ipairs(Requests) do
                    if Action == Requested then
                        local Value = Humanoid.Cooldown and Humanoid.Cooldown:GetAttribute(Action)
                        Results[Action] = Value
                    end
                end
            else
                local Value = Humanoid.Cooldown and Humanoid.Cooldown:GetAttribute(Action)
                Results[Action] = Value
            end
        end
    end

	if Info and Info.Connection then
		for _, Value in pairs(Results) do
			if Value ~= true then
				return false
			end
		end
		return true
	end

	return Results
end

return StatusController