local Animation = {}

local TweenService = game:GetService("TweenService")

export type AnimationConfig = {
    duration: number?,
    delay: number?,
    reverses: boolean?,
    repeatCount: number?,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?,
    onStep: ((progress: number) -> ())?,
    onComplete: (() -> ())?
}

-- Duration
Animation.Duration = {
    Shortest = 0.15,
    Short = 0.2,
    Medium = 0.3,
    Long = 0.5,
    Longest = 0.8
}

-- Easing
Animation.Easing = {
    -- Basic
    Linear = Enum.EasingStyle.Linear,
    Quad = Enum.EasingStyle.Quad,
    Cubic = Enum.EasingStyle.Cubic,
    Quart = Enum.EasingStyle.Quart,
    Quint = Enum.EasingStyle.Quint,

    -- Special
    Back = Enum.EasingStyle.Back,
    Bounce = Enum.EasingStyle.Bounce,
    Elastic = Enum.EasingStyle.Elastic,

    -- Directions
    In = Enum.EasingDirection.In,
    Out = Enum.EasingDirection.Out,
    InOut = Enum.EasingDirection.InOut
}

local function createTweenInfo(config: AnimationConfig): TweenInfo
    return TweenInfo.new(
        config.duration or Animation.Duration.Medium,
        config.easingStyle or Animation.Easing.Quad,
        config.easingDirection or Animation.Easing.Out,
        config.repeatCount or 0,
        config.reverses or false,
        config.delay or 0
    )
end

-- Presets
Animation.Presets = {
    -- Common Durations
    Short = TweenInfo.new(Animation.Duration.Short),
    Medium = TweenInfo.new(Animation.Duration.Medium),
    Long = TweenInfo.new(Animation.Duration.Long),

    -- Common Easing
    Linear = TweenInfo.new(Animation.Duration.Medium, Animation.Easing.Linear),
    Smooth = TweenInfo.new(Animation.Duration.Medium, Animation.Easing.Quad),
    Spring = TweenInfo.new(Animation.Duration.Long, Animation.Easing.Back),
    Elastic = TweenInfo.new(Animation.Duration.Long, Animation.Easing.Elastic),

    -- Fade Animations
    FadeIn = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            BackgroundTransparency = 0,
            TextTransparency = 0,
            ImageTransparency = 0
        }
    },
    FadeOut = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            BackgroundTransparency = 1,
            TextTransparency = 1,
            ImageTransparency = 1
        }
    },

    -- Scale Animations
    ScaleIn = {
        duration = Animation.Duration.Medium,
        easingStyle = Animation.Easing.Back,
        properties = {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    ScaleOut = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },

    -- Slide Animations
    SlideInFromTop = {
        duration = Animation.Duration.Medium,
        easingStyle = Animation.Easing.Back,
        startProperties = {
            Position = UDim2.new(0.5, 0, -0.5, 0)
        },
        properties = {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    SlideOutToTop = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            Position = UDim2.new(0.5, 0, -0.5, 0)
        }
    },
    SlideInFromBottom = {
        duration = Animation.Duration.Medium,
        easingStyle = Animation.Easing.Back,
        startProperties = {
            Position = UDim2.new(0.5, 0, 1.5, 0)
        },
        properties = {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    SlideOutToBottom = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            Position = UDim2.new(0.5, 0, 1.5, 0)
        }
    },

    -- Special Effects
    Bounce = {
        duration = Animation.Duration.Long,
        easingStyle = Animation.Easing.Bounce,
        properties = {
            Size = UDim2.new(1, 0, 1, 0)
        }
    },
    Shake = {
        duration = Animation.Duration.Medium,
        easingStyle = Animation.Easing.Linear,
        repeatCount = 2,
        reverses = true,
        properties = {
            Position = UDim2.new(0.51, 0, 0.5, 0)
        }
    },
    Pulse = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Linear,
        repeatCount = 1,
        reverses = true,
        properties = {
            Size = UDim2.new(1.1, 0, 1.1, 0)
        }
    },

    -- Progress Bar Animations
    ProgressFill = {
        duration = Animation.Duration.Medium,
        easingStyle = Animation.Easing.Quad,
        properties = {
            Size = UDim2.new(1, 0, 1, 0)
        }
    },
    ProgressEmpty = {
        duration = Animation.Duration.Short,
        easingStyle = Animation.Easing.Quad,
        properties = {
            Size = UDim2.new(0, 0, 1, 0)
        }
    },
    ProgressIndeterminate = {
        duration = Animation.Duration.Long,
        easingStyle = Animation.Easing.Linear,
        repeatCount = -1,
        properties = {
            Position = UDim2.new(1, 0, 0, 0)
        }
    }
}

local ActiveTweens = {}

function Animation.Stop(instance: Instance)
    if not instance then return end
    if ActiveTweens[instance] then
        for _, tween in pairs(ActiveTweens[instance]) do
            tween:Cancel()
        end
        ActiveTweens[instance] = nil
    end
end

function Animation.Tween(instance: Instance, properties: {[string]: any}, config: AnimationConfig?)
    if not instance then return end

    local tweenInfo = createTweenInfo(config or {})
    local tween = TweenService:Create(instance, tweenInfo, properties)

    ActiveTweens[instance] = ActiveTweens[instance] or {}
    table.insert(ActiveTweens[instance], tween)

    tween.Completed:Connect(function()
        if ActiveTweens[instance] then
            for i, t in pairs(ActiveTweens[instance]) do
                if t == tween then
                    table.remove(ActiveTweens[instance], i)
                    break
                end
            end
            if #ActiveTweens[instance] == 0 then
                ActiveTweens[instance] = nil
            end
        end
    end)

    tween:Play()
    return tween
end

function Animation.Sequence(animations: {{instance: Instance, properties: {[string]: any}, config: AnimationConfig?}})
    local sequence = {}
    local currentDelay = 0

    for _, animation in ipairs(animations) do
        local config = animation.config or {}
        config.delay = (config.delay or 0) + currentDelay

        local tween = Animation.Tween(animation.instance, animation.properties, config)
        table.insert(sequence, tween)

        currentDelay += (config.duration or 0.3) + (config.delay or 0)
    end

    return sequence
end

-- Preset
function Animation.PlayPreset(instance: Instance, presetName: string)
    local preset = Animation.Presets[presetName]
    if not preset then return end

    if preset.startProperties then
        for property, value in pairs(preset.startProperties) do
            instance[property] = value
        end
        task.wait()
    end

    return Animation.Tween(instance, preset.properties, {
        duration = preset.duration,
        easingStyle = preset.easingStyle,
        easingDirection = preset.easingDirection,
        repeatCount = preset.repeatCount,
        reverses = preset.reverses
    })
end

-- Utility
function Animation.To(instance: Instance, properties: {[string]: any}, config: AnimationConfig)
    local tweenInfo = createTweenInfo(config)
    local tween = TweenService:Create(instance, tweenInfo, properties)

    if config.onComplete then
        tween.Completed:Once(config.onComplete)
    end

    tween:Play()
    return tween
end

function Animation.Chain(tweens: {Tween})
    local currentTween = tweens[1]
    if not currentTween then return end

    for i = 1, #tweens - 1 do
        local nextTween = tweens[i + 1]
        if nextTween then
            currentTween.Completed:Once(function()
                nextTween:Play()
            end)
            currentTween = nextTween
        end
    end

    tweens[1]:Play()
    return tweens
end

function Animation.Group(tweens: {Tween})
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    return tweens
end

function Animation.Reset(instance: Instance, properties: {string})
    for _, property in ipairs(properties) do
        instance[property] = instance:GetAttribute("Original" .. property) or instance[property]
    end
end

function Animation.SaveState(instance: Instance, properties: {string})
    for _, property in ipairs(properties) do
        instance:SetAttribute("Original" .. property, instance[property])
    end
end

function Animation.Progress(progressBar: Frame, progress: number, config: AnimationConfig?)
    if not progressBar then return end

    local fillBar = progressBar:FindFirstChild("Fill")
    if not fillBar then return end

    local targetSize = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
    local tweenConfig = config or {}
    tweenConfig.duration = tweenConfig.duration or Animation.Duration.Medium
    tweenConfig.easingStyle = tweenConfig.easingStyle or Animation.Easing.Quad

    local tween = Animation.Tween(fillBar, {Size = targetSize}, tweenConfig)

    if tweenConfig.onStep then
        local connection
        connection = tween.TweenInfo.Changed:Connect(function()
            local currentProgress = fillBar.Size.X.Scale
            tweenConfig.onStep(currentProgress)

            if currentProgress >= progress then
                connection:Disconnect()
                if tweenConfig.onComplete then
                    tweenConfig.onComplete()
                end
            end
        end)
    end

    return tween
end

return Animation