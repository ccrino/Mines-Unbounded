require "common"
local Theory = require "AsciiTheory"
local Style = require "AsciiTheory/Style"
local Window = require "AsciiTheory/Window"
local Button = require "AsciiTheory/Button"
local TextField = require "AsciiTheory/TextField"
local Pane = require "AsciiTheory/Pane"

return function()
    --- BEGIN LOAD XP RESOURCES ---
    Theory:registerMappedColors {
        darkest  = { 0 / 255, 0 / 255, 64 / 255 },
        dark     = { 0 / 255, 0 / 255, 178 / 255 },
        normal   = { 0 / 255, 0 / 255, 255 / 255 },
        light    = { 51 / 255, 51 / 255, 255 / 255 },
        lightest = { 102 / 255, 102 / 255, 255 / 255 },
    }

    Style:newStyles(Window, {
        board = "Assets/UnboundedBoardFrame.xp",
        config = "Assets/UnboundedConfigFrame.xp",
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
        id = "gameWindow",
        style = "board",
        dim = Theory.Dim(0, 0, 47, 50),
        { type = "textField",
            id = "scoreLabel",
            text = "0000000",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(19, 2, 9, 3),
            verticalAlign = "center",
            horizontalAlign = "center",
        },
        { type = "button",
            id = "newButton",
            command = "newGame",
            style = 'new',
            dim = Theory.Dim(3, 43, 9, 5),
        },
        { type = "button",
            id = "menuButton",
            command = "openMenu",
            style = 'menu',
            dim = Theory.Dim(35, 43, 9, 5)
        }
    }

    local menuWindow = Theory:parse {
        type = "window",
        id = "menuWindow",
        style = "config",
        dim = Theory.Dim(0, 0, 47, 50),

        upDownButtons(VALUE.ONE, 12, 13),
        upDownButtons(VALUE.TWO, 16, 13),
        upDownButtons(VALUE.THREE, 20, 13),
        upDownButtons(VALUE.FOUR, 24, 13),
        upDownButtons(VALUE.FIVE, 28, 13),

        upDownButtons(VALUE.SIX, 12, 17),
        upDownButtons(VALUE.SEVEN, 16, 17),
        upDownButtons(VALUE.EIGHT, 20, 17),
        upDownButtons(VALUE.FLAG, 24, 17),
        upDownButtons(VALUE.MINE, 28, 17),

        { type = "button",
            command = "toggleCheck",
            style = 'check',
            dim = Theory.Dim(31, 13, 5, 3),
        },
        { type = "button",
            command = "setToDefault",
            style = 'reset',
            dim = Theory.Dim(31, 17, 5, 3),
        },
        { type = "button",
            command = "leftPalette",
            style = 'left',
            dim = Theory.Dim(12, 29, 1, 1),
        },
        { type = "textField",
            id = "paletteReadout",
            text = "000",
            fg = "lightest",
            bg = "darkest",
            dim = Theory.Dim(13, 29, 3, 1),
            verticalAlign = "center",
            horizontalAlign = "center",
        },
        { type = "button",
            command = "rightPalette",
            style = 'right',
            dim = Theory.Dim(16, 29, 1, 1),
        },
        { type = "button",
            id = "saveButton",
            command = "saveGame",
            style = 'save',
            dim = Theory.Dim(3, 43, 9, 5),
        },
        { type = "button",
            id = "backButton",
            command = "closeMenu",
            style = 'back',
            dim = Theory.Dim(35, 43, 9, 5)
        }
    }

    Theory:attach(1, gameWindow)
    --- END DEFINE SCENE ---
end
