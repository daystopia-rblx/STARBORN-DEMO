--[[ Animation
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-02
]]
local Animation = {}

function Animation.Animation(animator: Animator, animationData: {id: string, looped: boolean, priority: Enum.AnimationPriority})
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
        animations[animKey] = Animation.Animation(animator, data)
    end
    return animations
end

function Animation.Categories(animator: Animator, categories: {string}, animationData: {[string]: {[string]: any}}): {[string]: AnimationTrack}
    local animations = {}
    for _, category in ipairs(categories) do
        local categoryData = animationData[category]
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

function Animation.Play(animations: {[string]: AnimationTrack}, category: string, name: string, animationData: {[string]: {[string]: any}}): boolean
    if not category or not name then
        warn("Both category and name must be provided")
        return false
    end

    if not animationData[category] then
        warn("Invalid category:", category)
        return false
    end

    local animKey = category .. "_" .. name
    if animations[animKey] then
        animations[animKey]:Play()
        return true
    else
        warn("Attempted to play non-existent animation:", animKey)
        return false
    end
end

function Animation.Stop(animations: {[string]: AnimationTrack}, category: string, name: string, animationData: {[string]: {[string]: any}}): boolean
    if not category or not name then
        warn("Both category and name must be provided")
        return false
    end

    if not animationData[category] then
        warn("Invalid category:", category)
        return false
    end

    local animKey = category .. "_" .. name
    if animations[animKey] then
        animations[animKey]:Stop()
        return true
    end
    return false
end

return Animation