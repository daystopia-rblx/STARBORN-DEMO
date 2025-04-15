local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")

local success, AnimationModule
repeat
	success, AnimationModule = pcall(function()
		return require(game:GetService("ReplicatedStorage").Modules:WaitForChild("AnimationModule"))
	end)
	if not success then
		task.wait(0.1)
	end
until success

print("Animation Module found, beginning preload...")

local function collectAnimationIds(tbl)
	local ids = {}

	for _, value in pairs(tbl) do
		if type(value) == "table" then
			if value.id and type(value.id) == "string" and value.id ~= "" then
				table.insert(ids, value.id)
			else
				local subIds = collectAnimationIds(value)
				for _, id in ipairs(subIds) do
					table.insert(ids, id)
				end
			end
		end
	end

	return ids
end

local animationIds = collectAnimationIds(AnimationModule.Assets.Animations)

local assetsToPreload = {}
for _, id in ipairs(animationIds) do
	local assetId = id:match("(%d+)")
	if assetId then
		table.insert(assetsToPreload, "rbxassetid://" .. assetId)
	end
end

print("Preloading " .. #assetsToPreload .. " animations...")

local animObjects = {}
for _, assetId in ipairs(assetsToPreload) do
	local anim = Instance.new("Animation")
	anim.AnimationId = assetId
	table.insert(animObjects, anim)
end

ContentProvider:PreloadAsync(animObjects)

for _, anim in ipairs(animObjects) do
	anim:Destroy()
end

print("Animation preloading complete.")