--[[ TimeService
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-11
]]

local Lighting = game:GetService("Lighting")

local TimeService = {}

TimeService.Dependencies = { "Event" }

TimeService.Events = {
    Start = true,
    Update = true
}

TimeService.CONSTANTS = {
    CYCLE_DURATION = 800, -- 13.33 minutes
    HOURS_PER_DAY = 24
}

local Services

local state = {
    cycleStartTime = 0,
    lastUpdate = 0,
    lastHour = -1,
    currentTime = {
        hour = 0,
        minute = 0,
        second = 0,
        dayFraction = 0
    }
}

-- [[ Helper Functions ]]
local function CalculateTime()
    local cycleTime = (os.clock() - state.cycleStartTime) % TimeService.CONSTANTS.CYCLE_DURATION
    local dayFraction = cycleTime / TimeService.CONSTANTS.CYCLE_DURATION
    local totalHours = dayFraction * TimeService.CONSTANTS.HOURS_PER_DAY
    local hour = math.floor(totalHours)
    local minute = math.floor((totalHours - hour) * 60)
    local second = math.floor(((totalHours - hour) * 60 - minute) * 60)

    return {
        hour = hour,
        minute = minute,
        second = second,
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
    state.currentTime = CalculateTime()
    state.lastHour = state.currentTime.hour

    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)

    Services.Event:Fire("Time.Start", state.currentTime)
    return true
end

function TimeService:Update(dt)
    local currentTime = os.clock()
    local elapsed = currentTime - state.lastUpdate
    state.lastUpdate = currentTime

    local timeInfo = CalculateTime()
    state.currentTime = timeInfo

    Lighting.ClockTime = timeInfo.dayFraction * 24

    if timeInfo.hour ~= state.lastHour then
        state.lastHour = timeInfo.hour

        Services.Event:Fire("Time.Update", {
            hour = timeInfo.hour,
            minute = timeInfo.minute,
            second = timeInfo.second,
            dayFraction = timeInfo.dayFraction
        })
    end
end

-- [[ Query Methods ]]
function TimeService:GetTime()
    return state.currentTime
end

function TimeService:GetCycle()
    return self.CONSTANTS.CYCLE_DURATION
end

function TimeService:GetStartTime()
    return state.cycleStartTime
end

function TimeService:GetStart()
    local currentTime = os.clock()
    local totalSeconds = currentTime - state.cycleStartTime
    local days = totalSeconds / self.CONSTANTS.CYCLE_DURATION
    return days
end

function TimeService:GetTimeOfDay(hour)
    hour = hour or state.currentTime.hour

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
    local time = state.currentTime
    return string.format("%02d:%02d", time.hour, time.minute)
end

return TimeService