--[[ InputController
    Input hub
    @author @NantesF
    @version 1.0.0
    @date 2025-04-12
]]

local InputController = {}

InputController.Dependencies = {
    "Event"
}

local Controllers
local Modules

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MovementController = require(game.ReplicatedStorage.Controllers.Combat.MovementController)

function InputController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function InputController:Start()
    UserInputService.InputBegan:Connect(function(input, GPE)
		if not GPE then
			self:HandleInputBegan(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input, GPE)
		if not GPE then
			self:HandleInputEnded(input)
		end
	end)
    return true
end

function InputController:HaltInput(Active)
	if Active == true then
		self.ReturnInput = true
	elseif Active == false then
		self.ReturnInput = false
	end
end

function InputController:HandleInputBegan(input)
    local Player = Players.LocalPlayer

	if self.ReturnInput then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.Keycode == Enum.KeyCode.W then
            MovementController:HandlePressed()
        elseif input.Keycode == Enum.KeyCode.Q then
        
        end
    end
end

function InputController:HandleInputEnded(input)
    local Player = Players.LocalPlayer

    if self.ReturnInput then return end

end

return InputController