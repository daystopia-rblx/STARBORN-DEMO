# SUN Engine Framework
*(Service Utility Network)*

A service-oriented game framework for Roblox that provides robust architecture, performance optimization, and developer productivity through modular services and comprehensive utilities for streamlined game development.

**Author**: Daystopia  
**Version**: 1.2.0 (ASCENDIUM Version)
**Created**: 2024-12-26
**Updated**: 2025-04-09

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

### Modules System

The framework features an automatic module importing system that handles dependency resolution and loading:

```lua
-- Simple category imports
Component.Tool = {"Promise", "Input"}

-- Path-based imports
Component.Data = {Citizens = "Dialogue/Citizens"}

-- Wildcard loading (all modules in the folder)
Component.Dialogue = {All = "Dialogue/*"}

local Services
local Modules

function Component:Init(services, modules)
    Services = services
    Modules = modules
    return true
end
```

### Event System

The framework supports three types of event listeners with built-in validation and throttling:

1. **Service/Controller Events**
   - Inter-component communication
   - Automatic dependency handling
   - Optional schema validation for type safety
      ```lua
      ["ComponentName.Event"] = {
          validate = true,
          schema = { field = "type" }
      }
      ```

2. **Listeners**
   - Built-in event handling through service/controller listeners
   - Automatic lifecycle management
   - Data validation and error handling
      ```lua
      ComponentName.Listeners = {
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
ComponentName.Events = {
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
Services are server-side modules that create core game systems with state, logic and events.

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

local Services
local Modules

function ExampleService:Init(services, modules)
    Services = services
    Modules = modules
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

### Controllers
Controllers are client-side modules that handle user interface, input, and local game state.

```lua
local ExampleController = {}

ExampleController.Dependencies = {
    "Event"
}

ExampleController.Events = {
    LocalUpdate = {
        server = false,
        client = true,
        local_only = true
    }
}

local Controllers
local Modules

ExampleController.Listeners = {
    ["Service.Event"] = function(self, data)
        -- Handle server event
        print("Received event from server:", data)
        -- Update local state
        self:UpdateFrame(data)
    end
}

function ExampleController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function ExampleController:Start()
    -- Initialize UI elements
    self:CreateFrame()
    return true
end

function ExampleController:CreateFrame()
    -- Create user interface elements
end

function ExampleController:UpdateFrame(data)
    -- Update interface based on data
end

function ExampleController:RequestData(type)
    -- Send request to server
    Controllers.Event:FireServer("Service.Request", type)
end

return ExampleController
```

### Interface Utilities
The framework includes a comprehensive set of interface creation utilities:

- **Animation**
  ```lua
  local Animation = require(ReplicatedStorage.Modules.Utility.Animation)
  
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
  local Input = require(ReplicatedStorage.Modules.Utility.Input)
  
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
              [Enum.UserInputType.MouseWheel] = 1,
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
  local Scale = require(ReplicatedStorage.Modules.Utility.Scale)
  
  -- Automatic UI scaling
  Scale.AutoScale(frame)
  ```

- **Sound**
  ```lua
  local Sound = require(ReplicatedStorage.Modules.Utility.Sound)
  
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
  local Tab = require(ReplicatedStorage.Modules.Utility.Tab)
  
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