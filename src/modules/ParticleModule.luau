--[[ ParticleModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-16
]]
local ParticleModule = {}

ParticleModule.Categories = {
    COMBAT = "Combat",
    ENVIRONMENT = "Environment",
    MOVEMENT = "Movement",
    MAGIC = "Magic",
    UTILITY = "Utility",
    FX = "Effects"
}

ParticleModule.EffectTypes = {
    VFX = "VFX",
    CHARACTER = "Character",
    SOUND = "Sound",
    LIGHT = "Light",
    BLOOD = "Blood",
    POOLED = "Pooled"
}

ParticleModule.Effects = {
    Combat = {
        Blood = function(context, parent, amount)
            if not parent then return nil end

            local bloodInstance = context.bloodengineinstance
            if not bloodInstance then return nil end

            amount = amount or math.random(5, 15)

            task.spawn(function()
                local emitsPerBurst = 3
                local emitDelay = 0.05
                local amountPerEmit = math.ceil(amount / emitsPerBurst)

                for i = 1, emitsPerBurst do
                    bloodInstance:EmitAmount(parent.Position, nil, amountPerEmit)
                    if i < emitsPerBurst then
                        task.wait(emitDelay)
                    end
                end
            end)

            return bloodInstance
        end
    }
}

ParticleModule.Handlers = {
    Effects = {
        [ParticleModule.EffectTypes.VFX] = function(context)
            local folders = context.folders
            local config = context.config

            if not config.vfx or not config.parent then return nil end

            local Effect = config.vfx:Clone()
            Effect.Parent = config.parent or (folders and folders.particles) or workspace

            if Effect:IsA("Attachment") then
                Effect.Position = Effect.Position + (config.position or Vector3.new(0, 0, 0))
            end

            local duration = config.duration or 1

            if config.notAttachment then
                for _, child in ipairs(Effect:GetChildren()) do
                    if child:IsA("ParticleEmitter") then
                        if config.colour or config.color then
                            child.Color = ColorSequence.new(config.colour or config.color)
                        end
                        child.Parent = config.parent
                        child:Emit(child:GetAttribute("EmitCount") or 1)
                        game:GetService("Debris"):AddItem(child, duration + 1)
                    end

                    task.delay(duration, function()
                        if child:IsA("ParticleEmitter") then
                            child.Enabled = false
                        end
                    end)
                end
                Effect:Destroy()
            else
                for _, v in pairs(Effect:GetChildren()) do
                    if v:IsA("ParticleEmitter") then
                        if config.colour or config.color then
                            v.Color = ColorSequence.new(config.colour or config.color)
                        end
                        v:Emit(v:GetAttribute("EmitCount") or 1)
                    end
                end
                game:GetService("Debris"):AddItem(Effect, duration)
            end

            return Effect
        end,

        [ParticleModule.EffectTypes.CHARACTER] = function(context)
            return ParticleModule.Handlers.Effects[ParticleModule.EffectTypes.VFX](context)
        end,

        [ParticleModule.EffectTypes.BLOOD] = function(context)
            local config = context.config
            local bloodInstance = context.bloodengineinstance

            if not config.parent then return nil end
            if not bloodInstance then return nil end

            local amount = config.amount or math.random(1, 10)

            task.spawn(function()
                local emitsPerBurst = 3
                local emitDelay = 0.05
                local amountPerEmit = math.ceil(amount / emitsPerBurst)

                for i = 1, emitsPerBurst do
                    bloodInstance:EmitAmount(config.parent.Position, nil, amountPerEmit)
                    if i < emitsPerBurst then
                        task.wait(emitDelay)
                    end
                end
            end)

            return bloodInstance
        end,

        [ParticleModule.EffectTypes.SOUND] = function(context)
            local services = context.services
            local config = context.config
            if not config.sfx then return nil end

            local soundConfig
            if type(config.sfx) == "string" and not string.find(config.sfx, "rbxassetid://") then
                soundConfig = config.sfx
            else
                soundConfig = {
                    id = config.sfx,
                    volume = config.volume or 1,
                    speed = config.speed or 1,
                    loop = config.loop or false,
                    spatial = true,
                    distance = 50,
                    category = config.category or "SFX",
                    parent = true,
                    randomPitch = config.randomPitch
                }

                local duration = config.duration
                if duration then
                    soundConfig.duration = duration
                end
            end

            local sound = services.Audio:PlaySound(config.parent, soundConfig)
            return sound
        end,

        [ParticleModule.EffectTypes.LIGHT] = function(context)
            local folders = context.folders
            local config = context.config

            local colour = config.colour or config.color or Color3.fromRGB(255, 255, 255)
            local brightness = config.brightness or 1
            local radius = config.radius or 8

            local Attachment
            if not config.parent then
                Attachment = Instance.new("Attachment")
                Attachment.Name = "LightAttach"
                Attachment.Parent = (folders and folders.lights) or workspace.Terrain

                if config.cfPosition then
                    local offset = Vector3.new(0, 0, -2)
                    Attachment.CFrame = config.cfPosition * CFrame.new(offset)
                end
            else
                Attachment = Instance.new("Attachment")
                Attachment.Name = "LightAttach"
                Attachment.Parent = config.parent
                Attachment.CFrame = CFrame.new()

                if config.position then
                    Attachment.Position = config.position
                end
            end

            local Light = Instance.new("PointLight")
            Light.Parent = Attachment
            Light.Color = colour
            Light.Brightness = brightness
            Light.Range = radius
            Light.Shadows = true

            local duration = config.duration
            if duration then
                game:GetService("Debris"):AddItem(Attachment, duration)
            end

            if config.tweenTime and config.tweenTable then
                local tweenInfo = TweenInfo.new(config.tweenTime)

                local tweenProps = {}
                for prop, value in pairs(config.tweenTable) do
                    local properCase = prop:sub(1,1):upper() .. prop:sub(2):lower()
                    tweenProps[properCase] = value
                end

                local tween = game:GetService("TweenService"):Create(Light, tweenInfo, tweenProps)
                tween:Play()
            end

            return Light
        end,

        [ParticleModule.EffectTypes.POOLED] = nil
    }
}

return ParticleModule