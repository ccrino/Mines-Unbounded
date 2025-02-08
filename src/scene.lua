require "common"
local Theory = require "AsciiTheory"
local Style = require "AsciiTheory/Style"
local Window = require "AsciiTheory/Window"
local Button = require "AsciiTheory/Button"
require "AsciiTheory/TextField"
require "AsciiTheory/Pane"

ManagedObjects = {
    GameWindow = "GameWindow",
    ScoreLabel = "ScoreLabel",
    SignalLostWindow = "SignalLostWindow",
    SignalDump = "SignalDump",
    MenuWindow = "MenuWindow",
    GamemodeDisplay = "GamemodeDisplay",
    GamemodeDescribe = "GamemodeDescribe",
    PaletteReadout = "PaletteReadout",

    BtnNewGame = "BtnNewGame",
    BtnOpenMenu = "BtnOpenMenu",
    BtnCloseMenu = "BtnCloseMenu"
}

return function()
    --- BEGIN LOAD XP RESOURCES ---
    Theory:registerMappedColors {
        darkest  = { 0 / 255, 0 / 255, 64 / 255 },
        dark     = { 0 / 255, 0 / 255, 178 / 255 },
        normal   = { 0 / 255, 0 / 255, 255 / 255 },
        lighter  = { 51 / 255, 51 / 255, 255 / 255 },
        lightest = { 102 / 255, 102 / 255, 255 / 255 },
    }

    Style:newStyles(Window, {
        board = "Assets/UnboundedBoardFrame.xp",
        config = "Assets/UnboundedConfigFrame.xp",
        signallost = "Assets/UnboundedSignalLost.xp",
    })
    Style:newStyles(Button, {
        new = "Assets/New_Button_Style.xp",
        menu = "Assets/Menu_Button_Style.xp",
        back = "Assets/Back_Button_Style.xp",
        save = "Assets/Save_Button_Style.xp",
        reset = "Assets/Reset_Button_Style.xp",
        check = "Assets/Check_Button_Style.xp",
        up = "Assets/Up_Arrow_Style.xp",
        down = "Assets/Down_Arrow_Style.xp",
        left = "Assets/Left_Arrow_Style.xp",
        right = "Assets/Right_Arrow_Style.xp",
    })
    --- END LOAD XP RESOURCES ---

    local function upDownButtons(param, x, y)
        return {
            type = 'pane',
            dim = Theory.Dim(x, y, 1, 3),
            {
                type = 'button',
                command = 'up',
                param = param,
                style = 'up',
                dim = Theory.Dim(x, y, 1, 1),
            },
            {
                type = 'button',
                command = 'down',
                param = param,
                style = 'down',
                dim = Theory.Dim(x, y + 2, 1, 1),
            }
        }
    end

    --- BEGIN DEFINE SCENE ---
    local gameWindow = Theory:parse {
        type = "window",
        id = ManagedObjects.GameWindow,
        style = "board",
        dim = Theory.Dim(0, 0, 47, 50),
        { type = "textField",
            id = ManagedObjects.ScoreLabel,
            text = "0000000",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(19, 2, 9, 3),
            verticalAlign = "center",
            horizontalAlign = "center",
        },
        { type = "button",
            id = ManagedObjects.BtnNewGame,
            command = "newGame",
            style = 'new',
            dim = Theory.Dim(3, 43, 9, 5),
        },
        { type = "button",
            id = ManagedObjects.BtnOpenMenu,
            command = "openMenu",
            style = 'menu',
            dim = Theory.Dim(35, 43, 9, 5)
        }
    }

    Theory:parse {
        type = "window",
        id = ManagedObjects.SignalLostWindow,
        style = "signallost",
        dim = Theory.Dim(7, 7, 33, 33),

        { type = "textField",
            text = "SIGNAL LOST",
            fg = { 1, 1, 0 },
            bg = { 0, 0, 0 },
            dim = Theory.Dim(16, 25, 15, 1),
            horizontalAlign = "center",
            fillBackground = true,
        },
        { type = "textField",
            id = ManagedObjects.SignalDump,
            text = "",
            fg = { 1, 1, 0 },
            bg = { 0, 0, 0 },
            dim = Theory.Dim(7, 27, 23, 13),
            verticalAlign = "max",
            horizontalAlign = "min",
        },
    }

    Theory:parse {
        type = "window",
        id = ManagedObjects.MenuWindow,
        style = "config",
        dim = Theory.Dim(0, 0, 47, 50),

        { type = "button",
            command = "leftGamemode",
            style = 'left',
            dim = Theory.Dim(10, 13, 1, 1)
        },
        { type = "textField",
            id = ManagedObjects.GamemodeDisplay,
            text = "Normal",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(11, 13, 9, 1),
            verticalAlign = "center",
            horizontalAlign = "center",
            fillBackground = true,
        },
        { type = "button",
            command = "rightGamemode",
            style = 'right',
            dim = Theory.Dim(20, 13, 1, 1)
        },
        { type = "textField",
            id = ManagedObjects.GamemodeDescribe,
            text = "board is ∞\n" ..
                VALUE.MINE .. " is lose\n" ..
                "_ is ₧\n\n" ..
                "+₧ is +" .. VALUE.MINE .. "\n\n",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(10, 15, 11, 8),
            verticalAlign = "center",
            horizontalAlign = "min",
            fillBackground = true,
        },

        upDownButtons(VALUE.ONE, 11, 31),
        upDownButtons(VALUE.TWO, 14, 31),
        upDownButtons(VALUE.THREE, 17, 31),
        upDownButtons(VALUE.FOUR, 20, 31),
        upDownButtons(VALUE.FIVE, 23, 31),

        upDownButtons(VALUE.SIX, 11, 34),
        upDownButtons(VALUE.SEVEN, 14, 34),
        upDownButtons(VALUE.EIGHT, 17, 34),
        upDownButtons(VALUE.FLAG, 20, 34),
        upDownButtons(VALUE.MINE, 23, 34),

        { type = "button",
            command = "toggleCheck",
            style = 'check',
            dim = Theory.Dim(26, 31, 3, 3),
        },
        { type = "button",
            command = "setToDefault",
            style = 'reset',
            dim = Theory.Dim(26, 34, 3, 3),
        },
        { type = "button",
            command = "leftPalette",
            style = 'left',
            dim = Theory.Dim(31, 32, 1, 1),
        },
        { type = "textField",
            id = ManagedObjects.PaletteReadout,
            text = "000",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(32, 32, 3, 1),
            verticalAlign = "center",
            horizontalAlign = "center",
        },
        { type = "button",
            command = "rightPalette",
            style = 'right',
            dim = Theory.Dim(35, 32, 1, 1),
        },
        { type = "button",
            command = "newGame",
            style = 'new',
            dim = Theory.Dim(3, 43, 9, 5),
        },
        { type = "button",
            id = ManagedObjects.BtnCloseMenu,
            command = "closeMenu",
            style = 'back',
            dim = Theory.Dim(35, 43, 9, 5)
        }
    }

    Theory:attach(1, gameWindow)
    --- END DEFINE SCENE ---
end
