--[[ Component
    @author @Daystopia
]]

local Component = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Style = require(script.Parent.Style)
local Controller = require(script.Parent.Controller)
local Scale = require(script.Parent.Scale)
local Sound = require(script.Parent.Sound)
local UserInputService = game:GetService("UserInputService")

-- Types
type ComponentConfig = {
    Name: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    BackgroundColor3: Color3?,
    BackgroundTransparency: number?,
    BorderSizePixel: number?,
    ZIndex: number?,
    LayoutOrder: number?,
    Parent: Instance?,
    [any]: any
}

-- Queue Management
local NotificationQueue = {
    items = {},
    processing = false,
    spacing = 10,
    activeNotifications = {},
    currentNotification = nil,
    lastNotificationTypes = {}
}

local PopupQueue = {
    items = {},
    processing = false,
    spacing = 10,
    activePopups = {},
    currentPopup = nil,
    lastPopupTypes = {}
}

local function processNotificationQueue()
    if NotificationQueue.processing or #NotificationQueue.items == 0 then return end
    if NotificationQueue.currentNotification then return end
    NotificationQueue.processing = true

    for i = #NotificationQueue.activeNotifications, 1, -1 do
        if not NotificationQueue.activeNotifications[i].frame.Parent then
            table.remove(NotificationQueue.activeNotifications, i)
        end
    end

    local nextItem = table.remove(NotificationQueue.items, 1)
    local position = UDim2.new(0.98, 0, 0.98, 0)
    nextItem.config.position = position

    NotificationQueue.lastNotificationTypes[nextItem.config.type] = os.time()

    if nextItem.config.type == "error" then
        Sound.Notify("Error")
    elseif nextItem.config.type == "success" then
        Sound.Notify("Success")
    elseif nextItem.config.type == "warning" then
        Sound.Notify("Warning")
    elseif nextItem.config.type == "info" then
        Sound.Notify("Info")
    end

    local frame = nextItem.createFunc(nextItem.config)
    NotificationQueue.currentNotification = {
        frame = frame,
        duration = nextItem.config.duration
    }

    task.delay(nextItem.config.duration + 0.5, function()
        NotificationQueue.currentNotification = nil
        NotificationQueue.processing = false
        processNotificationQueue()
    end)
end

local function processPopupQueue()
    if PopupQueue.processing or #PopupQueue.items == 0 then return end
    if PopupQueue.currentPopup then return end
    PopupQueue.processing = true

    for i = #PopupQueue.activePopups, 1, -1 do
        if not PopupQueue.activePopups[i].frame.Parent then
            table.remove(PopupQueue.activePopups, i)
        end
    end

    local nextItem = table.remove(PopupQueue.items, 1)
    local position = UDim2.new(0.5, 0, 0.005, 0)
    nextItem.config.position = position

    if nextItem.config.type then
        PopupQueue.lastPopupTypes[nextItem.config.type] = os.time()
    end

    local frame = nextItem.createFunc(nextItem.text, nextItem.config)
    PopupQueue.currentPopup = {
        frame = frame,
        duration = nextItem.config.duration
    }

    task.delay(nextItem.config.duration + 0.5, function()
        PopupQueue.currentPopup = nil
        PopupQueue.processing = false
        processPopupQueue()
    end)
end

-- Utilities
local function createCorner(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function applyConfig(instance: Instance, config: ComponentConfig)
    for prop, value in pairs(config) do
        if prop ~= "Parent" and
           prop ~= "cornerRadius" and
           prop ~= "disableHover" and
           instance[prop] ~= nil then
            instance[prop] = value
        end
    end
    if config.Parent then
        instance.Parent = config.Parent
    end
    if instance:IsA("GuiObject") and
       (not instance.Parent or
        instance.Parent:IsA("PlayerGui") or
        instance.Parent:IsA("ScreenGui")) then
        Scale.AutoScale(instance)
    end
end

local function setupButton(button: TextButton, defaultColor: Color3, config: ComponentConfig)
    if config.disableHover then return end

    button.MouseEnter:Connect(function()
        Sound.Button("Hover")
        Controller.Tween(button, {
            BackgroundColor3 = Style.Colors.Button.Hover
        }, {
            duration = Controller.Duration.Shortest
        })
    end)

    button.MouseLeave:Connect(function()
        Controller.Tween(button, {
            BackgroundColor3 = defaultColor
        }, {
            duration = Controller.Duration.Shortest
        })
    end)

    button.MouseButton1Click:Connect(function()
        Sound.Button("Click")
    end)
end

-- Component
function Component.CreateButton(config: ComponentConfig)
    local button = Instance.new("TextButton")
    local defaultColor = config.BackgroundColor3 or Style.Colors.Button.Default

    button.AutoButtonColor = false
    button.BackgroundColor3 = defaultColor
    button.BorderSizePixel = 0
    button.Size = config.Size or UDim2.new(0, 200, 0, 40)
    local weight = Style.Typography.Button.Weight or Enum.FontWeight.Regular
    button.FontFace = Font.new(Style.Typography.Button.Font, weight, Enum.FontStyle.Normal)
    button.TextSize = Style.Typography.Button.Size
    button.TextColor3 = Style.Colors.Text.Primary
    button.Text = config.Text or ""

    createCorner(button, Style.Layout.Corner.Medium)
    applyConfig(button, config)
    setupButton(button, defaultColor, config)

    return button
end

function Component.CreateLabel(config: ComponentConfig)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = config.Size or UDim2.new(1, 0, 0, 20)
    local weight = Style.Typography.Body.Weight or Enum.FontWeight.Regular
    label.FontFace = Font.new(Style.Typography.Body.Font, weight, Enum.FontStyle.Normal)
    label.TextSize = Style.Typography.Body.Size
    label.TextColor3 = Style.Colors.Text.Primary
    label.Text = config.Text or ""
    label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left

    applyConfig(label, config)
    return label
end

function Component.CreateFrame(config: ComponentConfig)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = config.BackgroundColor3 or Style.Colors.Background.Primary
    frame.BorderSizePixel = 0
    frame.Size = config.Size or UDim2.new(1, 0, 1, 0)

    if config.cornerRadius then
        createCorner(frame, config.cornerRadius)
    end

    applyConfig(frame, config)
    return frame
end

function Component.CreateScroll(config: ComponentConfig)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = config.Name or "ScrollFrame"
    scrollFrame.BackgroundColor3 = config.BackgroundColor3 or Style.Colors.Background.Primary
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Size = config.Size or UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = config.Position or UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = config.ScrollBarThickness or 4
    scrollFrame.ScrollBarImageColor3 = Style.Colors.Text.Secondary
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ClipsDescendants = true

    if config.cornerRadius then
        createCorner(scrollFrame, config.cornerRadius)
    end

    applyConfig(scrollFrame, config)
    return scrollFrame
end

function Component.CreateIconButton(config: ComponentConfig)
    local button = Instance.new("TextButton")
    local icon = Instance.new("TextLabel")
    local defaultColor = config.BackgroundColor3 or Style.Colors.Button.Default

    button.Size = config.Size or UDim2.new(0, 40, 0, 40)
    button.BackgroundColor3 = defaultColor
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false

    createCorner(button, Style.Layout.Corner.Medium)

    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = config.Icon or ""
    icon.TextColor3 = Style.Colors.Text.Primary
    icon.TextSize = config.IconSize or Style.Typography.Button.Size
    local weight = Style.Typography.Button.Weight or Enum.FontWeight.Regular
    icon.FontFace = Font.new(Style.Typography.Button.Font, weight, Enum.FontStyle.Normal)
    icon.Parent = button

    setupButton(button, defaultColor, config)
    applyConfig(button, config)
    return button
end

function Component.CreateInput(config: ComponentConfig)
    local container = Instance.new("Frame")
    local input = Instance.new("TextBox")

    container.BackgroundTransparency = 1
    container.Size = config.Size or UDim2.new(0, 200, 0, 40)

    input.Size = UDim2.new(1, 0, 1, 0)
    input.BackgroundColor3 = Style.Colors.Background.Secondary
    input.BorderSizePixel = 0
    local weight = Style.Typography.Body.Weight or Enum.FontWeight.Regular
    input.FontFace = Font.new(Style.Typography.Body.Font, weight, Enum.FontStyle.Normal)
    input.TextSize = Style.Typography.Body.Size
    input.TextColor3 = Style.Colors.Text.Primary
    input.PlaceholderText = config.PlaceholderText or ""
    input.PlaceholderColor3 = Style.Colors.Text.Secondary
    input.ClearTextOnFocus = config.ClearTextOnFocus or false
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = container

    createCorner(input, Style.Layout.Corner.Medium)

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, Style.Layout.Padding.Medium)
    padding.PaddingRight = UDim.new(0, Style.Layout.Padding.Medium)
    padding.Parent = input

    applyConfig(container, config)
    return container, input
end

function Component.CreateDropdown(config: ComponentConfig)
    local container = Instance.new("Frame")
    local button = Instance.new("TextButton")
    local options = Instance.new("Frame")
    local listLayout = Instance.new("UIListLayout")

    container.BackgroundTransparency = 1
    container.Size = config.Size or UDim2.new(0, 200, 0, 40)
    container.ClipsDescendants = true

    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = Style.Colors.Background.Secondary
    button.BorderSizePixel = 0
    local weight = Style.Typography.Body.Weight or Enum.FontWeight.Regular
    button.FontFace = Font.new(Style.Typography.Body.Font, weight, Enum.FontStyle.Normal)
    button.TextSize = Style.Typography.Body.Size
    button.TextColor3 = Style.Colors.Text.Primary
    button.Text = config.Text or "Select..."
    button.Parent = container

    createCorner(button, Style.Layout.Corner.Medium)

    options.Size = UDim2.new(1, 0, 0, 0)
    options.Position = UDim2.new(0, 0, 1, 5)
    options.BackgroundTransparency = 1
    options.Parent = container

    listLayout.Parent = options
    listLayout.Padding = UDim.new(0, 5)

    local isOpen = false

    button.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local optionsSize = listLayout.AbsoluteContentSize.Y

        if isOpen then
            Sound.Dropdown("Open")
        else
            Sound.Dropdown("Close")
        end

        TweenService:Create(options, Style.Controller.Short, {
            Size = UDim2.new(1, 0, 0, isOpen and optionsSize or 0)
        }):Play()
    end)

    local function addOption(text: string, callback: () -> ())
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, 0, 0, 40)
        option.BackgroundColor3 = Style.Colors.Background.Secondary
        option.BorderSizePixel = 0
        local weight = Style.Typography.Body.Weight or Enum.FontWeight.Regular
        option.FontFace = Font.new(Style.Typography.Body.Font, weight, Enum.FontStyle.Normal)
        option.TextSize = Style.Typography.Body.Size
        option.TextColor3 = Style.Colors.Text.Primary
        option.Text = text
        option.Parent = options

        createCorner(option, Style.Layout.Corner.Medium)

        option.MouseButton1Click:Connect(function()
            Sound.Dropdown("Select")
            button.Text = text
            isOpen = false
            options.Size = UDim2.new(1, 0, 0, 0)
            if callback then callback() end
        end)

        return option
    end

    applyConfig(container, config)
    return container, addOption
end

function Component.CreateToggle(config: ComponentConfig)
    local container = Instance.new("Frame")
    local button = Instance.new("TextButton")
    local indicator = Instance.new("Frame")

    container.BackgroundTransparency = 1
    container.Size = config.Size or UDim2.new(0, 50, 0, 30)

    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = Style.Colors.Background.Secondary
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = container

    createCorner(button, Style.Layout.Corner.Large)

    indicator.Size = UDim2.new(0.4, 0, 0.8, 0)
    indicator.Position = UDim2.new(0.1, 0, 0.1, 0)
    indicator.BackgroundColor3 = Style.Colors.Text.Secondary
    indicator.BorderSizePixel = 0
    indicator.Parent = button

    createCorner(indicator, Style.Layout.Corner.Large)

    local isEnabled = config.InitialState or false
    local function updateState()
        local targetPosition = isEnabled and UDim2.new(0.5, 0, 0.1, 0) or UDim2.new(0.1, 0, 0.1, 0)
        local targetColor = isEnabled and Style.Colors.Accent.Primary or Style.Colors.Text.Secondary

        if isEnabled then
            Sound.Toggle(true)
        else
            Sound.Toggle(false)
        end

        TweenService:Create(indicator, Style.Controller.Short, {
            Position = targetPosition,
            BackgroundColor3 = targetColor
        }):Play()

        if config.OnChanged then
            config.OnChanged(isEnabled)
        end
    end

    button.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        updateState()
    end)

    updateState()
    applyConfig(container, config)
    return container, {
        SetState = function(state: boolean)
            isEnabled = state
            updateState()
        end,
        GetState = function()
            return isEnabled
        end
    }
end

function Component.CreateHeader(config)
    local header = Instance.new("Frame")
    header.Name = config.Name or "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1

    local title = Instance.new("TextLabel")
    title.Name = config.Name and (config.Name .. "Title") or "HeaderTitle"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.title or ""
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = Style.Typography.Header.Size
    local weight = Style.Typography.Header.Weight or Enum.FontWeight.Regular
    title.FontFace = Font.new(Style.Typography.Header.Font, weight, Enum.FontStyle.Normal)
    title.TextXAlignment = Enum.TextXAlignment.Center

    if config.onClose then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = config.Name and (config.Name .. "CloseButton") or "HeaderCloseButton"
        closeButton.Size = UDim2.new(0, 40, 0, 40)
        closeButton.Position = UDim2.new(1, -60, 0, 10)
        closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.new(1, 1, 1)
        closeButton.TextSize = Style.Typography.Button.Size
        local weight = Style.Typography.Button.Weight or Enum.FontWeight.Regular
        closeButton.FontFace = Font.new(Style.Typography.Button.Font, weight, Enum.FontStyle.Normal)
        closeButton.Parent = header

        Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

        closeButton.MouseButton1Click:Connect(config.onClose)
    end

    title.Parent = header

    return header
end

function Component.CreateWindow(config: {
    name: string,
    title: string,
    size: UDim2,
    parent: Instance,
    position: UDim2?,
    onClose: () -> ()?,
    initialTab: string?,
    tabs: {string}?
})
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.name
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = config.parent

    local frame = Component.CreateFrame({
        Name = "WindowFrame",
        Size = config.size,
        Position = config.position or UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Style.Colors.Background.Primary,
        cornerRadius = Style.Layout.Corner.Large,
        Parent = screenGui
    })

    local header = Component.CreateHeader({
        Name = config.name .. "Header",
        title = config.title,
        onClose = config.onClose
    })
    header.Parent = frame

    local contentFrame = frame
    local tabButtons = {}

    if config.tabs then
        local contentArea = Component.CreateFrame({
            Name = "ContentArea",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 60),
            BackgroundTransparency = 1,
            Parent = frame
        })

        local tabView = Component.CreateTab({
            tabs = config.tabs,
            size = UDim2.new(1, 0, 1, 0),
            position = UDim2.new(0, 0, 0, 0),
            parent = contentArea,
            onTabChanged = config.onTabChanged
        })
        contentFrame = tabView.contentFrame
        tabButtons = tabView.tabButtons
    end

    Scale.AutoScale(frame)

    return {
        frame = frame,
        screenGui = screenGui,
        contentFrame = contentFrame,
        tabButtons = tabButtons
    }
end

function Component.CreateTab(config: {
    tabs: {string},
    size: UDim2,
    position: UDim2,
    parent: Instance,
    onTabChanged: (string) -> ()
})
    local container = Component.CreateFrame({
        Name = "TabContainer",
        Size = config.size,
        Position = config.position,
        BackgroundTransparency = 1,
        Parent = config.parent
    })

    local tabContainer = Component.CreateFrame({
        Name = "TabButtonContainer",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0.02, 0),
        BackgroundTransparency = 1,
        Parent = container
    })

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Name = "TabLayout"
    tabLayout.Padding = UDim.new(0, 20)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = tabContainer

    local contentBackground = Component.CreateFrame({
        Name = "TabContentBackground",
        Size = UDim2.new(0.95, 0, 0.75, 0),
        Position = UDim2.new(0.5, 0, 0.12, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Style.Colors.Background.Modal,
        cornerRadius = Style.Layout.Corner.Large,
        Parent = container
    })

    local contentFrame = Component.CreateFrame({
        Name = "TabContentFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = contentBackground
    })

    local selectedTab = config.tabs[1]
    local tabButtons = {}

    for _, tabName in ipairs(config.tabs) do
        local tabButton = Component.CreateButton({
            Size = UDim2.new(0, 200, 0, 60),
            BackgroundColor3 = Style.Colors.Button.Default,
            Text = tabName,
            TextSize = Style.Typography.Button.Size,
            FontFace = Font.new(Style.Typography.Button.Font, Style.Typography.Button.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            cornerRadius = Style.Layout.Corner.Medium,
            disableHover = true,
            Parent = tabContainer
        })

        tabButtons[tabName] = tabButton

        tabButton.MouseButton1Click:Connect(function()
            selectedTab = tabName
            for name, button in pairs(tabButtons) do
                button.BackgroundColor3 = name == selectedTab and
                    Style.Colors.Button.Pressed or
                    Style.Colors.Button.Default
            end
            if config.onTabChanged then
                config.onTabChanged(tabName)
            end
        end)
    end

    tabButtons[selectedTab].BackgroundColor3 = Style.Colors.Button.Pressed

    return {
        container = container,
        contentFrame = contentFrame,
        tabButtons = tabButtons
    }
end

function Component.CreateSlot(config: {
    id: string,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    item: {icon: string?, quantity: number?, name: string?}?,
    onSelected: (string) -> ()?,
    onSwap: ((fromSlot: string, toSlot: string) -> ())?,
    onRightClick: ((string) -> ())?,
    isSelected: boolean?,
    Parent: Instance,
    LayoutOrder: number?
})
    local slotContainer = Component.CreateFrame({
        Name = "Slot" .. config.id,
        Size = config.Size or UDim2.new(0, 100, 0, 100),
        Position = config.Position,
        AnchorPoint = config.AnchorPoint,
        BackgroundColor3 = Color3.fromRGB(45, 45, 55),
        cornerRadius = 8,
        LayoutOrder = config.LayoutOrder,
        Parent = config.Parent
    })

    local strokeUI = Instance.new("UIStroke")
    strokeUI.Name = "SlotStroke"
    strokeUI.Color = Color3.fromRGB(55, 55, 65)
    strokeUI.Thickness = 2
    strokeUI.Parent = slotContainer

    local itemContainer = Instance.new("Frame")
    itemContainer.Name = "ItemContainer"
    itemContainer.Size = UDim2.new(1, 0, 1, 0)
    itemContainer.BackgroundTransparency = 1
    itemContainer.Parent = slotContainer

    if config.item then
        Component.CreateLabel({
            Name = "ItemIcon",
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0, 0, 0, 10),
            Text = config.item.icon or "📦",
            TextSize = 36,
            FontFace = Font.new(Style.Typography.Title.Font, Style.Typography.Title.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = itemContainer
        })

        if config.item.name then
            Component.CreateLabel({
                Name = "ItemName",
                Size = UDim2.new(1, -10, 0, 40),
                Position = UDim2.new(0, 5, 0.6, 0),
                Text = config.item.name,
                TextSize = Style.Typography.Small.Size,
                FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                BackgroundTransparency = 1,
                Parent = itemContainer
            })
        end

        if config.item.quantity and config.item.quantity > 1 then
            Component.CreateLabel({
                Name = "ItemQuantity",
                Size = UDim2.new(0, 50, 0, 30),
                Position = UDim2.new(1, -55, 1, -35),
                Text = tostring(config.item.quantity),
                TextSize = Style.Typography.Small.Size,
                FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Color3.fromRGB(255, 200, 0),
                BackgroundTransparency = 1,
                Parent = itemContainer
            })
        end
    end

    local isInSplitMode = false

    slotContainer.MouseEnter:Connect(function()
        Sound.Button("Hover")
        Controller.Update({
            instance = slotContainer,
            properties = {BackgroundColor3 = Color3.fromRGB(55, 55, 65)},
            duration = Controller.Duration.Shortest,
            easingStyle = Controller.Easing.Linear,
            pulseSize = true
        })
    end)

    slotContainer.MouseLeave:Connect(function()
        Controller.Update({
            instance = slotContainer,
            properties = {BackgroundColor3 = Color3.fromRGB(45, 45, 55)},
            duration = Controller.Duration.Shortest,
            easingStyle = Controller.Easing.Linear
        })
    end)

    local function updateState(isSelected: boolean, isSplitMode: boolean?)
        if isSplitMode ~= nil then
            isInSplitMode = isSplitMode
        end

        local strokeProps = isInSplitMode and {
            Color = Color3.fromRGB(85, 170, 0),
            Thickness = 3
        } or isSelected and {
            Color = Color3.fromRGB(0, 170, 255),
            Thickness = 3
        } or {
            Color = Color3.fromRGB(55, 55, 65),
            Thickness = 2
        }

        Controller.Update({
            instance = strokeUI,
            properties = strokeProps,
            duration = Controller.Duration.Shortest,
            easingStyle = Controller.Easing.Linear
        })

        Controller.Update({
            instance = slotContainer,
            properties = {
                BackgroundColor3 = (isSelected or isInSplitMode) and Style.Colors.Background.Selected or Color3.fromRGB(45, 45, 55)
            },
            duration = Controller.Duration.Shortest,
            easingStyle = Controller.Easing.Linear,
            pulseSize = isSelected or isInSplitMode
        })
    end

    local function startDragging(mouseX: number, mouseY: number)
        updateState(false)

        local dragClone = slotContainer:Clone()
        dragClone.Name = "DragClone"
        dragClone.AnchorPoint = Vector2.new(0.5, 0.5)
        dragClone.Position = UDim2.new(0, mouseX, 0, mouseY)
        dragClone.ZIndex = 10
        dragClone.BackgroundTransparency = 0.2
        dragClone.Parent = slotContainer:FindFirstAncestorWhichIsA("ScreenGui") or 
            game.Players.LocalPlayer:WaitForChild("PlayerGui")

        Controller.Update({
            instance = slotContainer,
            properties = {BackgroundTransparency = 0.5},
            duration = 0.2,
            easingStyle = Controller.Easing.Quad
        })

        for _, child in ipairs(itemContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                Controller.Update({
                    instance = child,
                    properties = {TextTransparency = 0.5},
                    duration = 0.2,
                    easingStyle = Controller.Easing.Quad
                })
            end
        end

        return dragClone
    end

    local function updateSlotContents(newItem: {icon: string?, quantity: number?, name: string?}?)
        local function createItemLabels()
            Component.CreateLabel({
                Name = "IconLabel",
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0.1, 10),
                Text = newItem.icon or "📦",
                TextSize = 36,
                FontFace = Font.new(Style.Typography.Title.Font, Style.Typography.Title.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                BackgroundTransparency = 1,
                TextTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = itemContainer
            })

            Component.CreateLabel({
                Name = "NameLabel", 
                Size = UDim2.new(1, -10, 0, 40),
                Position = UDim2.new(0, 5, 0.6, 0),
                Text = newItem.name,
                TextSize = Style.Typography.Small.Size,
                FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                TextTransparency = 1,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                BackgroundTransparency = 1,
                Parent = itemContainer
            })

            if newItem.quantity and newItem.quantity > 1 then
                Component.CreateLabel({
                    Name = "ItemQuantity",
                    Size = UDim2.new(0, 50, 0, 30),
                    Position = UDim2.new(1, -55, 1.1, -35),
                    Text = tostring(newItem.quantity),
                    TextSize = Style.Typography.Small.Size,
                    FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 200, 0),
                    BackgroundTransparency = 1,
                    Parent = itemContainer
                })
            end
        end

        local function animateLabels()
            task.delay(0.05, function()
                for _, child in ipairs(itemContainer:GetChildren()) do
                    if child:IsA("TextLabel") then
                        Controller.Update({
                            instance = child,
                            properties = {
                                TextTransparency = 0,
                                Position = UDim2.new(
                                    child.Position.X.Scale,
                                    child.Position.X.Offset,
                                    child.Position.Y.Scale - 0.1,
                                    child.Position.Y.Offset
                                )
                            },
                            duration = 0.15,
                            easingStyle = Controller.Easing.Quad
                        })
                    end
                end
            end)
        end

        local existingLabels = itemContainer:GetChildren()
        local labelCount = #existingLabels

        if labelCount == 0 then
            if newItem then
                createItemLabels()
                animateLabels()
            end
            return
        end

        local completedAnimations = 0
        for _, child in existingLabels do
            if child:IsA("TextLabel") then
                Controller.Update({
                    instance = child,
                    properties = {
                        TextTransparency = 1,
                        Position = UDim2.new(
                            child.Position.X.Scale,
                            child.Position.X.Offset,
                            child.Position.Y.Scale + 0.1,
                            child.Position.Y.Offset
                        )
                    },
                    duration = 0.15,
                    easingStyle = Controller.Easing.Quad,
                    onComplete = function()
                        child:Destroy()
                        completedAnimations += 1

                        if completedAnimations == labelCount and newItem then
                            createItemLabels()
                            animateLabels()
                        end
                    end
                })
            end
        end
    end

    if config.onSelected then
        local dragClone, isDragging, dragStartPos, mouseMoveCon

        local function startTracking()
            if mouseMoveCon then return end
            mouseMoveCon = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and dragStartPos then
                    local delta = Vector2.new(input.Position.X - dragStartPos.X, input.Position.Y - dragStartPos.Y)
                    if not isDragging and delta.Magnitude > 5 then
                        isDragging = true
                        dragClone = startDragging(input.Position.X, input.Position.Y)
                    elseif isDragging and dragClone then
                        dragClone.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
                    end
                end
            end)
        end

        local function stopTracking()
            if mouseMoveCon then
                mouseMoveCon:Disconnect()
                mouseMoveCon = nil
            end
        end

        slotContainer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Sound.Button("Click")
                dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
                if not isInSplitMode then
                    config.onSelected(config.id)
                end
                startTracking()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                Sound.Button("Click")
                if config.onRightClick then
                    config.onRightClick(config.id)
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                stopTracking()
                if dragClone then
                    Sound.Button("Drop")
                    local mousePos = UserInputService:GetMouseLocation()
                    local targetSlot = nil

                    local screenGui = dragClone.Parent
                    if screenGui then
                        for _, slot in ipairs(screenGui:GetDescendants()) do
                            if slot:IsA("Frame") and
                               (slot.Name:match("^Slot%d+$") or slot:FindFirstAncestor("toolbar")) and
                               slot ~= slotContainer then
                                local slotPos = slot.AbsolutePosition
                                local slotSize = slot.AbsoluteSize
                                local adjustedMouseY = mousePos.Y - game:GetService("GuiService"):GetGuiInset().Y

                                if mousePos.X >= slotPos.X and mousePos.X <= slotPos.X + slotSize.X and
                                   adjustedMouseY >= slotPos.Y and adjustedMouseY <= slotPos.Y + slotSize.Y then
                                    targetSlot = slot
                                    break
                                end
                            end
                        end
                    end

                    if targetSlot then
                        local fromSlotId = slotContainer.Name:match("%d+")
                        local toSlotId = targetSlot.Name:match("%d+")
                        local fromInventoryId = slotContainer:FindFirstAncestor("toolbar") and
                            "toolbar_" .. game.Players.LocalPlayer.UserId or
                            "player_" .. game.Players.LocalPlayer.UserId
                        local toInventoryId = targetSlot:FindFirstAncestor("toolbar") and
                            "toolbar_" .. game.Players.LocalPlayer.UserId or
                            "player_" .. game.Players.LocalPlayer.UserId
                        config.onSwap(fromSlotId, toSlotId, fromInventoryId, toInventoryId)
                    end

                    dragClone:Destroy()
                    dragClone = nil
                end
                isDragging = false
                dragStartPos = nil

                Controller.Update({
                    instance = slotContainer,
                    properties = {BackgroundTransparency = 0},
                    duration = 0.2,
                    easingStyle = Controller.Easing.Quad
                })

                for _, child in ipairs(itemContainer:GetChildren()) do
                    if child:IsA("TextLabel") then
                        Controller.Update({
                            instance = child,
                            properties = {TextTransparency = 0},
                            duration = 0.2,
                            easingStyle = Controller.Easing.Quad
                        })
                    end
                end
            end
        end)
    end

    updateState(config.isSelected or false)

    return slotContainer, updateState, updateSlotContents
end

function Component.CreateGrid(config: {
    parent: Instance,
    cellSize: UDim2,
    padding: UDim2,
    paddingAll: number?,
    columns: number?
})
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "GridLayout"
    gridLayout.CellSize = config.cellSize
    gridLayout.CellPadding = config.padding
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    if config.columns then
        gridLayout.FillDirectionMaxCells = config.columns
    end
    gridLayout.Parent = config.parent

    return gridLayout
end

function Component.CreateNotification(config: {
    title: string?,
    message: string,
    duration: number?,
    type: string?,
    position: UDim2?,
    rewards: {[string]: any}?,
    headerColor: Color3?
})
    if config.type and NotificationQueue.lastNotificationTypes[config.type] then
        local lastShown = NotificationQueue.lastNotificationTypes[config.type]
        local currentTime = os.time()

        if currentTime - lastShown < 5 then
            return
        end
    end

    table.insert(NotificationQueue.items, {
        config = config,
        createFunc = function(queueConfig)
            local LocalPlayer = Players.LocalPlayer

            local notificationGui = LocalPlayer.PlayerGui:FindFirstChild("NotificationGui")
            if not notificationGui then
                notificationGui = Instance.new("ScreenGui")
                notificationGui.Name = "NotificationGui"
                notificationGui.ResetOnSpawn = false
                notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                notificationGui.DisplayOrder = 9999
                notificationGui.Parent = LocalPlayer.PlayerGui
            end

            local notificationFolder = notificationGui:FindFirstChild("NotificationFolder")
            if not notificationFolder then
                notificationFolder = Instance.new("Folder")
                notificationFolder.Name = "NotificationFolder"
                notificationFolder.Parent = notificationGui
            end

            local cleanTitle = (queueConfig.title or ""):gsub("<[^>]+>", "")
            local cleanMessage = queueConfig.message:gsub("<[^>]+>", "")
            local textLength = math.max(cleanTitle:len() * 1.2, cleanMessage:len())
            local width = math.clamp(textLength * 4 + 40, 250, 300)
            local height = queueConfig.rewards and 145 or 105

            local accentColor = queueConfig.type == "success" and Color3.fromRGB(0, 255, 127) or
                               queueConfig.type == "error" and Color3.fromRGB(255, 85, 85) or
                               queueConfig.type == "warning" and Color3.fromRGB(255, 165, 0) or
                               queueConfig.type == "info" and Color3.fromRGB(0, 170, 255) or
                               Color3.fromRGB(0, 170, 255)

            local frame = Component.CreateFrame({
                Size = UDim2.new(0, width * 0.5, 0, height * 0.5),
                Position = UDim2.new(0.5, 0, 0, -height),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                BackgroundTransparency = 0.1,
                cornerRadius = 12,
                Parent = notificationFolder
            })

            local accentBar = Instance.new("Frame")
            accentBar.Name = "AccentBar"
            accentBar.Size = UDim2.new(1, 0, 0, 10)
            accentBar.Position = UDim2.new(0, 0, 0, 0)
            accentBar.BackgroundColor3 = accentColor
            accentBar.BorderSizePixel = 0
            accentBar.Parent = frame

            local accentCorner = Instance.new("UICorner")
            accentCorner.CornerRadius = UDim.new(0, 2)
            accentCorner.Parent = accentBar

            local title = Component.CreateLabel({
                Size = UDim2.new(1, -40, 0, 32),
                Position = UDim2.new(0, 20, 0, 20),
                Text = (queueConfig.title or ""):upper(),
                TextSize = Style.Typography.Subtitle.Size,
                FontFace = Font.new(Style.Typography.Subtitle.Font, Style.Typography.Subtitle.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextTransparency = 1,
                RichText = true,
                TextColor3 = queueConfig.headerColor or accentColor,
                Parent = frame
            })

            local message = Component.CreateLabel({
                Size = UDim2.new(1, -40, 0, 45),
                Position = UDim2.new(0, 20, 0, 52),
                Text = queueConfig.message,
                TextSize = Style.Typography.Subtitle.Size,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                FontFace = Font.new(Style.Typography.Subtitle.Font, Style.Typography.Subtitle.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextWrapped = true,
                TextTransparency = 1,
                RichText = true,
                Parent = frame
            })

            local rewardsContainer
            if queueConfig.rewards then
                rewardsContainer = Component.CreateFrame({
                    Size = UDim2.new(1, -40, 0, 40),
                    Position = UDim2.new(0, 20, 0, height - 52),
                    BackgroundTransparency = 1,
                    Parent = frame
                })

                local rewardsText = ""
                for item, amount in pairs(queueConfig.rewards) do
                    rewardsText = rewardsText .. string.format("+%d %s ", amount, item)
                end

                local rewardsLabel = Component.CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = rewardsText,
                    TextSize = Style.Typography.Caption.Size,
                    TextColor3 = accentColor,
                    FontFace = Font.new(Style.Typography.Caption.Font, Style.Typography.Caption.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextTransparency = 1,
                    Parent = rewardsContainer
                })
            end

            Scale.AutoScale(frame)

            frame.BackgroundTransparency = 1
            frame.Position = UDim2.new(0.5, 0, 0, -height)
            frame.Size = UDim2.new(0, width * 0.5, 0, height * 0.5)

            Controller.Update({
                instance = frame,
                properties = {
                    Size = UDim2.fromOffset(width, height),
                    Position = UDim2.new(0.5, 0, 0, 20),
                    BackgroundTransparency = 0.1
                },
                duration = Controller.Duration.Medium,
                easingStyle = Controller.Easing.Back,
                onComplete = function()
                    Controller.Update({
                        instance = title,
                        properties = { TextTransparency = 0 },
                        duration = Controller.Duration.Short
                    })
                    Controller.Update({
                        instance = message,
                        properties = { TextTransparency = 0 },
                        duration = Controller.Duration.Short
                    })
                    if queueConfig.rewards then
                        for _, child in ipairs(rewardsContainer:GetChildren()) do
                            if child:IsA("TextLabel") then
                                Controller.Update({
                                    instance = child,
                                    properties = { TextTransparency = 0 },
                                    duration = Controller.Duration.Short
                                })
                            end
                        end
                    end
                end
            })

            if queueConfig.duration then
                task.delay(queueConfig.duration, function()
                    Controller.Update({
                        instance = title,
                        properties = { TextTransparency = 1 },
                        duration = Controller.Duration.Short
                    })
                    Controller.Update({
                        instance = message,
                        properties = { TextTransparency = 1 },
                        duration = Controller.Duration.Short
                    })
                    if queueConfig.rewards then
                        for _, child in ipairs(rewardsContainer:GetChildren()) do
                            if child:IsA("TextLabel") then
                                Controller.Update({
                                    instance = child,
                                    properties = { TextTransparency = 1 },
                                    duration = Controller.Duration.Short
                                })
                            end
                        end
                    end

                    task.delay(0.15, function()
                        Controller.Update({
                            instance = frame,
                            properties = {
                                Position = UDim2.new(0.5, 0, 0, -height),
                                BackgroundTransparency = 1
                            },
                            duration = Controller.Duration.Medium,
                            easingStyle = Controller.Easing.Back,
                            onComplete = function()
                                frame:Destroy()
                            end
                        })

                        Controller.Update({
                            instance = accentBar,
                            properties = {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(0.5, 0, 0, 4)
                            },
                            duration = 0.25,
                            easingStyle = Controller.Easing.Quad
                        })
                    end)
                end)
            end

            return frame
        end
    })

    processNotificationQueue()
end

function Component.CreatePopup(text, config)
    if config.type and PopupQueue.lastPopupTypes[config.type] then
        local lastShown = PopupQueue.lastPopupTypes[config.type]
        local currentTime = os.time()

        if currentTime - lastShown < 5 then
            return
        end
    end

    table.insert(PopupQueue.items, {
        text = text,
        config = config,
        createFunc = function(popupText, popupConfig)
            local LocalPlayer = Players.LocalPlayer

            local popupGui = LocalPlayer.PlayerGui:FindFirstChild("PopupGui")
            if not popupGui then
                popupGui = Instance.new("ScreenGui")
                popupGui.Name = "PopupGui"
                popupGui.ResetOnSpawn = false
                popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                popupGui.DisplayOrder = 9999
                popupGui.Parent = LocalPlayer.PlayerGui
            end

            local popupFolder = popupGui:FindFirstChild("PopupFolder")
            if not popupFolder then
                popupFolder = Instance.new("Folder")
                popupFolder.Name = "PopupFolder"
                popupFolder.Parent = popupGui
            end

            local frame = Instance.new("Frame")
            frame.AutomaticSize = Enum.AutomaticSize.X
            frame.Size = UDim2.new(0, 0, 0, 80)
            frame.Position = popupConfig.position
            frame.AnchorPoint = Vector2.new(0.5, 0)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            frame.BorderSizePixel = 0
            frame.Name = "Popup"
            frame.ZIndex = 10
            frame.Parent = popupFolder

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 20)
            padding.PaddingRight = UDim.new(0, 20)
            padding.Parent = frame

            local header = Instance.new("TextLabel")
            header.Name = "Header"
            header.BackgroundTransparency = 1
            header.Size = UDim2.new(1, 0, 0, 24)
            header.Position = UDim2.new(0, 0, 0, 8)
            header.FontFace = Font.new(Style.Typography.Button.Font, Style.Typography.Button.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            header.TextColor3 = popupConfig.headerColor or Color3.fromRGB(255, 100, 100)
            header.TextSize = Style.Typography.Button.Size
            header.Text = popupConfig.headerText or ""
            header.TextTransparency = 1
            header.TextXAlignment = Enum.TextXAlignment.Center
            header.TextWrapped = false
            header.RichText = true
            header.ZIndex = 11
            header.Parent = frame

            local description = Instance.new("TextLabel")
            description.Name = "Description"
            description.BackgroundTransparency = 1
            description.Size = UDim2.new(0, 0, 0, 20)
            description.Position = UDim2.new(0, 0, 0, 32)
            description.FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            description.TextColor3 = popupConfig.descriptionColor or Color3.fromRGB(255, 255, 255)
            description.TextSize = Style.Typography.Small.Size
            description.Text = popupText
            description.TextTransparency = 1
            description.TextXAlignment = Enum.TextXAlignment.Center
            description.TextWrapped = false
            description.RichText = true
            description.AutomaticSize = Enum.AutomaticSize.X
            description.ZIndex = 11
            description.Parent = frame

            frame.BackgroundTransparency = 1
            frame.Position = UDim2.new(0.5, 0, 0, -100)
            frame.Size = UDim2.new(0, 50, 0, 20)

            local inTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local popupTweens = {
                TweenService:Create(frame, inTweenInfo, {
                    Position = popupConfig.position,
                    BackgroundTransparency = 0.1,
                    Size = UDim2.new(0, 0, 0, 80)
                }),
                TweenService:Create(header, inTweenInfo, {
                    TextTransparency = 0
                }),
                TweenService:Create(description, inTweenInfo, {
                    TextTransparency = 0
                })
            }

            for _, tween in ipairs(popupTweens) do tween:Play() end

            if popupConfig.duration then
                task.delay(popupConfig.duration, function()
                    local textTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
                    local frameTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)

                    local textTweens = {
                        TweenService:Create(header, textTweenInfo, {
                            TextTransparency = 1
                        }),
                        TweenService:Create(description, textTweenInfo, {
                            TextTransparency = 1
                        })
                    }

                    local frameTween = TweenService:Create(frame, frameTweenInfo, {
                        Position = UDim2.new(0.5, 0, 0, -100),
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 50, 0, 20)
                    })

                    for _, tween in ipairs(textTweens) do tween:Play() end

                    task.delay(0.01, function()
                        frameTween:Play()
                        frameTween.Completed:Connect(function()
                            frame:Destroy()
                        end)
                    end)
                end)
            end

            return frame
        end
    })

    processPopupQueue()
end

function Component.CreateConfirm(config: {
    title: string,
    message: string,
    confirmText: string?,
    cancelText: string?,
    onConfirm: () -> (),
    onCancel: (() -> ())?,
    parent: Instance?
})
    local LocalPlayer = Players.LocalPlayer

    local dialogGui = LocalPlayer.PlayerGui:FindFirstChild("DialogGui")
    if not dialogGui then
        dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "DialogGui"
        dialogGui.ResetOnSpawn = false
        dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        dialogGui.DisplayOrder = 9999
        dialogGui.Parent = LocalPlayer.PlayerGui
    end

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = dialogGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 220)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0
    frame.Parent = background

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 2
    stroke.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 0, 40)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = Style.Typography.Subtitle.Size
    local weight = Style.Typography.Subtitle.Weight or Enum.FontWeight.Regular
    titleLabel.FontFace = Font.new(Style.Typography.Subtitle.Font, weight, Enum.FontStyle.Normal)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 70)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = config.message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = Style.Typography.Small.Size
    messageLabel.FontFace = Font.new(Style.Typography.Small.Font, Style.Typography.Small.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = frame

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 50)
    buttonContainer.Position = UDim2.new(0, 20, 1, -70)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = frame

    local confirmButton = Component.CreateButton({
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(1, -160, 0, 0),
        Text = config.confirmText or "Confirm",
        TextSize = 20,
        FontFace = Font.new(Style.Typography.Button.Font, Style.Typography.Button.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        BackgroundColor3 = Color3.fromRGB(85, 170, 0),
        cornerRadius = 8,
        Parent = buttonContainer
    })

    local cancelButton = Component.CreateButton({
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(1, -340, 0, 0),
        Text = config.cancelText or "Cancel",
        TextSize = 20,
        FontFace = Font.new(Style.Typography.Button.Font, Style.Typography.Button.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        BackgroundColor3 = Color3.fromRGB(200, 60, 60),
        cornerRadius = 8,
        Parent = buttonContainer
    })

    local function cleanup()
        background:Destroy()
    end

    confirmButton.MouseButton1Click:Connect(function()
        config.onConfirm()
        cleanup()
    end)

    cancelButton.MouseButton1Click:Connect(function()
        if config.onCancel then
            config.onCancel()
        end
        cleanup()
    end)

    return background
end

return Component