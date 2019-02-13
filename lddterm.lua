local lddterm = {}

lddterm.alwaysRender = false	-- renders after any and all screen-changing functions.
lddterm.useColors = true		-- use "tput" for colors. looks swood, but decreases performance

lddterm.windows = {}

local isUnix = package.config:sub(1,1) == "/"

if not isUnix then
	error("Linux or Unix is required to use. I'm not sorry.")
end

-- proper color support is only in Lua 5.2 and higher
if _VERSION == "Lua 5.1" then
	lddterm.useColors = false
end

local scr_x, scr_y

-- used primarily for computercraft compatibility, for what it's worth
local colors = {
	white = 1,
	orange = 2,
	magenta = 4,
	lightBlue = 8,
	yellow = 16,
	lime = 32,
	pink = 64,
	gray = 128,
	lightGray = 256,
	cyan = 512,
	purple = 1024,
	blue = 2048,
	brown = 4096,
	green = 8192,
	red = 16384,
	black = 32768
}

local colorsToRGB = {
	[1] 	= {240, 240, 240},
	[2] 	= {242, 178,  51},
	[4] 	= {229, 127, 216},
	[8] 	= {153, 178, 242},
	[16] 	= {222, 222, 108},
	[32] 	= {127, 204,  25},
	[64] 	= {242, 178, 204},
	[128] 	= { 76,  76,  76},
	[256] 	= {153, 153, 153},
	[512] 	= { 76, 153, 178},
	[1024] 	= {178, 102, 229},
	[2048] 	= { 51, 102, 204},
	[4096] 	= {127, 102,  76},
	[8192] 	= { 87, 166,  78},
	[16384] = {204,  76,  76},
	[32768] = { 25,  25,  25}
}
local RGBtoColors = {}
local tColors = {}

for k,v in pairs(colors) do
	tColors[k] = colorsToRGB[v]
end

for k,v in pairs(colorsToRGB) do
	RGBtoColors[v] = k
end

-- run program and return its output
local function capture(cmd, raw)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	if raw then
		return s
	else
		s = string.gsub(s, '^%s+', '')
		s = string.gsub(s, '%s+$', '')
		s = string.gsub(s, '[\n\r]+', ' ')
		return s
	end
end

lddterm.sleep = function(n) -- seconds
	local t0 = os.clock()
	while os.clock() - t0 <= n do end
end

lddterm.clear = function()
	os.execute("clear")
end

local determineScreenSize = function()
	scr_x = capture("tput cols")
	scr_y = capture("tput lines")
end

lddterm.newWindow = function(width, height, x, y, meta)
	meta = meta or {}
	local window = {
		width = width,
		height = height,
		cursor = meta.cursor or {1, 1},
		colors = meta.colors or {tColors.white, tColors.black},
		clearChar = meta.clearChar or " ",
		x = x or 1,
		y = y or 1,
		buffer = {{},{},{}},
	}
	for y = 1, height do
		window.buffer[1][y] = {}
		window.buffer[2][y] = {}
		window.buffer[3][y] = {}
		for x = 1, width do
			window.buffer[1][y][x] = window.clearChar
			window.buffer[2][y][x] = window.colors[1]
			window.buffer[3][y][x] = window.colors[2]
		end
	end

	window.handle = {}
	window.handle.setCursorPos = function(x, y)
		window.cursor = {x, y}
	end
	window.handle.getCursorPos = function()
		return window.cursor[1], window.cursor[2]
	end
	window.handle.scroll = function(amount)
		if amount > 0 then
			for i = 1, amount do
				for c = 1, 3 do
					table.remove(window.buffer[c], 1)
					window.buffer[c][window.height] = {}
					for xx = 1, width do
						window.buffer[c][window.height][xx] = (
							c == 1 and window.clearChar or
							c == 2 and window.colors[1] or
							c == 3 and window.colors[2]
						)
					end
				end
			end
		elseif amount < 0 then
			for i = 1, -amount do
				for c = 1, 3 do
					window.buffer[c][window.height] = nil
					table.insert(window.buffer[c], 1, {})
					for xx = 1, width do
						window.buffer[c][1][xx] = (
							c == 1 and window.clearChar or
							c == 2 and window.colors[1] or
							c == 3 and window.colors[2]
						)
					end
				end
			end
		end
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end
	window.handle.scrollX = function(amount)
		if amount > 0 then
			for i = 1, amount do
				for c = 1, 3 do
					for y = 1, window.height do
						table.remove(window.buffer[c][y], 1)
						window.buffer[c][y][window.width] = (
							c == 1 and window.clearChar or
							c == 2 and window.colors[1] or
							c == 3 and window.colors[2]
						)
					end
				end
			end
		elseif amount < 0 then
			for i = 1, -amount do
				for c = 1, 3 do
					for y = 1, window.height do
						window.buffer[c][y][window.width] = nil
						table.insert(window.buffer[c][y], 1, (
							c == 1 and window.clearChar or
							c == 2 and window.colors[1] or
							c == 3 and window.colors[2]
						))
					end
				end
			end
		end
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end
	window.handle.write = function(text, x, y, ignoreAlwaysRender)
		if type(text) == "number" then
			text = tostring(text)
		end
		assert(text, "expected string 'text'")
		local cx = math.floor(tonumber(x) or window.cursor[1])
		local cy = math.floor(tonumber(y) or window.cursor[2])
		text = text:sub(math.max(0, -cx - 1))
		for i = 1, #text do
			if cx >= 1 and cx <= window.width and cy >= 1 and cy <= window.height then
				window.buffer[1][cy][cx] = text:sub(i,i)
				window.buffer[2][cy][cx] = window.colors[1]
				window.buffer[3][cy][cx] = window.colors[2]
			end
			if cx >= window.width or cy < 1 then
				cx = 1
				if cy >= window.height then
					window.handle.scroll(1)
				else
					cy = cy + 1
				end
			else
				cx = cx + 1
			end
		end
		window.cursor = {cx, cy}
		if lddterm.alwaysRender and not ignoreAlwaysRender then
			lddterm.render()
		end
	end
	window.handle.blit = function(char, textCol, backCol, x, y)
		if type(char) == "number" then
			char = tostring(char)
		end
		if type(textCol) == "number" then
			textCol = tostring(textCol)
		end
		if type(backCol) == "number" then
			backCol = tostring(backCol)
		end
		assert(text, "expected string 'text'")
		local cx = math.floor(tonumber(x) or window.cursor[1])
		local cy = math.floor(tonumber(y) or window.cursor[2])
		text = text:sub(math.max(0, -cx - 1))
		for i = 1, #text do
			if cx >= 1 and cx <= window.width and cy >= 1 and cy <= window.height then
				window.buffer[1][cy][cx] = char:sub(i,i)
				window.buffer[2][cy][cx] = textCol:sub(i,i)
				window.buffer[3][cy][cx] = backCol:sub(i,i)
			end
			if cx >= window.width or cy < 1 then
				cx = 1
				if cy >= window.height then
					window.handle.scroll(1)
				else
					cy = cy + 1
				end
			else
				cx = cx + 1
			end
		end
		window.cursor = {cx, cy}
		if lddterm.alwaysRender and not ignoreAlwaysRender then
			lddterm.render()
		end
	end
	window.handle.print = function(text, x, y)
		text = text and tostring(text)
		window.handle.write(text, x, y, true)
		window.cursor[1] = 1
		if window.cursor[2] >= window.height then
			window.handle.scroll(1)
		else
			window.cursor[2] = window.cursor[2] + 1
			if lddterm.alwaysRender then
				lddterm.render()
			end
		end
	end
	window.handle.clear = function(char)
		local cx = 1
		for y = 1, window.height do
			for x = 1, window.width do
				if char then
					cx = (x % #char) + 1
				end
				window.buffer[1][y][x] = char:sub(cx, cx) or window.clearChar
				window.buffer[2][y][x] = window.colors[1]
				window.buffer[3][y][x] = window.colors[2]
			end
		end
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end
	window.handle.clearLine = function(cy, char)
		cy = math.floor(cy)
		local cx = 1
		for x = 1, window.width do
			if char then
				cx = (x % #char) + 1
			end
			window.buffer[1][cy or window.cursor[2]][x] = char:sub(cx, cx) or window.clearChar
			window.buffer[2][cy or window.cursor[2]][x] = window.colors[1]
			window.buffer[3][cy or window.cursor[2]][x] = window.colors[2]
		end
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end
	window.handle.clearColumn = function(cx, char)
		cx = math.floor(cx)
		char = char and char:sub(1,1)
		for y = 1, window.height do
			window.buffer[1][y][cx or window.cursor[1]] = char or window.clearChar
			window.buffer[2][y][cx or window.cursor[1]] = window.colors[1]
			window.buffer[3][y][cx or window.cursor[1]] = window.colors[2]
		end
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end
	window.handle.getSize = function()
		return window.width, window.height
	end
	window.handle.setTextColor = function(color)
		if colorsToRGB[color] then
			window.colors[1] = colorsToRGB[color]
		end
	end
	window.handle.setTextColorRGB = function(red, green, blue)
		if not green then
			local col = (("%x"):format(red) .. "000000"):sub(1,6)
			window.colors[1] = {
				tonumber("0x"..col:sub(1,2)),
				tonumber("0x"..col:sub(3,4)),
				tonumber("0x"..col:sub(5,6))
			}
		else
			window.colors[1] = {math.floor(red), math.floor(green), math.floor(blue)}
		end
	end
	window.handle.setBackgroundColor = function(color)
		if colorsToRGB[color] then
			window.colors[2] = colorsToRGB[color]
		end
	end
	window.handle.setBackgroundColorRGB = function(red, green, blue)
		if not green then
			local col = (("%x"):format(red) .. "000000"):sub(1,6)
			window.colors[2] = {
				tonumber("0x"..col:sub(1,2)),
				tonumber("0x"..col:sub(3,4)),
				tonumber("0x"..col:sub(5,6))
			}
		else
			window.colors[2] = {math.floor(red), math.floor(green), math.floor(blue)}
		end
	end
	window.handle.getTextColor = function()
		return RGBtoColors[window.colors[1]] or colors.white
	end
	window.handle.getBackgroundColor = function()
		return RGBtoColors[window.colors[2]] or colors.black
	end
	window.handle.moveWindow = function(x, y)
		window.x = math.floor(x or window.x)
		window.y = math.floor(y or window.y)
		if lddterm.alwaysRender then
			lddterm.render()
		end
	end

	window.ccapi = {
		colors = colors,
		paintutils = {
			loadImage = function( sPath )
				if type( sPath ) ~= "string" then
					error( "bad argument #1 (expected string, got " .. type( sPath ) .. ")", 2 )
				end

				if fs.exists( sPath ) then
					local file = io.open( sPath, "r" )
					local sContent = file:read("*a")
					file:close()
					return parseImage( sContent ) -- delegate image parse to parseImage
				end
				return nil
			end
		}
	}

	window.layer = #lddterm.windows + 1
	lddterm.windows[window.layer] = window

	return window
end

lddterm.setLayer = function(window, _layer)
	local layer = math.max(1, math.min(#lddterm.windows, _layer))

	local win = window
	table.remove(lddterm.windows, win.layer)
	table.insert(lddterm.windows, layer, win)

	if lddterm.alwaysRender then
		lddterm.render()
	end
	return true
end

-- if the screen changes size, the effect is broken
local old_scr_x, old_scr_y

lddterm.render = function()
	local sx, sy
	local c, t, b	-- char, text, back
	local lt, lb
	-- determine new screen size and change lddterm screen to fit
	old_scr_x, old_scr_y = scr_x, scr_y
	determineScreenSize()
	if old_scr_x ~= scr_x or old_scr_y ~= scr_y then
		lddterm.clear()
	end
	local line = ""
	for y = 1, scr_y do
		for x = 1, scr_x do

			c = " "
			lt, lb = t, b
			t, b = tColors.white, tColors.black
			for l = 1, #lddterm.windows do
				sx = x - lddterm.windows[l].x + 1
				sy = y - lddterm.windows[l].y + 1
				if lddterm.windows[l].buffer[1][sy] then
					if lddterm.windows[l].buffer[1][sy][sx] then
						c = lddterm.windows[l].buffer[1][sy][sx] or c
						t = lddterm.windows[l].buffer[2][sy][sx] or t
						b = lddterm.windows[l].buffer[3][sy][sx] or b
						break
					end
				end
			end
			if lddterm.useColors then
				if lt ~= t then
					if type(t) ~= "table" then
						error("t = '" .. t .. "'")
					end
					line = line .. '\x1b[38;2;'..table.concat(t, ";", 1, 3)..'m'
				end
				if lb ~= b then
					if type(b) ~= "table" then
						error("b = '" .. b .. "'")
					end
					line = line .. '\x1b[48;2;'..table.concat(b, ";", 1, 3)..'m'
				end
			end

			line = line .. c:gsub("'", "’"):gsub("\"", "”")

		end
	end
	os.execute("tput cup 0 0; printf \"" .. line .. "\"")
end

return lddterm
