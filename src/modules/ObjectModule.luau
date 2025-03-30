
--[[ ObjectModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local ObjectModule = {}

function ObjectModule.GetName(name: string)
    for categoryName, category in pairs(ObjectModule.Templates) do
        for objectName, object in pairs(category) do
            if objectName == name then
                return object
            end
        end
    end
    return nil
end

ObjectModule.Categories = {
    FURNITURE = "Furniture",
    WEAPONS = "Weapons",
}

ObjectModule.CategoryGroups = {
    FURNITURE = {
        "SEATING"
    },
    WEAPONS = {
        "SWORD"
    }
}

ObjectModule.Templates = {
    SEATING = {
        CHAIR = {
            defaults = { properties = { interaction = "seat, pickup", drag = { drag = true, weight = 8 } } },
            variants = {
                wooden = { name = "Wooden Chair", prefix = "Wooden", price = 10.00, description = "A basic wooden chair" },
            }
        }
    },
}

return ObjectModule