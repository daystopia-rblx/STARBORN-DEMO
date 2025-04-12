--[[ LocationModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local LocationModule = {}

function LocationModule.GetLocation(name: string)
    name = name:upper()
    if LocationModule.Templates[name] then return LocationModule.Templates[name] end
    for _, category in pairs(LocationModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

function LocationModule.GetHours(locationSubType)
    return locationSubType and LocationModule.Hours[locationSubType:upper()] or nil
end

function LocationModule.CheckOpen(template, currentHour)
    if not template or not template.hours then
        return false
    end

    local hours = template.hours

    if hours.open == nil or hours.close == nil then
        return false
    end

    if hours.open < hours.close then
        return currentHour >= hours.open and currentHour < hours.close
    else
        return currentHour >= hours.open or currentHour < hours.close
    end
end

LocationModule.Categories = {
    HOMES = "Residential Buildings",
    SHOPS = "Commercial Establishments",
    INNS = "Hospitality Locations",
    RELIGIOUS = "Religious Buildings",
    GOVERNMENT = "Government Buildings"
}

LocationModule.CategoryGroups = {
    HOMES = {
        "COMMONER_HOME",
        "NOBLE_MANSION"
    },
    SHOPS = {
        "GENERAL_STORE",
        "BLACKSMITH"
    },
    INNS = {
        "VILLAGE_INN"
    },
    RELIGIOUS = {
        "TEMPLE"
    }
}

LocationModule.Hours = {
    STORE = {hour_open = 8, hour_close = 20},
    INN = {hour_open = 10, hour_close = 2},
    TEMPLE = {hour_open = 6, hour_close = 22},
    GUILD = {hour_open = 8, hour_close = 22},
    HOME = {hour_open = nil, hour_close = nil},
    BLACK_MARKET = {hour_open = 22, hour_close = 4},
    ALWAYS_OPEN = {hour_open = 0, hour_close = 24}
}

LocationModule.Templates = {
    -- Residential Buildings
    HOMES = {
        COMMONER_HOME = {
            defaults = { zone = "settlement", location_type = "interior", security = 1, ownership = "personal", guards = 0, lock_level = 1 },
            variants = { default = { name = "Commoner's Home", description = "A simple dwelling for common folk" } }
        },
        NOBLE_MANSION = {
            defaults = { zone = "settlement", location_type = "interior", security = 3, ownership = "personal", guards = 2, lock_level = 3 },
            variants = { default = { name = "Noble's Mansion", description = "An opulent residence for the wealthy" } }
        }
    },

    -- Commercial Establishments
    SHOPS = {
        GENERAL_STORE = {
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = LocationModule.Hours.STORE, store_type = "general", guards = 0, lock_level = 2 },
            variants = { default = { name = "General Store", description = "A shop selling various goods and supplies" } }
        },
        BLACKSMITH = {
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = LocationModule.Hours.STORE, store_type = "smithy", guards = 0, lock_level = 2 },
            variants = { default = { name = "Blacksmith", description = "A forge for crafting and repairing metal items" } }
        }
    },

    -- Hospitality Locations
    INNS = {
        VILLAGE_INN = {
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = LocationModule.Hours.INN, guards = 1, lock_level = 2 },
            variants = { default = { name = "Village Inn", description = "A cozy establishment offering food and lodging" } }
        }
    },
    RELIGIOUS = {
        TEMPLE = {
            defaults = { zone = "settlement", location_type = "interior", security = 3, ownership = "faction", hours = LocationModule.Hours.TEMPLE, guards = 2, lock_level = 3 },
            variants = { default = { name = "Temple", description = "A sacred place of worship and reflection" } }
        }
    }
}

return LocationModule