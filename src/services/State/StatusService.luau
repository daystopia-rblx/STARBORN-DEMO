--[[ StatusService
    Create and check player statuses
    @author @NantesF
    @version 1.0.0
    @date 2025-04-09
]]

local StatusService = {
	Timers = {},
}

local HttpService = game:GetService("HttpService")

type Info = {
	Set: any,
	Timed: boolean,
	Time: number,
	SetTo: boolean,
    Connection: boolean,
    Exclude: {string}?
}

StatusService.Dependencies = {
    "Event",
}

StatusService.Modules= {
    "Status"
}

StatusService.Events = {
    Create = { validate = true },
}

StatusService.Listeners = {
    ["Status.Create"] = function(self, Player: Player, Humanoid: Humanoid, Type: string, Action: string, Info: Info)
        if not Humanoid then return end

        self:CreateStatus(Humanoid, Type, Action, Info)
    end,
}

local Services
local Modules

function StatusService:Init(services, modules)
	Services = services
    Modules = modules
    return true
end

function StatusService:TimedStatus(Humanoid: Humanoid, Type: string, Action: string, Info: Info)
	if not Info.SetTo then
		Info.SetTo = false
	end

	if not Info.Time then
		Info.Time = 1
	end

	self.Timers[Humanoid] = self.Timers[Humanoid] or {}

	local Key = Type .. ":" .. Action
	local Token = HttpService:GenerateGUID(false)
	self.Timers[Humanoid][Key] = Token

	task.delay(Info.Time, function()
		if self.Timers[Humanoid] and self.Timers[Humanoid][Key] == Token then
			Humanoid[Type]:SetAttribute(Action, Info.SetTo)
			self.Timers[Humanoid][Key] = nil
		end
	end)
end

function StatusService:CreateStatus(Humanoid: Humanoid, Type: string, Action: string, Info: Info)
	Humanoid[Type]:SetAttribute(Action, Info.Set)

	if Info.Timed then
		self:TimedStatus(Humanoid, Type, Action, Info)
	end
end

function StatusService:CheckStatus(Humanoid: Humanoid, Info: Info): {} | boolean
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

function StatusService:CheckSpecific(Humanoid: Humanoid, Info: Info, ...: string): {} | boolean
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
            if Value == true then
                return true
            end
        end
        return false
    end

    return Results
end

function StatusService:CheckCooldowns(Humanoid: Humanoid, Info: Info, ...: string): {} | boolean
	local Requests = {...}
	local Results = {}

	if Info then
		for i, value in pairs(Info) do
			if type(value) == "string" then
				table.insert(Requests, value)
			end
		end
	end
    
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
			if Value == true then
				return true
			end
		end
		return false
	end

	return Results
end

return StatusService