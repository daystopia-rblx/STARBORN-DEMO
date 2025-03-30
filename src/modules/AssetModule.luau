--[[ AssetModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local AssetModule = {}

-- Asset Types
AssetModule.Types = {
    ANIMATION = "Animation",
    SOUND = "Sound",
    PARTICLE = "ParticleEmitter",
    IMAGE = "ImageLabel",
    DECAL = "Decal",
    MESH = "MeshPart",
    TEXTURE = "Texture",
    TRAIL = "Trail",
    BEAM = "Beam",
    MODEL = "Model"
}

-- Property Maps
AssetModule.Properties = {
    Animation = {
        speed = "PlaybackSpeed",
        priority = "Priority",
        looped = "Looped",
        weight = "Weight"
    },
    Sound = {
        volume = "Volume",
        pitch = "PlaybackSpeed",
        looped = "Looped",
        spatial = "RollOffMode",
        maxDistance = "RollOffMaxDistance",
        minDistance = "RollOffMinDistance",
        timePosition = "TimePosition"
    },
    ParticleEmitter = {
        color = "Color",
        size = "Size",
        transparency = "Transparency",
        rate = "Rate",
        speed = "Speed",
        lifetime = "Lifetime",
        enabled = "Enabled",
        lightEmission = "LightEmission",
        lightInfluence = "LightInfluence",
        orientation = "Orientation",
        rotSpeed = "RotSpeed",
        rotation = "Rotation",
        shape = "Shape",
        spreadAngle = "SpreadAngle",
        squash = "Squash",
        acceleration = "Acceleration",
        drag = "Drag",
        timeScale = "TimeScale",
        velocityInheritance = "VelocityInheritance",
        zOffset = "ZOffset"
    },
    ImageLabel = {
        size = "Size",
        position = "Position",
        transparency = "ImageTransparency",
        color = "ImageColor3",
        rectOffset = "ImageRectOffset",
        rectSize = "ImageRectSize",
        scaleType = "ScaleType",
        sliceCenter = "SliceCenter",
        tileSize = "TileSize"
    },
    Decal = {
        transparency = "Transparency",
        color = "Color3",
        offset = "StudsOffsetWorldSpace",
        face = "Face"
    },
    MeshPart = {
        textureId = "TextureID",
        size = "Size",
        color = "Color",
        material = "Material",
        collisionFidelity = "CollisionFidelity",
        renderFidelity = "RenderFidelity"
    },
    Texture = {
        transparency = "Transparency",
        color = "Color3",
        studsPer = { "StudsPerTileU", "StudsPerTileV" },
        offset = { "OffsetStudsU", "OffsetStudsV" },
        face = "Face"
    },
    Trail = {
        color = "Color",
        transparency = "Transparency",
        lifetime = "Lifetime",
        minLength = "MinLength",
        maxLength = "MaxLength",
        widthScale = "WidthScale",
        textureMode = "TextureMode"
    },
    Beam = {
        color = "Color",
        transparency = "Transparency",
        width = { "Width0", "Width1" },
        curveSize = { "CurveSize0", "CurveSize1" },
        segments = "Segments",
        textureMode = "TextureMode",
        textureSpeed = "TextureSpeed"
    },
    Model = {
        size = "PrimaryPart.Size",
        position = "PrimaryPart.Position",
        orientation = "PrimaryPart.Orientation",
        anchored = "PrimaryPart.Anchored",
        collisionGroup = "PrimaryPart.CollisionGroup"
    }
}

-- Validation Rules
AssetModule.Validation = {
    required = {
        Animation = { "id" },
        Sound = { "id" },
        ParticleEmitter = { "id" },
        ImageLabel = { "id" },
        Decal = { "id" },
        MeshPart = { "id" },
        Texture = { "id" },
        Trail = { "id" },
        Beam = { "id" },
        Model = { "id" }
    },
    types = {
        id = "string",
        speed = "number",
        volume = "number",
        rate = "number",
        size = { "number", "Vector3", "UDim2" },
        color = { "Color3", "ColorSequence" },
        transparency = { "number", "NumberSequence" },
        enabled = "boolean",
        looped = "boolean"
    }
}

-- Asset Configuration
AssetModule.Config = {
    Animation = {
        folder = "Animations",
        idProp = "AnimationId",
        defaults = {
            looped = true,
            priority = Enum.AnimationPriority.Core,
            weight = 1
        }
    },
    Sound = {
        folder = "Sounds",
        idProp = "SoundId",
        defaults = {
            volume = 0.5,
            rollOffMode = Enum.RollOffMode.InverseTapered,
            maxDistance = 100
        }
    },
    ParticleEmitter = {
        folder = "Particles",
        idProp = "Texture",
        defaults = {
            enabled = true,
            lifetime = NumberRange.new(1),
            rate = 20
        }
    },
    ImageLabel = {
        folder = "Images",
        idProp = "Image",
        defaults = {
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Stretch
        }
    },
    Decal = {
        folder = "Decals",
        idProp = "Texture",
        defaults = {
            transparency = 0
        }
    },
    MeshPart = {
        folder = "Meshes",
        idProp = "MeshId",
        defaults = {
            material = Enum.Material.SmoothPlastic,
            collisionFidelity = Enum.CollisionFidelity.Default
        }
    },
    Texture = {
        folder = "Textures",
        idProp = "Texture",
        defaults = {
            StudsPerTileU = 2,
            StudsPerTileV = 2
        }
    },
    Trail = {
        folder = "Trails",
        idProp = "Texture",
        defaults = {
            lifetime = 1,
            minLength = 0.1,
            maxLength = 10
        }
    },
    Beam = {
        folder = "Beams",
        idProp = "Texture",
        defaults = {
            segments = 10,
            textureMode = Enum.TextureMode.Stretch
        }
    },
    Model = {
        folder = "Models",
        idProp = "id",
        defaults = {
            anchored = true
        }
    }
}

-- Asset Categories
AssetModule.Categories = {
    CHARACTER = {
        name = "Character",
        priority = 1,
        dependencies = { "ANIMATION", "PARTICLE" }
    },
    EFFECT = {
        name = "Effect",
        priority = 2,
        dependencies = { "PARTICLE", "SOUND" }
    },
    UI = {
        name = "UI",
        priority = 3,
        dependencies = { "IMAGE" }
    },
    WORLD = {
        name = "World",
        priority = 4,
        dependencies = { "MODEL", "TEXTURE", "DECAL" }
    },
    ITEM = {
        name = "Item",
        priority = 5,
        dependencies = { "MODEL", "PARTICLE", "SOUND" }
    }
}

-- Asset States
AssetModule.States = {
    DEFAULT = "Default",
    ACTIVE = "Active",
    INACTIVE = "Inactive",
    DISABLED = "Disabled",
    HIGHLIGHTED = "Highlighted",
    SELECTED = "Selected"
}

return AssetModule