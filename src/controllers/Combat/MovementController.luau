--[[ MovementController
    Core player movement (Local)
    @author @NantesF
    @version 1.0.0
    @date 2025-04-08
]]

local MovementController = {
    --[[ Constraints ]]
    TapTime = 0.3 :: number,
    LastPress = 0 :: number,
    Debounce = false :: boolean
}

MovementController.Dependencies = {
    "Event"
}

local Players = game:GetService("Players")
local StatusController = require(game.ReplicatedStorage.Controllers.Status.StatusController)

--[[ State ]]
local Controllers
local Modules

--[[ Core Functions ]]
function MovementController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

--[[ Running ]]
function MovementController:HandlePressed()
    if self.Debounce then return end
    local CurrentTime = tick()
    if CurrentTime - self.LastPress <= self.TapTime then
        self:ToggleRun(true)
    end
    self.LastPress = CurrentTime
end

function MovementController:ToggleRun(Active: boolean)
    local Player = Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local Humanoid = Character:FindFirstChild("Humanoid")


    if not StatusController:CheckStatus(Humanoid, {Connection = true}, "Running") then
        Humanoid.WalkSpeed = 32
        print("Working!")
    end
end

return MovementController