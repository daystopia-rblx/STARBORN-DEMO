--[[ InputController
    Input hub
    @author @NantesF
    @version 1.0.0
    @date 2025-04-12
]]

local InputController = {}

InputController.Dependencies = {
    "Event",
    "Movement",
    "Status"
}

local Controllers
local Modules

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
    local Character = Player.Character

	if self.ReturnInput then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            Controllers.Movement:HandlePressed()
        elseif input.KeyCode == Enum.KeyCode.Q then
            Controllers.Movement:StartDodge()
        elseif input.KeyCode == Enum.KeyCode.F then
            Controllers.Event:FireServer("Combat.Parry", true)
        elseif input.KeyCode == Enum.KeyCode.H then
            if not Controllers.Status:CheckSpecific(Character.Humanoid, {Connection = true}, "Equipped") then
                Controllers.Event:FireServer("Combat.Equip")
            else
                Controllers.Event:FireServer("Combat.Unequip")
            end
        elseif input.KeyCode == Enum.KeyCode.R then
            Controllers.Event:FireServer("Combat.Critical")
        elseif input.KeyCode == Enum.KeyCode.Space then
            Controllers.Movement:StartVault()
            Controllers.Event:FireServer("Combat.Stomp")
        elseif input.KeyCode == Enum.KeyCode.LeftAlt then
            self.AltPressed = true
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Controllers.Status:CheckSpecific(Character.Humanoid, {Connection = true}, "Equipped") then
            if self.AltPressed == true then
                Controllers.Event:FireServer("Combat.Lunge")
            else
                Controllers.Event:FireServer("Combat.Attack")
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		if Controllers.Movement:CurrentlyDodging() then
			Controllers.Movement:CancelDodge()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        Controllers.Event:FireServer("Combat.Critical")
    end
end

function InputController:HandleInputEnded(input)
    local Player = Players.LocalPlayer

    if self.ReturnInput then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            Controllers.Movement:ToggleRun(false)
        elseif input.KeyCode == Enum.KeyCode.F then
            Controllers.Event:FireServer("Combat.Parry", false)
        elseif input.KeyCode == Enum.KeyCode.LeftAlt then
            self.AltPressed = false
        end
    end
end

return InputController