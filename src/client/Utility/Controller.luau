local Controller = {}

local Animation = require(script.Parent.Animation)

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

local SLIDE_OFFSETS = {
    Up = UDim2.new(0, 0, -0.5, 0),
    Down = UDim2.new(0, 0, 0.5, 0),
    Left = UDim2.new(-0.5, 0, 0, 0),
    Right = UDim2.new(0.5, 0, 0, 0)
}

--[[ Utility Functions ]]
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
    return Animation.Chain({
        Animation.To(instance, startValue, {
            duration = duration * 0.5,
            easingStyle = easingStyle or Animation.Easing.Back
        }),
        Animation.To(instance, endValue, {
            duration = duration * 0.5,
            easingStyle = easingStyle or Animation.Easing.Back
        })
    })
end

--[[ Core Functions ]]
function Controller.Update(config: UpdateConfig)
    if not config.instance then return end

    local properties = config.properties or {}
    local duration = config.duration or Animation.Duration.Short
    local easingStyle = config.easingStyle or Animation.Easing.Quad
    local tweens = {}

    if config.instance:IsA("UIStroke") then
        local strokeProperties = {
            Transparency = properties.Transparency,
            Color = properties.Color,
            Thickness = properties.Thickness
        }

        local mainTween = Animation.To(config.instance, strokeProperties, {
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

    local mainTween = Animation.To(config.instance, properties, {
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
            shakeSequence[i] = Animation.To(config.instance, {
                Position = UDim2.new(
                    originalPosition.X.Scale,
                    originalPosition.X.Offset + (math.random() - 0.5) * intensity,
                    originalPosition.Y.Scale,
                    originalPosition.Y.Offset + (math.random() - 0.5) * intensity
                )
            }, {duration = 0.05})
        end
        shakeSequence[6] = Animation.To(config.instance, {Position = originalPosition}, {duration = 0.05})
        local shakeTween = Animation.Chain(shakeSequence)
        table.insert(tweens, shakeTween[1])
    end

    if config.bounce then
        local bounceTween = Animation.Chain({
            Animation.To(config.instance, {
                Position = UDim2.new(
                    originalPosition.X.Scale,
                    originalPosition.X.Offset,
                    originalPosition.Y.Scale + 0.1,
                    originalPosition.Y.Offset
                )
            }, {
                duration = duration * 0.3,
                easingStyle = Animation.Easing.Bounce
            }),
            Animation.To(config.instance, {Position = originalPosition}, {
                duration = duration * 0.7,
                easingStyle = Animation.Easing.Bounce
            })
        })
        table.insert(tweens, bounceTween[1])
    end

    if config.fadeChildren then
        for _, child in ipairs(config.instance:GetChildren()) do
            if child:IsA("GuiObject") then
                table.insert(tweens, Animation.To(child, {
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
            table.insert(tweens, Animation.To(groupInstance, properties, {
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
        duration = duration or Animation.Duration.Normal,
        fadeChildren = true
    })
end

function Controller.FadeOut(instance: Instance, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 1, TextTransparency = 1},
        duration = duration or Animation.Duration.Normal,
        fadeChildren = true
    })
end

--[[ Slide Functions ]]
function Controller.SlideIn(instance: Instance, direction: string, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 0, TextTransparency = 0},
        duration = duration or Animation.Duration.Normal,
        slideDirection = direction,
        fadeChildren = true
    })
end

function Controller.SlideOut(instance: Instance, direction: string, duration: number?)
    return Controller.Update({
        instance = instance,
        properties = {BackgroundTransparency = 1, TextTransparency = 1},
        duration = duration or Animation.Duration.Normal,
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

    local tweens = Animation.Progress(progressBar, progress, {
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
            table.insert(tweens, Animation.To(textLabel, {TextColor3 = textColor}, {
                duration = config.duration,
                easingStyle = config.easingStyle
            }))
        end
        table.insert(tweens, Animation.To(fillBar, {BackgroundColor3 = bgColor}, {
            duration = config.duration,
            easingStyle = config.easingStyle
        }))
    end

    return tweens
end

return Controller