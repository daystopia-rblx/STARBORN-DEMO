local Tab = {}

local activeTab = nil
local isTransitioning = false
local registeredTabs = {}
local TRANSITION_COOLDOWN = 0.05


function Tab.Create(name: string, openCallback: () -> (), closeCallback: () -> ())
    if registeredTabs[name] then return end

    registeredTabs[name] = {
        onOpen = openCallback,
        onClose = closeCallback
    }
end

function Tab.Toggle(name: string)
    if isTransitioning or not registeredTabs[name] then return end

    isTransitioning = true
    local isClosing = activeTab == name
    local currentTab = registeredTabs[activeTab]
    local targetTab = registeredTabs[name]

    if currentTab then currentTab.onClose() end

    if not isClosing then
        targetTab.onOpen()
        activeTab = name
    else
        activeTab = nil
    end

    task.delay(TRANSITION_COOLDOWN, function()
        isTransitioning = false
    end)

    return not isClosing
end

function Tab.isOpen(name: string): boolean
    return activeTab == name
end

function Tab.isActive(): string?
    return activeTab
end

function Tab.Close()
    if activeTab and registeredTabs[activeTab] then
        registeredTabs[activeTab].onClose()
        activeTab = nil
    end
end

function Tab.Destroy(name: string)
    if registeredTabs[name] then
        if activeTab == name then
            Tab.Close()
        end
        registeredTabs[name] = nil
    end
end

function Tab.Get(): {string}
    local tabs = {}
    for name in pairs(registeredTabs) do
        table.insert(tabs, name)
    end
    return tabs
end

return Tab
