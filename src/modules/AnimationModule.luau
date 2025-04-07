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
            IDLE = { id = "rbxassetid://90320874944386", looped = true, priority = Enum.AnimationPriority.Core },
            IDLE_2 = { id = "rbxassetid://90320874944386", looped = true, priority = Enum.AnimationPriority.Core },
            WALK = { id = "rbxassetid://89856718087120", looped = true, priority = Enum.AnimationPriority.Core },
            SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
            JUMP = { id = "rbxassetid://117683847104181", looped = false, priority = Enum.AnimationPriority.Action },
            FALL = { id = "rbxassetid://95957590187070", looped = true, priority = Enum.AnimationPriority.Action },
            CROUCH_IDLE = { id = "rbxassetid://17665952892", looped = true, priority = Enum.AnimationPriority.Core },
            CROUCH_WALK = { id = "rbxassetid://17665954907", looped = true, priority = Enum.AnimationPriority.Core },
            SWIM_IDLE = { id = "rbxassetid://131899647125024", looped = true, priority = Enum.AnimationPriority.Core },
            SWIM = { id = "rbxassetid://91416508630464", looped = true, priority = Enum.AnimationPriority.Core }
        },

        LANDING = {
            SMALL = { id = "rbxassetid://126155617121254", looped = false, priority = Enum.AnimationPriority.Action },
            LARGE = { id = "rbxassetid://129602897503230", looped = false, priority = Enum.AnimationPriority.Action },
            HURT = { id = "rbxassetid://129602897503230", looped = false, priority = Enum.AnimationPriority.Action },
            HURT_LOTS = { id = "rbxassetid://129602897503230", looped = false, priority = Enum.AnimationPriority.Action }
        },

        ROLL = {
            FORWARD = { id = "rbxassetid://132297618125563", looped = false, priority = Enum.AnimationPriority.Action },
            BACK = { id = "rbxassetid://72976489794297", looped = false, priority = Enum.AnimationPriority.Action },
            LEFT = { id = "rbxassetid://123959749072908", looped = false, priority = Enum.AnimationPriority.Action },
            RIGHT = { id = "rbxassetid://79008182923204", looped = false, priority = Enum.AnimationPriority.Action },
            CANCEL = { id = "rbxassetid://89782835062182", looped = false, priority = Enum.AnimationPriority.Action }
        },

        WALL = {
            RUN_LEFT = { id = "rbxassetid://112704346655755", looped = true, priority = Enum.AnimationPriority.Action },
            RUN_RIGHT = { id = "rbxassetid://74903089680298", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB = { id = "rbxassetid://112322610854760", looped = true, priority = Enum.AnimationPriority.Action },
            HOLD = { id = "rbxassetid://115086722054003", looped = true, priority = Enum.AnimationPriority.Action }
        },

        LEDGE = {
            GRAB = { id = "rbxassetid://138462721425923", looped = false, priority = Enum.AnimationPriority.Action },
            HOLD = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB = { id = "rbxassetid://89000907008779", looped = false, priority = Enum.AnimationPriority.Action },
            SHUFFLE_LEFT = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action },
            SHUFFLE_RIGHT = { id = "rbxassetid://133756585356209", looped = true, priority = Enum.AnimationPriority.Action }
        },

        SPECIAL = {
            SLIDE = { id = "rbxassetid://127776657665417", looped = false, priority = Enum.AnimationPriority.Action },
            SWING = { id = "rbxassetid://110764238186844", looped = true, priority = Enum.AnimationPriority.Action },
            CLIMB = { id = "rbxassetid://130390595288877", looped = true, priority = Enum.AnimationPriority.Action },
            VAULT = { id = "rbxassetid://101998356719605", looped = false, priority = Enum.AnimationPriority.Action },
            AIR_DASH = { id = "rbxassetid://119303443959406", looped = false, priority = Enum.AnimationPriority.Action }
        },

        STATUS = {
            KNOCKED_WALK = { id = "rbxassetid://75568944088870", looped = true, priority = Enum.AnimationPriority.Core },
            KNOCKED_IDLE = { id = "rbxassetid://115643695474696", looped = true, priority = Enum.AnimationPriority.Core },
            KNOCKED_RECOVER = { id = "rbxassetid://91819842132170", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_1 = { id = "rbxassetid://131773097186708", looped = false, priority = Enum.AnimationPriority.Action },
            PAIN_2 = { id = "rbxassetid://72464429803348", looped = false, priority = Enum.AnimationPriority.Action },
            GRIP = { id = "rbxassetid://74209689386963", looped = false, priority = Enum.AnimationPriority.Action },
            GETTING_GRIPPED = { id = "rbxassetid://111905234290449", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN = { id = "rbxassetid://118361849490979", looped = false, priority = Enum.AnimationPriority.Action },
            BLOCK_BROKEN_IDLE = { id = "rbxassetid://100900626756395", looped = true, priority = Enum.AnimationPriority.Core }
        },

        CARRY = {
            WALK = { id = "rbxassetid://111788423236374", looped = true, priority = Enum.AnimationPriority.Core },
            IDLE = { id = "rbxassetid://102411210324532", looped = true, priority = Enum.AnimationPriority.Core },
            RUN = { id = "rbxassetid://98377843180581", looped = true, priority = Enum.AnimationPriority.Core },
            BEING_CARRIED = { id = "rbxassetid://138129168405614", looped = true, priority = Enum.AnimationPriority.Core },
            PICKUP_DOWNED = { id = "rbxassetid://109314469382249", looped = false, priority = Enum.AnimationPriority.Action },
            GETTING_PICKED_UP = { id = "rbxassetid://113799422209127", looped = false, priority = Enum.AnimationPriority.Action },
            THROW = { id = "rbxassetid://117091230405433", looped = false, priority = Enum.AnimationPriority.Action }
        },

        COMBAT = {
            PARRY_1 = { id = "rbxassetid://104915035560099", looped = false, priority = Enum.AnimationPriority.Action },
            PARRY_2 = { id = "rbxassetid://92814853491938", looped = false, priority = Enum.AnimationPriority.Action }
        },

        EMOTES = {
            CHALLENGE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            HYSTERICAL = { id = "rbxassetid://102180575245565", looped = false, priority = Enum.AnimationPriority.Core },
            MEDITATE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            MOCKING = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
            WEEPING = { id = "", looped = false, priority = Enum.AnimationPriority.Core }
        },

        WEAPONS = {
            GLOVES = {
                SWING_1 = { id = "rbxassetid://88649918878431", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://70965252565582", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://101002586724777", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://72629371626537", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_5 = { id = "rbxassetid://114028184472440", looped = false, priority = Enum.AnimationPriority.Action },
                LUNGE = { id = "rbxassetid://77714110746670", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://112989725494663", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://86742188738316", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://93567396967679", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://113000820843078", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://88634727417929", looped = true, priority = Enum.AnimationPriority.Core },
                SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                RUN_ATTACK = { id = "rbxassetid://111166542519601", looped = false, priority = Enum.AnimationPriority.Action },
                CRITICAL = { id = "rbxassetid://136746036831819", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://89808050969595", looped = true, priority = Enum.AnimationPriority.Core }
            },

            DAGGER = {
                SWING_1 = { id = "rbxassetid://120146568175354", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://95193900736899", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://101695034489717", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://123156924052689", looped = false, priority = Enum.AnimationPriority.Action },
                LUNGE = { id = "rbxassetid://129328009977391", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://112989725494663", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://86742188738316", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://93567396967679", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://88340023034298", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://88634727417929", looped = true, priority = Enum.AnimationPriority.Core },
                SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                RUN_ATTACK = { id = "rbxassetid://111166542519601", looped = false, priority = Enum.AnimationPriority.Action },
                CRITICAL = { id = "rbxassetid://81940178754669", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://139368084700439", looped = true, priority = Enum.AnimationPriority.Core }
            }
        }
    }
}

return AnimationModule