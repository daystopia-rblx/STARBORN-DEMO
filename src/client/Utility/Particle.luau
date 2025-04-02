--[[ Particle
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-02
]]
local Debris = game:GetService("Debris")

type ParticleProperties = {
    lifetime: number?,
    position: Vector3?,
    orientation: Vector3?,
    offset: CFrame?,
    weld: boolean?,
    continuous: boolean?,
    target: string?,
    emitCount: number?,
    speed: NumberRange?,
    size: NumberSequence?,
    transparency: NumberSequence?,
    color: ColorSequence?,
    sound: {
        volume: number?,
        playbackSpeed: number?
    }?
}

local Particle = {}

function Particle.Effect(basePart: BasePart | Folder, attachTo: BasePart, properties: ParticleProperties?): (Instance?, () -> ()?)
    if not basePart or not attachTo then return nil end

    if basePart:IsA("Folder") and properties and properties.target then
        local targetPart = basePart:FindFirstChild(properties.target)
        if not targetPart then
            warn("Failed to find target part:", properties.target)
            return nil
        end
        basePart = targetPart
    end

    local sourceAttachment = basePart:FindFirstChildWhichIsA("Attachment")
    if sourceAttachment then
        local clonedAttachment = sourceAttachment:Clone()
        clonedAttachment.Parent = attachTo

        if properties then
            if properties.position then
                clonedAttachment.Position = properties.position
            end
            if properties.orientation then
                clonedAttachment.Orientation = properties.orientation
            end
            if properties.offset then
                clonedAttachment.CFrame = properties.offset
            end
        end

        local function SetEmitter(enabled: boolean)
            for _, instance in clonedAttachment:GetDescendants() do
                if instance:IsA("ParticleEmitter") then
                    instance.Enabled = enabled
                end
            end
        end

        if properties and properties.continuous then
            SetEmitter(true)
            return clonedAttachment, function()
                SetEmitter(false)
                task.delay(2, function()
                    if clonedAttachment then
                        clonedAttachment:Destroy()
                    end
                end)
            end
        end

        for _, instance in clonedAttachment:GetDescendants() do
            if instance:IsA("ParticleEmitter") then
                if properties and properties.emitCount then
                    instance:Emit(properties.emitCount)
                else
                    instance:Emit()
                end

                if properties then
                    if properties.speed then
                        instance.Speed = properties.speed
                    end
                    if properties.size then
                        instance.Size = properties.size
                    end
                    if properties.transparency then
                        instance.Transparency = properties.transparency
                    end
                    if properties.color then
                        instance.Color = properties.color
                    end
                end
            end
            if instance:IsA("Sound") and properties and properties.sound then
                if properties.sound.volume then
                    instance.Volume = properties.sound.volume
                end
                if properties.sound.playbackSpeed then
                    instance.PlaybackSpeed = properties.sound.playbackSpeed
                end
                instance:Play()
            end
        end

        Debris:AddItem(clonedAttachment, properties and properties.lifetime or 2)
        return clonedAttachment
    end

    local clonedEffect = basePart:Clone()
    local primaryPart = nil

    if clonedEffect:IsA("Model") then
        primaryPart = clonedEffect.PrimaryPart or clonedEffect:FindFirstChild("Base") or clonedEffect:FindFirstChildWhichIsA("BasePart")
        if not primaryPart then
            clonedEffect:Destroy()
            return nil
        end
    else
        primaryPart = clonedEffect
    end

    if properties and properties.offset then
        if clonedEffect:IsA("Model") then
            clonedEffect:PivotTo(attachTo.CFrame * properties.offset)
        else
            clonedEffect.CFrame = attachTo.CFrame * properties.offset
        end
    else
        if clonedEffect:IsA("Model") then
            clonedEffect:PivotTo(attachTo.CFrame)
        else
            clonedEffect.CFrame = attachTo.CFrame
        end
    end

    if properties and properties.weld then
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = attachTo
        weld.Part1 = primaryPart
        weld.Parent = clonedEffect
    end

    clonedEffect.Parent = attachTo.Parent

    local function SetEmitter(enabled: boolean)
        for _, instance in clonedEffect:GetDescendants() do
            if instance:IsA("ParticleEmitter") then
                instance.Enabled = enabled
            end
        end
    end

    if properties and properties.continuous then
        SetEmitter(true)
        return clonedEffect, function()
            SetEmitter(false)
            task.delay(2, function()
                if clonedEffect then
                    clonedEffect:Destroy()
                end
            end)
        end
    end

    for _, instance in clonedEffect:GetDescendants() do
        if instance:IsA("ParticleEmitter") then
            if properties and properties.emitCount then
                instance:Emit(properties.emitCount)
            else
                instance:Emit()
            end

            if properties then
                if properties.speed then
                    instance.Speed = properties.speed
                end
                if properties.size then
                    instance.Size = properties.size
                end
                if properties.transparency then
                    instance.Transparency = properties.transparency
                end
                if properties.color then
                    instance.Color = properties.color
                end
            end
        end
        if instance:IsA("Sound") and properties and properties.sound then
            if properties.sound.volume then
                instance.Volume = properties.sound.volume
            end
            if properties.sound.playbackSpeed then
                instance.PlaybackSpeed = properties.sound.playbackSpeed
            end
            instance:Play()
        end
    end

    Debris:AddItem(clonedEffect, properties and properties.lifetime or 2)
    return clonedEffect
end

function Particle.Play(effectPath: string, attachTo: BasePart, properties: ParticleProperties?): (Instance?, () -> ()?)
    if not effectPath or not attachTo then return nil end

    local effect = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Particles")
    for _, pathPart in ipairs(string.split(effectPath, "/")) do
        effect = effect:WaitForChild(pathPart)
    end

    if not effect then
        warn("Failed to find particle effect:", effectPath)
        return nil
    end

    return Particle.Effect(effect, attachTo, properties)
end

function Particle.Cancel(effect: Instance?)
    if effect then
        effect:Destroy()
    end
end

return Particle