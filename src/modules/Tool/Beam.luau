--[[ Beam
    Advanced beam effect system with dynamic animations and particle effects.
    Handles beam creation, animation, sparking effects and color transitions.
    @author @Daystopia
    @version 1.0.0
    @date 2025-01-09
]]
local Beam = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Types
export type BeamConfig = {
    Attachment0: Attachment,
    Attachment1: Attachment,
    PartCount: number?,
    Enabled: boolean?,
    CurveSize0: number?,
    CurveSize1: number?,
    MinRadius: number?,
    MaxRadius: number?,
    Frequency: number?,
    AnimationSpeed: number?,
    Thickness: number?,
    MinThicknessMultiplier: number?,
    MaxThicknessMultiplier: number?,
    MinTransparency: number?,
    MaxTransparency: number?,
    PulseSpeed: number?,
    PulseLength: number?,
    FadeLength: number?,
    ContractFrom: number?,
    Color: Color3 | ColorSequence?,
    ColorOffsetSpeed: number?,
    Sparks: number?
}

-- Constants
local CAMERA = Workspace.CurrentCamera
local RANDOM = Random.new()
local offsetAngle = math.cos(math.rad(90))

-- Utilities
local function DiscretePulse(input, s, k, f, t, min, max)
    return math.clamp((k)/(2*f) - math.abs((input - t*s + 0.5*(k))/(f)), min, max)
end

local function NoiseBetween(x, y, z, min, max)
    return min + (max - min)*(math.noise(x, y, z) + 0.5)
end

local function CubicBezier(p0, p1, p2, p3, t)
    local mt = 1 - t
    local mt2 = mt * mt
    local t2 = t * t
    return p0*mt2*mt + p1*3*t*mt2 + p2*3*mt*t2 + p3*t2*t
end

local function RandomVectorOffsetBetween(v, minAngle, maxAngle)
    local angle = RANDOM:NextNumber(0, 2*math.pi)
    local cosAngle = RANDOM:NextNumber(math.cos(maxAngle), math.cos(minAngle))
    return (CFrame.lookAt(Vector3.new(), v) * CFrame.Angles(0, 0, angle) * CFrame.Angles(math.acos(cosAngle), 0, 0)).LookVector
end

local BoltPart = Instance.new("Part")
BoltPart.TopSurface = Enum.SurfaceType.Smooth
BoltPart.BottomSurface = Enum.SurfaceType.Smooth
BoltPart.Anchored = true
BoltPart.CanCollide = false
BoltPart.Shape = Enum.PartType.Cylinder
BoltPart.Name = "BoltPart"
BoltPart.Material = Enum.Material.Neon
BoltPart.Color = Color3.new(1, 1, 1)
BoltPart.Transparency = 1
BoltPart.Locked = true
BoltPart.CastShadow = false

local ActiveBolts = {}
local ActiveSparks = {}

local BeamBolt = {}
BeamBolt.__index = BeamBolt

function BeamBolt.new(config: BeamConfig)
    local self = setmetatable({}, BeamBolt)

    self.Enabled = config.Enabled or true
    self.Attachment0 = config.Attachment0
    self.Attachment1 = config.Attachment1
    self.CurveSize0 = config.CurveSize0 or 0
    self.CurveSize1 = config.CurveSize1 or 0
    self.MinRadius = config.MinRadius or 0
    self.MaxRadius = config.MaxRadius or 2.4
    self.Frequency = config.Frequency or 2
    self.AnimationSpeed = config.AnimationSpeed or 7
    self.Thickness = config.Thickness or 1
    self.MinThicknessMultiplier = config.MinThicknessMultiplier or 0.2
    self.MaxThicknessMultiplier = config.MaxThicknessMultiplier or 1
    self.MinTransparency = config.MinTransparency or 0
    self.MaxTransparency = config.MaxTransparency or 1
    self.PulseSpeed = config.PulseSpeed or 5
    self.PulseLength = config.PulseLength or 1000000
    self.FadeLength = config.FadeLength or 0.2
    self.ContractFrom = config.ContractFrom or 0.5
    self.Color = config.Color or Color3.new(1, 1, 1)
    self.ColorOffsetSpeed = config.ColorOffsetSpeed or 3

    self.Parts = table.create(config.PartCount or 30)
    self.PartsHidden = false
    self.DisabledTransparency = 1
    self.StartT = os.clock()
    self.RanNum = RANDOM:NextNumber(0, 100)
    self.RefIndex = #ActiveBolts + 1

    local a0, a1 = self.Attachment0, self.Attachment1
    local p0, p1 = a0.WorldPosition, a1.WorldPosition
    local p2 = p0 + a0.WorldAxis*self.CurveSize0
    local p3 = p1 - a1.WorldAxis*self.CurveSize1

    local PrevPoint = p0
    local bezier0 = p0
    local MainBranchN = config.PartCount or 30
    local xInverse = CFrame.lookAt(Vector3.new(), Vector3.new(1, 0, 0)):inverse()

    for i = 1, MainBranchN do
        local t1 = i/MainBranchN
        local bezier1 = CubicBezier(p0, p2, p3, p1, t1)
        local NextPoint = i ~= MainBranchN and (CFrame.lookAt(bezier0, bezier1)).Position or bezier1

        local BPart = BoltPart:Clone()
        BPart.Size = Vector3.new((NextPoint - PrevPoint).Magnitude, 0, 0)
        BPart.CFrame = CFrame.lookAt(0.5*(PrevPoint + NextPoint), NextPoint)*xInverse
        BPart.Parent = CAMERA

        self.Parts[i] = BPart
        PrevPoint, bezier0 = NextPoint, bezier1
    end

    ActiveBolts[self.RefIndex] = self
    return self
end

function BeamBolt:Destroy()
    ActiveBolts[self.RefIndex] = nil
    for _, part in self.Parts do
        part:Destroy()
    end
    table.clear(self.Parts)
    self = nil
end

-- Beam Sparks Class
local BeamSparks = {}
BeamSparks.__index = BeamSparks

function BeamSparks.new(BeamBolt, MaxSparkCount)
    local self = setmetatable({}, BeamSparks)

    self.Enabled = true
    self.BeamBolt = BeamBolt
    self.MaxSparkCount = MaxSparkCount or 10
    self.MinSpeed = 4
    self.MaxSpeed = 6
    self.MinDistance = 3
    self.MaxDistance = 6
    self.MinPartsPerSpark = 8
    self.MaxPartsPerSpark = 10

    self.SparksN = 0
    self.SlotTable = {}
    self.RefIndex = #ActiveSparks + 1

    ActiveSparks[self.RefIndex] = self
    return self
end

function BeamSparks:Destroy()
    ActiveSparks[self.RefIndex] = nil
    for i, v in pairs(self.SlotTable) do
        if v.Parts[1].Parent == nil then
            self.SlotTable[i] = nil
        end
    end
    self = nil
end

RunService.Heartbeat:Connect(function(dt)
    local currentTime = os.clock()

    for _, bolt in pairs(ActiveBolts) do
        if bolt.Enabled then
            bolt.PartsHidden = false
            local MinOpa = 1 - bolt.MaxTransparency
            local MaxOpa = 1 - bolt.MinTransparency
            local timePassed = currentTime - bolt.StartT

            if timePassed < (bolt.PulseLength + 1)/bolt.PulseSpeed then
                local numParts = #bolt.Parts
                for i, BPart in bolt.Parts do
                    local t1 = i/numParts
                    local Opacity = DiscretePulse(t1, bolt.PulseSpeed, bolt.PulseLength, bolt.FadeLength, timePassed, MinOpa, MaxOpa)
                    local time = -timePassed
                    local input = (bolt.AnimationSpeed*time) + bolt.Frequency*10*t1 - 0.2 + bolt.RanNum*4
                    local input2 = 5*((bolt.AnimationSpeed*0.01*time)/10 + bolt.Frequency*t1) + bolt.RanNum*4

                    local noise0 = NoiseBetween(5*input, 1.5, 5*0.2*input2, 0, 0.1*2*math.pi) + 
                                 NoiseBetween(0.5*input, 1.5, 0.5*0.2*input2, 0, 0.9*2*math.pi)
                    local noise1 = NoiseBetween(3.4, input2, input, bolt.MinRadius, bolt.MaxRadius)*
                                 math.exp(-5000*(t1 - 0.5)^10)
                    local thicknessNoise = NoiseBetween(2.3, input2, input, bolt.MinThicknessMultiplier, bolt.MaxThicknessMultiplier)

                    if Opacity > bolt.ContractFrom then
                        BPart.Size = Vector3.new(BPart.Size.X, bolt.Thickness*thicknessNoise*Opacity, bolt.Thickness*thicknessNoise*Opacity)
                        BPart.CFrame = CFrame.new(BPart.Position)*
                                     CFrame.Angles(0, 0, noise0)*
                                     CFrame.Angles(math.acos(math.clamp(NoiseBetween(input2, input, 2.7, offsetAngle, 1), -1, 1)), 0, 0)*
                                     CFrame.new(0, 0, -noise1)
                        BPart.Transparency = 1 - Opacity
                    elseif Opacity > bolt.ContractFrom - 1/(numParts*bolt.FadeLength) then
                        local interp = (1 - (Opacity - (bolt.ContractFrom - 1/(numParts*bolt.FadeLength)))*numParts*bolt.FadeLength)*
                                     (t1 < timePassed*bolt.PulseSpeed - 0.5*bolt.PulseLength and 1 or -1)
                        BPart.Size = Vector3.new((1 - math.abs(interp))*BPart.Size.X, 
                                               bolt.Thickness*thicknessNoise*Opacity,
                                               bolt.Thickness*thicknessNoise*Opacity)
                        BPart.Transparency = 1 - Opacity
                    else
                        BPart.Transparency = 1
                    end

                    if typeof(bolt.Color) == "Color3" then
                        BPart.Color = bolt.Color
                    else
                        t1 = (bolt.RanNum + t1 - timePassed*bolt.ColorOffsetSpeed)%1
                        local keypoints = bolt.Color.Keypoints
                        for i = 1, #keypoints - 1 do
                            if keypoints[i].Time < t1 and t1 < keypoints[i + 1].Time then
                                local alpha = (t1 - keypoints[i].Time)/(keypoints[i + 1].Time - keypoints[i].Time)
                                BPart.Color = keypoints[i].Value:lerp(keypoints[i + 1].Value, alpha)
                                break
                            end
                        end
                    end
                end
            else
                bolt:Destroy()
            end
        elseif not bolt.PartsHidden then
            bolt.PartsHidden = true
            for _, part in bolt.Parts do
                part.Transparency = bolt.DisabledTransparency
            end
        end
    end

    for _, spark in pairs(ActiveSparks) do
        if spark.Enabled and spark.SparksN < spark.MaxSparkCount then
            local Bolt = spark.BeamBolt
            if Bolt.Parts[1].Parent == nil then
                spark:Destroy()
                continue
            end

            local BoltParts = Bolt.Parts
            local opaque_parts = {}

            for part_i = 1, #BoltParts do
                if BoltParts[part_i].Transparency < 0.3 then
                    opaque_parts[#opaque_parts + 1] = (part_i - 0.5)/#BoltParts
                end
            end

            if #opaque_parts > 0 then
                local minSlot = math.ceil(opaque_parts[1]*spark.MaxSparkCount)
                local maxSlot = math.ceil(opaque_parts[#opaque_parts]*spark.MaxSparkCount)

                for _ = 1, RANDOM:NextInteger(1, spark.MaxSparkCount - spark.SparksN) do
                    local available_slots = {}
                    for slot_i = minSlot, maxSlot do
                        if not spark.SlotTable[slot_i] then
                            available_slots[#available_slots + 1] = slot_i
                        end
                    end

                    if #available_slots > 0 then
                        local ChosenSlot = available_slots[RANDOM:NextInteger(1, #available_slots)]
                        local localTrng = RANDOM:NextNumber(-0.5, 0.5)
                        local ChosenT = (ChosenSlot - 0.5 + localTrng)/spark.MaxSparkCount

                        local dist, ChosenPart = 10, 1
                        for opaque_i = 1, #opaque_parts do
                            local testdist = math.abs(opaque_parts[opaque_i] - ChosenT)
                            if testdist < dist then
                                dist = testdist
                                ChosenPart = math.floor((opaque_parts[opaque_i]*#BoltParts + 0.5) + 0.5)
                            end
                        end

                        local Part = BoltParts[ChosenPart]
                        local A1, A2 = {}, {}
                        A1.WorldPosition = Part.Position + localTrng*Part.CFrame.RightVector*Part.Size.X
                        A2.WorldPosition = A1.WorldPosition + 
                                         RandomVectorOffsetBetween(Part.CFrame.RightVector, math.pi/4)*
                                         RANDOM:NextNumber(spark.MinDistance, spark.MaxDistance)
                        A1.WorldAxis = (A2.WorldPosition - A1.WorldPosition).Unit
                        A2.WorldAxis = A1.WorldAxis

                        local NewSpark = BeamBolt.new({
                            Attachment0 = A1,
                            Attachment1 = A2,
                            PartCount = RANDOM:NextInteger(spark.MinPartsPerSpark, spark.MaxPartsPerSpark),
                            MinRadius = 0,
                            MaxRadius = 0.8,
                            AnimationSpeed = 0,
                            Thickness = Part.Size.Y/2,
                            MinThicknessMultiplier = 1,
                            MaxThicknessMultiplier = 1,
                            PulseLength = 0.5,
                            PulseSpeed = RANDOM:NextNumber(spark.MinSpeed, spark.MaxSpeed),
                            FadeLength = 0.25,
                            Color = Color3.fromHSV(Part.Color:ToHSV())
                        })

                        spark.SlotTable[ChosenSlot] = NewSpark
                    end
                end
            end
        end

        local slotsInUse = 0
        for i, v in pairs(spark.SlotTable) do
            if v.Parts[1].Parent ~= nil then
                slotsInUse += 1
            else
                spark.SlotTable[i] = nil
            end
        end
        spark.SparksN = slotsInUse
    end
end)

function Beam.CreateBolt(config: BeamConfig)
    local bolt = BeamBolt.new(config)
    if config.Sparks then
        BeamSparks.new(bolt, config.Sparks)
    end
    return bolt
end

return Beam