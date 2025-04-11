--[[ TimeService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]

local Lighting = game:GetService("Lighting")

local TimeService = {}

TimeService.Dependencies = { "Event" }

TimeService.Events = {
    Start = true
}

TimeService.CONSTANTS = {
    CYCLE_DURATION = 800, -- 13.33 minutes
    HOURS_PER_DAY = 24
}

local Services

local state = {
    cycleStartTime = 0,
    lastUpdate = 0
}

-- [[ Helper Functions ]]
local function CalculateTime()
    local cycleTime = (os.clock() - state.cycleStartTime) % TimeService.CONSTANTS.CYCLE_DURATION
    local dayFraction = cycleTime / TimeService.CONSTANTS.CYCLE_DURATION
    local totalHours = dayFraction * TimeService.CONSTANTS.HOURS_PER_DAY
    local hour = math.floor(totalHours)

    return {
        hour = hour,
        dayFraction = dayFraction
    }
end

-- [[ Core Methods ]]
function TimeService:Init(services)
    Services = services
    return true
end

function TimeService:Start()
    local sevenAMOffset = (7/24) * self.CONSTANTS.CYCLE_DURATION
    state.cycleStartTime = os.clock() - sevenAMOffset
    state.lastUpdate = os.clock()

    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)

    Services.Event:Fire("Time.Start", CalculateTime())
    return true
end

function TimeService:Update(dt)
    local currentTime = os.clock()
    local elapsed = currentTime - state.lastUpdate
    state.lastUpdate = currentTime

    local timeInfo = CalculateTime()
    Lighting.ClockTime = timeInfo.dayFraction * 24
end

-- [[ Query Methods ]]
function TimeService:GetTime()
    return CalculateTime()
end

function TimeService:GetTimeOfDay(hour)
    if hour >= 5 and hour < 8 then
        return "Dawn"
    elseif hour >= 8 and hour < 17 then
        return "Day"
    elseif hour >= 17 and hour < 20 then
        return "Dusk"
    else
        return "Night"
    end
end

function TimeService:FormatTime()
    local time = self:GetTime()
    return string.format("%02d:00", time.hour)
end

return TimeService