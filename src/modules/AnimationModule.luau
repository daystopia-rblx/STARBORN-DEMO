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
            LEDGE = { id = "rbxassetid://92548348824136", looped = true, priority = Enum.AnimationPriority.Action },
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
                SWING_1 = { id = "rbxassetid://82038558877404", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://126634347387431", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://138865196577184", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://97241224463509", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://138696284595714", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://116687952242424", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://116374783188059", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://99524816218464", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://99524816218464", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://102941527854844", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://139655356885848", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://136921978712677", looped = true, priority = Enum.AnimationPriority.Core }
            },

            KICKBOXING = {
                SWING_1 = { id = "rbxassetid://122867108888158", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://115240863295006", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://135504084006314", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://119972234941849", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://103908699892247", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://116687952242424", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://116374783188059", looped = false, priority = Enum.AnimationPriority.Action },
                EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://124637544797325", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://124637544797325", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://102941527854844", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://139655356885848", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://136921978712677", looped = true, priority = Enum.AnimationPriority.Core }
            },

            SPEAR = {
                SWING_1 = { id = "rbxassetid://80006442833311", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://126442952721831", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://101803708858673", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://104231434732190", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://140294832023497", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://98473702742583", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://123536170704471", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://119473257883735", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://119473257883735", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://75520841197167", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://130159296235561", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://81179993641590", looped = true, priority = Enum.AnimationPriority.Core }
            },

            SWORD = {
                SWING_1 = { id = "rbxassetid://94919100744313", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://110920445228459", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://120658608444084", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://71431158565049", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://139983572655733", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://111966041236659", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://90026537512425", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://115299391742915", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://115299391742915", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://91893405321103", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://133166085516178", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://99062324978791", looped = true, priority = Enum.AnimationPriority.Core }
            },

            HAMMER = {
                SWING_1 = { id = "rbxassetid://75548864111272", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://92582340154508", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://125355185540948", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://89602749400428", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://90339120534607", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://135982421015191", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://87693436023371", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://104301407799114", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://104301407799114", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://103577489572564", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://112712977989532", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://106113634366450", looped = true, priority = Enum.AnimationPriority.Core }
            },

            KATANA = {
                SWING_1 = { id = "rbxassetid://103220157718151", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://101837663539836", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://95292140666190", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://128823171587164", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://79608289223890", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://98256705919441", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://116935002602411", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://84818574953400", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://84818574953400", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://88877843571195", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://100760374288831", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://88220959437731", looped = true, priority = Enum.AnimationPriority.Core }
            },

            AXE = {
                SWING_1 = { id = "rbxassetid://138972853004235", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://108752448498220", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://137790789326053", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://115080503724066", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://74245559935919", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://122751925779499", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://115958889112009", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://109696435487731", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://109696435487731", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://100726506325727", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://70454322588015", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://97475103189037", looped = true, priority = Enum.AnimationPriority.Core }
            },

            DAGGER = {
                SWING_1 = { id = "rbxassetid://75054502728004", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_2 = { id = "rbxassetid://110653831989473", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_3 = { id = "rbxassetid://124389926373008", looped = false, priority = Enum.AnimationPriority.Action },
                SWING_4 = { id = "rbxassetid://85570310777166", looped = false, priority = Enum.AnimationPriority.Action },
                AERIAL = { id = "rbxassetid://84539707387437", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY_START = { id = "rbxassetid://98321663628593", looped = false, priority = Enum.AnimationPriority.Action },
                PARRY = { id = "rbxassetid://100844766348419", looped = false, priority = Enum.AnimationPriority.Action },
                --EQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                --UNEQUIP = { id = "rbxassetid://0", looped = false, priority = Enum.AnimationPriority.Action },
                IDLE = { id = "rbxassetid://91122677748636", looped = true, priority = Enum.AnimationPriority.Core },
                WALK = { id = "rbxassetid://91122677748636", looped = true, priority = Enum.AnimationPriority.Core },
                --SPRINT = { id = "rbxassetid://91170009929269", looped = true, priority = Enum.AnimationPriority.Core },
                CRITICAL = { id = "rbxassetid://87678059994134", looped = false, priority = Enum.AnimationPriority.Action },
                BLOCK_POSE = { id = "rbxassetid://81164889368320", looped = true, priority = Enum.AnimationPriority.Core },
                BLOCK_IMPACT = { id = "rbxassetid://123918381710375", looped = true, priority = Enum.AnimationPriority.Core }
            },
        }
    }
}

return AnimationModule