task.wait(0.125)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

local function updateCameraOffset()
    local offsetPosition = (rootPart.CFrame + Vector3.new(0, 1.5, 0)):pointToObjectSpace(head.CFrame.p)
    local tweenInfo = TweenInfo.new(0.2)
    local tween = TweenService:Create(humanoid, tweenInfo, {CameraOffset = offsetPosition})
    tween:Play()
end

RunService:BindToRenderStep("CameraOffset", Enum.RenderPriority.Camera.Value - 1, updateCameraOffset)
