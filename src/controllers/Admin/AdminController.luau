--[[ AdminController
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-19
]]
local AdminController = {}

AdminController.Dependencies = {
    "Event"
}

AdminController.Modules = {
    "Admin"
}

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--[[ State ]]
local Controllers
local Modules
local State = {
    adminMode = false,
    commandHistory = {},
    permissions = 0
}

--[[ Listeners ]]
AdminController.Listeners = {
    ["Admin.Permission"] = function(self, data)
        if data.targetId == tostring(LocalPlayer.UserId) then
            State.permissions = data.level
        end
    end,

    ["Admin.Mute"] = function(self, data)
        if data.isMuted then
            local channel = TextChatService:FindChannelByName("General")
            if channel then
                local expiryTime = data.expiry and os.date("%H:%M:%S", data.expiry) or "unknown time"
                local message = string.format("You are muted until %s", expiryTime)

                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = message,
                    Color = Color3.fromRGB(255, 50, 50),
                    Font = Enum.Font.SourceSansBold
                })
            end
        end
    end,

    ["Admin.Command"] = function(self, data)
        if data and data.success ~= nil then
            local message = data.success 
                and (data.message or "Command executed successfully")
                or ("Error: " .. (data.message or "Unknown error"))

            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[Admin] " .. message,
                Color = data.success and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50),
                Font = Enum.Font.SourceSansBold
            })
        end
    end
}

--[[ Core Functions ]]
function AdminController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function AdminController:Start()
    self:ListenChat()
    self:RequestPermissions()
    return true
end

local lastMessageText = ""
local lastMessageTime = 0
local DEBOUNCE_THRESHOLD = 0.1

function AdminController:ListenChat()
    TextChatService.OnIncomingMessage = function(message)
        local props = Instance.new("TextChatMessageProperties")
        local currentTime = os.clock()

        if message.TextSource then
            local player = Players:GetPlayerByUserId(message.TextSource.UserId)

            if player and player == LocalPlayer then
                if message.Text == lastMessageText and currentTime - lastMessageTime < DEBOUNCE_THRESHOLD then
                    props.Text = ""
                    return props
                end

                lastMessageText = message.Text
                lastMessageTime = currentTime


                if message.Text:sub(1, 1) ~= "/" then
                    Controllers.Event:FireServer("Admin.Mute", {
                        player = LocalPlayer
                    })
                end

                if message.Text:sub(1, 1) == "/" then
                    self:ProcessCommand(message.Text)
                end
            end
        end

        props.Text = message.Text
        return props
    end
end

function AdminController:ProcessCommand(message)
    table.insert(State.commandHistory, {
        message = message,
        timestamp = os.time()
    })

    if #State.commandHistory > 50 then
        table.remove(State.commandHistory, 1)
    end

    Controllers.Event:FireServer("Admin.Command", {
        command = message,
        sender = LocalPlayer
    })
end

function AdminController:RequestPermissions()
    Controllers.Event:FireServer("Admin.Permission", {
        request = "query"
    })
end

return AdminController