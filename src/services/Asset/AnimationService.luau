--[[ AnimationService
    Advanced animation system with pooling, queueing, and priority management.
    Handles animation loading, playback control, and transition effects.
    @author @Daystopia
    @version 1.0.2
    @date 2024-12-27
]]
local AnimationService = {}

--[[ Dependencies ]]
AnimationService.Dependencies = {
    "Event",
    "Asset"
}

--[[ Events ]]
AnimationService.Events = {
    Play = true,
    Stop = true,
    Queue = true,
    Cancel = true
}

--[[ Services & Modules ]]
local Services
local Modules
--[[ Constants ]]
local CONSTANTS = {
    DEFAULT_FADE_TIME = 0.1,
    DEFAULT_WEIGHT = 1,
    DEFAULT_SPEED = 1,
    POOL_SIZE = {
        MIN = 5,
        MAX = 20
    },
    PRIORITY = {
        LOW = 1,
        MEDIUM = 2,
        HIGH = 3,
        CUTSCENE = 4
    }
}

--[[ Types ]]
type AnimationData = {
    track: AnimationTrack,
    priority: number
}

type QueuedAnimation = {
    category: string,
    name: string,
    options: {[string]: any}
}

type AnimationConfig = {
    preset: string,
    looped: boolean?,
    priority: Enum.AnimationPriority?,
    fadeTime: number?,
    weight: number?,
    speed: number?
}

--[[ State ]]
local state = {
    pools = {},
    playing = {},
    queues = {}
}

--[[ Core Functions ]]
function AnimationService:Init(services)
    Services = services
    return true
end

function AnimationService:Cleanup()
    for _, animations in pairs(state.playing) do
        for i = 1, #animations do
            animations[i].track:Stop()
        end
    end
    table.clear(state.pools)
    table.clear(state.playing)
    table.clear(state.queues)
end

-- [[ Animation Functions ]]
function AnimationService:GetAnimator(model)
    local humanoid = model:FindFirstChild("Humanoid")
    return humanoid and humanoid:FindFirstChild("Animator") or model:FindFirstChild("Animator")
end

local function GetAnimation(animator, config)
    local category = config.category or "Animations"
    local pool = state.pools[category]

    print("Requesting animation for category:", category, "and preset:", config.preset)
    if not pool then
        print("No pool found for category:", category)
        return nil
    end

    if not pool then
        pool = {
            available = table.create(CONSTANTS.POOL_SIZE.MIN),
            size = 0
        }
        state.pools[category] = pool
    end

    if pool.size < CONSTANTS.POOL_SIZE.MAX then
        local presetData = Services.Asset:GetAsset("Animations", config.preset, "Animation")
        if not presetData then
            warn("No preset data found for:", config.preset)
            return nil
        end

        local animation = animator:LoadAnimation(presetData.instance)
        if not animation then
            warn("Failed to load animation for preset:", config.preset)
            return nil
        end

        pool.size += 1
        animation.Looped = config.looped or false
        animation.Priority = config.priority or Enum.AnimationPriority.Core
        animation:Stop()
        animation.TimePosition = 0
        return animation
    end

    local animation = table.remove(pool.available)
    if not animation then
        warn("No available animation found in pool for category:", category)
        return nil
    end

    animation:Stop()
    animation.TimePosition = 0

    if config.preset then
        local presetData = Services.Asset:GetAsset("Animations", config.preset, "Animation")
        if presetData then
            animation.AnimationId = presetData.instance.AnimationId
        end
    end

    animation.Looped = config.looped or false
    animation.Priority = config.priority or Enum.AnimationPriority.Core

    return animation
end

local function ReleaseAnimation(animation, category)
    local pool = state.pools[category]
    if not pool then return end

    if animation.IsPlaying then
        animation:Stop()
    end

    if #pool.available < CONSTANTS.POOL_SIZE.MAX then
        animation.TimePosition = 0
        animation.Looped = false
        animation.Priority = Enum.AnimationPriority.Core
        table.insert(pool.available, animation)
    else
        animation:Destroy()
        pool.size -= 1
    end
end

function AnimationService:PlayAnimation(model, config)
    if not model then
        warn("No model provided")
        return
    end

    local animator = self:GetAnimator(model)
    if not animator then
        warn("No animator found for model", model:GetFullName())
        return
    end

    local animation = GetAnimation(animator, config)
    if not animation then
        warn("No animation found for config", config)
        return
    end

    animation:Play(
        config.fadeTime or CONSTANTS.DEFAULT_FADE_TIME,
        config.weight or CONSTANTS.DEFAULT_WEIGHT,
        config.speed or CONSTANTS.DEFAULT_SPEED
    )

    local modelPlaying = state.playing[model]
    if not modelPlaying then
        modelPlaying = {}
        state.playing[model] = modelPlaying
    end

    table.insert(modelPlaying, {
        track = animation,
        priority = animation.Priority.Value
    })

    Services.Event:Fire("Animation.Play", model:GetFullName(), config.preset)
    return animation
end

function AnimationService:StopAnimation(model, preset)
    local animator = self:GetAnimator(model)
    if not animator then return end

    local tracks = animator:GetPlayingAnimationTracks()
    for i = 1, #tracks do
        if tracks[i].Name == preset then
            tracks[i]:Stop(0.3)
            break
        end
    end

    local modelPlaying = state.playing[model]
    if modelPlaying then
        for i = #modelPlaying, 1, -1 do
            if modelPlaying[i].track.Name == preset then
                table.remove(modelPlaying, i)
                break
            end
        end
    end

    Services.Event:Fire("Animation.Stop", model:GetFullName(), preset)
end

function AnimationService:QueueAnimation(model, config)
    config.priority = config.priority or CONSTANTS.PRIORITY.LOW

    local modelQueue = state.queues[model]
    if not modelQueue then
        modelQueue = {}
        state.queues[model] = modelQueue
    end

    table.insert(modelQueue, {
        preset = config.preset,
        options = config
    })

    Services.Event:Fire("Animation.Queue", model:GetFullName(), config.preset)

    if #modelQueue == 1 then
        self:ProcessQueue(model)
    end
end

function AnimationService:ProcessQueue(model)
    local modelQueue = state.queues[model]
    if not modelQueue or #modelQueue == 0 then return end

    local nextAnim = modelQueue[1]
    local currentlyPlaying = state.playing[model]

    if not currentlyPlaying or nextAnim.options.priority >= (currentlyPlaying[1] and currentlyPlaying[1].priority or 0) then
        table.remove(modelQueue, 1)
        self:PlayAnimation(model, nextAnim.options)
    end
end

function AnimationService:CancelAnimation(model, priority)
    priority = priority or CONSTANTS.PRIORITY.HIGH

    local modelQueue = state.queues[model]
    if modelQueue then
        for i = #modelQueue, 1, -1 do
            if (modelQueue[i].options.priority or 0) <= priority then
                table.remove(modelQueue, i)
            end
        end
    end

    local modelPlaying = state.playing[model]
    if modelPlaying then
        for i = #modelPlaying, 1, -1 do
            local track = modelPlaying[i]
            local trackPriority = track.priority or 0
            if trackPriority <= priority then
                pcall(function()
                    track.track:Stop()
                    track.track:Destroy()
                end)
                table.remove(modelPlaying, i)
            end
        end
    end

    Services.Event:Fire("Animation.Cancel", model:GetFullName(), priority)
end

return AnimationService