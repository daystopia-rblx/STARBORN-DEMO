local DaggerService = {}

DaggerService.Dependencies = {
    "Event",
    "Asset",
    "Status",
    "Stat",
    "Hitbox",
    "Particle"
}

DaggerService.Modules = {
    "Animation",
    "Status",
    "Stat",
    "Sound"
}
local Utility = {
    Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
}

local Services
local Modules

local Debris = game:GetService("Debris")
local CombatService = require(game.ServerScriptService.Services.Combat.CombatService)

function DaggerService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function DaggerService:Trail(Character, Duration)
    for _, trail in ipairs(Character:GetDescendants()) do
        if trail:IsA("Trail") and ((trail:GetAttribute("WeaponTrail") == true)) then
            trail.Enabled = true
            task.delay(Duration, function()
                trail.Enabled = false
            end)
            return
        end
    end

    for _, trail in ipairs(Character:GetDescendants()) do
        if trail:IsA("Trail") and ((trail:GetAttribute("GripTrail") == true)) then
            trail.Enabled = true
            task.delay(Duration, function()
                trail.Enabled = false
            end)
        end
    end
end

function DaggerService:Critical(Character: Model, Humanoid: Humanoid, Root: BasePart, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Critical") == true then return end

    Services.Status:CreateStatus(Humanoid, "Combat", "Critical", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Critical.Duration})
    Services.Status:CreateStatus(Humanoid, "Cooldown", "Critical", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Critical.Cooldown})

    local function Checker()
        local cancelled = false

        task.spawn(function()
            while Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical") do
                if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed", "Parried") then
                    cancelled = true
                    Utility.Animation:Stop(Humanoid, "Critical")
                    break
                end
                task.wait()
            end
        end)

        return function()
            return cancelled
        end
    end

    local Interrupted = Checker()

    local Origin = Character:GetAttribute("SPEED") or 16
    task.spawn(function()
        while task.wait() do
            if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical") then
                Humanoid.WalkSpeed = Origin / 4
            else
                Humanoid.WalkSpeed = Origin
            end
        end
    end)

    Utility.Animation:Play(Data.Attack.Critical.Animation.id, Humanoid, Data.Attack.Speed, Enum.AnimationPriority.Action3, "Critical")
    DaggerService:Trail(Character, Data.Attack.Critical.Duration)

    local Params = OverlapParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {Character}

    task.wait(Data.Attack.Critical.Windup)

    if not Interrupted() and not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then  
        local CombatConfig = {
            DamageType = Data.Attack.Critical.DamageType,
            Damage = Data.Attack.Critical.Damage,
        }

        for i = 1, 3 do
            if Interrupted() or Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then
                break
            end

            local Swing = tostring("Swing_"..i)
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Data.Attack.Critical[Swing], parent = Root, duration = 2, volume = 0.5})

            local Hitbox = Services.Hitbox:Create(Root.CFrame, Data.Attack.Critical.Hitbox, Params)
            Hitbox:WeldTo(Root)
            Hitbox:SetConfig({
                Offset = Data.Attack.Critical.Offset
            })

            Hitbox:OnHit(function(Char, Hum, Rot)
                CombatService:Handler(Humanoid, Hum, CombatConfig)
            end)

            Hitbox:Run(0.15)
            
            if i < 3 then
                task.wait(0.2)
            end
        end
    end
end

return DaggerService