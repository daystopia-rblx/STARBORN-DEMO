--[[ StatusController
    Create and check player statuses
    @author @NantesF
    @version 1.0.0
    @date 2025-04-09
]]

local StatusController = {}

StatusController.Modules= {
    "Status"
}

local Modules

type Info = {
    Connection: boolean
}

function StatusController:Init(modules)
    Modules = modules
    return true
end

--[[function StatusController:TimedStatus(Humanoid: Humanoid, Type: string, Action: string, Info: Info)
	if not Info.SetTo then
		Info.SetTo = nil
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

function StatusController:CreateStatus(Humanoid: Humanoid, Type: string, Action: string, Info: Info)
	Humanoid[Type]:SetAttribute(Action, Info.Set)

	if Info.Timed then
		self:TimedStatus(Humanoid, Type, Action, Info)
	end
end]]

function StatusController:CheckStatus(Humanoid: Humanoid, Info: Info): {} | boolean
	local Results = {}
	local Active = true

	for Category, Actions in pairs(Modules.Data.StatusModule) do
		Results[Category] = {}

		for _, Action in ipairs(Actions) do
			local Value = Humanoid[Category] and Humanoid[Category]:GetAttribute(Action)
			Results[Category][Action] = Value

			if Info.Connection and Value ~= true then
				Active = false
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

	for Category, Actions in pairs(Modules.Data.StatusModule) do
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

return StatusController