---@alias palette_string_pack {darkest: string, dark: string, normal: string, light: string, lightest: string}

---@type palette_string_pack[]
local stringColors =
{
    { --anxiety
        darkest = "#221330";
        dark    = "#293452";
        normal  = "#32545e";
        light   = "#447a5a";
        lightest= "#548d58";
    },
    { --sodas and skateboards
        darkest = "#831d80";
        dark    = "#6d49a8";
        normal  = "#567dc3";
        light   = "#5ab6e0";
        lightest= "#6ae3f4";
    },
    { --guidance
        darkest = "#7a6947";
        dark    = "#f9ea8d";
        normal  = "#d3d87c";
        light   = "#aebb69";
        lightest= "#8c9458";
    },
    { --constant rambling
        darkest = "#ed8f8b";
        dark    = "#f3c5a4";
        normal  = "#fbe8c6";
        light   = "#add6fa";
        lightest= "#90c9ff";
    },
    { --the sweetest chill
        darkest = "#343432";
        dark    = "#645b9e";
        normal  = "#8e84c3";
        light   = "#c5aee4";
        lightest= "#e4e9e6";
    },
    { --saltwater tears
        darkest = "#dbf4bf";
        dark    = "#b7e4a1";
        normal  = "#60a581";
        light   = "#547b7d";
        lightest= "#446c6c";
    },
    { --damned if i do
        darkest = "#da8ba0";
        dark    = "#f0b6c1";
        normal  = "#fbeded";
        light   = "#e9e9e9";
        lightest= "#ccd2ce";
    },
    { --without a heart
        darkest = "#fae4e7";
        dark    = "#dfb8c1";
        normal  = "#8c98c1";
        light   = "#97a8e8";
        lightest= "#c8d1f8";
    },
    { --high fashion
        darkest = "#f6e06f";
        dark    = "#f3bf7c";
        normal  = "#e5968c";
        light   = "#bd72a1";
        lightest= "#946aa9";
    },
    { --im not alone yet
        darkest = "#9999a4";
        dark    = "#b1b4b9";
        normal  = "#d4d5ce";
        light   = "#fcfcfc";
        lightest= "#f3dfc4";
    },
    { --castle in the sky
        darkest = "#6b3238";
        dark    = "#d57d68";
        normal  = "#f2c99a";
        light   = "#f5e8ad";
        lightest= "#9bdab9";
    },
    { --pumpkaboo
        darkest = "#dfecf7";
        dark    = "#e0bc6f";
        normal  = "#b88246";
        light   = "#906146";
        lightest= "#532d20";
    },
    { --cherry soda
        darkest = "#221206";
        dark    = "#39160d";
        normal  = "#781b24";
        light   = "#932e44";
        lightest= "#fcf3e4";
    },
    { --i kinda like you back
        darkest = "#96f873";
        dark    = "#cdfa73";
        normal  = "#fcf475";
        light   = "#f2be6a";
        lightest= "#ed9660";
    },
    { --ominiferous
        darkest = "#e9f1b6";
        dark    = "#c1cb80";
        normal  = "#bd9d7c";
        light   = "#bb6582";
        lightest= "#ab3b85";
    },
    { --blooming
        darkest = "#f9fdda";
        dark    = "#d4f3b8";
        normal  = "#bcdead";
        light   = "#eea6b6";
        lightest= "#ee8d9e";
    },
    { --this is my swamp
        darkest = "#526c67";
        dark    = "#507d59";
        normal  = "#6c9460";
        light   = "#95c26f";
        lightest= "#cde09d";
    },
    { --what i gain i lose
        darkest = "#a39db7";
        dark    = "#e1d6e0";
        normal  = "#f4f1f8";
        light   = "#f9e3cd";
        lightest= "#f5bfb5";
    },
    { --cyberbullies
        darkest = "#acf8dc";
        dark    = "#84bfe0";
        normal  = "#5c82e6";
        light   = "#3240ed";
        lightest= "#0b04f0";
    },
    { --cool sunsets
        darkest = "#d5eea7";
        dark    = "#b5dbad";
        normal  = "#8bbc9e";
        light   = "#4f8587";
        lightest= "#22466a";
    },
    { --subtle melancholy
        darkest = "#7b6492";
        dark    = "#8f80a0";
        normal  = "#a8a7af";
        light   = "#b6c6be";
        lightest= "#c7ead2";
    },
    { --conversation hearts
        darkest = "#e43464";
        dark    = "#c95177";
        normal  = "#ae858d";
        light   = "#9cc0a1";
        lightest= "#95f8bb";
    },
    { --tuesdays
        darkest = "#a395f6";
        dark    = "#beb5f7";
        normal  = "#cfc7f9";
        light   = "#f9ebab";
        lightest= "#f9e278";
    },
}

local tableColors = {}
for i, stringSet in pairs(stringColors) do
    local tableSet = {}
    for color, str in pairs(stringSet) do
        tableSet[color] = {
            tonumber(str:sub(2,3),16)/255;
            tonumber(str:sub(4,5),16)/255;
            tonumber(str:sub(6,7),16)/255;
        }
    end
    tableColors[i] = tableSet
end

return tableColors