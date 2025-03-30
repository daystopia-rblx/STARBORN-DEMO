--[[ ParticleService
    Dynamic particle effect system with pooling and performance optimization.
    Handles effect creation, lifecycle management, and automatic cleanup of particle emitters.
    @author @Daystopia
    @version 1.0.1
    @date 2024-12-26
]]
local ParticleService = {}

--[[ Dependencies ]]
ParticleService.Dependencies = {
    "Event",
    "Asset"
}

--[[ Events ]]
ParticleService.Events = {
    Play = true,
    Stop = true
}

--[[ Services & Modules ]]
local Services

--[[ Constants ]]
local CONSTANTS = {
    DEFAULT_LIFETIME = 5,
    POOL_SIZE = {
        MIN = 10,
        MAX = 50
    },
    CATEGORIES = {
        ENVIRONMENT = "Environment",
        COMBAT = "Combat",
        MOVEMENT = "Movement",
        MAGIC = "Magic"
    }
}

--[[ Types ]]
type ParticleConfig = {
    preset: string,
    duration: number?,
    position: Vector3?,
    color: ColorSequence?,
    size: NumberSequence?,
    speed: NumberRange?,
    emission: NumberRange?,
    category: string?
}

--[[ State ]]
local state = {
    active = {},
    pools = {},
    presets = {}
}

--[[ Core Functions ]]
function ParticleService:Init(services)
    Services = services
    return true
end

function ParticleService:Cleanup()
    for particle in pairs(state.active) do
        particle:Destroy()
        if particle.Parent:IsA("Attachment") then
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

    table.clear(state.active)
    table.clear(state.pools)
    table.clear(state.presets)
end

--[[ Particle Functions ]]
local function CreateParticle(config)
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
        local preset = state.presets[config.preset]
        if not preset then
            local presetData = Services.Asset:GetAsset("Particles", config.preset, "ParticleEmitter")
            if not presetData then return nil end
            preset = presetData.instance:Clone()
            state.presets[config.preset] = preset
        end

        particle = preset:Clone()
        pool.size += 1
    end

    if not particle then return nil end

    if config.color then particle.Color = config.color end
    if config.size then particle.Size = config.size end
    if config.speed then particle.Speed = config.speed end
    if config.emission then particle.Rate = config.emission end

    return particle
end

local function ReleaseParticle(particle, preset)
    local pool = state.pools[preset]
    if not pool then return end

    particle.Parent = nil
    if #pool.available < CONSTANTS.POOL_SIZE.MAX then
        particle:Clear()
        table.insert(pool.available, particle)
    else
        particle:Destroy()
        pool.size -= 1
    end
end

function ParticleService:CreateEffect(parent, config)
    if not parent or not config.preset then return end

    local particle = CreateParticle(config)
    if not particle then return end

    if config.position then
        local attachment = Instance.new("Attachment")
        attachment.Position = config.position
        attachment.Parent = parent
        particle.Parent = attachment
    else
        particle.Parent = parent
    end

    state.active[particle] = {
        preset = config.preset,
        startTime = os.clock()
    }

    local duration = config.duration or CONSTANTS.DEFAULT_LIFETIME
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

function ParticleService:StopEffect(particle, instant)
    if not particle then return end

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
end

function ParticleService:StopCategory(category, instant)
    for particle, data in pairs(state.active) do
        local preset = state.presets[data.preset]
        if preset and preset:GetAttribute("Category") == category then
            self:StopEffect(particle, instant)
        end
    end
end

return ParticleService