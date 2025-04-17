--[[ ParticleService
    Dynamic particle effect system with pooling and performance optimization.
    Handles effect creation, lifecycle management, and automatic cleanup of particle emitters.
    @author @Daystopia / @NantesF
    @version 1.0.2
    @date 2025-04-16
]]
local ParticleService = {}

--[[ Dependencies ]]
ParticleService.Dependencies = {
    "Event",
    "Asset",
    "Audio"
}

--[[ Modules ]]
ParticleService.Modules = {
    "Particle"
}

--[[ Events ]]
ParticleService.Events = {
    Create = true,
    Play = true,
    Stop = true
}

--[[ Services & Modules ]]
local Services
local Modules
local Debris = game:GetService("Debris")

--[[ Imports ]]
local ImportInstances = {}
local Imports = {
    {
        name = "BloodEngine",
        path = game.ReplicatedStorage.Assets.Imports.BloodEngine,
        instanceName = "BloodEngineInstance",
        initMethod = function(module)
            return module.new()
        end
    }
}

--[[ Constants ]]
local CONSTANTS = {
    LIFETIME = 1,
    POOL_SIZE = {
        MIN = 10,
        MAX = 50
    },
    FOLDER_NAMES = {
        PARTICLES = "Particles",
        LIGHTS = "Lights",
        SOUNDS = "Sounds",
        EFFECTS = "Effects"
    }
}

--[[ Types ]]
type ParticleConfig = {
    -- Core Configuration
    preset: string?,
    effectType: string?,
    duration: number?,
    category: string?,
    parent: Part?,
    position: Vector3?,

    -- Visual Properties
    color: ColorSequence?,
    colour: Color3?,
    size: NumberSequence?,
    transparency: NumberSequence?,
    texture: string?,
    lightEmission: number?,
    lightInfluence: number?,
    brightness: number?,
    zOffset: number?,
    squash: NumberSequence?,

    -- Motion Properties
    speed: NumberRange?,
    emission: NumberRange?,
    rate: number?,
    acceleration: Vector3?,
    velocityInheritance: number?,
    velocitySpread: NumberRange?,
    drag: number?,
    lockedToPart: boolean?,
    windAffectsDrag: boolean?,

    -- Emission Shape Properties
    shape: Enum.ParticleEmitterShape?,
    shapeInOut: Enum.ParticleEmitterShapeInOut?,
    shapePartial: number?,
    shapeStyle: Enum.ParticleEmitterShapeStyle?,
    emissionDirection: Enum.NormalId?,
    spreadAngle: Vector2?,

    -- Animation Properties
    lifetime: NumberRange?,
    timeScale: number?,
    orientation: Enum.ParticleOrientation?,
    rotSpeed: NumberRange?,
    rotation: NumberRange?,

    -- Flipbook Properties
    flipbookFramerate: NumberRange?,
    flipbookLayout: Enum.ParticleFlipbookLayout?,
    flipbookMode: Enum.ParticleFlipbookMode?,
    flipbookStartRandom: boolean?,

    -- State Properties
    enabled: boolean?,

    -- Effect-Specific Properties
    vfx: Attachment?,
    loop: boolean?,
    notAttachment: boolean?,

    -- Sound Properties
    sfx: string?,
    volume: number?,
    randomPitch: boolean?,

    -- Light properties
    radius: number?,
    cfPosition: CFrame?,

    -- Animation Properties
    tweenTime: number?,
    tweenTable: {[string]: any}?,

    -- Blood Effect Properties
    amount: number?
}

--[[ State ]]
local state = {
    active = {},
    pools = {},
    presets = {},
    folders = {}
}

ParticleService.Listeners = {
    ["Particle.Create"] = function(self, player, config)
        self:CreateParticle(config)
    end,

    ["Particle.Play"] = function(self, player, effectCategory, effectName, ...)
        self:PlayParticle(effectCategory, effectName, ...)
    end,

    ["Particle.Stop"] = function(self, player, particle, instant)
        self:StopParticle(particle, instant)
    end
}

--[[ Utility Functions ]]
local function CreateFolders(parent)
    local folders = {}
    local function CreateFolder(name, parent)
        local folder = parent:FindFirstChild(name)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = name
            folder.Parent = parent
        end
        return folder
    end

    local runtimeFolder = workspace:FindFirstChild("Runtime")
    if not runtimeFolder then
        runtimeFolder = Instance.new("Folder")
        runtimeFolder.Name = "Runtime"
        runtimeFolder.Parent = workspace
    end

    folders.root = CreateFolder("Effects", runtimeFolder)
    folders.particles = CreateFolder(CONSTANTS.FOLDER_NAMES.PARTICLES, folders.root)
    folders.lights = CreateFolder(CONSTANTS.FOLDER_NAMES.LIGHTS, folders.root)
    folders.sounds = CreateFolder(CONSTANTS.FOLDER_NAMES.SOUNDS, folders.root)
    folders.effects = CreateFolder(CONSTANTS.FOLDER_NAMES.EFFECTS, folders.root)

    return folders
end

local function LoadImports()
    for _, importInfo in ipairs(Imports) do
        local success, result = pcall(function()
            local module = require(importInfo.path)
            Imports[importInfo.name] = module

            if importInfo.initMethod and type(importInfo.initMethod) == "function" then
                local instance = importInfo.initMethod(module)
                local instanceName = importInfo.instanceName or (importInfo.name .. "Instance")
                ImportInstances[instanceName] = instance
            end

            return true
        end)

        if not success then
            warn("Failed to load import: " .. importInfo.name .. " - " .. tostring(result))
        end
    end
end

--[[ Core Functions ]]
function ParticleService:Init(services, modules)
    Services = services
    Modules = modules
    LoadImports()
    return true
end

function ParticleService:Start()
    state.folders = CreateFolders(workspace)
    return true
end

function ParticleService:Cleanup()
    for particle in pairs(state.active) do
        particle:Destroy()
        if particle.Parent and particle.Parent:IsA("Attachment") then
            particle.Parent:Destroy()
        end
    end

    for _, pool in pairs(state.pools) do
        for _, particle in ipairs(pool.available) do
            particle:Destroy()
        end
    end

    for _, preset in pairs(state.presets) do
        preset:Destroy()
    end

    if state.folders.root then
        state.folders.root:Destroy()
    end

    table.clear(state.active)
    table.clear(state.pools)
    table.clear(state.presets)
    table.clear(state.folders)
end

--[[ Particle Functions ]]
local function GetPreset(presetName)
    if not presetName then return nil end

    local preset = state.presets[presetName]
    if preset then return preset end

    local presetData = Services.Asset:GetAsset("Particles", presetName, "ParticleEmitter")
    if not presetData or not presetData.instance then
        warn("Failed to get particle preset:", presetName)
        return nil
    end

    if not presetData.instance:IsA("ParticleEmitter") then
        warn("Asset is not a ParticleEmitter:", presetName)
        return nil
    end

    preset = presetData.instance:Clone()
    state.presets[presetName] = preset

    return preset
end

local function ReleaseParticle(particle, preset)
    if not particle then
        warn("Cannot release nil particle")
        return
    end

    if not preset then
        warn("Cannot release particle without preset name")
        return
    end

    local pool = state.pools[preset]
    if not pool then
        particle:Destroy()
        return
    end

    particle.Parent = nil

    if #pool.available < CONSTANTS.POOL_SIZE.MAX then
        particle:Clear()
        particle.Enabled = false

        if particle:FindFirstChildOfClass("Attachment") then
            particle:FindFirstChildOfClass("Attachment"):Destroy()
        end

        for name, _ in pairs(particle:GetAttributes()) do
            particle:SetAttribute(name, nil)
        end

        table.insert(pool.available, particle)
    else
        particle:Destroy()
        pool.size -= 1
    end
end

function ParticleService:CreateParticle(config)
    if not config then return nil end

    local effectType = config.effectType
    local effectConfig = nil

    if config.preset then
        if not effectType and config.effectType then
            effectType = config.effectType
        end
    end

    if effectType then
        effectType = string.upper(string.sub(effectType, 1, 1)) .. string.lower(string.sub(effectType, 2))
    end

    if effectType and Modules.Particle.Handlers.Effects[effectType] then
        local context = {
            services = Services,
            folders = state.folders,
            config = config        }

        for name, instance in pairs(ImportInstances) do
            context[name:lower()] = instance
        end

        local configObjects = Modules.Particle.Handlers.Effects[effectType](context)
        if not configObjects then
            return nil
        end

        local results = {}

        if type(configObjects) == "table" then
            for key, config in pairs(configObjects) do
                if type(config) == "table" and config.effectType then
                    results[key] = self:CreateParticle(config)
                else
                    results[key] = config
                end
            end
        else
            results = configObjects
        end

        return results
    end

    if (effectType and effectType == "Pooled") or not effectType then
        if not config.preset or not config.parent then return nil end

        local pool = state.pools[config.preset]
        if not pool then
            pool = {
                available = table.create(CONSTANTS.POOL_SIZE.MIN),
                size = 0
            }
            state.pools[config.preset] = pool
        end

        local particle = table.remove(pool.available)
        if not particle and pool.size < CONSTANTS.POOL_SIZE.MAX then
            local preset = GetPreset(config.preset)
            if not preset then return nil end

            particle = preset:Clone()
            pool.size += 1
        end

        if not particle then return nil end

        if config.position then
            local attachment = Instance.new("Attachment")
            attachment.Position = config.position
            attachment.Parent = config.parent
            particle.Parent = attachment
        else
            particle.Parent = config.parent
        end

        state.active[particle] = {
            preset = config.preset,
            startTime = os.clock()
        }

        local duration = config.duration or CONSTANTS.LIFETIME
        task.delay(duration, function()
            if not particle.Parent then return end

            particle.Enabled = false
            task.wait(particle.Lifetime.Max)

            local data = state.active[particle]
            if data then
                state.active[particle] = nil
                ReleaseParticle(particle, data.preset)
                if particle.Parent:IsA("Attachment") then
                    particle.Parent:Destroy()
                end
            end

            Services.Event:Fire("Particle.Stop", config.preset)
        end)

        Services.Event:Fire("Particle.Play", config.preset)
        return particle
    end

    return nil
end

function ParticleService:PlayParticle(effectCategory, effectName, ...)
    if not effectCategory or not effectName then
        warn("Cannot play particle effect: missing category or name")
        return nil
    end

    local effectsCategory = Modules.Particle.Effects[effectCategory]
    if not effectsCategory then
        warn("Effect category not found:", effectCategory)
        return nil
    end

    local effectFunction = effectsCategory[effectName]
    if not effectFunction or type(effectFunction) ~= "function" then
        warn("Effect not found or not a function:", effectName)
        return nil
    end

    local context = {
        services = Services,
        folders = state.folders,
        config = nil
    }

    for name, instance in pairs(ImportInstances) do
        context[name:lower()] = instance
    end

    local configObjects = effectFunction(context, ...)
    if not configObjects then
        return nil
    end

    local results = {}

    if type(configObjects) == "table" then
        for key, config in pairs(configObjects) do
            if type(config) == "table" and config.effectType then
                results[key] = self:CreateParticle(config)
            else
                results[key] = config
            end
        end
    else
        results = configObjects
    end

    return results
end

function ParticleService:StopParticle(particle, instant)
    if not particle then return end

    if particle:IsA("ParticleEmitter") then
        local data = state.active[particle]
        if not data then return end

        if instant then
            state.active[particle] = nil
            ReleaseParticle(particle, data.preset)
            if particle.Parent:IsA("Attachment") then
                particle.Parent:Destroy()
            end
        else
            particle.Enabled = false
            task.delay(particle.Lifetime.Max, function()
                if not state.active[particle] then return end

                state.active[particle] = nil
                ReleaseParticle(particle, data.preset)
                if particle.Parent:IsA("Attachment") then
                    particle.Parent:Destroy()
                end
            end)
        end

        Services.Event:Fire("Particle.Stop", data.preset)
    elseif particle:IsA("Sound") then
        if instant then
            particle:Stop()
            particle:Destroy()
        else
            particle:Stop()
            Debris:AddItem(particle, 1)
        end
    elseif particle:IsA("Light") or particle:IsA("PointLight") then
        if instant then
            if particle.Parent then
                particle.Parent:Destroy()
            else
                particle:Destroy()
            end
        else
            Debris:AddItem(particle.Parent or particle, 1)
        end
    elseif particle:IsA("Attachment") then
        if instant then
            particle:Destroy()
        else
            for _, child in ipairs(particle:GetChildren()) do
                if child:IsA("ParticleEmitter") then
                    child.Enabled = false
                end
            end
            Debris:AddItem(particle, 1)
        end
    end
end

return ParticleService