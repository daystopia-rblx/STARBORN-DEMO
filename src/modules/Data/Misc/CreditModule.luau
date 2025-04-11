--[[ CreditModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local CreditModule = {}

CreditModule.Credits = {
    ["Development Team"] = {
        {role = "Founder", contributors = {"@ItsFrazix"}},
        {role = "Programmer", contributors = {"@Daystopia"}, {"@NantesF"}},
        {role = "Builder", contributors = {""}},
        {role = "Modeler", contributors = {""}},
        {role = "Writer", contributors = {""}},
        {role = "Artist", contributors = {""}},
        {role = "UI Designer", contributors = {""}},
        {role = "Composer", contributors = {""}}
    },

    ["Special Thanks"] = {
        "Community Testers",
        "Early Supporters"
    }
}

CreditModule.Contributors = {
    ["@ItsFrazix"] = {
        "Producer"
    },

    ["@Daystopia"] = {
        "Programming"
    },

    ["@NantesF"] = {
        "Programming"
    }
}

function CreditModule:GetFormat(credit)
    if type(credit) == "string" then
        return credit
    end

    if type(credit) == "table" and credit.role and credit.contributors then
        local contributorText = table.concat(credit.contributors, ", ")
        return credit.role .. " - " .. contributorText
    end

    return ""
end

return CreditModule