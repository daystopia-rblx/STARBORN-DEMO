# SUN Engine Framework
*(Service Utility Network)*

A service-oriented game framework for Roblox that provides robust architecture, performance optimization, and developer productivity through modular services and comprehensive utilities for streamlined game development.

**Author**: Daystopia  
**Version**: 1.1.0 (ASCENDIUM Version)
**Created**: 2024-12-26
**Updated**: 2025-03-30

## Overview

## Architecture

### Game Services

- **StartService**
  - Manages service lifecycles with dependency handling and hot reloading
  - Configurable update rates with performance monitoring
  - Error recovery and state management
  - Event handling with hooks and middleware
  - Sync/async operation support

- **EventService**
  - Bidirectional server-client communication
  - Network optimization with throttling and rate limits
  - Event filtering and transformations
  - Cross-service event handling
  - Reliable/unreliable networking modes

- **DataService**
  - Template-based data structure system
  - Automated periodic data operations
  - Deep field verification and updates
  - Error recovery with retries
  - Cross-service data event handling

- **AssetService**
  - Dynamic resource loading
  - Asset pooling and optimization
  - Priority-based queueing
  - Asset variant management
  - Resource utilization monitoring

- **AudioService**
  - Advanced spatial audio system
  - Category-based sound management
  - Dynamic volume multipliers
  - Audio effects processing
  - Adaptive music transitions

- **ParticleService**
  - Dynamic effect generation
  - Performance-optimized emitters
  - Particle presets and templates
  - Effect intensity scaling
  - Visual effect sequencing

- **AnimationService**
  - Priority-based animation queueing
  - Smooth transition blending
  - Custom animation tracks
  - Animation speed control
  - Multi-track synchronization

- **MusicService**
  - Dynamic track selection
  - Cross-fading transitions
  - Region-based playlists
  - Adaptive intensity scaling
  - Mood-based track selection

- **ObjectService**
  - Modular object templates
  - Attribute inheritance system
  - Dynamic instance creation
  - Object variant management
  - Property normalization

- **ToolService**
  - Tool behavior templates
  - Custom interaction modes
  - Tool modification system
  - Usage tracking and limits
  - Multi-tool coordination

- **InteractService**
  - Custom proximity detection
  - Multi-prompt management
  - Dynamic key binding
  - Interaction queueing
  - Priority-based handling

- **ActionService**
  - Action validation system
  - Cooldown management
  - Conflict resolution
  - Action chaining
  - Input buffering

- **PlayerService**
  - Role-based configuration
  - Character customization
  - Team management
  - Player matchmaking
  - Session tracking

- **StatService**
  - Stat calculation system
  - Progress and leveling
  - Multiplier management
  - Regeneration mechanics
  - Stat modification rules

- **StateService**
  - State transition validation
  - Exclusive state management
  - State duration tracking
  - Cooldown management
  - Category-based state grouping
  - State effect handling
  - Conditional state transitions

- **TeleportService**
  - Server matchmaking
  - Queue priority system
  - Loading transitions
  - Group teleportation
  - Server validation

- **ZoneService**
  - Dynamic zone transitions
  - Area effect management
  - Zone type behaviors
  - Boundary detection
  - Region attributes

### Event System

The framework supports three types of event listeners with built-in validation and throttling:

1. **Service Events**
   - Inter-service communication
   - Automatic dependency handling
   - Optional schema validation for type safety
      ```lua
      ["ServiceName.Event"] = {
          validate = true,
          schema = { field = "type" }
      }
      ```

2. **Service Listeners**
   - Built-in event handling through service listeners
   - Automatic lifecycle management
   - Data validation and error handling
      ```lua
      ServiceName.Listeners = {
          ["Event.Name"] = function(self, data)
              -- Handle event
          end
      }
      ```

3. **Instance Signals**
   - Native Roblox instance signals
   - Automatic connection management
      ```lua
      [workspace.ChildAdded] = function(self, child) end
      ```

Events can be configured with the following options:

```lua
ExampleService.Events = {
    BasicEvent = true,     -- Equivalent to { server = true, client = true }

    CustomEvent = {
        server = true,     -- Allow server to fire (default: true)
        client = true,     -- Allow clients to fire (default: true)
        validate = true,   -- Validate incoming data (default: false)
        throttle = 0.1,    -- Seconds between fires (default: 0)
        reliable = true    -- Use reliable networking (default: true)
    },

    ServerEvent = {
        server = true,
        client = false     -- Prevent client firing
    },

    ThrottledEvent = {
        throttle = 0.1,    -- Rate limit client fires
        reliable = false   -- Use faster unreliable replication
    }
}
```

## Core Components

### Services
Services are modules that create core game systems with state, logic and events.

```Lua
local ExampleService = {}

ExampleService.Dependencies = {
    "OtherService"  -- List required dependencies
}

ExampleService.Events = {
    MyEvent = true  -- Define service events
}

ExampleService.Listeners = {
    -- Listen to another service's event
    ["OtherService.SomeEvent"] = function(self, ...)
        -- Handle event
    end,

    -- Listen to Player events
    ["Players.PlayerAdded"] = function(self, player)
        -- Handle new player
    end,

    -- Listen to Roblox instance signals
    [workspace.ChildAdded] = function(self, child)
        -- Handle new child
    end
}

function ExampleService:Init(services)
    Services = services
    return true
end

function ExampleService:Start()
    -- Start service
    return true
end

function ExampleService:Update(deltaTime)
    -- Perform per-frame updates
    -- deltaTime is the time elapsed since last frame
end

return ExampleService
```

### Handlers
Handlers are server scripts that process game events, handling specific tasks like player management while services manage core logic.

```lua
local ExampleHandler = {}

-- Import required services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

-- Define event handlers
local Events = {
    ["Client.Example.Action"] = {
        handler = function(player, data)
            -- Handle player action request
            -- Validate action data
            if not data.actionType then return end
            print(string.format("Player %s performed action: %s", player.Name, data.actionType))
        end
    },
    
    ["Client.Example.Request"] = {
        handler = function(player, data)
            -- Handle player request
            -- Validate request data
            if not data.requestType then return end
            print(string.format("Player %s made request: %s", player.Name, data.requestType))
        end
    }
}

-- Initialize event listeners
local function Initialize()
    for eventName, event in pairs(Events) do
        Services.Event:OnServerEvent(eventName, event.handler)
    end
end

Initialize()

return ExampleHandler
```

### Clients
Clients are local scripts that handle game state, user input, and user interface while communicating with the server.

```lua
local ExampleClient = {}

-- Import required services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

-- Define event handlers
local Events = {
    ["Client.Example.Update"] = {
        handler = function(data)
            print("Received update:", data)
            -- Handle event data
        end
    },
    
    ["Client.Example.Get"] = {
        handler = function(data)
            -- Process received data
            return true
        end
    }
}

-- Initialize event listeners
local function Initialize()
    for eventName, handler in pairs(Events) do
        Services.Event:OnClientEvent(eventName, handler.handler)
    end
end

Initialize()
```

### Interface Utilities
The framework includes a comprehensive set of interface creation utilities:

- **Animation**
  ```lua
  local Animation = require(client.Utility.Animation)
  
  -- Create smooth transitions
  Animation.Tween(frame, {
      Position = UDim2.new(0.5, 0, 0.5, 0)
  }, {
      duration = Animation.Duration.Short,
      easingStyle = Animation.Easing.Back
  })
  ```

- **Input**
  ```lua
  local Input = require(client.Utility.Input)
  
  -- Multi-platform input handling (PC, Console, Mobile)
  Input.HandleInput({
      -- Action bindings
      actions = {
          {
              name = "Inventory",
              keys = { 
                  Enum.KeyCode.Tab,
                  Enum.KeyCode.ButtonY
              }
          },
          {
              name = "Sprint",
              keys = { 
                  Enum.KeyCode.LeftShift,
                  Enum.KeyCode.ButtonR2
              },
              throttle = 0.1
          }
      },

      -- Camera zoom control
      axes = {
          name = "Zoom",
          keys = {
              [Enum.UserInputType.MouseWheel] = 1
              [Enum.KeyCode.DPadUp] = 0.5,
              [Enum.KeyCode.DPadDown] = -0.5,
              [Enum.UserInputType.TouchPinch] = 0.5
          },
          smooth = true,
          deadzone = 0.1
      }
  })
  ```

- **Scale**
  ```lua
  local Scale = require(client.Utility.Scale)
  
  -- Automatic UI scaling
  Scale.AutoScale(frame)
  ```

- **Sound**
  ```lua
  local Sound = require(client.Utility.Sound)
  
  -- Play UI sound effects
  Sound.Button("Primary")
  Sound.Toggle(true)
  Sound.Dropdown("Open")
  Sound.Notify("Success")
  Sound.Input("Submit")
  Sound.Nav("Forward")
  Sound.Action("Success")
  ```

- **Tab**
  ```lua
  local Tab = require(client.Utility.Tab)
  
  -- Register a new tab with open/close callbacks
  Tab.Create("Inventory", 
    function() -- Open callback
        -- Show inventory UI
    end,
    function() -- Close callback
        -- Hide inventory UI
    end
  )

  -- Toggle tab state
  Tab.Toggle("Inventory") -- Returns true if opened, false if closed

  -- Query tab states
  Tab.isOpen("Inventory")    -- Check if specific tab is open
  Tab.isActive()             -- Get name of currently active tab
  Tab.Get()                  -- Get list of all registered tabs

  -- Cleanup
  Tab.Close()                -- Close active tab
  Tab.Destroy("Inventory")   -- Remove tab registration
  ```