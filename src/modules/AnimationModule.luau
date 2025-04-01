local AnimationModule = {}

--[[ Assets ]]
AnimationModule.Assets = {
    Animations = {
        -- Locomotion
        IDLE = { id = "rbxassetid://90320874944386", looped = true, priority = Enum.AnimationPriority.Core },
        IDLE_2 = { id = "rbxassetid://90320874944386", looped = true, priority = Enum.AnimationPriority.Core },
        WALK = { id = "rbxassetid://89856718087120", looped = true, priority = Enum.AnimationPriority.Core },
        SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
        JUMP = { id = "rbxassetid://117683847104181", looped = false, priority = Enum.AnimationPriority.Action },
        FALL = { id = "rbxassetid://95957590187070", looped = true, priority = Enum.AnimationPriority.Action },
        CROUCH_IDLE = { id = "rbxassetid://17665952892", looped = true, priority = Enum.AnimationPriority.Core },
        CROUCH_WALK = { id = "rbxassetid://17665954907", looped = true, priority = Enum.AnimationPriority.Core },

        -- Landing
        LAND_SMALL = { id = "rbxassetid://126155617121254", looped = false, priority = Enum.AnimationPriority.Action },
        LAND_LARGE = { id = "rbxassetid://129602897503230", looped = false, priority = Enum.AnimationPriority.Action },
        LAND_HURT = { id = "rbxassetid://119142751536548", looped = false, priority = Enum.AnimationPriority.Action },
        LAND_HURT_LOTS = { id = "rbxassetid://138041867901848", looped = false, priority = Enum.AnimationPriority.Action },

        -- Rolling
        ROLL_FORWARD = { id = "rbxassetid://132297618125563", looped = false, priority = Enum.AnimationPriority.Action },
        ROLL_BACK = { id = "rbxassetid://72976489794297", looped = false, priority = Enum.AnimationPriority.Action },
        ROLL_LEFT = { id = "rbxassetid://123959749072908", looped = false, priority = Enum.AnimationPriority.Action },
        ROLL_RIGHT = { id = "rbxassetid://79008182923204", looped = false, priority = Enum.AnimationPriority.Action },
        ROLL_CANCEL = { id = "rbxassetid://89782835062182", looped = false, priority = Enum.AnimationPriority.Action },

        -- Wall Movement
        WALL_RUN_LEFT = { id = "rbxassetid://112704346655755", looped = true, priority = Enum.AnimationPriority.Action },
        WALL_RUN_RIGHT = { id = "rbxassetid://74903089680298", looped = true, priority = Enum.AnimationPriority.Action },
        WALL_CLIMB = { id = "rbxassetid://112322610854760", looped = true, priority = Enum.AnimationPriority.Action },
        WALL_HOLD = { id = "rbxassetid://112322610854760", looped = true, priority = Enum.AnimationPriority.Action },

        -- Ledge Movement
        LEDGE_HOLD = { id = "", looped = true, priority = Enum.AnimationPriority.Action },
        LEDGE_CLIMB = { id = "rbxassetid://89000907008779", looped = false, priority = Enum.AnimationPriority.Action },

        -- Special Movement
        SLIDE = { id = "rbxassetid://127776657665417", looped = false, priority = Enum.AnimationPriority.Action },
        SWING = { id = "rbxassetid://110764238186844", looped = true, priority = Enum.AnimationPriority.Action },
        CLIMB = { id = "rbxassetid://130390595288877", looped = true, priority = Enum.AnimationPriority.Action },
        VAULT = { id = "rbxassetid://101998356719605", looped = false, priority = Enum.AnimationPriority.Action },
        AIR_DASH = { id = "rbxassetid://119303443959406", looped = false, priority = Enum.AnimationPriority.Action },

        -- Status
        KNOCKED_WALK = { id = "rbxassetid://75568944088870", looped = true, priority = Enum.AnimationPriority.Core },
        KNOCKED_IDLE = { id = "rbxassetid://115643695474696", looped = true, priority = Enum.AnimationPriority.Core },
        KNOCKED_RECOVER = { id = "rbxassetid://91819842132170", looped = false, priority = Enum.AnimationPriority.Action },
        PAIN_1 = { id = "rbxassetid://131773097186708", looped = false, priority = Enum.AnimationPriority.Action },
        PAIN_2 = { id = "rbxassetid://72464429803348", looped = false, priority = Enum.AnimationPriority.Action },
        GRIP = { id = "rbxassetid://74209689386963", looped = false, priority = Enum.AnimationPriority.Action },
        GETTING_GRIPPED = { id = "rbxassetid://111905234290449", looped = false, priority = Enum.AnimationPriority.Action },
        BLOCK_BROKEN = { id = "rbxassetid://118361849490979", looped = false, priority = Enum.AnimationPriority.Action },
        BLOCK_BROKEN_IDLE = { id = "rbxassetid://100900626756395", looped = true, priority = Enum.AnimationPriority.Core },

        -- Carrying
        CARRY_WALK = { id = "rbxassetid://111788423236374", looped = true, priority = Enum.AnimationPriority.Core },
        CARRYING_IDLE = { id = "rbxassetid://102411210324532", looped = true, priority = Enum.AnimationPriority.Core },
        CARRYING_RUN = { id = "rbxassetid://98377843180581", looped = true, priority = Enum.AnimationPriority.Core },
        BEING_CARRIED = { id = "rbxassetid://138129168405614", looped = true, priority = Enum.AnimationPriority.Core },
        PICKUP_DOWNED = { id = "rbxassetid://109314469382249", looped = false, priority = Enum.AnimationPriority.Action },
        GETTING_PICKED_UP = { id = "rbxassetid://113799422209127", looped = false, priority = Enum.AnimationPriority.Action },
        THROW_CARRY = { id = "rbxassetid://117091230405433", looped = false, priority = Enum.AnimationPriority.Action },

        -- Parry
        PARRY_1 = { id = "rbxassetid://104915035560099", looped = false, priority = Enum.AnimationPriority.Action },
        PARRY_2 = { id = "rbxassetid://92814853491938", looped = false, priority = Enum.AnimationPriority.Action },

        -- Miscellaneous
        SIT = { id = "", looped = true, priority = Enum.AnimationPriority.Core },

        -- Emotes
        CHALLENGE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
        HYSTERICAL = { id = "rbxassetid://102180575245565", looped = false, priority = Enum.AnimationPriority.Core },
        MEDITATE = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
        MOCKING = { id = "", looped = false, priority = Enum.AnimationPriority.Core },
        WEEPING = { id = "", looped = false, priority = Enum.AnimationPriority.Core },

        -- Gloves Animations
        GLOVES_SWING_1 = { id = "rbxassetid://88649918878431", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_SWING_2 = { id = "rbxassetid://70965252565582", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_SWING_3 = { id = "rbxassetid://101002586724777", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_SWING_4 = { id = "rbxassetid://72629371626537", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_SWING_5 = { id = "rbxassetid://114028184472440", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_LUNGE = { id = "rbxassetid://77714110746670", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_PARRY_START = { id = "rbxassetid://112989725494663", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_PARRY = { id = "rbxassetid://86742188738316", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_EQUIP = { id = "rbxassetid://93567396967679", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_UNEQUIP = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_IDLE = { id = "rbxassetid://113000820843078", looped = true, priority = Enum.AnimationPriority.Core },
        GLOVES_WALK = { id = "rbxassetid://88634727417929", looped = true, priority = Enum.AnimationPriority.Core },
        GLOVES_SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
        GLOVES_RUN_ATTACK = { id = "rbxassetid://111166542519601", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_CRITICAL = { id = "rbxassetid://136746036831819", looped = false, priority = Enum.AnimationPriority.Action },
        GLOVES_BLOCK_POSE = { id = "rbxassetid://89808050969595", looped = true, priority = Enum.AnimationPriority.Core },

        -- Dagger Animations
        DAGGER_SWING_1 = { id = "rbxassetid://120146568175354", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_SWING_2 = { id = "rbxassetid://95193900736899", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_SWING_3 = { id = "rbxassetid://101695034489717", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_SWING_4 = { id = "rbxassetid://123156924052689", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_LUNGE = { id = "rbxassetid://129328009977391", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_PARRY_START = { id = "rbxassetid://112989725494663", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_PARRY = { id = "rbxassetid://86742188738316", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_EQUIP = { id = "rbxassetid://93567396967679", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_UNEQUIP = { id = "", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_IDLE = { id = "rbxassetid://88340023034298", looped = true, priority = Enum.AnimationPriority.Core },
        DAGGER_WALK = { id = "rbxassetid://88634727417929", looped = true, priority = Enum.AnimationPriority.Core },
        DAGGER_SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
        DAGGER_RUN_ATTACK = { id = "rbxassetid://111166542519601", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_CRITICAL = { id = "rbxassetid://81940178754669", looped = false, priority = Enum.AnimationPriority.Action },
        DAGGER_BLOCK_POSE = { id = "rbxassetid://139368084700439", looped = true, priority = Enum.AnimationPriority.Core }
    }
}

return AnimationModule