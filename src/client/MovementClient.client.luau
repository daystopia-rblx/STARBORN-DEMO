--[[ MovementClient
    Input player movement communication
    @author @NantesF
    @version 1.0.0
    @date 2025-04-08
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Controllers = {
    Movement = require(ReplicatedStorage.Controllers.MovementController)
}

local Utility = {
    Animation = require(script.Parent.Utility.Animation),
    Input = require(script.Parent.Utility.Input),
    Camera = require(script.Parent.Utility.Camera),
    Particle = require(script.Parent.Utility.Particle),
    Sound = require(script.Parent.Utility.Sound)
}

local ActionConfig = {
    id = "playerControls",
    actions = {
        Utility.Input.CreateAction("Run", {Enum.KeyCode.W}, function(Active: boolean)
            if Active then
                Controllers.Movement:HandlePressed()
            end
        end)
    },
    keyboardEnabled = true
}

local Handler = Utility.Input.HandleInput(ActionConfig)