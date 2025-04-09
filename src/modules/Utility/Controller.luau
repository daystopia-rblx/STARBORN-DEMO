--[[ Controller
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-02
]]
local Controller = {}

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

type UpdateConfig = {
    instance: Instance,
    properties: {[string]: any},
    animateSize: boolean?,
    animatePosition: boolean?,
    pulseText: boolean?,
    pulseSize: boolean?,
    pulseColor: boolean?,
    errorState: boolean?,
    successState: boolean?,
    warningState: boolean?,
    duration: number?,
    easingStyle: Enum.EasingStyle?,
    onComplete: (() -> ())?,
    delay: number?,
    slideDirection: string?,
    fadeChildren: boolean?,
    reverses: boolean?,
    repeatCount: number?,
    bounce: boolean?,
    shake: boolean?,
    shakeIntensity: number?,
    group: {Instance}?,
    onStep: ((progress: number) -> ())?
}

-- Duration
Controller.Duration = {
    Shortest = 0.15,
    Short = 0.2,
    Medium = 0.3,
    Normal = 0.3,
    Long = 0.5,
    Longest = 0.8
}

-- Easing
Controller.Easing = {
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

local SLIDE_OFFSETS = {
    Up = UDim2.new(0, 0, -0.5, 0),
    Down = UDim2.new(0, 0, 0.5, 0),
    Left = UDim2.new(-0.5, 0, 0, 0),
    Right = UDim2.new(0.5, 0, 0, 0)
}

local function createTweenInfo(config: AnimationConfig): TweenInfo
    return TweenInfo.new(
        config.duration or Controller.Duration.Medium,
        config.easingStyle or Controller.Easing.Quad,
        config.easingDirection or Controller.Easing.Out,
        config.repeatCount or 0,
        config.reverses or false,
        config.delay or 0
    )
end

-- Presets
Controller.Presets = {
    -- Common Durations
    Short = TweenInfo.new(Controller.Duration.Short),
    Medium = TweenInfo.new(Controller.Duration.Medium),
    Long = TweenInfo.new(Controller.Duration.Long),

    -- Common Easing
    Linear = TweenInfo.new(Controller.Duration.Medium, Controller.Easing.Linear),
    Smooth = TweenInfo.new(Controller.Duration.Medium, Controller.Easing.Quad),
    Spring = TweenInfo.new(Controller.Duration.Long, Controller.Easing.Back),
    Elastic = TweenInfo.new(Controller.Duration.Long, Controller.Easing.Elastic),

    -- Fade Animations
    FadeIn = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            BackgroundTransparency = 0,
            TextTransparency = 0,
            ImageTransparency = 0
        }
    },
    FadeOut = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            BackgroundTransparency = 1,
            TextTransparency = 1,
            ImageTransparency = 1
        }
    },

    -- Scale Animations
    ScaleIn = {
        duration = Controller.Duration.Medium,
        easingStyle = Controller.Easing.Back,
        properties = {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    ScaleOut = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },

    -- Slide Animations
    SlideInFromTop = {
        duration = Controller.Duration.Medium,
        easingStyle = Controller.Easing.Back,
        startProperties = {
            Position = UDim2.new(0.5, 0, -0.5, 0)
        },
        properties = {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    SlideOutToTop = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            Position = UDim2.new(0.5, 0, -0.5, 0)
        }
    },
    SlideInFromBottom = {
        duration = Controller.Duration.Medium,
        easingStyle = Controller.Easing.Back,
        startProperties = {
            Position = UDim2.new(0.5, 0, 1.5, 0)
        },
        properties = {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    },
    SlideOutToBottom = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            Position = UDim2.new(0.5, 0, 1.5, 0)
        }
    },

    -- Special Effects
    Bounce = {
        duration = Controller.Duration.Long,
        easingStyle = Controller.Easing.Bounce,
        properties = {
            Size = UDim2.new(1, 0, 1, 0)
        }
    },
    Shake = {
        duration = Controller.Duration.Medium,
        easingStyle = Controller.Easing.Linear,
        repeatCount = 2,
        reverses = true,
        properties = {
            Position = UDim2.new(0.51, 0, 0.5, 0)
        }
    },
    Pulse = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Linear,
        repeatCount = 1,
        reverses = true,
        properties = {
            Size = UDim2.new(1.1, 0, 1.1, 0)
        }
    },

    -- Progress Bar Animations
    ProgressFill = {
        duration = Controller.Duration.Medium,
        easingStyle = Controller.Easing.Quad,
        properties = {
            Size = UDim2.new(1, 0, 1, 0)
        }
    },
    ProgressEmpty = {
        duration = Controller.Duration.Short,
        easingStyle = Controller.Easing.Quad,
        properties = {
            Size = UDim2.new(0, 0, 1, 0)
        }
    },
    ProgressIndeterminate = {
        duration = Controller.Duration.Long,
        easingStyle = Controller.Easing.Linear,
        repeatCount = -1,
        properties = {
            Position = UDim2.new(1, 0, 0, 0)
        }
    }
}

local ActiveTweens = {}

--[[ Utility Functions ]]
function Controller.Stop(instance: Instance)
    if not instance then return end
    if ActiveTweens[instance] then
        for _, tween in pairs(ActiveTweens[instance]) do
            tween:Cancel()
        end
        ActiveTweens[instance] = nil
    end
end

function Controller.Tween(instance: Instance, properties: {[string]: any}, config: AnimationConfig?)
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

function Controller.Sequence(animations: {{instance: Instance, properties: {[string]: any}, config: AnimationConfig?}})
    local sequence = {}
    local currentDelay = 0

    for _, animation in ipairs(animations) do
        local config = animation.config or {}
        config.delay = (config.delay or 0) + currentDelay

        local tween = Controller.Tween(animation.instance, animation.properties, config)
        table.insert(sequence, tween)

        currentDelay += (config.duration or 0.3) + (config.delay or 0)
    end

    return sequence
end

function Controller.PlayPreset(instance: Instance, presetName: string)
    local preset = Controller.Presets[presetName]
    if not preset then return end

    if preset.startProperties then
        for property, value in pairs(preset.startProperties) do
            instance[property] = value
        end
        task.wait()
    end

    return Controller.Tween(instance, preset.properties, {
        duration = preset.duration,
        easingStyle = preset.easingStyle,
        easingDirection = preset.easingDirection,
        repeatCount = preset.repeatCount,
        reverses = preset.reverses
    })
end

function Controller.To(instance: Instance, properties: {[string]: any}, config: AnimationConfig)
    local tweenInfo = createTweenInfo(config)
    local tween = TweenService:Create(instance, tweenInfo, properties)

    if config.onComplete then
        tween.Completed:Once(config.onComplete)
    end

    tween:Play()
    return tween
end

function Controller.Chain(tweens: {Tween})
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

function Controller.Group(tweens: {Tween})
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    return tweens
end

function Controller.Reset(instance: Instance, properties: {string})
    for _, property in ipairs(properties) do
        instance[property] = instance:GetAttribute("Original" .. property) or instance[property]
    end
end

function Controller.SaveState(instance: Instance, properties: {string})
    for _, property in ipairs(properties) do
        instance:SetAttribute("Original" .. property, instance[property])
    end
end

function Controller.Progress(progressBar: Frame, progress: number, config: AnimationConfig?)
    if not progressBar then return end

    local fillBar = progressBar:FindFirstChild("Fill")
    if not fillBar then return end

    local targetSize = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
    local tweenConfig = config or {}
    tweenConfig.duration = tweenConfig.duration or Controller.Duration.Medium
    tweenConfig.easingStyle = tweenConfig.easingStyle or Controller.Easing.Quad

    local tween = Controller.Tween(fillBar, {Size = targetSize}, tweenConfig)

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

--[[ Utility Functions from Controller ]]
local function getState(config)
    if config.errorState then
        return Color3.new(1, 0, 0), Color3.new(1, 0, 0)
    elseif config.successState then
        return Color3.new(0, 1, 0), Color3.new(0, 1, 0)
    elseif config.warningState then
        return Color3.new(1, 1, 0), Color3.new(1, 1, 0)
    end
    return nil, nil
end

local function createPulse(instance, startValue, endValue, duration, easingStyle)
    return Controller.Chain({
        Controller.To(instance, startValue, {
            duration = duration * 0.5,
            easingStyle = easingStyle or Controller.Easing.Back
        }),
        Controller.To(instance, endValue, {
            duration = duration * 0.5,
            easingStyle = easingStyle or Controller.Easing.Back
        })
    })
end

--[[ Core Functions ]]
function Controller.Update(config: UpdateConfig)
    if not config.instance then return end

    local properties = config.properties or {}
    local duration = config.duration or Controller.Duration.Short
    local easingStyle = config.easingStyle or Controller.Easing.Quad
    local tweens = {}

    if config.instance:IsA("UIStroke") then
        local strokeProperties = {
            Transparency = properties.Transparency,
            Color = properties.Color,
            Thickness = properties.Thickness
        }

        local mainTween = Controller.To(config.instance, strokeProperties, {
            duration = duration,
            easingStyle = easingStyle,
            delay = config.delay,
            reverses = config.reverses,
            repeatCount = config.repeatCount
        })
        table.insert(tweens, mainTween)

        if config.onComplete then
            mainTween.Completed:Once(config.onComplete)
        end

        return tweens
    end

    local originalSize = config.pulseSize and config.instance.Size
    local originalTextSize = (config.pulseText and (config.instance:IsA("TextLabel") or config.instance:IsA("TextButton"))) and config.instance.TextSize
    local originalColor = config.pulseColor and (
        config.instance:IsA("TextLabel") and config.instance.TextColor3 or
        config.instance:IsA("Frame") and config.instance.BackgroundColor3
    )
    local originalPosition = config.instance.Position

    local textColor, bgColor = getState(config)
    if textColor then
        properties.TextColor3 = properties.TextColor3 or textColor
        properties.BackgroundColor3 = properties.BackgroundColor3 or bgColor
    end

    if config.slideDirection and SLIDE_OFFSETS[config.slideDirection] and not config.instance:IsA("UIStroke") then
        local offset = SLIDE_OFFSETS[config.slideDirection]
        properties.Position = UDim2.new(
            originalPosition.X.Scale + offset.X.Scale,
            originalPosition.X.Offset + offset.X.Offset,
            originalPosition.Y.Scale + offset.Y.Scale,
            originalPosition.Y.Offset + offset.Y.Offset
        )
    end

    local mainTween = Controller.To(config.instance, properties, {
        duration = duration,
        easingStyle = easingStyle,
        delay = config.delay,
        reverses = config.reverses,
        repeatCount = config.repeatCount
    })
    table.insert(tweens, mainTween)

    if config.pulseSize and originalSize then
        local pulseTween = createPulse(
            config.instance,
            {Size = UDim2.new(
                originalSize.X.Scale * 1.1,
                originalSize.X.Offset * 1.1,
                originalSize.Y.Scale * 1.1,
                originalSize.Y.Offset * 1.1
            )},
            {Size = originalSize},
            duration
        )
        table.insert(tweens, pulseTween[1])
    end

    if config.pulseText and originalTextSize then
        local textTween = createPulse(
            config.instance,
            {TextSize = originalTextSize * 1.2},
            {TextSize = originalTextSize},
            duration
        )
        table.insert(tweens, textTween[1])
    end

    if config.pulseColor and originalColor then
        local colorTween = createPulse(
            config.instance,
            {TextColor3 = textColor or originalColor},
            {TextColor3 = originalColor},
            duration
        )
        table.insert(tweens, colorTween[1])
    end

    if config.shake then
        local intensity = config.shakeIntensity or 5
        local shakeSequence = table.create(6)
        for i = 1, 5 do
            shakeSequence[i] = Controller.To(config.instance, {
                Position = UDim2.new(
                    originalPosition.X.Scale,
                    originalPosition.X.Offset + (math.random() - 0.5) * intensity,
                    originalPosition.Y.Scale,
                    originalPosition.Y.Offset + (math.random() - 0.5) * intensity
                )
            }, {duration = 0.05})
        end
        shakeSequence[6] = Controller.To(config.instance, {Position = originalPosition}, {duration = 0.05})
        local shakeTween = Controller.Chain(shakeSequence)
        table.insert(tweens, shakeTween[1])
    end

    if config.bounce then
        local bounceTween = Controller.Chain({
            Controller.To(config.instance, {
                Position = UDim2.new(
                    originalPosition.X.Scale,
                    originalPosition.X.Offset,
                    originalPosition.Y.Scale + 0.1,
                    originalPosition.Y.Offset
                )
            }, {
                duration = duration * 0.3,
                easingStyle = Controller.Easing.Bounce
            }),
            Controller.To(config.instance, {Position = originalPosition}, {
                duration = duration * 0.7,
                easingStyle = Controller.Easing.Bounce
            })
        })
        table.insert(tweens, bounceTween[1])
    end

    if config.fadeChildren then
        for _, child in ipairs(config.instance:GetChildren()) do
            if child:IsA("GuiObject") then
                table.insert(tweens, Controller.To(child, {
                    BackgroundTransparency = properties.BackgroundTransparency or 1,
                    TextTransparency = properties.TextTransparency or 1
                }, {
                    duration = duration,
                    delay = config.delay,
                    easingStyle = easingStyle
                }))
            end
        end
    end

    if config.group then
        for _, groupInstance in ipairs(config.group) do
            table.insert(tweens, Controller.To(groupInstance, properties, {
                duration = duration,
                delay = config.delay,
                easingStyle = easingStyle
            }))
        end
    end

    if config.onComplete then
        mainTween.Completed:Once(config.onComplete)
    end

    return tweens
end

--[[ Fade Functions ]]
function Controller.FadeIn(instance: Instance, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 0, TextTransparency = 0},
        duration = duration or Controller.Duration.Normal,
        fadeChildren = true
    })
end

function Controller.FadeOut(instance: Instance, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 1, TextTransparency = 1},
        duration = duration or Controller.Duration.Normal,
        fadeChildren = true
    })
end

--[[ Slide Functions ]]
function Controller.SlideIn(instance: Instance, direction: string, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 0, TextTransparency = 0},
        duration = duration or Controller.Duration.Normal,
        slideDirection = direction,
        fadeChildren = true
    })
end

function Controller.SlideOut(instance: Instance, direction: string, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 1, TextTransparency = 1},
        duration = duration or Controller.Duration.Normal,
        slideDirection = direction,
        fadeChildren = true
    })
end

--[[ Progress Functions ]]
function Controller.UpdateProgress(progressBar: Frame, progress: number, config: UpdateConfig?)
    if not progressBar then return end

    local fillBar = progressBar:FindFirstChild("Fill")
    if not fillBar then return end

    local textLabel = progressBar:FindFirstChild("ProgressText")
    local config = config or {}

    local tweens = Controller.Progress(progressBar, progress, {
        duration = config.duration,
        easingStyle = config.easingStyle,
        onStep = config.onStep,
        onComplete = config.onComplete
    })

    if textLabel and textLabel:IsA("TextLabel") then
        textLabel.Text = string.format("%d%%", math.floor(progress * 100))
    end

    local textColor, bgColor = getState(config)
    if textColor then
        if textLabel then
            table.insert(tweens, Controller.To(textLabel, {TextColor3 = textColor}, {
                duration = config.duration,
                easingStyle = config.easingStyle
            }))
        end
        table.insert(tweens, Controller.To(fillBar, {BackgroundColor3 = bgColor}, {
            duration = config.duration,
            easingStyle = config.easingStyle
        }))
    end

    return tweens
end

return Controller