-- Reworking old character creation menu
--[[ CharacterController
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local CharacterController = {}

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

CharacterController.Dependencies = {
    "Event"
}

CharacterController.Modules = {
    "Credit",
    "Name",
    "Body",
    "Race"
}

local Utility = {
    Controller = require(ReplicatedStorage.Modules.Utility.Controller),
    Sound = require(ReplicatedStorage.Modules.Utility.Sound)
}

--[[ References ]]
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
--local PlayerGui = Player:WaitForChild("PlayerGui")
local Alphabet = "abcdefghijklmnopqrstuvwxyz"

CharacterController.Frames = {
	"fleshAndForm",
	"heritageAndForm",
	"soulSigil",
	"aetherTattoos",
	"embellishments",
	"chosenRelic",
}

CharacterController.FrameNames = {
    ["fleshAndForm"] = "Flesh & Form",
    ["heritageAndForm"] = "Heritage and Form",
    ["soulSigil"] = "Soul Sigil",
    ["aetherTattoos"] = "Aether Tattoos",
    ["embellishments"] = "Embellishments",
    ["chosenRelic"] = "Chosen Relic"
}

--[[ State ]]
local Controllers
local Modules
local State = {
    CurrentSlot = nil,
    CharacterData = {},
    CurrentCreatorTab = 1,
    --GUI = PlayerGui:WaitForChild("CharacterGui"),
    ui = {
        container = {
            background = nil,
            menuOptions = {
                playTab = {
                    button = nil
                },
                rankedTab = {
                    button = nil
                },
                creditsTab = {
                    button = nil
                }
            }
        },
        main = {
            playThing = nil,
            background = nil,
            textLabel = nil
        },
        overlays = {
            black = nil,
            red = nil,
            main = nil
        },
        creditsContainer = {
            actualTab = {
                overlay = nil,
                creditsText = nil,
                scrollingFrame = nil
            },
            backTab = {
                button = nil
            }
        },
        slotContainer = {
            backTab = {
                button = nil
            },
            scrollingFrame = {
                buyButton = nil
            }
        },
        characterCreator = {
            mainFrame = {
                frame = {
                    currentOptionName = nil
                },
                navigationButtons = {
                    right = nil,
                    left = nil
                },
                soulSigil = {
                    firstName = {
                        searchKey = nil,
                        title = nil,
                        scrollingFrame = nil
                    },
                    lastName = {
                        searchKey = nil,
                        title = nil,
                        scrollingFrame = nil
                    }
                },
                heritageAndForm = {
                    raceName = nil,
                    raceDescription = nil,
                    bodyTypes = nil,
                    rerollButton = nil
                },
                embellishments = {
                    uiList = nil
                },
                chosenRelic = {
                    relics = {
                        greatsword = nil,
                        sword = nil,
                        dagger = nil
                    }
                },
                aetherTattoos = {
                    uiList = nil
                },
                fleshAndForm = {
                    scrollingFrame = nil,
                    selection = nil
                }
            },
            confirmButton = nil
        }
    }
}

--[[ Events ]]
CharacterController.Events = {
    Select = true,
    Create = true,
    Load = true,
    Customize = true
}

--[[ Listeners ]]
CharacterController.Listeners = {
    ["Player.CharacterAdded"] = function(self, character)
        Camera.CameraSubject = character:WaitForChild("Humanoid")
    end,

    ["Character.Customize"] = function(self, data)
        self:ShowCharacter(data.potentialFullName, data.slotsAvailable)
    end,

    ["Character.Load"] = function(self)
        local newChar = Player.Character or Player.CharacterAdded:Wait()
        Camera.CameraSubject = newChar:WaitForChild("Humanoid")
    end
}

--[[ Core Functions ]]
function CharacterController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function CharacterController:Start()
    return true
end

--[[ Interface Functions ]]
function CharacterController:ShowCharacter(potentialFullName, slotsAvailable)
    self:SetupInterface()
    self:SetupElements(potentialFullName, slotsAvailable)
end

function CharacterController:SetupInterface()
    local overlays = {
        State.ui.overlays.main,
        State.ui.overlays.red,
        State.ui.overlays.black
    }

    for _, overlay in ipairs(overlays) do
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.Visible = true
    end

    State.ui.main.playThing.Visible = true
    State.ui.container.Visible = false

    Utility.Controller.Tween(State.ui.overlays.black, {BackgroundTransparency = 1})
    Utility.Controller.Tween(State.ui.main.playThing, {TextTransparency = 0})

    local buttons = {
        State.ui.container.menuOptions.playTab.button,
        State.ui.container.menuOptions.creditsTab.button,
        State.ui.container.menuOptions.rankedTab.button,
        State.ui.creditsContainer.backTab.button,
        State.ui.slotContainer.backTab.button
    }

    for _, button in ipairs(buttons) do
        self:SetupButton(button)
    end

    self:SetupNavigation()
    self:SetupCredits()
end

function CharacterController:SetupElements(potentialFullName, slotsAvailable)
    local playerCharacter = self:CreatePlayer()
    self:ConfigureCamera()
    self:SetupSlots(potentialFullName, slotsAvailable)
end

function CharacterController:CreatePlayer()
    local playerCharacter = ReplicatedStorage:WaitForChild("PlayerCharacter"):Clone()
    playerCharacter.Parent = workspace

    State.IdleAnimation = playerCharacter.Humanoid:LoadAnimation(playerCharacter.IdleDown)
    State.IdleAnimation:Play()

    local playerReference = ReplicatedStorage:WaitForChild("PlayerReferences"):WaitForChild(Player.Name)
    for _, accessory in pairs(playerReference:GetChildren()) do
        if accessory:IsA("Accessory") and accessory:WaitForChild("Handle"):FindFirstChild("HairAttachment") then
            local clone = accessory:Clone()
            clone.Parent = playerCharacter

            local handle = clone:WaitForChild("Handle")
            handle:FindFirstChildWhichIsA("SpecialMesh").TextureId = ""
            handle.Color = Color3.fromRGB(255, 255, 255)
            handle.CFrame = playerReference:WaitForChild("Head").CFrame
            handle:WaitForChild("AccessoryWeld").Part1 = playerCharacter.Head
        end
    end

    local bodyColors = playerReference:WaitForChild("Body Colors"):Clone()
    for _, bodyPartEnum in ipairs(Enum.BodyPart:GetEnumItems()) do
        bodyColors[bodyPartEnum.Name.."Color3"] = Color3.fromRGB(255, 255, 255)
    end
    bodyColors.Parent = playerCharacter

    return playerCharacter
end

function CharacterController:ValidateData(characterData)
    if not characterData then return false end

    if not characterData.FirstName or characterData.FirstName == "" then return false end
    if not characterData.LastName or characterData.LastName == "" then return false end
    if not characterData.Race or characterData.Race == "" then return false end
    if not characterData.BodyType or characterData.BodyType == "" then return false end
    if not characterData.Relic or characterData.Relic == "" then return false end

    return true
end

function CharacterController:ConfigureCamera()
    local cameraPoints = {
        Main = workspace:WaitForChild("MainCamera"),
        Creator = workspace:WaitForChild("CreatorCamera")
    }

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = cameraPoints.Main.CFrame
    Camera.FieldOfView = cameraPoints.Main:GetAttribute("FOV")
end

function CharacterController:SetupNavigation()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and State.ui.main.playThing.Visible and input.KeyCode == Enum.KeyCode.Space then
            self:DisplayMenu()
        end
    end)

    self:SetupTransition(
        State.ui.container.menuOptions.playTab.button,
        State.ui.container,
        State.ui.slotContainer,
        State.ui.slotContainer.backTab
    )

    self:SetupTransition(
        State.ui.slotContainer.backTab.button,
        State.ui.slotContainer,
        State.ui.container,
        nil,
        true
    )

    self:SetupTransition(
        State.ui.container.menuOptions.creditsTab.button,
        State.ui.container,
        State.ui.creditsContainer,
        State.ui.creditsContainer.backTab
    )

    self:SetupTransition(
        State.ui.creditsContainer.backTab.button,
        State.ui.creditsContainer,
        State.ui.container,
        nil,
        true
    )

    State.ui.characterCreator.confirmButton.MouseButton1Click:Connect(function()
        if State.ui.characterCreator.confirmButton.Text == "Are you sure?" then
            if not self:ValidateData(State.CharacterData) then
                State.ui.characterCreator.confirmButton.Text = "Confirm"
                return
            end

            self:SubmitCharacter()
        else
            State.ui.characterCreator.confirmButton.Text = "Are you sure?"
        end
    end)
end

function CharacterController:SetupTransition(button, fromContainer, toContainer, tab, isBackButton)
    button.MouseButton1Click:Connect(function()
        Utility.Sound.Button("Click")
        self:TransitionScreen(0, 0.35, function()
            task.wait(0.35)
            fromContainer.Visible = false
            toContainer.Visible = true

            if tab then
                tab.Interactable = true
                tab.Visible = true
            end

            if isBackButton and tab then
                tab.Interactable = false
                tab.Visible = false
            end

            self:TransitionScreen(1, 0.35)
        end)
    end)
end

function CharacterController:SetupButton(button)
    if not button or not button.Visible then return end

    button.MouseEnter:Connect(function()
        Utility.Sound.Button("Hover")
        Utility.Controller.Tween(button, {TextTransparency = 0}, {
            duration = 0.2,
            easingStyle = Utility.Controller.Easing.Sine
        })
    end)

    button.MouseLeave:Connect(function()
        Utility.Controller.Tween(button, {TextTransparency = 0.3}, {
            duration = 0.2,
            easingStyle = Utility.Controller.Easing.Sine
        })
    end)
end

function CharacterController:SetupCredits()
    for name, credits in pairs(Modules.Credit.Credits) do
        local tab = script.TabExample:Clone()
        tab.Text = "- "..name.." -"
        tab.Parent = State.ui.creditsContainer.actualTab.scrollingFrame

        for _, credit in pairs(credits) do
            local entry = script.TextExample:Clone()
            entry.Text = Modules.Credit:GetFormat(credit)
            entry.Parent = tab.Frame
        end
    end
end

function CharacterController:SetupSlots(potentialFullName, slotsAvailable)
    State.CharacterData = {
        Relic = "",
        Ornament = "",
        ["Facial Marking"] = "",
        Face = "",
        Hair = ""
    }

    for i = 1, slotsAvailable do
        local hasExistingCharacter = potentialFullName and potentialFullName[i] ~= ""
        local slotTab = script.SlotTab:Clone()
        slotTab.Parent = State.ui.slotContainer.scrollingFrame
        slotTab.Name = slotTab.Name..i
        slotTab.SlotName.Text = string.upper(Alphabet:sub(i, i))..(hasExistingCharacter and ": "..potentialFullName[i] or ": ???")

        slotTab.MouseButton1Click:Connect(function()
            self:SelectSlot(i, hasExistingCharacter)
        end)
    end

    State.ui.slotContainer.scrollingFrame.buyButton.MouseButton1Click:Connect(function()
        warn("Character slot purchase is not implemented yet")
    end)
end

function CharacterController:SelectSlot(slotId, hasExistingCharacter)
    Utility.Controller.Tween(Camera, {
        CFrame = workspace:WaitForChild("CreatorCamera").CFrame,
        FieldOfView = workspace:WaitForChild("CreatorCamera"):GetAttribute("FOV")
    }, {duration = 1})

    State.ui.overlays.main.Visible = false
    State.ui.overlays.red.Visible = false
    State.ui.slotContainer.Visible = false
    State.IdleAnimation:Stop()

    if hasExistingCharacter then
        Controllers.Event:FireServer("Character.Load", slotId)
        return
    end

    State.CharacterData.Slot = slotId
    State.ui.characterCreator.Visible = true

    workspace.PlayerCharacter.Humanoid:LoadAnimation(workspace.PlayerCharacter.TurnAnim):Play()
    workspace.PlayerCharacter.Humanoid:LoadAnimation(workspace.PlayerCharacter.IdleLook):Play()

    task.wait(0.5)
    Utility.Controller.Tween(State.ui.characterCreator.mainFrame, {Position = UDim2.new(0.176, 0, 0.442, 0)}, {duration = 0.5})
    Utility.Controller.Tween(State.ui.characterCreator.confirmButton, {Position = UDim2.new(0.5, 0, 0.943, 0)}, {duration = 0.5})

    self:SetupCreator()
end

function CharacterController:SetupCreator()
    State.CurrentCreatorTab = 1

    State.ui.characterCreator.mainFrame.frame.currentOptionName.Text = CharacterController.FrameNames[CharacterController.Frames[State.CurrentCreatorTab]]
    self:SetupRace()
    self:SetupTab()
    self:SetupInteract()
    self:SetupContent()

    State.ui.characterCreator.mainFrame[CharacterController.Frames[State.CurrentCreatorTab]].Visible = false
    State.ui.characterCreator.mainFrame[CharacterController.Frames[State.CurrentCreatorTab]].Visible = true
end

function CharacterController:SetupRace()
    local raceIndex = Modules.Race.RaceIndex
    local raceTable = Modules.Race.Races
    local newRace = raceIndex[math.random(#raceIndex)]

    State.ui.characterCreator.mainFrame.heritageAndForm.raceName.Text = newRace
    State.ui.characterCreator.mainFrame.heritageAndForm.raceDescription.Text = raceTable[newRace]
    State.CharacterData.Race = newRace

    State.ui.characterCreator.mainFrame.heritageAndForm.rerollButton.MouseButton1Click:Connect(function()
        Utility.Sound.Button("Click")
        self:RerollRace()
    end)
end

function CharacterController:RerollRace()
    local previousRace = State.ui.characterCreator.mainFrame.heritageAndForm.raceName.Text
    local raceIndex = Modules.Race.RaceIndex
    local raceTable = Modules.Race.Races

    local newRace = raceIndex[math.random(#raceIndex)]

    if newRace == previousRace then
        repeat
            newRace = raceIndex[math.random(#raceIndex)]
        until newRace ~= previousRace
    end

    State.ui.characterCreator.mainFrame.heritageAndForm.raceName.Text = newRace
    State.ui.characterCreator.mainFrame.heritageAndForm.raceDescription.Text = raceTable[newRace]
    State.CharacterData.Race = newRace
end

function CharacterController:SetupTab()
    State.ui.characterCreator.mainFrame.navigationButtons.left.MouseButton1Click:Connect(function()
        self:NavigateCreator(-1)
    end)

    State.ui.characterCreator.mainFrame.navigationButtons.right.MouseButton1Click:Connect(function()
        self:NavigateCreator(1)
    end)
end

function CharacterController:SetupInteract()
    self:SetupName()
    self:SetupBody()
    self:SetupWeapon()
    self:SetupSearch()
end

function CharacterController:SetupName()
    local firstNames = Modules.Name.FirstName
    local lastNames = Modules.Name.LastName

    local nameData = {
        ["firstName"] = firstNames,
        ["lastName"] = lastNames
    }

    for namePair, nameList in pairs(nameData) do
        for _, name in pairs(nameList) do
            local nameButton = script.NameButton:Clone()
            nameButton.Text = name
            nameButton.Name = name.."NameButton"
            nameButton.Parent = State.ui.characterCreator.mainFrame.soulSigil[namePair].scrollingFrame
            nameButton.FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json")
            nameButton.TextColor3 = Color3.fromRGB(0, 0, 0)

            nameButton.MouseButton1Click:Connect(function()
                Utility.Sound.Button("Click")
                self:SelectName(namePair, name, nameButton)
            end)
        end
    end
end

function CharacterController:SelectName(namePair, name, selectedButton)
    for _, button in pairs(selectedButton.Parent:GetChildren()) do
        if button:IsA("TextButton") then
            Utility.Controller.Tween(button, {
                TextColor3 = Color3.fromRGB(64, 64, 64),
                TextTransparency = 0.25
            }, {duration = 0.5})
        end
    end

    State.CharacterData[namePair] = name

    Utility.Controller.Tween(selectedButton, {
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0,
        TextStrokeTransparency = 0
    }, {duration = 0.5})
end

function CharacterController:SetupBody()
    for _, bodyButton in pairs(State.ui.characterCreator.mainFrame.heritageAndForm.bodyTypes:GetChildren()) do
        if bodyButton:IsA("ImageButton") then
            bodyButton.MouseButton1Click:Connect(function()
                Utility.Sound.Button("Click")
                self:SelectBody(bodyButton)
            end)
        end
    end
end

function CharacterController:SelectBody(selectedButton)
    for _, button in pairs(State.ui.characterCreator.mainFrame.heritageAndForm.bodyTypes:GetChildren()) do
        if button:IsA("ImageButton") then
            button.Image = "rbxassetid://83311654253717"
        end
    end

    selectedButton.Image = "rbxassetid://94971188832378"
    State.CharacterData.BodyType = selectedButton:FindFirstChildWhichIsA("TextLabel").Text
end

function CharacterController:SetupWeapon()
    for _, select in pairs(State.ui.characterCreator.mainFrame.chosenRelic.relics:GetChildren()) do
        if select:IsA("ImageButton") then
            local weaponName = string.gsub(select.Name, "Relic", "")
            select:WaitForChild("HoverText").Text = weaponName

            select.MouseEnter:Connect(function()
                Utility.Sound.Button("Hover")
                Utility.Controller.Tween(select:WaitForChild("HoverText"), {
                    TextTransparency = 0,
                    Position = UDim2.new(0, 0, 1, 0)
                }, {duration = 0.25})
            end)

            select.MouseLeave:Connect(function()
                Utility.Controller.Tween(select:WaitForChild("HoverText"), {
                    TextTransparency = 0.2,
                    Position = UDim2.new(0, 0, 0.5, 0)
                }, {duration = 0.25})
            end)

            select.MouseButton1Click:Connect(function()
                Utility.Sound.Button("Click")
                self:SelectWeapon(select, weaponName)
            end)
        end
    end
end

function CharacterController:SelectWeapon(button, weaponName)
    button:WaitForChild("HoverText").TextStrokeTransparency = 0
    Utility.Controller.Tween(button:WaitForChild("HoverText"), {TextStrokeTransparency = 1}, {duration = 0.5})
    State.CharacterData.Relic = weaponName
end

function CharacterController:SetupSearch()
    for _, search in pairs(State.ui.characterCreator.mainFrame.soulSigil:GetChildren()) do
        if search.Name:find("Name") and search:FindFirstChild("SearchKey") then
            local searchBar = search:FindFirstChild("SearchKey")

            searchBar:GetPropertyChangedSignal("Text"):Connect(function()
                self:FilterName(searchBar)
            end)
        end
    end
end

function CharacterController:FilterName(searchBar)
    local inputText = string.lower(searchBar.Text)

    for _, button in pairs(searchBar.Parent:FindFirstChildWhichIsA("ScrollingFrame"):GetChildren()) do
        if button:IsA("TextButton") then
            button.Visible = string.find(string.lower(button.Text), inputText, 1, true) ~= nil
        end
    end
end

function CharacterController:SetupContent()
    State.ui.characterCreator.mainFrame.fleshAndForm:GetPropertyChangedSignal("Visible"):Connect(function()
        if State.ui.characterCreator.mainFrame.fleshAndForm.Visible then
            self:LoadSkin()
        end
    end)

    State.ui.characterCreator.mainFrame.aetherTattoos:GetPropertyChangedSignal("Visible"):Connect(function()
        if State.ui.characterCreator.mainFrame.aetherTattoos.Visible then
            self:LoadMarking()
        end
    end)

    State.ui.characterCreator.mainFrame.embellishments:GetPropertyChangedSignal("Visible"):Connect(function()
        if State.ui.characterCreator.mainFrame.embellishments.Visible then
            self:LoadOrnaments()
        end
    end)
end

function CharacterController:LoadSkin()
    local parentFrame = State.ui.characterCreator.mainFrame.fleshAndForm.scrollingFrame
    self:ClearChildren(parentFrame, "Frame")

    for _, colorName in ipairs(Modules.Body.SkinIndex) do
        local tab = script.SkinColorTemplate:Clone()
        tab.Name = colorName
        tab.ColorButton.BackgroundColor3 = Color3.fromHex(Modules.Body.SkinColors[colorName])
        tab.Parent = parentFrame

        tab.ColorButton.MouseButton1Click:Connect(function()
            Utility.Sound.Button("Click")
            self:SelectSkin(colorName, parentFrame.Parent.selection)
        end)
    end
end

function CharacterController:SelectSkin(colorName, selectionLabel)
    State.CharacterData.SkinColor = Modules.Body.SkinColors[colorName]
    selectionLabel.Text = colorName

    local bodyColor = workspace.PlayerCharacter:WaitForChild("Body Colors")
    local selectedColor = Color3.fromHex(Modules.Body.SkinColors[colorName])

    for _, bodyPartEnum in ipairs(Enum.BodyPart:GetEnumItems()) do
        bodyColor[bodyPartEnum.Name.."Color3"] = selectedColor
    end
end

function CharacterController:LoadMarking()
    local parentFrame = State.ui.characterCreator.mainFrame.aetherTattoos.uiList
    self:ClearChildren(parentFrame, "Frame")

    local raceFolder = ReplicatedStorage.Customization.FacialMarkings:WaitForChild(State.CharacterData.Race)

    for _, mark in pairs(raceFolder:GetChildren()) do
        local tab = script.HeadTemplate:Clone()
        tab.Name = "TattooTemplate"
        tab.Parent = parentFrame

        local clone = mark:Clone()
        clone.Parent = tab.ViewportFrame.Head

        self:SetupHead(tab, function()
            self:ApplyMarking(mark)
        end)
    end
end

function CharacterController:ApplyMarking(mark)
    if workspace.PlayerCharacter.Head:FindFirstChild("Marking") then
        workspace.PlayerCharacter.Head:FindFirstChild("Marking"):Destroy()
    end

    Utility.Sound.Button("Click")
    State.CharacterData["Facial Marking"] = mark.Name

    local decal = mark:Clone()
    decal.Parent = workspace.PlayerCharacter.Head
    decal.Name = "Marking"
end

function CharacterController:LoadOrnaments()
    local parentFrame = State.ui.characterCreator.mainFrame.embellishments
    self:ClearChildren(parentFrame, "Frame")

    local raceFolder = ReplicatedStorage.Customization.Ornaments:WaitForChild(State.CharacterData.Race)

    for _, ornament in pairs(raceFolder:GetChildren()) do
        local tab = script.HeadTemplate:Clone()
        tab.Name = "OrnamentTemplate"
        tab.Parent = parentFrame

        local clone = ornament:Clone()
        clone.Parent = tab.ViewportFrame.Head

        if ornament:FindFirstChildWhichIsA("Weld") then
            ornament:FindFirstChildWhichIsA("Weld").Part0 = tab.ViewportFrame.Head
        end

        self:SetupHead(tab, function()
            Utility.Sound.Button("Click")
            State.CharacterData.Ornament = ornament.Name
        end)
    end
end

function CharacterController:ClearChildren(parent, className)
    for _, item in pairs(parent:GetChildren()) do
        if not className or item:IsA(className) then
            item:Destroy()
        end
    end
end

function CharacterController:SetupHead(tab, clickCallback)
    local connection

    tab.HeadButton.MouseEnter:Connect(function()
        Utility.Sound.Button("Hover")

        connection = RunService.RenderStepped:Connect(function()
            local mouse = Player:GetMouse()
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            local framePos = tab.HeadButton.AbsolutePosition
            local frameSize = tab.HeadButton.AbsoluteSize

            local relativeX = (mousePos.X - framePos.X) / frameSize.X - 0.5
            local relativeY = (mousePos.Y - framePos.Y) / frameSize.Y - 0.5
            local lookDirection = Vector3.new(-relativeX * 2, relativeY * 2, -1):Unit()

            Utility.Controller.Tween(tab.ViewportFrame.Head, {
                CFrame = CFrame.lookAt(
                    tab.ViewportFrame.Head.Position, 
                    tab.ViewportFrame.Head.Position + lookDirection
                ) * CFrame.Angles(0, math.rad(180), 0)
            }, {duration = 0.2})
        end)
    end)

    tab.HeadButton.MouseLeave:Connect(function()
        connection:Disconnect()
        task.wait(0.2)
        Utility.Controller.Tween(tab.ViewportFrame.Head, {Orientation = Vector3.new(0, 180, 0)}, {duration = 0.3})
    end)

    tab.HeadButton.MouseButton1Click:Connect(clickCallback)
end

--[[ Character Creator Functions ]]
function CharacterController:NavigateCreator(direction)
    State.CurrentCreatorTab = State.CurrentCreatorTab + direction

    if State.CurrentCreatorTab <= 0 then
        State.CurrentCreatorTab = #CharacterController.Frames
    elseif State.CurrentCreatorTab > #CharacterController.Frames then
        State.CurrentCreatorTab = 1
    end

    for _, frame in pairs(State.ui.characterCreator.mainFrame:GetChildren()) do
        if frame:IsA("Frame") and not frame:HasTag("DonotRemove") then
            frame.Visible = (frame.Name == CharacterController.Frames[State.CurrentCreatorTab])
        end
    end

    local direction = (direction > 0) and 1 or -1
    local nameLabel = State.ui.characterCreator.mainFrame.frame.currentOptionName

    Utility.Controller.Tween(nameLabel, {Position = UDim2.new(0.62 * direction, 0, 0, 0)}, {
        duration = 0.15,
        easingStyle = Utility.Controller.Easing.Quad,
        easingDirection = Utility.Controller.Easing.In,
        onComplete = function()
            nameLabel.Text = CharacterController.FrameNames[CharacterController.Frames[State.CurrentCreatorTab]]
            nameLabel.Position = UDim2.new(-0.62 * direction, 0, 0, 0)

            Utility.Controller.Tween(nameLabel, {Position = UDim2.new(0, 0, 0, 0)}, {
                duration = 0.15,
                easingStyle = Utility.Controller.Easing.Quad,
                easingDirection = Utility.Controller.Easing.Out
            })
        end
    })
end

function CharacterController:SubmitCharacter()
    State.ui.characterCreator.mainFrame.Visible = false
    Utility.Controller.Tween(game.Lighting.Blur, {Size = 48}, {duration = 5})

    if State.MenuMusic then
        Utility.Controller.Tween(State.MenuMusic, {Volume = 0.1}, {duration = 5})
    end

    task.spawn(function()
        task.wait(5)
        workspace.PlayerCharacter:Destroy()
        Camera.CameraType = Enum.CameraType.Follow
        game.Lighting.Blur.Size = 0

        Controllers.Event:FireServer("Character.Create", State.CharacterData)
    end)
end

--[[ Utility Functions ]]
function CharacterController:DisplayMenu()
    Utility.Sound.Button("Click")

    local fadeOutConfig = {
        duration = 0.5,
        onComplete = function()
            State.main.playThing.Visible = false
            State.container.Visible = true

            task.spawn(function()
                for _, btn in ipairs({State.container.menuOptions.playTab.button, State.container.menuOptions.rankedTab.button, State.container.menuOptions.creditsTab.button}) do
                    Utility.Controller.Tween(btn.Parent, {ImageTransparency = 0}, {duration = 0.25})
                    Utility.Controller.Tween(btn, {TextTransparency = 0.3}, {duration = 0.25})
                    task.wait(0.075)
                    btn.Active = false
                end
            end)

            for _, btn in ipairs({State.container.menuOptions.playTab.button, State.container.menuOptions.rankedTab.button, State.container.menuOptions.creditsTab.button}) do
                local txtLbl = btn:FindFirstChildOfClass("TextLabel")
                if txtLbl then
                    Utility.Controller.Tween(txtLbl, {TextTransparency = 0}, {
                        duration = 0.5,
                        onComplete = function()
                            btn.Active = true
                        end
                    })
                    task.wait(0.15)
                end
            end
        end
    }

    Utility.Controller.Tween(State.main.playThing, {TextTransparency = 1}, fadeOutConfig)
end

function CharacterController:TransitionScreen(targetTransparency, duration, callback)
    local tween1 = Utility.Controller.Tween(State.overlays.main, {BackgroundTransparency = targetTransparency}, {
        duration = duration,
        easingStyle = Utility.Controller.Easing.Quad
    })

    local tween2 = Utility.Controller.Tween(State.overlays.red, {BackgroundTransparency = targetTransparency}, {
        duration = duration,
        easingStyle = Utility.Controller.Easing.Quad,
        onComplete = callback
    })
end

--[[ State Functions ]]
function CharacterController:GetCurrentSlot()
    return State.CurrentSlot
end

function CharacterController:GetCharacterData()
    return State.CharacterData
end

return CharacterController