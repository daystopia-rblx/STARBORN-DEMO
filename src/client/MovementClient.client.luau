--[[ MovementClient
    @author @Daystopia
    @version 1.1.1
    @date 2025-04-07
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--[[ Dependencies ]]
local Modules = {
    Animation = require(ReplicatedStorage.Modules.AnimationModule),
    Stat = require(ReplicatedStorage.Modules.StatModule)
}

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Tools = {
    Spring = require(ReplicatedStorage.Modules.Tool.Spring),
    Bezier = require(ReplicatedStorage.Modules.Tool.Bezier),
    Debug = require(ReplicatedStorage.Modules.Tool.Debug)
}

local Utility = {
    Animation = require(script.Parent.Utility.Animation),
    Input = require(script.Parent.Utility.Input),
    Camera = require(script.Parent.Utility.Camera),
    Particle = require(script.Parent.Utility.Particle),
    Sound = require(script.Parent.Utility.Sound)
}

--[[ Configuration ]]
local CONFIG = {
    VELOCITY = {
        FALL_DAMAGE_THRESHOLD = 65,
        HARD_LAND_THRESHOLD = 45,
        LARGE_FALL_THRESHOLD = 25
    },

    ANIMATION = {
        BLEND_TIME = {
            DEFAULT = 0.25,
            QUICK = 0.07
        }
    },

    CONTROLS = {
        DOUBLE_TAP_WINDOW = 0.25,
        IDLE_TIMEOUT = 0.8,
        CROUCH_KEY = Enum.KeyCode.C,
        SPRINT_KEY = Enum.KeyCode.LeftShift,
        RAGDOLL_KEY = Enum.KeyCode.R
    },

    ROLL = {
        SPEED = 32,
        DURATION = {
            FORWARD = 0.35,
            SIDE = 0.3
        },
        COOLDOWN = {
            FORWARD = 0.8,
            SIDE = 1.0
        },
        VERTICAL_FORCE = 0,
        CANCEL = {
            MIN_TIME = 0.12,
            CHAIN_WINDOW = 0.25,
            CHAIN_STAMINA_MULT = 1.35
        }
    },

    DASH = {
        FORCE = 95000,
        RESPONSIVENESS = 20,
        DISTANCE = 18,
        DURATION = 0.35,
        COOLDOWN = 0.4,
        VFX = {
            DURATION = 1.5,
            EMIT_ATTRIBUTE = "EmitCount"
        }
    },

    SLIDE = {
        SPEED = 28,
        DURATION = 0.8,
        COOLDOWN = 0.6,
        MIN_VELOCITY = 5,
        GROUND_FRICTION = 0.1,
        AIR_FRICTION = 0.05
    },

    LEDGE = {
        SHUFFLE_SPEED = 6,
        CHECK_DISTANCE = 1.5,
        WALL_MIN_HEIGHT = 6,
        HANG_DURATION = 5,
        CLIMB_SPEED = 8,
        DROP_COOLDOWN = 0.5,
        PUSH_FORCE = 10,
        JUMP_HORIZONTAL_FORCE = 100,
        JUMP_VERTICAL_FORCE = 50,
        WALL_JUMP_COOLDOWN = 1.0
    },

    WALL_RUN = {
        DURATION = 0.6,
        SUSTAIN = 0.25,
        COOLDOWN = 1.2,
        SPEED = 24,
        MIN_HEIGHT = 4,
        CHECK_DISTANCE = 1.2,
        ANGLE_THRESHOLD = 65,
        GRAVITY_FACTOR = 0.4,
        EXIT_BOOST = 100
    },

    VAULT = {
        MAX_HEIGHT = 4.2,
        MIN_HEIGHT = 0.5,
        CHECK_DISTANCE = 2.5,
        DURATION = 0.65,
        COOLDOWN = 0.4,
        BOOST_FORCE = 40,
        ANGLE_THRESHOLD = 45
    },

    CLIMB = {
        SPEED = 8,
        MAX_HEIGHT = 15,
        CHECK_DISTANCE = 1.8,
        COOLDOWN = 0.7,
        STAMINA_COST = 10,
        ANGLE_THRESHOLD = 80
    },
    SWING = {
        TIMING = {
            DURATION = 0.7,
            MAX_TIME = 6,
            COOLDOWN = 0.5,
            RECOVERY_TIME = 1.0,
            DETECT_COOLDOWN = 0.5,
        },

        DETECT = {
            RANGE = 12,
            INTERACT_RANGE = 4,
            ANGLE = 50,
            FOV = 85,
            HEIGHT_DIFFERENCE_MAX = 5,
            MAX_DISTANCE = 5,
        },

        MOVEMENT = {
            ROTATION_SPEED = 2.5,
            DISTANCE = 10,
            HEIGHT = 5,
            FORWARD_DISTANCE = 15,
            END_HEIGHT = 2,
            BOOST_FORCE = 65,
        },

        SURFACE = {
            MIN_DIMENSION = 0.5,
            LONG_THRESHOLD = 8,
            MIN_HEIGHT_REGULAR = 3,
            MIN_HEIGHT_LONG = 2,
            PROXIMITY_THRESHOLD = 1.0,
            DIRECTION_THRESHOLD = 0.7,
        },

        CHAIN = {
            WINDOW_START = 0.5,
            WINDOW_END = 0.9,
            HEIGHT_MULT = 1.2,
            FORWARD_MULT = 0.8,
            END_HEIGHT_MULT = 0.8,
            BOOST_UP_MULT = 0.5,
            BOOST_FWD_MULT = 0.7,
            DETECT_ANGLE_SPREAD = 75,
            DETECT_ANGLE_STEPS = 15,
            HEIGHT_OFFSETS = {-1, 0, 1, 2},
            MAX_RECENT_POINTS = 3,
        },

        VALIDATION = {
            MIN_WALL_HEIGHT = 7,
            MIN_SURFACE_DISTANCE = 2,
            MAX_SURFACE_DISTANCE = 20,
            MIN_GROUND_CLEARANCE = 2,
            MAX_CEILING_DISTANCE = 10,
            WALL_DOT_THRESHOLD = 0.7,
        },

        PHYSICS = {
            VELOCITY_BLEND = 0.8,
            MIN_EXIT_SPEED = 20,
            MAX_EXIT_SPEED = 80,
            GRAVITY_INFLUENCE = 0.3,
            ROTATION_SMOOTHING = 0.2,
            PATH_FOLLOW_SPEED = 30,
            PATH_CORRECTION_RATE = 20,
        }
    },

    CAMERA_SETTINGS = {
        FOV = 72,
        WALK_FOV = 72,
        SPRINT_FOV = 82,
        VAULT_FOV = 86,
        TRANSITION_TIME = 0.2,
        ZOOM = 12,
        MIN_ZOOM = 8,
        MAX_ZOOM = 14
    },

    CURSOR_CONFIG = {
        ENABLED = true,
        DEFAULT_CURSOR = "",
        OVERRIDE_DEFAULT = true
    },

    SHIFT_LOCK_CONFIG = {
        CHARACTER_ROTATION_SPEED = 5,
        CAMERA_TRANSITION_IN_SPEED = 16,
        CAMERA_TRANSITION_OUT_SPEED = 18,
        LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.3, 0),
        LOCKED_MOUSE_ICON = "http://www.roblox.com/asset/?id=7347416154",
        TRANSITION_SPRING_DAMPER = 0.7,
        CHARACTER_SMOOTH_ROTATION = true
    },

    UI_SETTINGS = {
        EMOTE_MENU = {
            FADE_DURATION = 0.2,
            DISPLAY_ORDER = 999998
        },
        DEATH_OVERLAY = {
            FADE_DURATION = 1.2,
            COLOR = Color3.fromRGB(0, 0, 0)
        }
    },

    RAGDOLL = {
        ATTACHMENT_CFRAMES = {
            ["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
            ["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
            ["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
            ["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
            ["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
        },

        INSTANCE_NAMES = {
            ["RagdollAttachment"] = true,
            ["RagdollConstraint"] = true,
            ["ColliderPart"] = true,
        },

        MAIN_PARTS = {
            "Torso", "UpperTorso", "LowerTorso",
            "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
            "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
            "Head"
        },

        IMPULSE_FORCE = 100,
        DURATION = 5
    },

    STATE_DEFINITIONS = {
        RUNNING = {
            attributeName = "RUNNING",
            fieldName = "isSprinting",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true,
                [Enum.HumanoidStateType.Jumping] = true,
                [Enum.HumanoidStateType.Freefall] = true,
                [Enum.HumanoidStateType.Landed] = true
            },
            setupFunction = nil,
            cleanupFunction = nil
        },
        CROUCHING = {
            attributeName = "CROUCHING",
            fieldName = "isCrouching",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true,
                [Enum.HumanoidStateType.Jumping] = true,
                [Enum.HumanoidStateType.Freefall] = true,
                [Enum.HumanoidStateType.Landed] = true
            },
            setupFunction = nil,
            cleanupFunction = nil
        },
        RAGDOLL = {
            attributeName = "RAGDOLL",
            fieldName = "isRagdoll",
            validHumanoidStates = {},
            setupFunction = "SetupRagdoll",
            cleanupFunction = "ResetRagdoll",
            humanoidState = Enum.HumanoidStateType.Ragdoll,
            endState = Enum.HumanoidStateType.GettingUp
        },
        ROLL = {
            attributeName = "ROLL",
            fieldName = "isRolling",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true,
                [Enum.HumanoidStateType.Jumping] = true,
                [Enum.HumanoidStateType.Freefall] = true,
                [Enum.HumanoidStateType.Landed] = true
            },
            setupFunction = "SetupRoll",
            cleanupFunction = nil
        },
        SLIDE = {
            attributeName = "SLIDE",
            fieldName = "isSliding",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true
            },
            setupFunction = "SetupSlide",
            cleanupFunction = nil
        },
        DASH = {
            attributeName = "DASH",
            fieldName = "isDashing",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Freefall] = true
            },
            setupFunction = "SetupDash",
            cleanupFunction = nil
        },
        VAULT = {
            attributeName = "VAULT",
            fieldName = "isVaulting",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true
            },
            setupFunction = "SetupVault",
            cleanupFunction = nil
        },
        CLIMB = {
            attributeName = "CLIMB",
            fieldName = "isClimbing",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true,
                [Enum.HumanoidStateType.Jumping] = true,
                [Enum.HumanoidStateType.Freefall] = true
            },
            setupFunction = nil,
            cleanupFunction = nil
        },
        WALL_RUN = {
            attributeName = "WALL_RUN",
            fieldName = "isWallRunning",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Freefall] = true
            },
            setupFunction = "SetupWall",
            cleanupFunction = nil
        },
        SWING = {
            attributeName = "SWING",
            fieldName = "isSwinging",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Freefall] = true
            },
            setupFunction = "SetupSwing",
            cleanupFunction = nil
        },
        LEDGE = {
            attributeName = "LEDGE",
            fieldName = "isLedgeHanging",
            validHumanoidStates = {
                [Enum.HumanoidStateType.Running] = true,
                [Enum.HumanoidStateType.RunningNoPhysics] = true,
                [Enum.HumanoidStateType.Jumping] = true,
                [Enum.HumanoidStateType.Freefall] = true
            },
            setupFunction = "SetupLedge",
            cleanupFunction = nil
        }
    }
}

--[[ State Definitions ]]
local STATE_ANIMATIONS = {
    [Enum.HumanoidStateType.Running] = {"LOCOMOTION", "WALK"},
    [Enum.HumanoidStateType.RunningNoPhysics] = {"LOCOMOTION", "WALK"},
    [Enum.HumanoidStateType.Jumping] = {"LOCOMOTION", "JUMP"},
    [Enum.HumanoidStateType.Freefall] = {"LOCOMOTION", "FALL"},
    [Enum.HumanoidStateType.Landed] = {"LANDING", "SMALL"},
    [Enum.HumanoidStateType.Swimming] = {"LOCOMOTION", "SWIM"},
    [Enum.HumanoidStateType.Climbing] = {"WALL", "CLIMB"},
    [Enum.HumanoidStateType.Seated] = {"LOCOMOTION", "IDLE"},
    [Enum.HumanoidStateType.Dead] = {"STATUS", "KNOCKED_IDLE"},
    [Enum.HumanoidStateType.GettingUp] = {"STATUS", "KNOCKED_RECOVER"},
    [Enum.HumanoidStateType.FallingDown] = {"STATUS", "PAIN_1"},
    [Enum.HumanoidStateType.Ragdoll] = {"STATUS", "PAIN_2"}
}

--[[ MovementClient Class ]]
local MovementClient = {}
MovementClient.LocalPlayer = Players.LocalPlayer

--[[ Private State ]]
local animState = {
    currentState = nil,
    animations = {},
    currentlyPlaying = { category = nil, name = nil }
}

local equipState = {
    isRunning = false,
    isWalking = false,
    isCrouching = false,
    isRagdoll = false,
    isHanging = false,
    isInAir = false,
    isClimbing = false,
    isVaulting = false,
    isRolling = false,
    isSliding = false
}

local movementState = {
    isSprinting = false,
    isCrouching = false,
    lastWTapTime = 0,
    isRagdoll = false,
    ragdollStartTime = 0,
    ragdollDuration = 0,
    isSliding = false,
    isVaulting = false,
    lastVerticalVelocity = 0,
    maxFallVelocity = 0
}

local keyStates = {
    W = false,
    A = false,
    S = false,
    D = false,
    C = false,
    Space = false
}

local humanoidRef = nil
local characterRef = nil
local inputHandler = nil

local cameraState = {
    isLocked = false,
    isShiftLocked = false,
    shiftLockOffset = Vector3.new(0, 0, 0),
    previousCameraType = nil,
    shiftLockConnection = nil,
    camOffsetSpring = nil,
    lastLookVector = Vector3.new(0, 0, 0)
}

local uiState = {
    emoteMenu = {
        enabled = false,
        frame = nil,
        scrollFrame = nil,
        isOpen = false
    },
    deathOverlay = {
        frame = nil,
        transparency = 1
    }
}

local footstepState = {
    lastFootstepTime = 0,
    lastMaterial = nil,
    currentSound = nil,
    isWalking = false,
    lastCrouchState = nil,
    lastSprintState = nil
}

local mechanicState = {
    lastMechanicTime = 0,
    cooldown = 0.1
}

--[[ Event Handlers ]]
MovementClient.Events = {
    ["Character.AttributeChanged"] = {
        handler = function(data)
            local stateData = nil

            for _, def in pairs(CONFIG.STATE_DEFINITIONS) do
                if def.attributeName == data.attribute then
                    stateData = def
                    break
                end
            end

            if not stateData then return end

            local fieldName = stateData.fieldName
            if not fieldName then return end

            if movementState[fieldName] ~= data.value then
                movementState[fieldName] = data.value

                if data.attribute == "RAGDOLL" then
                    if data.value then
                        MovementClient:SetupRagdoll()
                    else
                        MovementClient:ResetRagdoll()
                    end
                end

                MovementClient:UpdateMove()
            end
        end
    },

    ["Movement.State"] = {
        handler = function(data)
            if not data or not data.state then return end

            local state = data.state
            local value = data.value

            if state == "RUNNING" then
                return
            elseif state == "RAGDOLL" then
                duration = CONFIG.RAGDOLL.DURATION
            elseif state == "CLIMB" then
                duration = CONFIG.CLIMB.COOLDOWN
            elseif state == "ROLL" then
                duration = CONFIG.ROLL.COOLDOWN
            elseif state == "SLIDE" then
                duration = CONFIG.SLIDE.COOLDOWN
            elseif state == "VAULT" then
                duration = CONFIG.VAULT.COOLDOWN
            end

            local stateData = CONFIG.STATE_DEFINITIONS[state]
            if stateData and stateData.fieldName then
                movementState[stateData.fieldName] = value
                MovementClient:UpdateMove()
            end
        end
    }
}

--[[ Debug Config ]]
local DEBUG = {
    ENABLED = false,
    RATE_LIMIT = 0.5,
    SWING = {
        ENABLED = true,
        SHOW_POINTS = true,
        VALIDATION = false,
        RAYCAST = false,
        PATH = false,
        CHAIN = true,
    },
    VAULT = {
        ENABLED = false,
    },
    WALL_RUN = {
        ENABLED = false,
    },
}

local Debug = Tools.Debug.new(DEBUG)

--[[ Helper Functions ]]
function MovementClient:CheckStructures(part, checkType)
    local proximityParams = OverlapParams.new()
    proximityParams.FilterDescendantsInstances = {characterRef}
    proximityParams.FilterType = Enum.RaycastFilterType.Exclude

    local checks = {
        VAULT = function()
            local vaultHeight = 2.5
            local vaultDepth = 3

            local topClearanceCheck = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position + Vector3.new(0, vaultHeight/2, 0)),
                Vector3.new(part.Size.X + 1, vaultHeight, part.Size.Z + 1),
                proximityParams
            )

            local forwardClearanceCheck = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position + part.CFrame.LookVector * vaultDepth),
                Vector3.new(part.Size.X + 1, vaultHeight, 2),
                proximityParams
            )

            return #topClearanceCheck > 2 or #forwardClearanceCheck > 2
        end,

        SWING = function()
            local partSize = part.Size
            local maxDim = math.max(partSize.X, partSize.Z)
            local minDim = math.min(partSize.X, partSize.Z)

            if maxDim > 20 then
                local lookVec = characterRef.HumanoidRootPart.CFrame.LookVector
                local partLookVec = (part.Position - characterRef.HumanoidRootPart.Position).Unit
                local dot = math.abs(lookVec:Dot(partLookVec))

                if dot > 0.7 then
                    return true
                end
            end

            local partsAround = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position),
                Vector3.new(part.Size.X + 1, part.Size.Y, part.Size.Z + 1),
                proximityParams
            )

            local connectedWalls = 0
            for _, nearbyPart in ipairs(partsAround) do
                if nearbyPart ~= part and nearbyPart.Anchored then
                    local maxNearbyDim = math.max(nearbyPart.Size.X, nearbyPart.Size.Z)
                    if maxNearbyDim > 20 then
                        connectedWalls += 1
                    end
                end
            end

            return connectedWalls > 0
        end,

        CONNECTED = function()
            local partsAbove = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position + Vector3.new(0, part.Size.Y + 0.5, 0)),
                Vector3.new(part.Size.X + 1, 1, part.Size.Z + 1),
                proximityParams
            )

            local partsBelow = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position + Vector3.new(0, -part.Size.Y - 0.5, 0)),
                Vector3.new(part.Size.X + 1, 1, part.Size.Z + 1),
                proximityParams
            )

            local partsAround = workspace:GetPartBoundsInBox(
                CFrame.new(part.Position),
                Vector3.new(part.Size.X + 2, part.Size.Y, part.Size.Z + 2),
                proximityParams
            )

            local connectedParts = 0
            for _, nearbyPart in ipairs(partsAbove) do
                if nearbyPart ~= part and nearbyPart.Anchored then
                    connectedParts += 1
                end
            end
            for _, nearbyPart in ipairs(partsBelow) do
                if nearbyPart ~= part and nearbyPart.Anchored then
                    connectedParts += 1
                end
            end
            for _, nearbyPart in ipairs(partsAround) do
                if nearbyPart ~= part and nearbyPart.Anchored then
                    connectedParts += 1
                end
            end

            return connectedParts > 2
        end
    }

    if not checkType or not checks[checkType] then
        return checks.CONNECTED()
    end

    return checks[checkType]()
end

function MovementClient:CheckCollision(origin, direction, distance)
    if not self:ValidateCharacter() then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {characterRef}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local heightOffsets = {0, 0.5, 1.2}
    local collisionsAtHeight = {}
    local lastResult

    for _, heightOffset in ipairs(heightOffsets) do
        local rayOrigin = origin + Vector3.new(0, heightOffset, 0)
        local rayDistance = direction.Unit * (distance or 2)

        local result = workspace:Raycast(
            rayOrigin,
            rayDistance,
            params
        )

        if result then
            local angle = math.acos(result.Normal:Dot(Vector3.new(0, 1, 0)))
            if heightOffset == 0 and angle > 0.785 then
                return true, result
            elseif heightOffset > 0 and angle > 1.48 then
                collisionsAtHeight[heightOffset] = result
                lastResult = result
            end
        end
    end

    local numCollisions = 0
    for _ in pairs(collisionsAtHeight) do
        numCollisions += 1
    end

    if numCollisions >= 2 then
        return true, lastResult
    end

    if collisionsAtHeight[1.2] and not collisionsAtHeight[0.5] then
        return false
    end

    return false
end

function MovementClient:ValidateCharacter()
    local startTime = os.clock()
    local timeout = 3

    while not characterRef and (os.clock() - startTime) < timeout do
        characterRef = self.LocalPlayer.Character
        if characterRef then break end
        task.wait(0.1)
    end
    if not characterRef then return false end

    while not humanoidRef and (os.clock() - startTime) < timeout do
        humanoidRef = characterRef:FindFirstChild("Humanoid")
        if humanoidRef then break end
        task.wait(0.1)
    end
    if not humanoidRef then return false end

    while not characterRef:FindFirstChild("HumanoidRootPart") and (os.clock() - startTime) < timeout do
        task.wait(0.1)
    end
    if not characterRef:FindFirstChild("HumanoidRootPart") then return false end
    if not humanoidRef.Parent then return false end

    return true
end

--[[ Animation Functions ]]
function MovementClient:StopAnimation(categories)
    if not self:ValidateCharacter() then return end

    for _, category in ipairs(categories) do
        for animName, _ in pairs(Modules.Animation.Assets.Animations[category] or {}) do
            local success = Utility.Animation.Stop(animState.animations, category, animName, CONFIG.ANIMATION.BLEND_TIME.QUICK)
        end
    end
end

function MovementClient:PlayAnimation(category, name, blendTime, speed)
    if not self:ValidateCharacter() then return end
    blendTime = blendTime or CONFIG.ANIMATION.BLEND_TIME.DEFAULT

    if animState.currentlyPlaying.category == category and animState.currentlyPlaying.name == name then
        return
    end

    if category == "LOCOMOTION" then
        self:StopAnimation({"LOCOMOTION"})
    elseif category == "LANDING" then
        self:StopAnimation({"LANDING"})
    elseif category == "STATUS" then
        self:StopAnimation({"STATUS"})
    end

    Utility.Animation.Play(animState.animations, category, name, blendTime, speed)

    animState.currentlyPlaying.category = category
    animState.currentlyPlaying.name = name
end

function MovementClient:PlayState(humanoid, state)
    if not self:ValidateCharacter() then return end

    local animData = STATE_ANIMATIONS[state]
    if not animData then return end

    self:PlayAnimation(animData[1], animData[2])
end

function MovementClient:GetAnimations()
    local playing = {}
    for key, track in pairs(animState.animations) do
        if track and track.IsPlaying then
            table.insert(playing, key)
        end
    end
    return table.concat(playing, ", ")
end

--[[ Input Functions ]]
function MovementClient:SetupInput()
    if not self:ValidateCharacter() then return end

    if inputHandler then
        inputHandler.Disconnect()
        inputHandler = nil
    end

    local actions = {
        -- Movement
        Utility.Input.CreateAction("MoveForward", {Enum.KeyCode.W}, function(isActive)
            if isActive then
                local currentTime = os.clock()
                if currentTime - movementState.lastWTapTime < CONFIG.CONTROLS.DOUBLE_TAP_WINDOW then
                    if movementState.isCrouching then
                        self:SetState("CROUCHING", false)
                    end
                    self:SetState("RUNNING", true)
                end
                movementState.lastWTapTime = currentTime
            else
                if movementState.isSprinting then
                    self:SetState("RUNNING", false)
                end
            end

            keyStates.W = isActive
            self:UpdateMove()
            self:CheckState()
        end),

        Utility.Input.CreateAction("MoveLeft", {Enum.KeyCode.A}, function(isActive)
            keyStates.A = isActive
            self:UpdateMove()
            self:CheckState()
        end),

        Utility.Input.CreateAction("MoveBack", {Enum.KeyCode.S}, function(isActive)
            keyStates.S = isActive
            self:UpdateMove()
            self:CheckState()
        end),

        Utility.Input.CreateAction("MoveRight", {Enum.KeyCode.D}, function(isActive)
            keyStates.D = isActive
            self:UpdateMove()
            self:CheckState()
        end),

        -- Roll/Dash
        Utility.Input.CreateAction("Roll", {Enum.KeyCode.Q}, function(isActive)
            if not isActive then return end

            if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall or
               (self.swingState and self.swingState.isSwinging) then
                if self.airDashState then
                    self:StartDash()
                end
                return
            end

            if self.rollState and self.rollState.isRolling and self.rollState.cancel then
                self:CancelRoll()
                return
            end

            local direction = "forward"
            if keyStates.S then
                direction = "backward"
            elseif keyStates.A then
                direction = "left"
            elseif keyStates.D then
                direction = "right"
            end

            self:StartRoll(direction)
        end),

        -- Emergency Exit
        Utility.Input.CreateAction("ExitMechanic", {Enum.KeyCode.F}, function(isActive)
            if not isActive then return end

            if self.ledgeState and self.ledgeState.isClimbing then
                self:DropLedge()
                return
            end

            if self.swingState and self.swingState.isSwinging then
                self:EndSwing()
                return
            end

            if self.vaultState and self.vaultState.isVaulting then
                if characterRef and characterRef.HumanoidRootPart then
                    characterRef.HumanoidRootPart.Anchored = false
                end
                self.vaultState.isVaulting = false
                movementState.isVaulting = false
                if workspace.CurrentCamera then
                    Utility.Camera.FOV(workspace.CurrentCamera, CONFIG.CAMERA_SETTINGS.FOV, 0.15)
                end
                self:UpdateMove()
                return
            end

            if self.wallRunState and self.wallRunState.isWallRunning then
                self:StopWall()
                return
            end
        end),

        -- Crouch
        Utility.Input.CreateAction("Crouch", {CONFIG.CONTROLS.CROUCH_KEY}, function(isActive)
            keyStates.C = isActive

            if isActive then
                if movementState.isSprinting then
                    self:SetState("RUNNING", false)
                end
                self:ToggleCrouch()
            end
        end, {throttle = 0.2}),

        -- Slide
        Utility.Input.CreateAction("Slide", {Enum.KeyCode.LeftControl}, function(isActive)
            if isActive and keyStates.W and movementState.isSprinting and not movementState.isRagdoll then
                self:StartSlide()
            end
        end),

        -- Ragdoll
        Utility.Input.CreateAction("Ragdoll", {CONFIG.CONTROLS.RAGDOLL_KEY}, function(isActive)
            if not isActive then return end

            if movementState.isRagdoll then
                movementState.ragdollDuration = 0
                movementState.ragdollStartTime = 0

                humanoidRef:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoidRef:ChangeState(Enum.HumanoidStateType.GettingUp)

                task.delay(0.05, function()
                    if self:ValidateCharacter() then
                        self:ResetRagdoll()
                        self:SetState("RAGDOLL", false)
                        self:PlayAnimation("LOCOMOTION", "IDLE")
                    end
                end)
            else
                self:StartRagdoll(CONFIG.RAGDOLL.DURATION)
            end
        end),

        -- Emotes
        Utility.Input.CreateAction("Emotes", {Enum.KeyCode.T}, function(isActive)
            if isActive then
                self:ToggleEmotes()
            end
        end, {throttle = 0.3}),

        -- Jump/Ledge
        Utility.Input.CreateAction("Jump", {Enum.KeyCode.Space}, function(isActive)
            keyStates.Space = isActive

            if isActive then
                if movementState.isCrouching then
                    self:SetState("CROUCHING", false)
                elseif self.ledgeState then
                    if self.ledgeState.isWallJumping and humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
                        self:JumpLedge()
                    elseif self.ledgeState.isClimbing then
                        self:DropLedge()
                    end
                end
            end
        end),

        -- Shift Lock
        Utility.Input.CreateAction("ShiftLock", {Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift}, function(isActive)
            if isActive and humanoidRef and humanoidRef.Health > 0 then
                self:ToggleShiftLock()
            end
        end),

        -- Wall Run
        Utility.Input.CreateAction("WallRunLeft", {}, function(isActive)
            if isActive and keyStates.Space and humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
                self:StartWall("left")
            end
        end),

        Utility.Input.CreateAction("WallRunRight", {}, function(isActive)
            if isActive and keyStates.Space and humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
                self:StartWall("right")
            end
        end),
    }

    local inputConfig = {
        id = "movement",
        actions = actions,
        mouseEnabled = true,
        keyboardEnabled = true,
        gamepadEnabled = true,
        touchEnabled = false,
        requireGameFocus = true
    }

    inputHandler = Utility.Input.HandleInput(inputConfig)
end

--[[ State Management ]]
function MovementClient:ProcessState(humanoid, oldState, newState)
    if not self:ValidateCharacter() then return end

    animState.currentState = newState

    if movementState.isCrouching and (
        newState == Enum.HumanoidStateType.Jumping or
        newState == Enum.HumanoidStateType.Freefall or
        newState == Enum.HumanoidStateType.Swimming or
        newState == Enum.HumanoidStateType.Climbing
    ) then
        self:SetState("CROUCHING", false)
    end

    if oldState == Enum.HumanoidStateType.Climbing and newState ~= Enum.HumanoidStateType.Climbing then
        self:StopAnimation({"WALL"})
    elseif newState == Enum.HumanoidStateType.Climbing then
        local isMoving = keyStates.W or keyStates.S or keyStates.A or keyStates.D

        self:StopAnimation({"WALL"})
        self:PlayAnimation("WALL", isMoving and "CLIMB" or "HOLD")
        return
    end

    for stateName, stateData in pairs(CONFIG.STATE_DEFINITIONS) do
        local fieldName = stateData.fieldName
        if fieldName and movementState[fieldName] then
            if stateData.validHumanoidStates and next(stateData.validHumanoidStates) and not stateData.validHumanoidStates[newState] then
                self:SetState(stateName, false)
            end
        end
    end

    local ragdollData = CONFIG.STATE_DEFINITIONS.RAGDOLL
    if newState == ragdollData.humanoidState and not movementState[ragdollData.fieldName] then
        if movementState.isCrouching then
            self:SetState("CROUCHING", false)
        end
        if cameraState.isShiftLocked then
            self:ToggleShiftLock()
        end
        self:SetState("RAGDOLL", true)
    elseif oldState == ragdollData.humanoidState and movementState[ragdollData.fieldName] and newState == ragdollData.endState then
        self:SetState("RAGDOLL", false)
    end

    if newState == Enum.HumanoidStateType.Landed then
        if self.airDashState and self.airDashState.isDashing then
            self:StopAnimation({"SPECIAL", "AIR_DASH"})
            self.airDashState.isDashing = false
        end

        if oldState == Enum.HumanoidStateType.Freefall then
            self:ProcessLanding(humanoid)
        end
    else
        self:PlayState(humanoid, newState)
    end

    for emoteName, _ in pairs(Modules.Animation.Assets.Animations.EMOTES or {}) do
        local animKey = "EMOTES_" .. emoteName
        if animState.animations[animKey] and animState.animations[animKey].IsPlaying then
            self:StopAnimation({"EMOTES"})
            self:PlayAnimation("LOCOMOTION", "IDLE")
            break
        end
    end
end

function MovementClient:CheckState()
    if not self:ValidateCharacter() then return end

    local currentState = humanoidRef:GetState()
    if currentState == Enum.HumanoidStateType.Climbing or currentState == Enum.HumanoidStateType.Swimming then
        self:ProcessState(humanoidRef, currentState, currentState)
    end
end

function MovementClient:ProcessLanding(humanoid)
    local fallSpeed = humanoid.RootPart and math.abs(humanoid.RootPart.Velocity.Y) or 0
    movementState.maxFallVelocity = 0

    if self.swingState and self.swingState.wasSwinging then
        local landingDelay = os.clock() - (self.swingState.swingEndTime or 0)
        if landingDelay < 2.0 then
            local currentVel = humanoid.RootPart.AssemblyLinearVelocity
            humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, currentVel.Y, 0)
        end
        self.swingState.wasSwinging = false
        self.swingState.swingEndTime = nil
    end

    if self.airDashState and self.airDashState.isDashing then
        self:StopAnimation({"SPECIAL", "AIR_DASH"})
        self.airDashState.isDashing = false
    end

    Utility.Animation.Stop(animState.animations, "LOCOMOTION", "FALL", CONFIG.ANIMATION.BLEND_TIME.QUICK)

    if movementState.isSprinting and keyStates.W then
        self:PlayAnimation("LOCOMOTION", "SPRINT")
        return
    end

    local landCategory = "LANDING"
    local landAnim

    if fallSpeed > CONFIG.VELOCITY.HARD_LAND_THRESHOLD then
        landAnim = "HURT_LOTS"
        Services.Event:FireServer("Client.Movement.Fall", {
            velocity = fallSpeed,
            severity = "high"
        })
    elseif fallSpeed > CONFIG.VELOCITY.FALL_DAMAGE_THRESHOLD then
        landAnim = "HURT"
        Services.Event:FireServer("Client.Movement.Fall", {
            velocity = fallSpeed,
            severity = "medium"
        })
    elseif fallSpeed > CONFIG.VELOCITY.LARGE_FALL_THRESHOLD then
        landAnim = "LARGE"
    else
        landAnim = "SMALL"
    end

    self:PlayAnimation(landCategory, landAnim, CONFIG.ANIMATION.BLEND_TIME.QUICK)

    local landingTrack = animState.animations[landCategory .. "_" .. landAnim]
    if landingTrack then
        landingTrack.Stopped:Connect(function()
            if animState.currentState == Enum.HumanoidStateType.Running or
               animState.currentState == Enum.HumanoidStateType.RunningNoPhysics then
                self:PlayState(humanoid, animState.currentState)

                if keyStates.W then
                    self:SetState("RUNNING", true)
                end
            end
        end)
    end
end

function MovementClient:UpdateMove()
    if not self:ValidateCharacter() then return end
    if animState.currentState ~= Enum.HumanoidStateType.Running and
       animState.currentState ~= Enum.HumanoidStateType.RunningNoPhysics then
        return
    end

    local isMoving = keyStates.W or keyStates.A or keyStates.S or keyStates.D
    local targetAnim
    local targetFOV = CONFIG.CAMERA_SETTINGS.FOV

    footstepState.isWalking = isMoving and not movementState.isSliding and not movementState.isRolling

    if not isMoving then
        targetAnim = movementState.isCrouching and "CROUCH_IDLE" or "IDLE"
        targetFOV = CONFIG.CAMERA_SETTINGS.WALK_FOV
    else
        if movementState.isCrouching then
            targetAnim = "CROUCH_WALK"
            targetFOV = CONFIG.CAMERA_SETTINGS.WALK_FOV
        elseif movementState.isSprinting then
            targetAnim = "SPRINT"
            targetFOV = CONFIG.CAMERA_SETTINGS.SPRINT_FOV
        else
            targetAnim = "WALK"
            targetFOV = CONFIG.CAMERA_SETTINGS.WALK_FOV
        end
    end

    if animState.currentlyPlaying.category ~= "LOCOMOTION" or animState.currentlyPlaying.name ~= targetAnim then
        self:PlayAnimation("LOCOMOTION", targetAnim)
    end

    local camera = workspace.CurrentCamera
    if camera and camera.FieldOfView ~= targetFOV then
        Utility.Camera.FOV(camera, targetFOV, CONFIG.CAMERA_SETTINGS.TRANSITION_TIME)
    end
end

function MovementClient:CheckMove()
    if not self:ValidateCharacter() then return end

    task.spawn(function()
        while self:ValidateCharacter() do
            self:UpdateMove()
            self:UpdateFootsteps()

            if movementState.isRagdoll and movementState.ragdollDuration > 0 then
                local currentTime = os.clock()
                if currentTime - movementState.ragdollStartTime >= movementState.ragdollDuration then
                    movementState.ragdollDuration = 0
                    movementState.ragdollStartTime = 0

                    humanoidRef:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    humanoidRef:ChangeState(Enum.HumanoidStateType.GettingUp)

                    task.delay(0.05, function()
                        if self:ValidateCharacter() and movementState.isRagdoll then
                            self:ResetRagdoll()
                            self:SetState("RAGDOLL", false)
                            self:PlayAnimation("LOCOMOTION", "IDLE")
                        end
                    end)
                end
            end

            task.wait(0.1)
        end
    end)
end

function MovementClient:SetState(stateName, value)
    local stateData = CONFIG.STATE_DEFINITIONS[stateName]
    if not stateData then return end

    local fieldName = stateData.fieldName
    if not fieldName then return end

    if movementState[fieldName] == value then return end

    if value and stateData.setupFunction then
        local setupFunc = self[stateData.setupFunction]
        if setupFunc then
            setupFunc(self)
        end
    end

    Services.Event:FireServer("Movement.State", {
        state = stateName,
        value = value
    })

    movementState[fieldName] = value
    self:UpdateMove()
end

function MovementClient:ToggleCrouch()
    self:SetState("CROUCHING", not movementState.isCrouching)
end

--[[ Ledge Functions ]]
function MovementClient:SetupLedge()
    if not self:ValidateCharacter() then return end

    if not self.ledgeState then
        self.ledgeState = {
            bodyVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment"),
            isClimbing = false,
            canLedge = true,
            ledgeAvailable = true,
            grabbingLedge = false,
            shuffleVelocity = Vector3.new(0, 0, 0),
            wallJumpDebounce = false,
            lastWallJumpTime = 0,
            wallJumpCount = 0,
            initialJumpHeight = 0,
            maxWallJumps = 1,
            maxJumpHeight = 18
        }

        self.ledgeState.bodyVelocity.Attachment0 = self.ledgeState.attachment
        self.ledgeState.bodyVelocity.Enabled = false
        self.ledgeState.bodyVelocity.MaxForce = math.huge
        self.ledgeState.bodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.ledgeState.attachment.Parent = characterRef.HumanoidRootPart
        self.ledgeState.bodyVelocity.Parent = characterRef.HumanoidRootPart
    end

    if self.ledgeConnection then
        self.ledgeConnection:Disconnect()
    end

    self.ledgeConnection = RunService.Heartbeat:Connect(function()
        if not self:ValidateCharacter() then return end

        if self.swingState and self.swingState.isSwinging then
            return
        end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {characterRef}

        local result = workspace:Raycast(characterRef.HumanoidRootPart.Position, characterRef.HumanoidRootPart.CFrame.LookVector * 1, raycastParams)
        local otherResult = workspace:Raycast(characterRef.HumanoidRootPart.Position + Vector3.new(0, 2.5, 0), characterRef.HumanoidRootPart.CFrame.LookVector * 2, raycastParams)

        if result and not otherResult then
            local hitPart = result.Instance
            if hitPart.Size.Y >= 7 and not self.ledgeState.isClimbing and
               self.ledgeState.ledgeAvailable and self.ledgeState.canLedge then
                local humanoidState = humanoidRef:GetState()
                if humanoidState == Enum.HumanoidStateType.Freefall or
                   (humanoidState == Enum.HumanoidStateType.Running and keyStates.W) then
                    self:ClimbLedge()
                end
            end
        elseif result and otherResult then
            local hitPart = result.Instance
            local currentTime = os.clock()
            local currentHeight = characterRef.HumanoidRootPart.Position.Y

            if hitPart.Size.Y >= 14 and
               not self.ledgeState.isClimbing and
               not self.ledgeState.wallJumpDebounce and
               (currentTime - self.ledgeState.lastWallJumpTime) > 1.0 and
               self.ledgeState.wallJumpCount < self.ledgeState.maxWallJumps and
               (currentHeight - self.ledgeState.initialJumpHeight) < self.ledgeState.maxJumpHeight and
               keyStates.Space then

                self.ledgeState.isWallJumping = true
                self.ledgeState.lastWallJumpTime = currentTime

                if self.ledgeState.wallJumpCount == 0 then
                    self.ledgeState.initialJumpHeight = currentHeight
                end
            end
        end
    end)
end

function MovementClient:UpdateShuffle()
    if not self:ValidateCharacter() then return end
    if not self.ledgeState or not self.ledgeState.isClimbing then return end

    local moveDir = Vector3.new(0, 0, 0)
    local isShuffling = false
    local shuffleDirection = nil

    local humanoidRootPart = characterRef.HumanoidRootPart

    if keyStates.A then
        moveDir = -humanoidRootPart.CFrame.RightVector
        isShuffling = true
        shuffleDirection = "left"
    elseif keyStates.D then
        moveDir = humanoidRootPart.CFrame.RightVector
        isShuffling = true
        shuffleDirection = "right"
    end

    if moveDir.Magnitude > 0 then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {characterRef}

        local currentWallCheck = workspace:Raycast(
            humanoidRootPart.Position,
            humanoidRootPart.CFrame.LookVector * 2.5,
            raycastParams
        )

        local nextWallCheck = workspace:Raycast(
            humanoidRootPart.Position + (moveDir * CONFIG.LEDGE.CHECK_DISTANCE),
            humanoidRootPart.CFrame.LookVector * 2.5,
            raycastParams
        )

        if currentWallCheck and nextWallCheck then
            local currentWallHeight = currentWallCheck.Instance.Size.Y
            local nextWallHeight = nextWallCheck.Instance.Size.Y

            if nextWallHeight <= currentWallHeight + 1 and nextWallHeight >= CONFIG.LEDGE.WALL_MIN_HEIGHT then
                self.ledgeState.shuffleVelocity = moveDir * CONFIG.LEDGE.SHUFFLE_SPEED
                self.ledgeState.bodyVelocity.VectorVelocity = self.ledgeState.shuffleVelocity

                if shuffleDirection == "left" then
                    if animState.currentlyPlaying.category ~= "LEDGE" or animState.currentlyPlaying.name ~= "SHUFFLE_LEFT" then
                        self:PlayAnimation("LEDGE", "SHUFFLE_LEFT", CONFIG.ANIMATION.BLEND_TIME.QUICK)
                    end
                elseif shuffleDirection == "right" then
                    if animState.currentlyPlaying.category ~= "LEDGE" or animState.currentlyPlaying.name ~= "SHUFFLE_RIGHT" then
                        self:PlayAnimation("LEDGE", "SHUFFLE_RIGHT", CONFIG.ANIMATION.BLEND_TIME.QUICK)
                    end
                end
            else
                self.ledgeState.shuffleVelocity = Vector3.new(0, 0, 0)
                self.ledgeState.bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)

                if animState.currentlyPlaying.category ~= "LEDGE" or animState.currentlyPlaying.name ~= "HOLD" then
                    self:PlayAnimation("LEDGE", "HOLD", CONFIG.ANIMATION.BLEND_TIME.QUICK)
                end
            end
        else
            self.ledgeState.shuffleVelocity = Vector3.new(0, 0, 0)
            self.ledgeState.bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)

            if animState.currentlyPlaying.category ~= "LEDGE" or animState.currentlyPlaying.name ~= "HOLD" then
                self:PlayAnimation("LEDGE", "HOLD", CONFIG.ANIMATION.BLEND_TIME.QUICK)
            end
        end
    else
        self.ledgeState.shuffleVelocity = Vector3.new(0, 0, 0)
        self.ledgeState.bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)

        if isShuffling == false and 
           (animState.currentlyPlaying.category == "LEDGE" and
           (animState.currentlyPlaying.name == "SHUFFLE_LEFT" or
            animState.currentlyPlaying.name == "SHUFFLE_RIGHT")) then
            self:PlayAnimation("LEDGE", "HOLD", CONFIG.ANIMATION.BLEND_TIME.QUICK)
        end
    end
end

function MovementClient:ClimbLedge()
    if not self.ledgeState then return end

    local currentTime = os.clock()
    if currentTime - mechanicState.lastMechanicTime < mechanicState.cooldown then
        return
    end
    mechanicState.lastMechanicTime = currentTime

    self.ledgeState.grabbingLedge = true
    self.ledgeState.isClimbing = true
    self.ledgeState.ledgeAvailable = false
    self.ledgeState.shuffleVelocity = Vector3.new(0, 0, 0)
    self.ledgeState.hangStartTime = os.clock()

    self:StopAnimation({"LOCOMOTION"})
    self:PlayAnimation("LEDGE", "GRAB")

    local humanoidRootPart = characterRef.HumanoidRootPart
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {characterRef}

    local wallResult = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector * CONFIG.LEDGE.CHECK_DISTANCE, raycastParams)
    if wallResult then
        local topCheckStart = wallResult.Position + Vector3.new(0, 3, 0)
        local edgeResult = workspace:Raycast(topCheckStart, Vector3.new(0, -4, 0), raycastParams)

        if edgeResult then
            local wallNormal = wallResult.Normal
            local targetPosition = edgeResult.Position + Vector3.new(0, -1.0, 0)
            targetPosition = targetPosition + (wallNormal * 0.5)

            humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition - wallNormal)
        else
            local wallNormal = wallResult.Normal
            local targetPosition = wallResult.Position + Vector3.new(0, 1.5, 0)
            targetPosition = targetPosition + (wallNormal * 0.5)

            humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition - wallNormal)
        end
    end

    self.ledgeState.bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    self.ledgeState.bodyVelocity.Enabled = true

    humanoidRef.AutoRotate = false

    if cameraState.isShiftLocked then
        self:ToggleShiftLock()
    end

    local grabTrack = animState.animations["LEDGE_GRAB"]
    if grabTrack then
        grabTrack.Stopped:Connect(function()
            if self.ledgeState and self.ledgeState.isClimbing then
                self:PlayAnimation("LEDGE", "HOLD")
            end
        end)
    end
    
    task.delay(CONFIG.LEDGE.HANG_DURATION, function()
        if self.ledgeState and self.ledgeState.isClimbing then
            self:DropLedge()
        end
    end)
end

function MovementClient:DropLedge()
    if not self:ValidateCharacter() then return end
    if not self.ledgeState then return end

    local humanoidRootPart = characterRef.HumanoidRootPart
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {characterRef}

    local wallResult = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector * CONFIG.LEDGE.CHECK_DISTANCE, raycastParams)
    if not wallResult then return end

    local wallNormal = wallResult.Normal
    local dropStartPos = wallResult.Position + Vector3.new(0, -1, 0)
    local dropEndPos = dropStartPos + (wallNormal * -1)

    local landingCheck = workspace:Raycast(dropEndPos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), raycastParams)
    if not landingCheck then return end

    self.ledgeState.grabbingLedge = false
    self.ledgeState.isClimbing = false

    self:StopAnimation({"LEDGE"})
    self:PlayAnimation("LEDGE", "CLIMB")

    humanoidRef.AutoRotate = true

    if cameraState.isShiftLocked then
        self:ToggleShiftLock()
    end

    self.ledgeState.bodyVelocity.Enabled = true
    self.ledgeState.bodyVelocity.VectorVelocity = wallNormal * -CONFIG.LEDGE.PUSH_FORCE + Vector3.new(0, CONFIG.LEDGE.CLIMB_SPEED, 0)

    local function resetPhysics()
        if self.ledgeState then
            self.ledgeState.bodyVelocity.Enabled = false
            self.ledgeState.bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)

            if humanoidRef then
                humanoidRef.PlatformStand = false
                humanoidRef.AutoRotate = true
            end
        end
    end

    task.delay(0.2, resetPhysics)

    local climbTrack = animState.animations["LEDGE_CLIMB"]
    if climbTrack then
        climbTrack.Stopped:Connect(resetPhysics)
    end

    task.delay(CONFIG.LEDGE.DROP_COOLDOWN, function()
        if self.ledgeState then
            self.ledgeState.ledgeAvailable = true
        end
    end)
end

function MovementClient:JumpLedge()
    if not self.ledgeState then return end

    self.ledgeState.wallJumpDebounce = true
    self.ledgeState.canLedge = false
    self.ledgeState.isWallJumping = false
    self.ledgeState.wallJumpCount = self.ledgeState.wallJumpCount + 1

    self:StopAnimation({"LEDGE"})
    self:PlayAnimation("LEDGE", "CLIMB")

    humanoidRef.AutoRotate = true

    if cameraState.isShiftLocked then
        self:ToggleShiftLock()
    end

    self.ledgeState.bodyVelocity.Enabled = true
    self.ledgeState.bodyVelocity.VectorVelocity = characterRef.HumanoidRootPart.CFrame.LookVector * CONFIG.LEDGE.JUMP_HORIZONTAL_FORCE + Vector3.new(0, CONFIG.LEDGE.JUMP_VERTICAL_FORCE, 0)

    self.ledgeState.canLedge = true

    task.delay(0.15, function()
        if not self.ledgeState.grabbingLedge then
            self.ledgeState.bodyVelocity.Enabled = false
        end
    end)

    task.delay(CONFIG.LEDGE.WALL_JUMP_COOLDOWN, function()
        if self.ledgeState then
            self.ledgeState.wallJumpDebounce = false
        end
    end)
end

--[[ Roll Functions ]]
function MovementClient:SetupRoll()
    if not self:ValidateCharacter() then return end

    if not self.rollState then
        self.rollState = {
            isRolling = false,
            cooldown = false,
            direction = "forward",
            bodyVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment"),
            cacheJumpPower = 0,
            cacheJumpHeight = 0,
            rollStartTime = 0,
            lastRollTime = 0,
            cancel = false
        }

        self.rollState.bodyVelocity.Attachment0 = self.rollState.attachment
        self.rollState.bodyVelocity.Enabled = false
        self.rollState.bodyVelocity.MaxForce = math.huge
        self.rollState.bodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.rollState.attachment.Parent = characterRef.HumanoidRootPart
        self.rollState.bodyVelocity.Parent = characterRef.HumanoidRootPart
    end
end

function MovementClient:StartRoll(direction)
    if not self:ValidateCharacter() then return end
    if movementState.isRagdoll or movementState.isSliding or movementState.isHanging then return end

    self:SetupRoll()

    if self.rollState.isRolling or self.rollState.cooldown then 
        return 
    end

    self:StopAnimation({"LOCOMOTION", "ROLL", "LANDING"})

    local humanoidRootPart = characterRef.HumanoidRootPart
    local currentTime = os.clock()
    local isChainedRoll = self.rollState.lastRollTime and
                         (currentTime - self.rollState.lastRollTime) <= CONFIG.ROLL.CANCEL.CHAIN_WINDOW

    self.rollState.cacheJumpPower = humanoidRef.JumpPower
    self.rollState.cacheJumpHeight = humanoidRef.JumpHeight
    humanoidRef.JumpPower = 0
    humanoidRef.JumpHeight = 0

    self.rollState.direction = direction
    self.rollState.rollStartTime = os.clock()
    self.rollState.lastRollTime = self.rollState.rollStartTime
    self.rollState.isRolling = true
    self.rollState.cancel = false
    movementState.isRolling = true

    local rollDirection = Vector3.new(0, 0, 0)
    local rollAnim = ""
    local isForwardOrBack = false

    if direction == "forward" then
        rollDirection = humanoidRootPart.CFrame.LookVector
        rollAnim = "FORWARD"
        isForwardOrBack = true
    elseif direction == "backward" then
        rollDirection = -humanoidRootPart.CFrame.LookVector
        rollAnim = "BACKWARD"
        isForwardOrBack = true
    elseif direction == "left" then
        rollDirection = -humanoidRootPart.CFrame.RightVector
        rollAnim = "LEFT"
    elseif direction == "right" then
        rollDirection = humanoidRootPart.CFrame.RightVector
        rollAnim = "RIGHT"
    end

    Utility.Sound.Play("SFX.Roll", humanoidRootPart)
    self:PlayAnimation("ROLL", rollAnim)

    task.delay(CONFIG.ROLL.CANCEL.MIN_TIME, function()
        if self.rollState and self.rollState.isRolling then
            self.rollState.cancel = true
        end
    end)

    local verticalForce = 0
    if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
        verticalForce = CONFIG.ROLL.VERTICAL_FORCE
    end

    rollDirection = rollDirection + Vector3.new(0, verticalForce, 0)
    self.rollState.bodyVelocity.VectorVelocity = rollDirection * CONFIG.ROLL.SPEED
    self.rollState.bodyVelocity.Enabled = true

    local collisionConnection
    collisionConnection = RunService.Heartbeat:Connect(function()
        if not self:ValidateCharacter() then
            if collisionConnection then
                collisionConnection:Disconnect()
            end
            return
        end

        if self:CheckCollision(humanoidRootPart.Position, rollDirection) then
            if collisionConnection then
                collisionConnection:Disconnect()
            end

            if self.rollState and self.rollState.isRolling then
                self:StopRoll()
            end
        end
    end)

    local duration = isForwardOrBack and CONFIG.ROLL.DURATION.FORWARD or CONFIG.ROLL.DURATION.SIDE
    local cooldown = isForwardOrBack and CONFIG.ROLL.COOLDOWN.FORWARD or CONFIG.ROLL.COOLDOWN.SIDE

    task.delay(duration, function()
        if collisionConnection then
            collisionConnection:Disconnect()
        end

        if self.rollState and self.rollState.isRolling then
            self:StopRoll()
        end
    end)

    self.rollState.cooldown = true
    task.delay(cooldown, function()
        if self.rollState then
            self.rollState.cooldown = false
        end
    end)
end

function MovementClient:StopRoll()
    if not self:ValidateCharacter() then return end
    if not self.rollState or not self.rollState.isRolling then return end

    self:SetState("ROLL", false)
    self.rollState.isRolling = false
    self.rollState.bodyVelocity.Enabled = false

    humanoidRef.JumpPower = self.rollState.cacheJumpPower
    humanoidRef.JumpHeight = self.rollState.cacheJumpHeight

    self:StopAnimation({"ROLL"})
    self:PlayAnimation("LANDING", "SMALL")
end

function MovementClient:CancelRoll()
    if not self:ValidateCharacter() then return end
    if not self.rollState or not self.rollState.isRolling or not self.rollState.cancel then return end

    self.rollState.isRolling = false
    self.rollState.bodyVelocity.Enabled = false
    self.rollState.cancel = false

    humanoidRef.JumpPower = self.rollState.cacheJumpPower
    humanoidRef.JumpHeight = self.rollState.cacheJumpHeight

    self:StopAnimation({"ROLL"})
    self:PlayAnimation("ROLL", "CANCEL")

    task.delay(0.1, function()
        self:PlayAnimation("LOCOMOTION", "IDLE")
    end)
end

--[[ Dash Functions ]]
function MovementClient:SetupDash()
    if not self:ValidateCharacter() then return end

    if not self.airDashState then
        self.airDashState = {
            isDashing = false,
            cooldown = false,
            lastDashTime = 0,
            linearVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment")
        }

        self.airDashState.linearVelocity.Attachment0 = self.airDashState.attachment
        self.airDashState.linearVelocity.MaxForce = CONFIG.DASH.FORCE
        self.airDashState.linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.airDashState.linearVelocity.Enabled = false
        self.airDashState.attachment.Parent = characterRef.HumanoidRootPart
        self.airDashState.linearVelocity.Parent = characterRef.HumanoidRootPart
    end
end

function MovementClient:StartDash()
    if not self:ValidateCharacter() then return end
    if not self.airDashState then return end
    if movementState.isRagdoll or movementState.isHanging then return end

    local currentTime = os.clock()
    if currentTime - self.airDashState.lastDashTime < CONFIG.DASH.COOLDOWN then
        return
    end

    self.airDashState.lastDashTime = currentTime
    self.airDashState.isDashing = true

    if self.swingState and self.swingState.isSwinging then
        self:EndSwing()
    end

    self:StopAnimation({"LOCOMOTION", "SPECIAL"})

    Utility.Sound.Play("SFX.Dash", characterRef.HumanoidRootPart)

    if not animState.animations["SPECIAL_AIR_DASH"] then
        local specialAnims = Utility.Animation.Categories(humanoidRef:WaitForChild("Animator"), {
            "SPECIAL"
        })
        for key, track in pairs(specialAnims) do
            animState.animations[key] = track
        end
    end

    if animState.animations["SPECIAL_AIR_DASH"] then
        animState.animations["SPECIAL_AIR_DASH"]:Play(0.1)
    else
        return
    end

    local humanoidRootPart = characterRef.HumanoidRootPart
    Utility.Particle.Play("Dash", humanoidRootPart, {
        emitCount = 25,
        lifetime = CONFIG.DASH.VFX.DURATION
    })

    local dashVelocity = humanoidRootPart.CFrame.LookVector * CONFIG.DASH.DISTANCE * (1/CONFIG.DASH.DURATION)
    self.airDashState.linearVelocity.VectorVelocity = dashVelocity
    self.airDashState.linearVelocity.MaxForce = CONFIG.DASH.FORCE
    self.airDashState.linearVelocity.Enabled = true

    self.airDashState.dashEndTime = os.clock() + CONFIG.DASH.DURATION

    task.delay(CONFIG.DASH.DURATION, function()
        if self.airDashState and self.airDashState.isDashing then
            self.airDashState.linearVelocity.Enabled = false
            self:StopAnimation({"SPECIAL", "AIR_DASH"})
            self.airDashState.isDashing = false
            self:PlayAnimation("LOCOMOTION", "FALL")
        end
    end)
end

function MovementClient:SetupSlide()
    if not self:ValidateCharacter() then return end

    if not self.slideState then
        self.slideState = {
            isSliding = false,
            lastSlideTime = 0,
            bodyVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment")
        }

        self.slideState.bodyVelocity.Attachment0 = self.slideState.attachment
        self.slideState.bodyVelocity.MaxForce = math.huge
        self.slideState.bodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.slideState.bodyVelocity.Enabled = false
        self.slideState.attachment.Parent = characterRef.HumanoidRootPart
        self.slideState.bodyVelocity.Parent = characterRef.HumanoidRootPart
    end
end

function MovementClient:StartSlide()
    if not self:ValidateCharacter() then return end
    if not self.slideState then return end
    if movementState.isRagdoll then return end

    local currentTime = os.clock()
    if currentTime - self.slideState.lastSlideTime < CONFIG.SLIDE.COOLDOWN then
        return
    end

    self.slideState.lastSlideTime = currentTime
    self.slideState.isSliding = true
    movementState.isSliding = true

    Utility.Sound.Play("SFX.Slide", characterRef.HumanoidRootPart)

    self:StopAnimation({"LOCOMOTION"})
    self:PlayAnimation("SPECIAL", "SLIDE")

    local humanoidRootPart = characterRef.HumanoidRootPart
    self.slideState.bodyVelocity.VectorVelocity = humanoidRootPart.CFrame.LookVector * CONFIG.SLIDE.SPEED
    self.slideState.bodyVelocity.Enabled = true

    local collisionConnection
    collisionConnection = RunService.Heartbeat:Connect(function()
        if not self:ValidateCharacter() then
            if collisionConnection then
                collisionConnection:Disconnect()
            end
            return
        end

        if self:CheckCollision(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector) then
            if self.slideState.bodyVelocity then
                self.slideState.bodyVelocity.Enabled = false
            end
            self.slideState.isSliding = false
            movementState.isSliding = false

            self:StopAnimation({"SPECIAL"})
            self:PlayAnimation("LANDING", "SMALL")

            if collisionConnection then
                collisionConnection:Disconnect()
            end

            local landingTrack = animState.animations["LANDING_SMALL"]
            if landingTrack then
                landingTrack.Stopped:Connect(function()
                    if not movementState.isSliding then
                        self:UpdateMove()
                    end
                end)
            end
        end
    end)

    task.delay(CONFIG.SLIDE.DURATION, function()
        if collisionConnection then
            collisionConnection:Disconnect()
        end

        if self.slideState then
            self.slideState.bodyVelocity.Enabled = false
            self.slideState.isSliding = false
            movementState.isSliding = false

            self:StopAnimation({"SPECIAL"})
            self:PlayAnimation("LANDING", "SMALL")

            local landingTrack = animState.animations["LANDING_SMALL"]
            if landingTrack then
                landingTrack.Stopped:Connect(function()
                    if not movementState.isSliding then
                        self:UpdateMove()
                    end
                end)
            end
        end
    end)
end

--[[ Vault Functions ]]
function MovementClient:SetupVault()
    if not self:ValidateCharacter() then return end

    if not self.vaultState then
        self.vaultState = {
            isVaulting = false,
            canVault = true,
            lastVaultTime = 0
        }
    end
end

function MovementClient:StartVault()
    if not self:ValidateCharacter() then return end
    if not self.vaultState then return end
    if self.vaultState.isVaulting then return end
    if movementState.isRagdoll or movementState.isSliding then return end
    if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then return end

    local currentTime = os.clock()
    if currentTime - self.vaultState.lastVaultTime < CONFIG.VAULT.COOLDOWN then return end

    local humanoidRootPart = characterRef.HumanoidRootPart

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {characterRef}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(
        humanoidRootPart.Position,
        humanoidRootPart.CFrame.LookVector * CONFIG.VAULT.CHECK_DISTANCE,
        raycastParams
    )

    if not raycastResult then return end
    local hitPart = raycastResult.Instance

    if hitPart:FindFirstAncestorWhichIsA("Model"):FindFirstChild("Humanoid") then return end
    if hitPart.Size.Y >= CONFIG.VAULT.MAX_HEIGHT then return end

    if self:CheckStructures(hitPart, "VAULT") then return end

    local topRaycast = workspace:Raycast(
        raycastResult.Position + Vector3.new(0, 2, 0),
        Vector3.new(0, -4, 0),
        raycastParams
    )

    if not topRaycast then return end

    local lookVector = humanoidRootPart.CFrame.LookVector
    local targetPos = topRaycast.Position + Vector3.new(0, humanoidRef.HipHeight + 0.5, 0) + (lookVector * 1)

    self.vaultState.isVaulting = true
    movementState.isVaulting = true
    self.vaultState.lastVaultTime = currentTime
    mechanicState.lastMechanicTime = currentTime

    Utility.Sound.Play("SFX.Dash", characterRef.HumanoidRootPart)

    self:StopAnimation({"LOCOMOTION"})
    self:PlayAnimation("SPECIAL", "VAULT", 0.1, 2.0)
    local camera = workspace.CurrentCamera
    if camera then
        Utility.Camera.FOV(camera, CONFIG.CAMERA_SETTINGS.VAULT_FOV, 0.15)
    end

    humanoidRootPart.Anchored = true
    local tweenInfo = TweenInfo.new(
        CONFIG.VAULT.DURATION,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local tween = game:GetService("TweenService"):Create(humanoidRootPart, tweenInfo, {
        CFrame = CFrame.new(targetPos, targetPos + lookVector)
    })

    tween:Play()
    tween.Completed:Connect(function()
        humanoidRootPart.Anchored = false
        self.vaultState.isVaulting = false
        movementState.isVaulting = false
        if camera then
            Utility.Camera.FOV(camera, CONFIG.CAMERA_SETTINGS.FOV, 0.15)
        end

        humanoidRootPart:ApplyImpulse(humanoidRootPart.CFrame.LookVector * CONFIG.VAULT.BOOST_FORCE)

        Utility.Particle.Play("Vault", humanoidRootPart, {
            emitCount = 25,
            lifetime = 0.75,
            offset = CFrame.new(0, -1.5, 0)
        })

        self:UpdateMove()
    end)
end

function MovementClient:CheckVault()
    if not self:ValidateCharacter() then return end
    if self.vaultState.isVaulting then return end
    if movementState.isRagdoll or movementState.isSliding then return end
    if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then return end

    if (self.ledgeState and self.ledgeState.isClimbing) or
       (self.swingState and self.swingState.isSwinging) then
        return
    end

    local currentTime = os.clock()
    if currentTime - self.vaultState.lastVaultTime < CONFIG.VAULT.COOLDOWN then return end

    if currentTime - mechanicState.lastMechanicTime < mechanicState.cooldown then
        return
    end

    local humanoidRootPart = characterRef.HumanoidRootPart
    if not keyStates.W then return end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {characterRef}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(
        humanoidRootPart.Position,
        humanoidRootPart.CFrame.LookVector * CONFIG.VAULT.CHECK_DISTANCE,
        raycastParams
    )

    if not raycastResult then return end
    local hitPart = raycastResult.Instance

    if hitPart:FindFirstAncestorWhichIsA("Model"):FindFirstChild("Humanoid") then return end
    if hitPart.Size.Y >= CONFIG.VAULT.MAX_HEIGHT then return end
    if (characterRef.Head.Position.Y - hitPart.Position.Y) < CONFIG.VAULT.MIN_HEIGHT then return end

    self:StartVault()
end

--[[ Swing Functions ]]
function MovementClient:SetupSwing()
    if not self:ValidateCharacter() then return end

    if not self.swingState then
        self.swingState = {
            isSwinging = false,
            canSwing = true,
            lastSwingTime = 0,
            bodyVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment"),
            wasSwinging = false,
            swingEndTime = nil,
            recentSwingPoints = {},
            maxRecentPoints = 3
        }

        self.swingState.bodyVelocity.Attachment0 = self.swingState.attachment
        self.swingState.bodyVelocity.MaxForce = math.huge
        self.swingState.bodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.swingState.bodyVelocity.Enabled = false
        self.swingState.attachment.Parent = characterRef.HumanoidRootPart
        self.swingState.bodyVelocity.Parent = characterRef.HumanoidRootPart
    end
end

function MovementClient:ValidateSwing(part, hitPosition, showDebug)
    local minDimension = math.min(part.Size.X, part.Size.Y, part.Size.Z)
    local maxDimension = math.max(part.Size.X, part.Size.Y, part.Size.Z)
    local isLong = maxDimension >= CONFIG.SWING.SURFACE.LONG_THRESHOLD
    local isCylindrical = false

    local dimensions = {part.Size.X, part.Size.Y, part.Size.Z}
    table.sort(dimensions)
    if math.abs(dimensions[1] - dimensions[2]) < 0.5 and dimensions[3] > dimensions[2] * 2 then
        isCylindrical = true
    end

    local localHitPos = part.CFrame:ToObjectSpace(CFrame.new(hitPosition)).Position

    if showDebug then
        Debug:Print("SWING", "VALIDATION", "Part Size:", part.Size)
        Debug:Print("SWING", "VALIDATION", "Min Dimension:", minDimension)
        Debug:Print("SWING", "VALIDATION", "Max Dimension:", maxDimension)
        Debug:Print("SWING", "VALIDATION", "Is Long:", isLong)
        Debug:Print("SWING", "VALIDATION", "Is Cylindrical:", isCylindrical)
        Debug:Print("SWING", "VALIDATION", "Local Hit Position:", localHitPos)
    end

    if isCylindrical then
        local relativeY = math.abs(localHitPos.Y) / (part.Size.Y/2)
        if relativeY > 0.9 then
            if showDebug then
                Debug:Print("SWING", "VALIDATION", "Invalid: Hitting top/bottom of cylinder")
            end
            return false
        end
    else
        local relativeY = math.abs(localHitPos.Y) / (part.Size.Y/2)
        if relativeY > 0.9 then
            if showDebug then
                Debug:Print("SWING", "VALIDATION", "Invalid: Hitting top/bottom face")
            end
            return false
        end
    end

    local character = Players.LocalPlayer.Character
    if not character then
        if showDebug then
            Debug:Print("SWING", "VALIDATION", "Invalid: No character")
        end
        return false
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        if showDebug then
            Debug:Print("SWING", "VALIDATION", "Invalid: No humanoid root part")
        end
        return false
    end

    local structureCheckResult = self:CheckStructures(part, "SWING")
    if structureCheckResult then
        if showDebug then
            Debug:Print("SWING", "VALIDATION", "Invalid: Failed structure check")
        end
        return false
    end

    local characterHeight = humanoidRootPart.Position.Y
    local swingPointHeight = hitPosition.Y
    local heightDifference = math.abs(swingPointHeight - characterHeight)

    if heightDifference > CONFIG.SWING.DETECT.HEIGHT_DIFFERENCE_MAX then
        if showDebug then
            Debug:Print("SWING", "VALIDATION", "Invalid: Height difference too large:", heightDifference)
        end
        return false
    end

    local swingStartPoint = humanoidRootPart.Position
    local lookVec = humanoidRootPart.CFrame.LookVector

    local forwardRayParams = RaycastParams.new()
    forwardRayParams.FilterDescendantsInstances = {characterRef, part}
    forwardRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local forwardDistance = CONFIG.SWING.MOVEMENT.FORWARD_DISTANCE

    local forwardRaycastResult = workspace:Raycast(
        swingStartPoint,
        lookVec * forwardDistance,
        forwardRayParams
    )

    if forwardRaycastResult then
        local wallDistance = (forwardRaycastResult.Position - swingStartPoint).Magnitude
        return false
    end

    local upwardRayParams = RaycastParams.new()
    upwardRayParams.FilterDescendantsInstances = {characterRef, part}
    upwardRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local heightCheck = CONFIG.SWING.VALIDATION.MAX_CEILING_DISTANCE

    local upwardRaycastResult = workspace:Raycast(
        hitPosition,
        Vector3.new(0, heightCheck, 0),
        upwardRayParams
    )

    if upwardRaycastResult then
        return false
    end

    local downwardRayParams = RaycastParams.new()
    downwardRayParams.FilterDescendantsInstances = {characterRef, part}
    downwardRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local downwardRaycastResult = workspace:Raycast(
        hitPosition,
        Vector3.new(0, -heightCheck, 0),
        downwardRayParams
    )

    if downwardRaycastResult then
        local floorDistance = (hitPosition.Y - downwardRaycastResult.Position.Y)
        if floorDistance < 2 then
            return false
        end
    end

    local swingStartPoint = humanoidRootPart.Position
    local swingOffset = (swingStartPoint - hitPosition).Unit * (CONFIG.SWING.MOVEMENT.DISTANCE or 4)
    local offsetPoint = hitPosition + swingOffset

    local heightAdjustment = 0
    local downwardRayParams = RaycastParams.new()
    downwardRayParams.FilterDescendantsInstances = {characterRef, part}
    downwardRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local downwardCheck = workspace:Raycast(hitPosition, Vector3.new(0, -20, 0), downwardRayParams)
    if downwardCheck then
        local groundHeight = downwardCheck.Position.Y
        local characterHeight = humanoidRootPart.Position.Y
        if characterHeight - groundHeight < 5 then
            heightAdjustment = math.min(5, 5 - (characterHeight - groundHeight))
        end
    end

    local midPoint = offsetPoint + Vector3.new(0, heightAdjustment, 0)
    local endPoint = offsetPoint + (lookVec * (CONFIG.SWING.MOVEMENT.FORWARD_DISTANCE or 8)) + Vector3.new(0, CONFIG.SWING.MOVEMENT.END_HEIGHT or 0, 0)

    if showDebug then
        Debug:Print("SWING", "PATH", "=== SWING PATH DEBUG ===")
        Debug:Print("SWING", "PATH", "Start Point:", swingStartPoint)
        Debug:Print("SWING", "PATH", "Hit Position:", hitPosition)
        Debug:Print("SWING", "PATH", "Offset Point:", offsetPoint)
        Debug:Print("SWING", "PATH", "Ground Check:", downwardCheck and downwardCheck.Position or "No ground found")
        Debug:Print("SWING", "PATH", "Height Adjustment:", heightAdjustment)
        Debug:Print("SWING", "PATH", "Mid Point:", midPoint)
        Debug:Print("SWING", "PATH", "End Point:", endPoint)
        Debug:Print("SWING", "PATH", "Height Difference:", heightDifference)
        Debug:Print("SWING", "PATH", "Swing Offset:", swingOffset)
        Debug:Print("SWING", "PATH", "Look Vector:", lookVec)

        if DEBUG.SWING.SHOW_POINTS then
            local points = {
                {pos = hitPosition, shape = "Cross", color = Color3.fromRGB(255, 0, 0), pulse = true},
                {pos = midPoint, shape = "Sphere", color = Color3.fromRGB(255, 255, 0)},
                {pos = endPoint, shape = "Sphere", color = Color3.fromRGB(0, 0, 255)}
            }

            for _, point in ipairs(points) do
                Debug:Point(point.pos, {
                    Shape = point.shape,
                    Size = 0.8,
                    Color = point.color,
                    Transparency = 0.3,
                    Duration = 3,
                    Pulse = point.pulse or false
                })
            end

            Debug:Path({swingStartPoint, hitPosition, midPoint, endPoint}, Color3.fromRGB(255, 128, 0))
        end
    end

    local landingRayParams = RaycastParams.new()
    landingRayParams.FilterDescendantsInstances = {characterRef, part}
    landingRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local directLandingCheck = workspace:Raycast(hitPosition, Vector3.new(0, -20, 0), landingRayParams)
    local projectedLandingCheck = workspace:Raycast(endPoint, Vector3.new(0, -20, 0), landingRayParams)

    if showDebug then
        if directLandingCheck then
            local directLandingDistance = (hitPosition.Y - directLandingCheck.Position.Y)
            Debug:Point(directLandingCheck.Position, Color3.fromRGB(0, 255, 0), 0.8)
        end

        if projectedLandingCheck then
            local projectedLandingDistance = (endPoint.Y - projectedLandingCheck.Position.Y)
            Debug:Point(projectedLandingCheck.Position, Color3.fromRGB(0, 100, 0), 0.8)
        end
    end

    if minDimension < CONFIG.SWING.SURFACE.MIN_DIMENSION then
        local minHeightRequired = isLong and CONFIG.SWING.SURFACE.MIN_HEIGHT_LONG or CONFIG.SWING.SURFACE.MIN_HEIGHT_REGULAR

        if part.Size.Y < minHeightRequired then
            return false
        end

        local localHitPos = part.CFrame:ToObjectSpace(CFrame.new(hitPosition)).Position

        local longAxis = "X"
        local longDimension = part.Size.X

        if part.Size.Y > longDimension then
            longAxis = "Y"
            longDimension = part.Size.Y
        end

        if part.Size.Z > longDimension then
            longAxis = "Z"
            longDimension = part.Size.Z
        end

        local isValidPosition = false
        local size = part.Size
        local hitLocal = localHitPos

        local threshold = CONFIG.SWING.SURFACE.PROXIMITY_THRESHOLD

        if longAxis == "X" then
            local distanceFromZSurface = math.min(
                math.abs(hitLocal.Z + size.Z/2),
                math.abs(hitLocal.Z - size.Z/2)
            )
            local distanceFromYSurface = math.min(
                math.abs(hitLocal.Y + size.Y/2),
                math.abs(hitLocal.Y - size.Y/2)
            )

            local lookVecLocal = part.CFrame:VectorToObjectSpace(lookVec)
            local facingAlongX = math.abs(lookVecLocal.X) > CONFIG.SWING.SURFACE.DIRECTION_THRESHOLD

            isValidPosition = not facingAlongX and (distanceFromZSurface <= threshold or distanceFromYSurface <= threshold)

        elseif longAxis == "Z" then
            local distanceFromXSurface = math.min(
                math.abs(hitLocal.X + size.X/2),
                math.abs(hitLocal.X - size.X/2)
            )
            local distanceFromYSurface = math.min(
                math.abs(hitLocal.Y + size.Y/2),
                math.abs(hitLocal.Y - size.Y/2)
            )

            local lookVecLocal = part.CFrame:VectorToObjectSpace(lookVec)
            local facingAlongZ = math.abs(lookVecLocal.Z) > CONFIG.SWING.SURFACE.DIRECTION_THRESHOLD

            isValidPosition = not facingAlongZ and (distanceFromXSurface <= threshold or distanceFromYSurface <= threshold)

        else
            local distanceFromXSurface = math.min(
                math.abs(hitLocal.X + size.X/2),
                math.abs(hitLocal.X - size.X/2)
            )
            local distanceFromZSurface = math.min(
                math.abs(hitLocal.Z + size.Z/2),
                math.abs(hitLocal.Z - size.Z/2)
            )

            isValidPosition = distanceFromXSurface <= threshold or distanceFromZSurface <= threshold
        end

        if not isValidPosition then
            return false
        end

        local distanceToSwingPoint = (hitPosition - humanoidRootPart.Position).Magnitude

        if distanceToSwingPoint > CONFIG.SWING.MOVEMENT.MAX_DISTANCE then
            return false
        end

        return true
    end

    return true
end

function MovementClient:DetectSwing()
    if not self.swingState or not self.swingState.canSwing then return false end
    if movementState.isRagdoll or movementState.isHanging then return false end

    if (self.ledgeState and self.ledgeState.isClimbing) or
       (self.vaultState and self.vaultState.isVaulting) then
        return false
    end

    local currentTime = os.clock()
    if currentTime - self.swingState.lastSwingTime < CONFIG.SWING.TIMING.COOLDOWN then return false end

    local humanoidRootPart = characterRef.HumanoidRootPart
    local position = humanoidRootPart.Position
    local lookVec = humanoidRootPart.CFrame.LookVector

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {characterRef}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastDirections = {
        {lookVec, 0},
        {lookVec + Vector3.new(0, 0.3, 0), 0.3},
        {lookVec + Vector3.new(0, 0.6, 0), 0.6},
        {lookVec + Vector3.new(0, -0.3, 0), -0.3}
    }

    for _, directionData in ipairs(raycastDirections) do
        local direction, heightOffset = directionData[1], directionData[2]
        local raycastResult = workspace:Raycast(
            position + Vector3.new(0, heightOffset, 0),
            direction * CONFIG.SWING.DETECT.RANGE,
            raycastParams
        )

        if raycastResult then
            local part = raycastResult.Instance

            Debug:Print("SWING", "RAYCAST", "=== RAYCAST DEBUG ===")
            Debug:Print("SWING", "RAYCAST", "Hit Part:", part:GetFullName())
            Debug:Print("SWING", "RAYCAST", "Hit Material:", raycastResult.Material)
            Debug:Print("SWING", "RAYCAST", "Hit Normal:", raycastResult.Normal.X, raycastResult.Normal.Y, raycastResult.Normal.Z)
            Debug:Print("SWING", "RAYCAST", "Hit Distance:", raycastResult.Distance)
            Debug:Print("SWING", "RAYCAST", "Part Size:", part.Size.X, part.Size.Y, part.Size.Z)

            if not part:IsA("BasePart") or part.CanCollide == false then
                Debug:Print("SWING", "RAYCAST", "Invalid swing surface: Not a solid part")
                Debug:Print("SWING", "RAYCAST", "IsBasePart:", part:IsA("BasePart"))
                Debug:Print("SWING", "RAYCAST", "CanCollide:", part.CanCollide)
                continue
            end

            local dimensions = {part.Size.X, part.Size.Y, part.Size.Z}
            table.sort(dimensions)
            local isCylindrical = math.abs(dimensions[1] - dimensions[2]) < 0.5 and dimensions[3] > dimensions[2] * 2
            Debug:Print("SWING", "RAYCAST", "Sorted dimensions:", dimensions[1], dimensions[2], dimensions[3])
            Debug:Print("SWING", "RAYCAST", "Is Cylindrical:", isCylindrical)

            local upDot = math.abs(raycastResult.Normal:Dot(Vector3.new(0, 1, 0)))
            Debug:Print("SWING", "RAYCAST", "Surface Angle (up dot):", upDot)

            if upDot > CONFIG.SWING.VALIDATION.WALL_DOT_THRESHOLD and not isCylindrical then
                Debug:Print("SWING", "RAYCAST", "Invalid swing surface: Surface too vertical (up dot > 0.7)")
                continue
            end

            if self:ValidateSwing(raycastResult.Instance, raycastResult.Position, true) then
                return raycastResult.Instance
            end
        end
    end

    return false
end

function MovementClient:StartSwing(swingPoint)
    if not self:ValidateCharacter() then return end
    if not self.swingState then return end
    if self.swingState.isSwinging then return end

    for _, recentPoint in ipairs(self.swingState.recentSwingPoints) do
        if recentPoint == swingPoint then
            return
        end
    end

    local currentTime = os.clock()
    if currentTime - self.swingState.lastSwingTime < CONFIG.SWING.TIMING.COOLDOWN then
        return
    end

    if currentTime - mechanicState.lastMechanicTime < 0.1 then
        return
    end
    mechanicState.lastMechanicTime = currentTime

    if self.swingState.recoveryTimer and coroutine.status(self.swingState.recoveryTimer) == "suspended" then
        task.cancel(self.swingState.recoveryTimer)
    end
    self.swingState.recoveryTimer = nil

    if self.swingState.swingEndTimer and coroutine.status(self.swingState.swingEndTimer) == "suspended" then
        task.cancel(self.swingState.swingEndTimer)
    end
    self.swingState.swingEndTimer = nil

    table.insert(self.swingState.recentSwingPoints, 1, swingPoint)
    if #self.swingState.recentSwingPoints > CONFIG.SWING.CHAIN.MAX_RECENT_POINTS then
        table.remove(self.swingState.recentSwingPoints)
    end

    self.swingState.isSwinging = true
    self.swingState.swingPoint = swingPoint
    self.swingState.canSwing = false
    self.swingState.lastSwingTime = currentTime
    self.swingState.chainDetected = false

    self:StopAnimation({"LOCOMOTION"})
    self:PlayAnimation("SPECIAL", "SWING")

    local humanoidRootPart = characterRef.HumanoidRootPart

    local startPoint = humanoidRootPart.Position
    local lookVec = humanoidRootPart.CFrame.LookVector

    local swingDirection = lookVec.Unit
    local sideOffset = Vector3.new(swingDirection.X, 0, swingDirection.Z).Unit * CONFIG.SWING.MOVEMENT.DISTANCE

    local swingCenter = swingPoint.Position
    local lowestPoint = swingCenter + Vector3.new(0, -CONFIG.SWING.MOVEMENT.DISTANCE * 0.8, 0)

    local arcHeight = CONFIG.SWING.MOVEMENT.HEIGHT
    local forwardDist = CONFIG.SWING.MOVEMENT.FORWARD_DISTANCE
    local endHeight = CONFIG.SWING.MOVEMENT.END_HEIGHT

    if self.swingState.inChainWindow then
        arcHeight = CONFIG.SWING.MOVEMENT.HEIGHT * CONFIG.SWING.CHAIN.HEIGHT_MULT
        forwardDist = CONFIG.SWING.MOVEMENT.FORWARD_DISTANCE * CONFIG.SWING.CHAIN.FORWARD_MULT
        endHeight = CONFIG.SWING.MOVEMENT.HEIGHT * CONFIG.SWING.CHAIN.END_HEIGHT_MULT
    end

    local midPoint = lowestPoint + (swingDirection * forwardDist * 0.5) + Vector3.new(0, arcHeight, 0)
    local endPoint = lowestPoint + (swingDirection * forwardDist) + Vector3.new(0, endHeight, 0)

    self.swingState.swingOffset = sideOffset
    self.swingState.pathCurve = Tools.Bezier.new(startPoint, midPoint, endPoint)
    self.swingState.swingStartTime = os.clock()
    self.swingState.swingDuration = CONFIG.SWING.TIMING.DURATION
    self.swingState.lastCFrame = humanoidRootPart.CFrame

    local initialPathDirection = (midPoint - startPoint).Unit
    initialPathDirection = Vector3.new(initialPathDirection.X, 0, initialPathDirection.Z).Unit

    local targetCFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), initialPathDirection)
    humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(targetCFrame, CONFIG.SWING.PHYSICS.ROTATION_SMOOTHING)

    self.swingState.bodyVelocity.Enabled = true

    self.swingState.swingEndTimer = task.delay(self.swingState.swingDuration, function()
        if self.swingState and self.swingState.isSwinging then
            self:EndSwing()
        end
    end)
end

function MovementClient:EndSwing()
    if not self:ValidateCharacter() then return end
    if not self.swingState or not self.swingState.isSwinging then return end

    if self.swingState.recoveryTimer and coroutine.status(self.swingState.recoveryTimer) == "suspended" then
        task.cancel(self.swingState.recoveryTimer)
    end
    self.swingState.recoveryTimer = nil

    if self.swingState.swingEndTimer and coroutine.status(self.swingState.swingEndTimer) == "suspended" then
        task.cancel(self.swingState.swingEndTimer)
    end
    self.swingState.swingEndTimer = nil

    self.swingState.isSwinging = false
    self.swingState.swingPoint = nil
    self.swingState.bodyVelocity.Enabled = false
    self.swingState.lastCFrame = nil

    local humanoidRootPart = characterRef.HumanoidRootPart

    local finalDirection = self.swingState.pathCurve:CalculateDerivativeAt(1)
    if finalDirection then
        finalDirection = finalDirection.Unit
    else
        finalDirection = Vector3.new(0, 1, 0)
    end

    local upwardBoost = Vector3.new(0, CONFIG.SWING.MOVEMENT.BOOST_FORCE * (self.swingState.inChainWindow and CONFIG.SWING.CHAIN.BOOST_UP_MULT or 0.3), 0)
    local forwardBoost = finalDirection * (CONFIG.SWING.MOVEMENT.BOOST_FORCE * (self.swingState.inChainWindow and CONFIG.SWING.CHAIN.BOOST_FWD_MULT or 0.8))
    local finalVelocity = forwardBoost + upwardBoost

    Debug:Print("SWING", "CHAIN", "=== SWING CHAIN DEBUG ===")
    Debug:Print("SWING", "CHAIN", "Final Direction:", finalDirection)
    Debug:Print("SWING", "CHAIN", "Final Velocity:", finalVelocity)
    Debug:Print("SWING", "CHAIN", "Current Velocity:", humanoidRootPart.AssemblyLinearVelocity)

    local currentVel = humanoidRootPart.AssemblyLinearVelocity
    local blendedVelocity = currentVel:Lerp(finalVelocity, CONFIG.SWING.PHYSICS.VELOCITY_BLEND)
    humanoidRootPart.AssemblyLinearVelocity = blendedVelocity

    Debug:Print("SWING", "CHAIN", "Blended Velocity:", blendedVelocity)
    Debug:Print("SWING", "CHAIN", "Chain Ready:", true)

    self.swingState.pathCurve = nil
    self.swingState.wasSwinging = true
    self.swingState.swingEndTime = os.clock()
    self.swingState.canSwing = true
    self.swingState.lastSwingTime = 0
    self.swingState.inChainWindow = true

    if not self.swingState.chainDetected then
        local chainConnection
        chainConnection = RunService.Heartbeat:Connect(function()
            if not self.swingState.inChainWindow or self.swingState.isSwinging then
                chainConnection:Disconnect()
                return
            end

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {characterRef}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude

            local lookVec = humanoidRootPart.CFrame.LookVector
            local position = humanoidRootPart.Position + Vector3.new(0, 2, 0)

            local angles = {-75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75}
            local chainTargets = {}

            for _, angle in ipairs(angles) do
                local direction = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(angle)) * lookVec

                local heightOffsets = {-1, 0, 1, 2}
                for _, heightOffset in ipairs(heightOffsets) do
                    local raycastResult = workspace:Raycast(
                        position + Vector3.new(0, heightOffset, 0),
                        direction.Unit * CONFIG.SWING.DETECT.RANGE,
                        raycastParams
                    )

                    if raycastResult and self:ValidateSwing(raycastResult.Instance, raycastResult.Position) then
                        table.insert(chainTargets, {
                            position = raycastResult.Position,
                            part = raycastResult.Instance,
                            distance = (raycastResult.Position - position).Magnitude
                        })

                        if DEBUG.SWING.SHOW_POINTS then
                            Debug:Point(raycastResult.Position, {
                                Shape = "Cross",
                                Size = 0.8,
                                Color = Color3.fromRGB(0, 255, 255),
                                Transparency = 0.3,
                                Duration = 0.1,
                                Pulse = true
                            })
                        end
                    end
                end
            end

            local uniqueTargets = {}
            local seenParts = {}
            for _, target in ipairs(chainTargets) do
                if not seenParts[target.part] then
                    seenParts[target.part] = true
                    table.insert(uniqueTargets, target)
                end
            end
            table.sort(uniqueTargets, function(a, b) return a.distance < b.distance end)

            if #uniqueTargets > 0 and keyStates.Space then
                Debug:Print("SWING", "CHAIN", "Chain Targets Found:", #uniqueTargets)

                local nextTarget = uniqueTargets[1]
                if nextTarget then
                    chainConnection:Disconnect()
                    self:StartSwing(nextTarget.part)
                end
            end
        end)
    end

    if DEBUG.SWING.SHOW_POINTS then
        local boostEnd = humanoidRootPart.Position + (blendedVelocity.Unit * 5)
        Debug:Point(humanoidRootPart.Position, {
            Shape = "Cross",
            Size = 1,
            Color = Color3.fromRGB(255, 128, 0),
            Transparency = 0.3,
            Duration = 2,
            Pulse = true
        })
        Debug:Point(boostEnd, {
            Shape = "Sphere",
            Size = 1,
            Color = Color3.fromRGB(0, 255, 128),
            Transparency = 0.3,
            Duration = 2,
            Pulse = false
        })
        Debug:Path({humanoidRootPart.Position, boostEnd}, Color3.fromRGB(255, 255, 0))
    end

    self:StopAnimation({"SPECIAL"})
    self:PlayAnimation("LOCOMOTION", "FALL")

    humanoidRef.AutoRotate = true

    local camera = workspace.CurrentCamera
    if camera then
        local lookDir = camera.CFrame.LookVector
        lookDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
        local targetCFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), lookDir)
        humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(targetCFrame, 0.2)
    end

    self.swingState.recoveryTimer = task.delay(CONFIG.SWING.TIMING.RECOVERY_TIME, function()
        if self.swingState and not self.swingState.isSwinging then
            self.swingState.wasSwinging = false
            self.swingState.swingEndTime = nil
            self.swingState.inChainWindow = false
            table.clear(self.swingState.recentSwingPoints)
            Debug:Print("SWING", "CHAIN", "Chain Window Closed")
        end
    end)
end

function MovementClient:UpdateSwing(delta)
    if not self:ValidateCharacter() then return end
    if not self.swingState or not self.swingState.isSwinging then return end

    local humanoidRootPart = characterRef.HumanoidRootPart
    local swingPoint = self.swingState.swingPoint
    if not swingPoint or not swingPoint.Parent then
        self:EndSwing()
        return
    end

    local timeSinceStart = os.clock() - self.swingState.swingStartTime
    local alpha = math.clamp(timeSinceStart / self.swingState.swingDuration, 0, 1)

    if alpha > CONFIG.SWING.CHAIN.WINDOW_START and alpha < CONFIG.SWING.CHAIN.WINDOW_END and keyStates.Space and not self.swingState.chainDetected then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {characterRef}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local lookVec = humanoidRootPart.CFrame.LookVector
        local position = humanoidRootPart.Position + Vector3.new(0, 2, 0)

        local angles = {}
        local maxAngle = CONFIG.SWING.CHAIN.DETECT_ANGLE_SPREAD
        local angleStep = CONFIG.SWING.CHAIN.DETECT_ANGLE_STEPS

        for angle = -maxAngle, maxAngle, angleStep do
            table.insert(angles, angle)
        end

        local chainTargets = {}
        local bestTarget = nil
        local bestDistance = math.huge

        for _, angle in ipairs(angles) do
            local direction = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(angle)) * lookVec

            for _, heightOffset in ipairs(CONFIG.SWING.CHAIN.HEIGHT_OFFSETS) do
                local raycastResult = workspace:Raycast(
                    position + Vector3.new(0, heightOffset, 0),
                    direction.Unit * CONFIG.SWING.DETECT.RANGE,
                    raycastParams
                )

                if raycastResult and raycastResult.Instance ~= swingPoint and 
                   self:ValidateSwing(raycastResult.Instance, raycastResult.Position, false) then
                    local distance = (raycastResult.Position - position).Magnitude
                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = {
                            position = raycastResult.Position,
                            part = raycastResult.Instance,
                            distance = distance
                        }
                    end
                end
            end
        end

        if bestTarget then
            if DEBUG.SWING.SHOW_POINTS then
                Debug:Point(bestTarget.position, {
                    Shape = "Cross",
                    Size = 1,
                    Color = Color3.fromRGB(0, 255, 255),
                    Transparency = 0.3,
                    Duration = 0.1,
                    Pulse = true
                })
            end

            Debug:Print("SWING", "CHAIN", "Early Chain Target Found")
            self.swingState.inChainWindow = true
            self.swingState.chainDetected = true
            self:EndSwing()
            self:StartSwing(bestTarget.part)
            return
        end
    end

    local targetPosition = self.swingState.pathCurve:CalculatePositionAt(alpha)
    local nextPosition = self.swingState.pathCurve:CalculatePositionAt(math.min(alpha + 0.1, 1))

    local toTarget = (targetPosition - humanoidRootPart.Position)
    local targetVelocity = toTarget.Unit * CONFIG.SWING.PHYSICS.PATH_FOLLOW_SPEED

    local currentVel = self.swingState.bodyVelocity.VectorVelocity
    local newVel = currentVel:Lerp(targetVelocity, delta * CONFIG.SWING.PHYSICS.PATH_CORRECTION_RATE)
    self.swingState.bodyVelocity.VectorVelocity = newVel

    local lookDir = (nextPosition - targetPosition).Unit
    local targetCFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), lookDir)

    if self.swingState.lastCFrame then
        local rotationDelta = (targetCFrame.Rotation:ToObjectSpace(self.swingState.lastCFrame.Rotation)).Position.Magnitude
        if rotationDelta < 1 then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(targetCFrame, delta * CONFIG.SWING.MOVEMENT.ROTATION_SPEED)
            self.swingState.lastCFrame = humanoidRootPart.CFrame
        end
    end
end

--[[ Wall Functions ]]
function MovementClient:SetupWall()
    if not self:ValidateCharacter() then return end

    if not self.wallRunState then
        self.wallRunState = {
            isWallRunning = false,
            canWallRun = true,
            currentDuration = 0,
            currentFalloff = 0,
            direction = nil,
            lastWallRunTime = 0,
            bodyVelocity = Instance.new("LinearVelocity"),
            attachment = Instance.new("Attachment"),
            wallNormal = Vector3.new(0, 0, 0),
            wallPosition = Vector3.new(0, 0, 0),
            shuffleVelocity = Vector3.new(0, 0, 0),
            shuffleSpeed = 10
        }

        self.wallRunState.bodyVelocity.Attachment0 = self.wallRunState.attachment
        self.wallRunState.bodyVelocity.MaxForce = math.huge
        self.wallRunState.bodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        self.wallRunState.bodyVelocity.Enabled = false
        self.wallRunState.attachment.Parent = characterRef.HumanoidRootPart
        self.wallRunState.bodyVelocity.Parent = characterRef.HumanoidRootPart
    end
end

function MovementClient:StartWall(direction)
    if not self:ValidateCharacter() then return end
    if not self.wallRunState or not self.wallRunState.canWallRun then return end
    if self.wallRunState.isWallRunning then return end
    if movementState.isRagdoll or movementState.isSliding then return end

    local currentTime = os.clock()
    if currentTime - self.wallRunState.lastWallRunTime < CONFIG.WALL_RUN.COOLDOWN then
        return
    end

    local isRightSide = direction == "right"
    local wallDirection = isRightSide and characterRef.HumanoidRootPart.CFrame.RightVector or -characterRef.HumanoidRootPart.CFrame.RightVector

    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.RespectCanCollide = true
    params.FilterDescendantsInstances = {characterRef}

    local raycastResult = workspace:Raycast(
        characterRef.HumanoidRootPart.Position,
        wallDirection * CONFIG.WALL_RUN.CHECK_DISTANCE,
        params
    )

    if not raycastResult then return end
    if raycastResult.Normal.Y > CONFIG.WALL_RUN.ANGLE_THRESHOLD / 90 then return end

    self.wallRunState.isWallRunning = true
    self.wallRunState.direction = direction
    self.wallRunState.currentDuration = CONFIG.WALL_RUN.DURATION
    self.wallRunState.currentFalloff = CONFIG.WALL_RUN.SUSTAIN
    self.wallRunState.wallNormal = raycastResult.Normal
    self.wallRunState.wallPosition = raycastResult.Position
    self.wallRunState.lastWallRunTime = currentTime

    local cf = CFrame.lookAt(characterRef.HumanoidRootPart.Position, raycastResult.Position) * 
               CFrame.Angles(0, math.rad(isRightSide and 90 or -90), 0)

    characterRef.HumanoidRootPart.CFrame = cf

    local velocity = cf.LookVector * CONFIG.WALL_RUN.SPEED * Vector3.new(1, 0, 1) - Vector3.new(0, self.wallRunState.currentFalloff, 0)
    self.wallRunState.bodyVelocity.VectorVelocity = velocity
    self.wallRunState.bodyVelocity.Enabled = true

    self:StopAnimation({"LOCOMOTION"})
    self:PlayAnimation("WALL", isRightSide and "RUN_RIGHT" or "RUN_LEFT")

    humanoidRef.AutoRotate = false

    return true
end

function MovementClient:StopWall()
    if not self:ValidateCharacter() then return end
    if not self.wallRunState or not self.wallRunState.isWallRunning then return end

    self.wallRunState.bodyVelocity.Enabled = false
    self.wallRunState.isWallRunning = false

    humanoidRef.AutoRotate = true

    local humanoidRootPart = characterRef.HumanoidRootPart
    if CONFIG.WALL_RUN.EXIT_BOOST > 0 then
        local boostDirection = (humanoidRootPart.CFrame.LookVector + self.wallRunState.wallNormal).Unit
        humanoidRootPart:ApplyImpulse(boostDirection * CONFIG.WALL_RUN.EXIT_BOOST)
    end

    self:StopAnimation({"WALL"})
    self:PlayAnimation("LOCOMOTION", "FALL")
end

function MovementClient:CheckWall(delta)
    if not self:ValidateCharacter() then return end
    if humanoidRef:GetState() ~= Enum.HumanoidStateType.Freefall then return end
    if not keyStates.Space then return end

    if self.wallRunState.isWallRunning then return end
    local currentTime = os.clock()
    if currentTime - self.wallRunState.lastWallRunTime < CONFIG.WALL_RUN.COOLDOWN then return end

    if movementState.isRagdoll or movementState.isSliding then return end

    local swingPoint = self:DetectSwing()
    if swingPoint then
        self:StartSwing(swingPoint)
        return
    end

    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.RespectCanCollide = true
    params.FilterDescendantsInstances = {characterRef}

    local leftCheck = workspace:Raycast(
        characterRef.HumanoidRootPart.Position,
        -characterRef.HumanoidRootPart.CFrame.RightVector * CONFIG.WALL_RUN.CHECK_DISTANCE,
        params
    )

    local rightCheck = workspace:Raycast(
        characterRef.HumanoidRootPart.Position,
        characterRef.HumanoidRootPart.CFrame.RightVector * CONFIG.WALL_RUN.CHECK_DISTANCE,
        params
    )

    if leftCheck and rightCheck then
        if keyStates.A then
            self:StartWall("left")
        elseif keyStates.D then
            self:StartWall("right")
        end
    elseif leftCheck then
        self:StartWall("left")
    elseif rightCheck then
        self:StartWall("right")
    end
end

function MovementClient:UpdateWall(deltaTime)
    if not self:ValidateCharacter() then return end
    if not self.wallRunState or not self.wallRunState.isWallRunning then return end

    local isRightSide = self.wallRunState.direction == "right"
    local wallDirection = isRightSide and characterRef.HumanoidRootPart.CFrame.RightVector or -characterRef.HumanoidRootPart.CFrame.RightVector

    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.RespectCanCollide = true
    params.FilterDescendantsInstances = {characterRef}

    local raycastResult = workspace:Raycast(
        characterRef.HumanoidRootPart.Position,
        wallDirection * CONFIG.WALL_RUN.CHECK_DISTANCE,
        params
    )

    if self.wallRunState.currentDuration > 0 then
        self.wallRunState.currentDuration -= deltaTime
    end

    if self.wallRunState.currentDuration <= 0 and self.wallRunState.currentFalloff > 0 then
        self.wallRunState.currentFalloff -= deltaTime
    end

    self:UpdateWallShuffle(deltaTime, raycastResult)

    if raycastResult and self.wallRunState.bodyVelocity.Enabled then
        local currentVelocity = self.wallRunState.bodyVelocity.VectorVelocity
        local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
        
        local gravityEffect = -workspace.Gravity * CONFIG.WALL_RUN.GRAVITY_FACTOR * deltaTime
        local newVerticalVelocity = currentVelocity.Y + gravityEffect
        
        self.wallRunState.bodyVelocity.VectorVelocity = horizontalVelocity + Vector3.new(0, newVerticalVelocity, 0)
    end

    if self.wallRunState.currentDuration <= 0 or not raycastResult or not keyStates.Space then
        self:StopWall()
        self:UpdateMove()
    end
end

function MovementClient:UpdateWallShuffle(deltaTime, raycastResult)
    if not self:ValidateCharacter() then return end
    if not self.wallRunState or not self.wallRunState.isWallRunning then return end
    if not raycastResult then return end

    local moveDir = Vector3.new(0, 0, 0)
    local wallNormal = raycastResult.Normal
    local humanoidRootPart = characterRef.HumanoidRootPart

    local upVector = Vector3.new(0, 1, 0)

    local sideVector = wallNormal:Cross(upVector).Unit

    if self.wallRunState.direction == "left" then
        sideVector = -sideVector
    end

    if keyStates.W then
        moveDir = moveDir + upVector
    end
    if keyStates.S then
        moveDir = moveDir - upVector
    end
    if keyStates.D then
        moveDir = moveDir + sideVector
    end
    if keyStates.A then
        moveDir = moveDir - sideVector
    end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * self.wallRunState.shuffleSpeed

        local debugPart = Instance.new("Part")
        debugPart.Size = Vector3.new(0.2, 0.2, 0.2)
        debugPart.Anchored = true
        debugPart.CanCollide = false
        debugPart.Color = Color3.fromRGB(255, 0, 0)
        debugPart.Position = humanoidRootPart.Position
        debugPart.Parent = workspace
        game:GetService("Debris"):AddItem(debugPart, 0.1)

        local nextPos = humanoidRootPart.Position + moveDir * deltaTime
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {characterRef}

        local wallCheck = workspace:Raycast(
            nextPos,
            wallNormal * -2,
            params
        )

        if wallCheck then
            local currentVelocity = self.wallRunState.bodyVelocity.VectorVelocity
            local verticalVelocity = Vector3.new(0, currentVelocity.Y, 0)
            local horizontalVelocity = moveDir

            self.wallRunState.bodyVelocity.VectorVelocity = horizontalVelocity + verticalVelocity
            self.wallRunState.shuffleVelocity = moveDir

            humanoidRootPart.CFrame = CFrame.lookAt(
                humanoidRootPart.Position, 
                humanoidRootPart.Position + wallNormal * -1
            )
        else
            self.wallRunState.shuffleVelocity = Vector3.new(0, 0, 0)
        end
    else
        self.wallRunState.shuffleVelocity = Vector3.new(0, 0, 0)
    end
end

--[[ Head Functions ]]
function MovementClient:UpdateHead(delta)
    if not self:ValidateCharacter() then return end

    local neck = characterRef:FindFirstChild("Torso") and characterRef.Torso:FindFirstChild("Neck") or
                 characterRef:FindFirstChild("UpperTorso") and characterRef.UpperTorso:FindFirstChild("Neck")
    if not neck then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local humanoidRootPart = characterRef.HumanoidRootPart
    local cameraDirection = humanoidRootPart.CFrame:ToObjectSpace(camera.CFrame).LookVector.Unit
    local neckC0 = neck.C0

    local horizontalAngle = math.clamp(-math.asin(cameraDirection.X), -math.pi/2, math.pi/2)
    local verticalAngle = math.clamp(-math.pi/2 + math.asin(cameraDirection.Y), -math.pi/2, math.pi/2)

    local newNeckC0
    if cameraDirection.Z > 0 then
        newNeckC0 = CFrame.new(neckC0.Position) *
                    CFrame.Angles(0, horizontalAngle, 0) *
                    CFrame.Angles(math.pi - verticalAngle, 0, math.pi)
    else
        newNeckC0 = CFrame.new(neckC0.Position) *
                    CFrame.Angles(0, horizontalAngle, 0) *
                    CFrame.Angles(verticalAngle, 0, math.pi)
    end

    neck.C0 = neck.C0:Lerp(newNeckC0, delta * 10)
end

--[[ Ragdoll Functions ]]
function MovementClient:CreateCollider(part)
    if not part then return end

    local collider = Instance.new("Part")
    collider.Name = "ColliderPart"
    collider.Size = part.Size / 1.7
    collider.Massless = true
    collider.CFrame = part.CFrame
    collider.Transparency = 1
    collider.Anchored = false
    collider.CanCollide = true

    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Part0 = collider
    weldConstraint.Part1 = part
    weldConstraint.Parent = collider

    collider.Parent = part

    return collider
end

function MovementClient:SetupRagdoll()
    humanoidRef.BreakJointsOnDeath = false
    humanoidRef.RequiresNeck = false
    humanoidRef.AutoRotate = false

    if humanoidRef:GetState() ~= Enum.HumanoidStateType.Ragdoll then
        humanoidRef:ChangeState(Enum.HumanoidStateType.Ragdoll)
    end
    humanoidRef:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

    for _, part in pairs(characterRef:GetDescendants()) do
        if part:IsA("BasePart") then
            local isMainPart = table.find(CONFIG.RAGDOLL.MAIN_PARTS, part.Name) ~= nil
            if isMainPart then
                part.Anchored = false
                part.CanCollide = true
            else
                part.CanCollide = false
            end
        end
    end

    for _, motor in pairs(characterRef:GetDescendants()) do
        if motor:IsA("Motor6D") then
            local attachmentConfig = CONFIG.RAGDOLL.ATTACHMENT_CFRAMES[motor.Name]
            if not attachmentConfig then continue end

            motor.Enabled = false

            local attachment0 = Instance.new("Attachment")
            local attachment1 = Instance.new("Attachment")

            attachment0.CFrame = attachmentConfig[1]
            attachment1.CFrame = attachmentConfig[2]

            attachment0.Name = "RagdollAttachment"
            attachment1.Name = "RagdollAttachment"

            if table.find(CONFIG.RAGDOLL.MAIN_PARTS, motor.Part1.Name) then
                MovementClient:CreateCollider(motor.Part1)
            end

            local ballSocket = Instance.new("BallSocketConstraint")
            ballSocket.Attachment0 = attachment0
            ballSocket.Attachment1 = attachment1
            ballSocket.Name = "RagdollConstraint"

            ballSocket.Radius = 0.15
            ballSocket.LimitsEnabled = true
            ballSocket.TwistLimitsEnabled = false
            ballSocket.MaxFrictionTorque = 0
            ballSocket.Restitution = 0
            ballSocket.UpperAngle = 90
            ballSocket.TwistLowerAngle = -45
            ballSocket.TwistUpperAngle = 45

            if motor.Name == "Neck" then
                ballSocket.TwistLimitsEnabled = true
                ballSocket.UpperAngle = 45
                ballSocket.TwistLowerAngle = -70
                ballSocket.TwistUpperAngle = 70
            end

            attachment0.Parent = motor.Part0
            attachment1.Parent = motor.Part1
            ballSocket.Parent = motor.Parent
        end
    end

    local torso = characterRef:FindFirstChild("Torso") or characterRef:FindFirstChild("UpperTorso")
    if torso then
        torso:ApplyImpulse(torso.CFrame.LookVector * CONFIG.RAGDOLL.IMPULSE_FORCE)
    end
end

function MovementClient:ResetRagdoll()
    humanoidRef:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

    humanoidRef.AutoRotate = true
    humanoidRef.PlatformStand = false
    humanoidRef.RequiresNeck = true
    humanoidRef.BreakJointsOnDeath = true

    for _, instance in pairs(characterRef:GetDescendants()) do
        if CONFIG.RAGDOLL.INSTANCE_NAMES[instance.Name] then
            instance:Destroy()
        end

        if instance:IsA("Constraint") or instance:IsA("BallSocketConstraint") then
            instance:Destroy()
        end
    end

    for _, motor in pairs(characterRef:GetDescendants()) do
        if motor:IsA("Motor6D") then
            motor.Enabled = true
        end
    end

    for _, part in pairs(characterRef:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
                part.CustomPhysicalProperties = nil
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end

    humanoidRef:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    humanoidRef:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

    local humanoidRootPart = characterRef:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.Anchored = true
        task.delay(0.05, function()
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.Anchored = false
            end
        end)
    end

    if humanoidRef:GetState() == Enum.HumanoidStateType.Ragdoll then
        humanoidRef:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    task.delay(0.1, function()
        if humanoidRef and humanoidRef.Parent then
            humanoidRef:Move(Vector3.new(0, 0, 0.01))
        end
    end)
end

function MovementClient:EndRagdoll()
    if not movementState.isRagdoll then return end

    movementState.ragdollStartTime = 0
    movementState.ragdollDuration = 0

    self:ResetRagdoll()

    task.delay(0.1, function()
        if self:ValidateCharacter() then
            self:SetState("RAGDOLL", false)

            task.delay(0.1, function()
                if self:ValidateCharacter() and not movementState.isRagdoll then
                    self:PlayAnimation("LOCOMOTION", "IDLE")
                end
            end)
        end
    end)
end

function MovementClient:StartRagdoll(duration)
    if movementState.isRagdoll then return end

    if cameraState.isShiftLocked then
        self:ToggleShiftLock()
    end

    if movementState.isCrouching then
        self:SetState("CROUCHING", false)
    end

    if movementState.isSprinting then
        self:SetState("RUNNING", false)
    end

    if self.ledgeState and self.ledgeState.isClimbing then
        self:DropLedge()
    end

    if self.swingState and self.swingState.isSwinging then
        self:EndSwing()
    end

    if self.vaultState and self.vaultState.isVaulting then
        self.vaultState.isVaulting = false
        movementState.isVaulting = false
        if characterRef.HumanoidRootPart then
            characterRef.HumanoidRootPart.Anchored = false
        end
    end

    if self.wallRunState and self.wallRunState.isWallRunning then
        self:StopWall()
    end

    self:StopAnimation({"LOCOMOTION"})
    self:StopAnimation({"SPECIAL"})
    self:StopAnimation({"LANDING"})
    self:StopAnimation({"LEDGE"})
    self:StopAnimation({"WALL"})
    self:StopAnimation({"ROLL"})

    movementState.ragdollStartTime = os.clock()
    movementState.ragdollDuration = duration or CONFIG.RAGDOLL.DURATION

    self:SetState("RAGDOLL", true)
    self:PlayAnimation("STATUS", "PAIN_2")

    task.delay(0.05, function()
        if humanoidRef and humanoidRef.Parent and movementState.isRagdoll then
            if humanoidRef:GetState() ~= Enum.HumanoidStateType.Ragdoll then
                humanoidRef:ChangeState(Enum.HumanoidStateType.Ragdoll)
            end
        end
    end)

    if duration and duration > 0 then
        task.delay(duration, function()
            if movementState.isRagdoll then
                self:EndRagdoll()
            end
        end)
    end
end

--[[ Velocity Functions ]]
function MovementClient:TrackVelocity()
    if not self:ValidateCharacter() then return end

    if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
        local currentVelocity = characterRef.HumanoidRootPart.AssemblyLinearVelocity.Y

        if currentVelocity < 0 and currentVelocity < movementState.maxFallVelocity then
            movementState.maxFallVelocity = currentVelocity
        end

        movementState.lastVerticalVelocity = currentVelocity
    end
end

--[[ Camera Functions ]]
function MovementClient:LockCamera()
    if not cameraState.isLocked then
        cameraState.previousCameraType = workspace.CurrentCamera.CameraType
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        cameraState.isLocked = true
    end
end

function MovementClient:UnlockCamera()
    if cameraState.isLocked then
        workspace.CurrentCamera.CameraType = cameraState.previousCameraType or Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        cameraState.isLocked = false
    end
end

--[[ Emote Functions ]]
function MovementClient:SetupEmotes()
    if not self:ValidateCharacter() then return end

    if uiState.emoteMenu.frame then return end

    local playerGui = self.LocalPlayer:WaitForChild("PlayerGui")
    local emoteGui = playerGui:WaitForChild("EmoteGui")

    uiState.emoteMenu.frame = emoteGui:WaitForChild("Background")
    uiState.emoteMenu.scrollFrame = uiState.emoteMenu.frame:WaitForChild("ScrollingFrame")
end

function MovementClient:CreateEmoteButton(category, emoteName)
    if not self:ValidateCharacter() then return end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    button.BackgroundTransparency = 0.5
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.Font = Enum.Font.Antique
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 20
    button.Text = emoteName:gsub("_", " ")
    button.AutoButtonColor = true

    button.MouseButton1Click:Connect(function()
        local animKey = category .. "_" .. emoteName
        if not animState.animations[animKey] then
            local originalColor = button.BackgroundColor3
            button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            task.delay(0.2, function()
                button.BackgroundColor3 = originalColor
                task.delay(0.1, function()
                    self:ToggleEmotes(false)
                end)
            end)
        return
    end

        self:PlayAnimation(category, emoteName)
        self:ToggleEmotes(false)
    end)

    return button
end

function MovementClient:ToggleEmotes(show)
    if not self:ValidateCharacter() then return end
    self:SetupEmotes()

    if not uiState.emoteMenu.frame then return end

    if show ~= nil then
        uiState.emoteMenu.isOpen = show
    else
        uiState.emoteMenu.isOpen = not uiState.emoteMenu.isOpen
    end

    if uiState.emoteMenu.isOpen then
        movementState.isStunned = true
        uiState.emoteMenu.frame.Visible = true
        local scrollFrame = uiState.emoteMenu.scrollFrame

        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local yOffset = 5
        for emoteName, _ in pairs(Modules.Animation.Assets.Animations.EMOTES or {}) do
            local button = self:CreateEmoteButton("EMOTES", emoteName)
            button.Position = UDim2.new(0, 5, 0, yOffset)
            button.Parent = scrollFrame
            button.BackgroundTransparency = 1
            button.TextTransparency = 1
            yOffset = yOffset + 45
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

        local tweenInfo = TweenInfo.new(CONFIG.UI_SETTINGS.EMOTE_MENU.FADE_DURATION, Enum.EasingStyle.Quad)
        local tween = game:GetService("TweenService"):Create(uiState.emoteMenu.frame, tweenInfo, {
            ImageTransparency = 0
        })
        tween:Play()

        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                local buttonTween = game:GetService("TweenService"):Create(child, tweenInfo, {
                    BackgroundTransparency = 0.5,
                    TextTransparency = 0
                })
                buttonTween:Play()
            end
        end
    else
        local scrollFrame = uiState.emoteMenu.scrollFrame
        local tweenInfo = TweenInfo.new(CONFIG.UI_SETTINGS.EMOTE_MENU.FADE_DURATION, Enum.EasingStyle.Quad)

        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                local buttonTween = game:GetService("TweenService"):Create(child, tweenInfo, {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })
                buttonTween:Play()
            end
        end

        local tween = game:GetService("TweenService"):Create(uiState.emoteMenu.frame, tweenInfo, {
            ImageTransparency = 1
        })
        tween:Play()

        tween.Completed:Connect(function()
            uiState.emoteMenu.frame.Visible = false
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
        end)
    end

    movementState.isStunned = uiState.emoteMenu.isOpen
end

--[[ Death Functions ]]
function MovementClient:SetupDeath()
    if not self:ValidateCharacter() then return end

    if uiState.deathOverlay.frame then return end

    local playerGui = self.LocalPlayer:WaitForChild("PlayerGui")
    local deathGui = playerGui:FindFirstChild("DeathOverlay")

    if not deathGui then
        deathGui = Instance.new("ScreenGui")
        deathGui.Name = "DeathOverlay"
        deathGui.DisplayOrder = 10000
        deathGui.Parent = playerGui

        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = CONFIG.UI_SETTINGS.DEATH_OVERLAY.COLOR
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Parent = deathGui
    end

    uiState.deathOverlay.frame = deathGui:WaitForChild("Overlay")
    uiState.deathOverlay.transparency = 1
end

function MovementClient:FadeDeath(fadeIn)
    self:SetupDeath()

    if not uiState.deathOverlay.frame then return end

    local targetTransparency = fadeIn and 0 or 1
    local tweenInfo = TweenInfo.new(
        CONFIG.UI_SETTINGS.DEATH_OVERLAY.FADE_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tween = game:GetService("TweenService"):Create(
        uiState.deathOverlay.frame,
        tweenInfo,
        {BackgroundTransparency = targetTransparency}
    )

    tween:Play()
    uiState.deathOverlay.transparency = targetTransparency
end

--[[ Shift Lock Functions ]]
function MovementClient:SetMouseState(enable)
    UserInputService.MouseBehavior = enable and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

function MovementClient:SetMouseIcon(enable)
    if not self:ValidateCharacter() then return end

    local mouse = self.LocalPlayer:GetMouse()
    mouse.Icon = enable and CONFIG.SHIFT_LOCK_CONFIG.LOCKED_MOUSE_ICON or
                (CONFIG.CURSOR_CONFIG.ENABLED and CONFIG.CURSOR_CONFIG.OVERRIDE_DEFAULT and
                CONFIG.CURSOR_CONFIG.DEFAULT_CURSOR or "")
end

function MovementClient:TransitionLockOffset(enable)
    if not cameraState.camOffsetSpring then
        cameraState.camOffsetSpring = Tools.Spring.new(Vector3.new(0, 0, 0))
        cameraState.camOffsetSpring.Damper = CONFIG.SHIFT_LOCK_CONFIG.TRANSITION_SPRING_DAMPER
    end

    if enable then
        cameraState.camOffsetSpring.Speed = CONFIG.SHIFT_LOCK_CONFIG.CAMERA_TRANSITION_IN_SPEED
        cameraState.camOffsetSpring.Target = CONFIG.SHIFT_LOCK_CONFIG.LOCKED_CAMERA_OFFSET
    else
        cameraState.camOffsetSpring.Speed = CONFIG.SHIFT_LOCK_CONFIG.CAMERA_TRANSITION_OUT_SPEED
        cameraState.camOffsetSpring.Target = Vector3.new(0, 0, 0)
    end

    cameraState.shiftLockOffset = cameraState.camOffsetSpring.Position
end

function MovementClient:ToggleShiftLock()
    if not self:ValidateCharacter() then return end
    if humanoidRef.Health <= 0 then return end

    if movementState.isRagdoll or (self.ledgeState and self.ledgeState.isClimbing) then
        if not cameraState.isShiftLocked then
            return
        end
    end

    cameraState.isShiftLocked = not cameraState.isShiftLocked

    self:SetMouseState(cameraState.isShiftLocked)
    self:SetMouseIcon(cameraState.isShiftLocked)
    self:TransitionLockOffset(cameraState.isShiftLocked)

    humanoidRef.AutoRotate = not cameraState.isShiftLocked
end

function MovementClient:UpdateShiftLock(delta)
    if not self:ValidateCharacter() then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local head = characterRef:FindFirstChild("Head")
    if not head then return end

    local distance = (head.Position - camera.CFrame.Position).Magnitude
    if distance > 1 then
        if cameraState.camOffsetSpring then
            cameraState.shiftLockOffset = cameraState.camOffsetSpring.Position
            if cameraState.shiftLockOffset.Magnitude > 0.01 then
                local lookVector = camera.CFrame.LookVector
                local rightVector = camera.CFrame.RightVector
                local upVector = camera.CFrame.UpVector

                local offset = rightVector * cameraState.shiftLockOffset.X +
                             upVector * cameraState.shiftLockOffset.Y +
                             lookVector * cameraState.shiftLockOffset.Z

                camera.CFrame = CFrame.new(camera.CFrame.Position + offset) *
                           CFrame.fromMatrix(Vector3.new(), rightVector, upVector, -lookVector)
            end
        end

        if cameraState.isShiftLocked and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            self:SetMouseState(true)
        end
    end

    if cameraState.isShiftLocked and not humanoidRef.Sit then
        local rootPart = characterRef:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local _, targetYaw, _ = camera.CFrame:ToOrientation()
        local currentCFrame = rootPart.CFrame
        local _, currentYaw, _ = currentCFrame:ToOrientation()

        local angleDiff = targetYaw - currentYaw
        while angleDiff > math.pi do angleDiff -= 2 * math.pi end
        while angleDiff < -math.pi do angleDiff += 2 * math.pi end

        local newYaw = currentYaw + (angleDiff * delta * 5 * CONFIG.SHIFT_LOCK_CONFIG.CHARACTER_ROTATION_SPEED)
        local newCFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, newYaw, 0)

        if CONFIG.SHIFT_LOCK_CONFIG.CHARACTER_SMOOTH_ROTATION then
            rootPart.CFrame = currentCFrame:Lerp(newCFrame, delta * 5 * CONFIG.SHIFT_LOCK_CONFIG.CHARACTER_ROTATION_SPEED)
        else
            rootPart.CFrame = newCFrame
        end
    end
end

--[[ Footstep Functions ]]
function MovementClient:GetFloor()
    if not self:ValidateCharacter() then return "Air" end
    local floorMaterial = humanoidRef.FloorMaterial
    return floorMaterial and tostring(floorMaterial):gsub("Enum.Material.", "") or "Air"
end

function MovementClient:PlayFootstep(material)
    if footstepState.currentSound then
        footstepState.currentSound:Stop()
        footstepState.currentSound = nil
    end

    local baseSpeed = 10/12
    local config = {
        effects = {
            pitch = {
                Octave = 1.0
            }
        },
        loop = true
    }

    if movementState.isCrouching then
        config.speed = baseSpeed * 0.6
        config.effects.pitch.Octave = 1/0.6
    elseif movementState.isSprinting then
        config.speed = baseSpeed * 1.7
        config.effects.pitch.Octave = 1/1.6
    else
        config.speed = baseSpeed
    end

    footstepState.currentSound = Utility.Sound.Play("SFX.Footsteps." .. material, characterRef, config)
    footstepState.lastMaterial = material
end

function MovementClient:UpdateFootsteps()
    if not self:ValidateCharacter() then return end

    local isMoving = humanoidRef.MoveDirection.Magnitude > 0
    local isRunning = humanoidRef:GetState() == Enum.HumanoidStateType.Running or
                     humanoidRef:GetState() == Enum.HumanoidStateType.RunningNoPhysics
    local isNotSpecial = not movementState.isSliding and
                        not movementState.isRolling and
                        not movementState.isDashing and
                        not movementState.isRagdoll

    if isMoving and isRunning and isNotSpecial then
        local material = self:GetFloor()
        if footstepState.lastMaterial ~= material or
           footstepState.lastCrouchState ~= movementState.isCrouching or
           footstepState.lastSprintState ~= movementState.isSprinting then

            self:PlayFootstep(material)
            footstepState.lastCrouchState = movementState.isCrouching
            footstepState.lastSprintState = movementState.isSprinting
        end
    else
        if footstepState.currentSound then
            footstepState.currentSound:Stop()
            footstepState.currentSound = nil
        end
        footstepState.lastMaterial = nil
        footstepState.lastCrouchState = nil
        footstepState.lastSprintState = nil
    end
end

--[[ Initialization Functions ]]
function MovementClient:SetupAttributes()
    if not self:ValidateCharacter() then return end

    local function MonitorAttribute(attributeName)
        local matchedState = nil
        for stateName, stateData in pairs(CONFIG.STATE_DEFINITIONS) do
            if stateData.attributeName == attributeName then
                matchedState = stateData
                break
            end
        end

        if not matchedState then return end

        local value = characterRef:GetAttribute(attributeName)
        local fieldName = matchedState.fieldName

        if fieldName and movementState[fieldName] ~= value then
            movementState[fieldName] = value

            if attributeName == "RAGDOLL" then
                if value then
                    self:SetupRagdoll()
                else
                    self:ResetRagdoll()
                end
            end

            self:UpdateMove()
        end
    end

    for _, stateData in pairs(CONFIG.STATE_DEFINITIONS) do
        if stateData.attributeName then
            characterRef:GetAttributeChangedSignal(stateData.attributeName):Connect(function()
                MonitorAttribute(stateData.attributeName)
            end)
        end
    end
end

function MovementClient:CleanupPhysics()
    if self.swingState then
        if self.swingState.bodyVelocity then
            self.swingState.bodyVelocity:Destroy()
        end
        if self.swingState.attachment then
            self.swingState.attachment:Destroy()
        end
        self.swingState = nil
    end

    if self.wallRunState then
        if self.wallRunState.bodyVelocity then
            self.wallRunState.bodyVelocity:Destroy()
        end
        if self.wallRunState.attachment then
            self.wallRunState.attachment:Destroy()
        end
        self.wallRunState = nil
    end

    if self.rollState then
        if self.rollState.bodyVelocity then
            self.rollState.bodyVelocity:Destroy()
        end
        if self.rollState.attachment then
            self.rollState.attachment:Destroy()
        end
        self.rollState = nil
    end

    if self.airDashState then
        if self.airDashState.linearVelocity then
            self.airDashState.linearVelocity:Destroy()
        end
        if self.airDashState.attachment then
            self.airDashState.attachment:Destroy()
        end
        self.airDashState = nil
    end

    if self.slideState then
        if self.slideState.bodyVelocity then
            self.slideState.bodyVelocity:Destroy()
        end
        if self.slideState.attachment then
            self.slideState.attachment:Destroy()
        end
        self.slideState = nil
    end

    if self.ledgeState then
        if self.ledgeState.bodyVelocity then
            self.ledgeState.bodyVelocity:Destroy()
        end
        if self.ledgeState.attachment then
            self.ledgeState.attachment:Destroy()
        end
        self.ledgeState = nil
    end
end

function MovementClient:SetupCharacter(character)
    if not character then return end

    self:CleanupPhysics()

    animState.currentlyPlaying = { category = nil, name = nil }

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    humanoidRef = humanoid
    characterRef = character

    if not self:ValidateCharacter() then return end

    Utility.Sound.Monitor(character.HumanoidRootPart, {"Running"})

    for _, stateData in pairs(CONFIG.STATE_DEFINITIONS) do
        if stateData.fieldName then
            movementState[stateData.fieldName] = false
        end
    end

    movementState.lastWTapTime = 0
    movementState.ragdollStartTime = 0
    movementState.ragdollDuration = 0
    mechanicState.lastMechanicTime = 0
    mechanicState.cooldown = 0.1

    keyStates.W = false
    keyStates.A = false
    keyStates.S = false
    keyStates.D = false
    keyStates.C = false
    keyStates.Space = false

    animState.animations = Utility.Animation.Categories(animator, {
        "LOCOMOTION", "LANDING", "STATUS", "WALL", "LEDGE", "SPECIAL", "ROLL", "EMOTES"
    })

    humanoid.StateChanged:Connect(function(oldState, newState)
        self:ProcessState(humanoid, oldState, newState)

        if newState == Enum.HumanoidStateType.Landed and self.ledgeState then
            self.ledgeState.wallJumpDebounce = false
            self.ledgeState.wallJumpCount = 0
            self.ledgeState.initialJumpHeight = 0
        end
    end)

    animState.currentState = humanoid:GetState()
    self:PlayState(humanoid, animState.currentState)

    self:SetupAttributes()
    self:SetupLedge()
    self:SetupSwing()
    self:SetupRoll()
    self:SetupDash()
    self:SetupWall()
    self:SetupVault()
    self:SetupSlide()
    self:CheckMove()

    humanoid.Died:Connect(function()
        self:CleanupPhysics()
        self:FadeDeath(true)

        if uiState.emoteMenu.isOpen then
            self:ToggleEmotes(false)
        end
    end)

    self:FadeDeath(false)
end

function MovementClient:Initialize()
    if self.initialized then return end
    self.initialized = true

    self:SetupInput()

    for eventName, eventData in pairs(self.Events) do
        Services.Event:OnClientEvent(eventName, eventData.handler)
    end

    local character = self.LocalPlayer.Character
    if character then
        self:SetupCharacter(character)
    end

    self.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        self:FadeDeath(false)
        self:SetupCharacter(newCharacter)
    end)

    if CONFIG.CURSOR_CONFIG.ENABLED and CONFIG.CURSOR_CONFIG.OVERRIDE_DEFAULT then
        local mouse = self.LocalPlayer:GetMouse()
        mouse.Icon = CONFIG.CURSOR_CONFIG.DEFAULT_CURSOR
    end

    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = CONFIG.CAMERA_SETTINGS.FOV
        self.LocalPlayer.CameraMode = Enum.CameraMode.Classic
        self.LocalPlayer.CameraMinZoomDistance = CONFIG.CAMERA_SETTINGS.MIN_ZOOM
        self.LocalPlayer.CameraMaxZoomDistance = CONFIG.CAMERA_SETTINGS.MAX_ZOOM
    end

    RunService.RenderStepped:Connect(function(delta)
        if not characterRef or not humanoidRef then return end

        self:UpdateShiftLock(delta)
        self:UpdateShuffle()
        self:UpdateHead(delta)
        self:UpdateSwing(delta)
        self:UpdateWall(delta)
        self:CheckVault()
        self:CheckWall(delta)
        self:TrackVelocity()

        if humanoidRef:GetState() == Enum.HumanoidStateType.Freefall then
            if keyStates.Space then
                local swingPoint = self:DetectSwing()
                if swingPoint then
                    self:StartSwing(swingPoint)
                end
            end
        end
    end)
end

MovementClient:Initialize()

return MovementClient