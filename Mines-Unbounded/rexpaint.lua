--
-- A lightweight REXPaint .xp reader for LOVE2D.
-- By Vriska Serket / @arachonteur 
--
-- Output table looks like this.
--[[
	{
		version = 0,
		layerCount = 0,
		layers = {
			[1] = {
				width = 20,
				height = 20,
				index = 1,
				cells = {
					[1] = {
						x = 0,
						y = 0,
						char = 0,
						fg = {1, 1, 1},
						bg = {0, 0, 0}
					},
					[...]
				}
			},
			[...]
		}
	}
]]
--
--
local exp = {
	version_bytes = 4,
	layer_count_bytes = 4,

	layer_width_bytes = 4,
	layer_height_bytes = 4,
	layer_keycode_bytes = 4,
	layer_fore_rgb_bytes = 3,
	layer_back_rgb_bytes = 3,

	transparent = {
		r = 255,
		g = 0,
		b = 255
	}
}

exp.layer_cell_bytes = exp.layer_keycode_bytes + exp.layer_fore_rgb_bytes + exp.layer_back_rgb_bytes


function exp:read(file)
	if love.filesystem.getInfo(file) then
		self.file = love.filesystem.read(file)
	else
		error(string.format("REXPaint Reader: File %s does not exist.", file))
	end

	self.fileString = love.data.decompress( "string", "gzip", self.file)

	local xp = {
		--version = 0,
		layerCount = 0,

		layers = {}
	}

	local offset = 0
	local version = {self.fileString:byte(offset, self.version_bytes)}
	offset = offset + self.version_bytes + 1

	local layer_count = {self.fileString:byte(offset, offset + self.layer_count_bytes)}
	offset = offset + self.layer_count_bytes

	--xp.version = version
	xp.layerCount = layer_count[1]

	for i = 1, layer_count[1] do
		local layerWidth = {self.fileString:byte(offset, offset + self.layer_width_bytes)}
		offset = offset + self.layer_width_bytes

		local layerHeight = {self.fileString:byte(offset, offset + self.layer_height_bytes)}
		offset = offset + self.layer_height_bytes

		local layerSize = self.layer_cell_bytes * layerWidth[1] * layerHeight[1]

		local layer = {
			index = i,
			width = layerWidth[1],
			height = layerHeight[1],
			cells = {}
		}

		for j = 1, layerWidth[1] * layerHeight[1] do
			local cell = {
				x = 0,
				y = 0,
				char = 1,
				fg = {
					r = 1,
					g = 1,
					b = 1
				},
				bg = {
					r = 1,
					g = 1,
					b = 1
				}
			}

			cell.y = (j - 1) % layer.height
			cell.x = ((j - 1)  - ( cell.y ) ) / layer.height

			local tempOffset = offset
			local keycode = {self.fileString:byte(tempOffset, tempOffset + self.layer_keycode_bytes - 1)}
			cell.char = (keycode[1]) + 1
			tempOffset = tempOffset + self.layer_keycode_bytes
			local fg = {self.fileString:byte(tempOffset, tempOffset + self.layer_fore_rgb_bytes - 1)}
			fg[1] = fg[1]/255
			fg[2] = fg[2]/255
			fg[3] = fg[3]/255
			cell.fg = fg
			tempOffset = tempOffset + self.layer_fore_rgb_bytes
			local bg = {self.fileString:byte(tempOffset, tempOffset + self.layer_back_rgb_bytes - 1)}
			bg[1] = bg[1]/255
			bg[2] = bg[2]/255
			bg[3] = bg[3]/255
			cell.bg = bg
			tempOffset = tempOffset + self.layer_back_rgb_bytes

			offset = tempOffset
			if ( cell.char ~= 1 ) then
				table.insert(layer.cells, cell)
			end
		end

		table.insert(xp.layers, layer)
	end

	return xp
end

return exp
