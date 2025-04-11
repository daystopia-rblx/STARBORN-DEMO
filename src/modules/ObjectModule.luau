--[[ ObjectModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-03-31
]]
local ObjectModule = {}

function ObjectModule.GetObject(name: string)
    name = name:upper()
    if ObjectModule.Templates[name] then return ObjectModule.Templates[name] end
    for _, category in pairs(ObjectModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

ObjectModule.Categories = {
    FURNITURE = "Furniture",
    CHECKPOINTS = "Checkpoints"
}

ObjectModule.CategoryGroups = {
    FURNITURE = {
        "SEATING"
    },
    CHECKPOINTS = {
        "BONFIRE",
        "BED"
    }
}

ObjectModule.Templates = {
    SEATING = {
        CHAIR = {
            defaults = { properties = { interaction = "seat" } },
            variants = {
                wooden = { name = "Wooden Chair", prefix = "Wooden", price = 10.00, description = "A basic wooden chair" },
            }
        }
    },

    BONFIRE = {
        defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.0 } },
        variants = {
            standard = { name = "Bonfire", description = "A place of respite. Rest here to restore health and set your spawn point." }
        }
    },
    BED = {
        defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.5 } },
        variants = {
            standard = { name = "Bed", description = "A modest bed for resting. Rest here to restore health and set your spawn point." }
        }
    }
}

return ObjectModule