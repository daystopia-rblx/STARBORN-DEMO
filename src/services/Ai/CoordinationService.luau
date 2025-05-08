local CoordinationService = {}
CoordinationService.__index = CoordinationService

function CoordinationService.new()
	local self = setmetatable({}, CoordinationService)
	self.engagements = {}
	self.WaitRadius = 8
	self.RotationTime = math.random(1, 10)
	return self
end

local function getTargetId(target)
	if target and target:IsA("Model") then
		local player = game.Players:GetPlayerFromCharacter(target)
		if player then
			return tostring(player.UserId)
		else
			return target:GetFullName()
		end
	end
	return nil
end

local function canCalculatePosition(target)
	return target and target:IsA("Model") and target:FindFirstChild("HumanoidRootPart")
end

function CoordinationService:RegisterEngagement(aiInstance, target)
	local targetId = getTargetId(target)
	if not targetId then 
		warn("RegisterEngagement: Invalid target")
		return 
	end

	if not self.engagements[targetId] then
		self.engagements[targetId] = {
			activeAi = nil,
			queue = {},
			lastSwitchTime = 0,
			positions = {}
		}
	end

	local engagement = self.engagements[targetId]
	for _, ai in ipairs(engagement.queue) do
		if ai == aiInstance then return end
	end

	table.insert(engagement.queue, aiInstance)
	if not engagement.activeAi then
		engagement.activeAi = aiInstance
	end

	self:RecalculatePositions(targetId)
end

function CoordinationService:RecalculatePositions(targetId)
	local engagement = self.engagements[targetId]
	if not engagement then return end

	engagement.positions = {}
	local numAIs = #engagement.queue
	for i, ai in ipairs(engagement.queue) do
		local angle = (i * (2 * math.pi / numAIs)) + math.rad(180)
		local position = {
			angle = angle,
			radius = self.WaitRadius + (i % 2) * 5
		}
		engagement.positions[ai] = position
	end
end

function CoordinationService:GetWaitPosition(aiInstance, target)
	if not canCalculatePosition(target) then 
		warn("GetWaitPosition: Cannot calculate position - missing character or HumanoidRootPart")
		return nil 
	end

	local targetId = getTargetId(target)
	local engagement = self.engagements[targetId]
	if not engagement or not engagement.positions[aiInstance] then
		warn("GetWaitPosition: No engagement found for target")
		return nil
	end

	local pos = engagement.positions[aiInstance]
	local targetPos = target.HumanoidRootPart.Position

	local offset = Vector3.new(
		math.cos(pos.angle) * pos.radius + (math.random() - 0.5) * 2,
		0,
		math.sin(pos.angle) * pos.radius + (math.random() - 0.5) * 2
	)
	return targetPos + offset
end

function CoordinationService:ShouldEngage(aiInstance, target)
	local targetId = getTargetId(target)
	if not targetId then
		return false
	end

	local engagement = self.engagements[targetId]
	if not engagement then return true end

	if #engagement.queue <= 1 then
		return true
	end

	local currentTime = tick()
	if currentTime - engagement.lastSwitchTime > self.RotationTime and 
		currentTime - (aiInstance.lastEngagementCheck or 0) > 2 then

		self:RotateActiveAI(targetId)
		engagement.lastSwitchTime = currentTime
		aiInstance.lastEngagementCheck = currentTime
	end

	return engagement.activeAi == aiInstance
end

function CoordinationService:RotateActiveAI(targetId)
	local engagement = self.engagements[targetId]
	if not engagement or #engagement.queue <= 1 then return end

	for i, ai in ipairs(engagement.queue) do
		if ai == engagement.activeAi then
			engagement.activeAi = engagement.queue[i % #engagement.queue + 1]
			break
		end
	end
end

function CoordinationService:RemoveFromEngagement(aiInstance, target)
	local targetId = getTargetId(target)
	if not targetId then
		warn("RemoveFromEngagement: Invalid target")
		return
	end

	local engagement = self.engagements[targetId]
	if not engagement then return end

	for i, ai in ipairs(engagement.queue) do
		if ai == aiInstance then
			table.remove(engagement.queue, i)
			break
		end
	end

	if engagement.activeAi == aiInstance then
		if #engagement.queue > 0 then
			engagement.activeAi = engagement.queue[1]
		else
			self.engagements[targetId] = nil
		end
	end
end

function CoordinationService:RemoveFromAllEngagements(aiInstance)
	for targetId, engagement in pairs(self.engagements) do
		for i, ai in ipairs(engagement.queue) do
			if ai == aiInstance then
				table.remove(engagement.queue, i)
				if engagement.activeAi == aiInstance then
					if #engagement.queue > 0 then
						engagement.activeAi = engagement.queue[1]
					else
						self.engagements[targetId] = nil
					end
				end
				break
			end
		end
	end
end

function CoordinationService:GetEngagementStatus(target)
	local targetId = getTargetId(target)
	if not targetId then return nil end

	local engagement = self.engagements[targetId]
	if not engagement then return nil end

	return {
		activeAi = engagement.activeAi,
		queueSize = #engagement.queue,
		hasPositions = next(engagement.positions) ~= nil
	}
end

return CoordinationService
