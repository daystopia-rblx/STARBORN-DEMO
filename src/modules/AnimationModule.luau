--[[ AnimationModule
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-07
]]
local AnimationModule = {}

--[[ Assets ]]
AnimationModule.Assets = {
    Animations = {
        LOCOMOTION = {
            IDLE = { id = "rbxassetid://122685105909562", looped = true, priority = Enum.AnimationPriority.Core },
            IDLE_2 = { id = "rbxassetid://122685105909562", looped = true, priority = Enum.AnimationPriority.Core },
            WALK = { id = "rbxassetid://130615697145140", looped = true, priority = Enum.AnimationPriority.Core },
            SPRINT = { id = "rbxassetid://124444643290689", looped = true, priority = Enum.AnimationPriority.Core },
            JUMP = { id = "rbxassetid://70501997475399", looped = false, priority = Enum.AnimationPriority.Action },
            FALL = { id = "rbxassetid://89519159080183", looped = true, priority = Enum.AnimationPriority.Action },
        },

        ROLL = {
            FORWARD = { id = "rbxassetid://81844962612048", looped = false, priority = Enum.AnimationPriority.Action },
            BACK = { id = "rbxassetid://134096203261668", looped = false, priority = Enum.AnimationPriority.Action },
            LEFT = { id = "rbxassetid://128164659045187", looped = false, priority = Enum.AnimationPriority.Action },
            RIGHT = { id = "rbxassetid://79415757119555", looped = false, priority = Enum.AnimationPriority.Action },
            CANCEL = { id = "rbxassetid://78730007511144", looped = false, priority = Enum.AnimationPriority.Action }
        },

        WALL = {
            RUN_LEFT = { id = "rbxassetid://111880841161882", looped = true, priority = Enum.AnimationPriority.Action },
            RUN_RIGHT = { id = "rbxassetid://105859729136618", looped = true, priority = Enum.AnimationPriority.Action },
            LEAP_LEFT = { id = "rbxassetid://97658678009478", looped = true, priority = Enum.AnimationPriority.Action },
            LEAP_RIGHT = { id = "rbxassetid://105198310504846", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB_1 = { id = "rbxassetid://88582569897007", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB_2 = { id = "rbxassetid://110825214802042", looped = true, priority = Enum.AnimationPriority.Action },
        },  

        STATUS = {
            PAIN_1 = { id = "rbxassetid://104570687545765", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_2 = { id = "rbxassetid://71621238065381", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_3 = { id = "rbxassetid://86621762138991", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN = { id = "rbxassetid://102439960881696", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN_IDLE = { id = "rbxassetid://85349531545064", looped = true, priority = Enum.AnimationPriority.Core }
        },

        COMBAT = {
            PARRY_1 = { id = "rbxassetid://128975445882117", looped = false, priority = Enum.AnimationPriority.Action },
            PARRY_2 = { id = "rbxassetid://126572085566589", looped = false, priority = Enum.AnimationPriority.Action },
            STOMP = { id = "rbxassetid://99185047406332", looped = false, priority = Enum.AnimationPriority.Action },
            DAZE_LOOP = { id = "rbxassetid://130826805456978", looped = false, priority = Enum.AnimationPriority.Action },
            DAZE_START = { id = "rbxassetid://111516494700640", looped = false, priority = Enum.AnimationPriority.Action },
        },

        FISHING = {
            IDLE = { id = "", looped = true, priority = Enum.AnimationPriority.Core },
            CAST = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            REEL = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            CATCH = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            BITE = { id = "", looped = true, priority = Enum.AnimationPriority.Core }
        },

        WEAPONS = {
            EQUIP = {
                EQUIP_1 = { id = "rbxassetid://73737387634684", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP_2 = { id = "rbxassetid://118276883179050", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "rbxassetid://136867849127982", looped = false, priority = Enum.AnimationPriority.Action },
            },

            FIST = {
                SWING_1 = { id = "rbxassetid://133569150898553", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://112280660000076", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://93286245817913", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://99450466658990", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://133600722655351", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://93991307067268", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://122805960251167", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://135536264419059", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://135536264419059", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://104607566914268", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://70601470557911", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://136897473293714", looped = true, priority = Enum.AnimationPriority.Core }
            },

            SPEAR = {
                SWING_1 = { id = "rbxassetid://80006442833311", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://126442952721831", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://101803708858673", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://104231434732190", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://140294832023497", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://98473702742583", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://123536170704471", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://127596650279179", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://135536264419059", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://75520841197167", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://130159296235561", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://81179993641590", looped = true, priority = Enum.AnimationPriority.Core }
            },
        }
    }
}

return AnimationModule