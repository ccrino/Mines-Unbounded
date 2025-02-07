---@alias palette_string_pack {darkest: string, darker: string, dark: string, normal: string, light: string, lighter: string, lightest: string, angle: number | nil }

---@type palette_string_pack[]
local stringColors =
{
    { --anxiety ++
        darkest  = "#221330",
        darker   = "#252341",
        dark     = "#293452",
        normal   = "#32545e",
        light    = "#37675c",
        lighter  = "#447a5a",
        lightest = "#548d58",
    },
    { --sodas and skateboards ~+
        darkest  = "#831d80",
        dark     = "#6d49a8",
        normal   = "#567dc3",
        lighter  = "#5ab6e0",
        lightest = "#6ae3f4",
    },
    { --guidance ~+
        darkest  = "#8c9458",
        dark     = "#aebb69",
        normal   = "#d3d87c",
        lighter  = "#f9ea8d",
        lightest = "#7a6947",
    },
    -- { --constant rambling --
    --     darkest  = "#ed8f8b",
    --     dark     = "#f3c5a4",
    --     normal   = "#fbe8c6",
    --     lighter  = "#add6fa",
    --     lightest = "#90c9ff",
    -- },
    { --the sweetest chill ++
        darkest  = "#343432",
        dark     = "#645b9e",
        normal   = "#8e84c3",
        lighter  = "#c5aee4",
        lightest = "#e4e9e6",
    },
    { --saltwater tears ~+
        darkest  = "#446c6c",
        dark     = "#547b7d",
        normal   = "#60a581",
        lighter  = "#b7e4a1",
        lightest = "#dbf4bf",
        angle    = 120
    },
    -- { --damned if i do ~-
    --     darkest  = "#da8ba0",
    --     dark     = "#f0b6c1",
    --     normal   = "#fbeded",
    --     lighter  = "#e9e9e9",
    --     lightest = "#ccd2ce",
    -- },
    -- { --without a heart ~-
    --     darkest  = "#fae4e7",
    --     dark     = "#dfb8c1",
    --     normal   = "#8c98c1",
    --     lighter  = "#97a8e8",
    --     lightest = "#c8d1f8",
    -- },
    { --high fashion   ~+
        darkest  = "#946aa9",
        dark     = "#bd72a1",
        normal   = "#e5968c",
        lighter  = "#f3bf7c",
        lightest = "#f6e06f",
        angle    = 180,
    },
    { --im not alone yet  ~+
        darkest  = "#9999a4",
        dark     = "#b1b4b9",
        normal   = "#d4d5ce",
        lighter  = "#fcfcfc",
        lightest = "#f3dfc4",
    },
    { --castle in the sky ++
        darkest  = "#6b3238",
        darker   = "#a05850",
        dark     = "#d57d68",
        normal   = "#f2c99a",
        light    = "#f5e8ad",
        lighter  = "#f5e8ad",
        lightest = "#9bdab9",
        angle    = 270,
    },
    { --pumpkaboo  ++
        darkest  = "#532d20",
        dark     = "#906146",
        normal   = "#b88246",
        lighter  = "#e0bc6f",
        lightest = "#dfecf7",
    },
    { --cherry soda ++
        darkest  = "#221206",
        dark     = "#39160d",
        normal   = "#781b24",
        light    = "#932e44",
        lighter  = "#932e44",
        lightest = "#fcf3e4",
    },
    -- { --i kinda like you back --
    --     darkest  = "#96f873",
    --     dark     = "#cdfa73",
    --     normal   = "#fcf475",
    --     lighter  = "#f2be6a",
    --     lightest = "#ed9660",
    -- },
    { --ominiferous  ~+ ~C
        darkest  = "#ab3b85",
        darker   = "#ab3b85",
        dark     = "#bb6582",
        normal   = "#bd9d7c",
        light    = "#c1cb80",
        lighter  = "#c1cb80",
        lightest = "#e9f1b6",
        angle    = 270,
    },
    -- { --blooming  ~~ (!!) -HC
    --     darkest  = "#ee8d9e",
    --     dark     = "#eea6b6",
    --     normal   = "#bcdead",
    --     lighter  = "#d4f3b8",
    --     lightest = "#f9fdda",
    -- },
    { --this is my swamp ++ ~C
        darkest  = "#526c67",
        darker   = "#526c67",
        dark     = "#507d59",
        normal   = "#6c9460",
        lighter  = "#95c26f",
        lightest = "#cde09d",
        angle    = 240,
    },
    -- { --what i gain i lose -- --HC
    --     darkest  = "#a39db7",
    --     dark     = "#e1d6e0",
    --     normal   = "#f4f1f8",
    --     light    = "#f9e3cd",
    --     lighter  = "#f9e3cd",
    --     lightest = "#f5bfb5",
    -- },
    { --cyberbullies ~+
        darkest  = "#acf8dc",
        dark     = "#84bfe0",
        normal   = "#5c82e6",
        lighter  = "#3240ed",
        lightest = "#0b04f0",
        angle    = 120,
    },
    { --cool sunsets ++
        darkest  = "#d5eea7",
        dark     = "#b5dbad",
        normal   = "#8bbc9e",
        lighter  = "#4f8587",
        lightest = "#22466a",
        angle    = 90,
    },
    { --subtle melancholy  ~- -H
        darkest  = "#7b6492",
        dark     = "#8f80a0",
        normal   = "#a8a7af",
        lighter  = "#b6c6be",
        lightest = "#c7ead2",
        angle    = 270,
    },
    -- { --conversation hearts -- --HC
    --     darkest  = "#e43464",
    --     dark     = "#c95177",
    --     normal   = "#ae858d",
    --     lighter  = "#9cc0a1",
    --     lightest = "#95f8bb",
    -- },
    -- { --tuesdays ~+ --HC  improve contrast?
    --     darkest  = "#a395f6",
    --     dark     = "#beb5f7",
    --     normal   = "#cfc7f9",
    --     lighter  = "#f9ebab",
    --     lightest = "#f9e278",
    -- },
    { --classic blue
        darkest  = "#000020",
        darker   = "#002040",
        dark     = "#002953",
        normal   = "#00468c",
        light    = "#0059b2",
        lighter  = "#0059b2",
        lightest = "#dddddd",
    },
}

local tableColors = {}
for i, stringSet in pairs(stringColors) do
    local tableSet = {}
    for color, str in pairs(stringSet) do
        if type(str) == "string" and str:match "#%x+" then
            tableSet[color] = {
                tonumber(str:sub(2, 3), 16) / 255,
                tonumber(str:sub(4, 5), 16) / 255,
                tonumber(str:sub(6, 7), 16) / 255,
            }
        else
            tableSet[color] = str
        end
    end
    tableColors[i] = tableSet
end

return tableColors
