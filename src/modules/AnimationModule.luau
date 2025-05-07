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
            --CROUCH_IDLE = { id = "rbxassetid://17665952892", looped = true, priority = Enum.AnimationPriority.Core },
            --CROUCH_WALK = { id = "rbxassetid://17665954907", looped = true, priority = Enum.AnimationPriority.Core },
            --SWIM_IDLE = { id = "rbxassetid://131899647125024", looped = true, priority = Enum.AnimationPriority.Core },
            --SWIM = { id = "rbxassetid://91416508630464", looped = true, priority = Enum.AnimationPriority.Core }
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
            CLIMB_1 = { id = "rbxassetid://123495626441292", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB_2 = { id = "rbxassetid://107729248952700", looped = true, priority = Enum.AnimationPriority.Action },
            HOLD_INTO = { id = "rbxassetid://112021937453544", looped = true, priority = Enum.AnimationPriority.Action },
            HOLD = { id = "rbxassetid://114818758201776", looped = true, priority = Enum.AnimationPriority.Action },
            HOLD_VAULT = { id = "rbxassetid://118684278383311", looped = true, priority = Enum.AnimationPriority.Action },
        },  

        LEDGE = {
            --GRAB = { id = "rbxassetid://138462721425923", looped = false, priority = Enum.AnimationPriority.Action },
            --HOLD = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action },
            --CLIMB = { id = "rbxassetid://89000907008779", looped = false, priority = Enum.AnimationPriority.Action },
            --SHUFFLE_LEFT = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action },
            --SHUFFLE_RIGHT = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action }
        },

        SPECIAL = {
            --SLIDE = { id = "rbxassetid://127776657665417", looped = false, priority = Enum.AnimationPriority.Action },
            --SWING = { id = "rbxassetid://110764238186844", looped = true, priority = Enum.AnimationPriority.Action },
            --CLIMB = { id = "rbxassetid://130390595288877", looped = true, priority = Enum.AnimationPriority.Action },
            --VAULT = { id = "rbxassetid://103974702055910", looped = false, priority = Enum.AnimationPriority.Action },
            --AIR_DASH = { id = "rbxassetid://119303443959406", looped = false, priority = Enum.AnimationPriority.Action }
        },

        STATUS = {
            --KNOCKED_WALK = { id = "rbxassetid://75568944088870", looped = true, priority = Enum.AnimationPriority.Core },
            --KNOCKED_IDLE = { id = "rbxassetid://115643695474696", looped = true, priority = Enum.AnimationPriority.Core },
            --KNOCKED_RECOVER = { id = "rbxassetid://91819842132170", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_1 = { id = "rbxassetid://104570687545765", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_2 = { id = "rbxassetid://71621238065381", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_3 = { id = "rbxassetid://86621762138991", looped = false, priority = Enum.AnimationPriority.Action },
            --GRIP = { id = "rbxassetid://74209689386963", looped = false, priority = Enum.AnimationPriority.Action },
            --GETTING_GRIPPED = { id = "rbxassetid://111905234290449", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN = { id = "rbxassetid://102439960881696", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN_IDLE = { id = "rbxassetid://85349531545064", looped = true, priority = Enum.AnimationPriority.Core }
        },

        CARRY = {
            --WALK = { id = "rbxassetid://111788423236374", looped = true, priority = Enum.AnimationPriority.Core },
            --IDLE = { id = "rbxassetid://102411210324532", looped = true, priority = Enum.AnimationPriority.Core },
            --RUN = { id = "rbxassetid://98377843180581", looped = true, priority = Enum.AnimationPriority.Core },
            --BEING_CARRIED = { id = "rbxassetid://138129168405614", looped = true, priority = Enum.AnimationPriority.Core },
            --PICKUP_DOWNED = { id = "rbxassetid://109314469382249", looped = false, priority = Enum.AnimationPriority.Action },
            --GETTING_PICKED_UP = { id = "rbxassetid://113799422209127", looped = false, priority = Enum.AnimationPriority.Action },
            --THROW = { id = "rbxassetid://117091230405433", looped = false, priority = Enum.AnimationPriority.Action }
        },

        COMBAT = {
            PARRY_1 = { id = "rbxassetid://128975445882117", looped = false, priority = Enum.AnimationPriority.Action },
            PARRY_2 = { id = "rbxassetid://126572085566589", looped = false, priority = Enum.AnimationPriority.Action },
            STOMP = { id = "rbxassetid://99185047406332", looped = false, priority = Enum.AnimationPriority.Action },
            DAZE_LOOP = { id = "rbxassetid://130826805456978", looped = false, priority = Enum.AnimationPriority.Action },
            DAZE_START = { id = "rbxassetid://111516494700640", looped = false, priority = Enum.AnimationPriority.Action },
        },

        EMOTES = {
            CHALLENGE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            --HYSTERICAL = { id = "rbxassetid://102180575245565", looped = false, priority = Enum.AnimationPriority.Core },
            MEDITATE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            MOCKING = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            WEEPING = { id = "", looped = false, priority = Enum.AnimationPriority.Core }
        },

        FISHING = {
            IDLE = { id = "", looped = true, priority = Enum.AnimationPriority.Core },
            CAST = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            REEL = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            CATCH = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
            BITE = { id = "", looped = true, priority = Enum.AnimationPriority.Core }
        },

        WEAPONS = {
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
        }
    }
}

return AnimationModule