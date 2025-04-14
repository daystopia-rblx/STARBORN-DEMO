--[[ Animation
    @author @Daystopia / @NantesF
    @version 1.0.2
    @date 2025-04-14
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = {
    Animation = require(ReplicatedStorage.Modules.AnimationModule)
}

local Animation = {}

function Animation:Play(Id: number, Humanoid: Humanoid, Speed: number, Priority: Enum.AnimationPriority, Name: string, ...)
	local Animation = Instance.new("Animation")
	Animation.AnimationId = Id
	local animator = Humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = Humanoid
	end
	local KeyframeCallback = nil
	local success, AnimTrack = pcall(function()
		return animator:LoadAnimation(Animation)
	end)

	local args = {...}
	for i = 1, #args do
		local arg = args[i]
		if type(arg) == "function" and not KeyframeCallback then
			KeyframeCallback = arg
		end
	end

	if not success then
		warn("Failed to load animation:", AnimTrack)
		return nil
	end

	AnimTrack.Priority = Priority or Enum.AnimationPriority.Action
	AnimTrack.Name = Name or "Animation"

	if KeyframeCallback then
		AnimTrack.KeyframeReached:Connect(function(keyframeName)
			KeyframeCallback(keyframeName)
		end)
	end

	AnimTrack:Play()

	if Speed then
		AnimTrack:AdjustSpeed(Speed or 1)
	end

	return AnimTrack
end

function Animation:Stop(Humanoid: Humanoid, Name: string)
	local animator = Humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, anim in pairs(animator:GetPlayingAnimationTracks()) do
			if anim.Name == Name then
				anim:Stop()
				break
			end
		end
	end
end

--[[function Animation.Animation(animator: Animator, animationData: {id: string, looped: boolean, priority: Enum.AnimationPriority})
    if not animationData or not animationData.id or animationData.id == "" then return nil end

    local animation = Instance.new("Animation")
    animation.AnimationId = animationData.id
    local track = animator:LoadAnimation(animation)
    track.Priority = animationData.priority
    track.Looped = animationData.looped
    return track
end

function Animation.Category(animator: Animator, categoryData: {[string]: any}, prefix: string): {[string]: AnimationTrack}
    if not categoryData then return {} end

    local animations = {}
    for name, data in pairs(categoryData) do
        local animKey = prefix .. "_" .. name
        local track = Animation.Animation(animator, data)
        if track then
            animations[animKey] = track
        end
    end
    return animations
end

function Animation.Categories(animator: Animator, categories: {string}): {[string]: AnimationTrack}
    local animations = {}
    for _, category in ipairs(categories) do
        local categoryData = Modules.Animation.Assets.Animations[category]
        if categoryData then
            local categoryAnimations = Animation.Category(animator, categoryData, category)
            for key, track in pairs(categoryAnimations) do
                animations[key] = track
            end
        else
            warn("Failed to load category:", category)
        end
    end
    return animations
end

function Animation.Play(animations: {[string]: AnimationTrack}, category: string, name: string, fadeTime: number?, speed: number?): boolean
    if not category or not name then return false end

    local animKey = category .. "_" .. name
    local track = animations[animKey]
    if track then
        track:AdjustSpeed(speed or 1)
        track:Play(fadeTime or 0.1)
        return true
    end
    return false
end

function Animation.Stop(animations: {[string]: AnimationTrack}, category: string, name: string, fadeTime: number?): boolean
    if not category or not name then return false end

    local animKey = category .. "_" .. name
    if animations[animKey] then
        animations[animKey]:Stop(fadeTime or 0.1)
        return true
    end
    return false
end

function Animation.Fade(animations: {[string]: AnimationTrack}, fromCategory: string, fromName: string, toCategory: string, toName: string, fadeTime: number?): boolean
    if not fromCategory or not fromName or not toCategory or not toName then return false end

    local fromKey = fromCategory .. "_" .. fromName
    local toKey = toCategory .. "_" .. toName

    if animations[fromKey] and animations[toKey] then
        animations[toKey]:Play(fadeTime or 0.1)
        animations[fromKey]:Stop(fadeTime or 0.1)
        return true
    end
    return false
end]]

return Animation