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

-- separates string into table based on divider
local explode = function(div, str, replstr, includeDiv)
	if (div == '') then
		return false
	end
	local pos, arr = 0, {}
	for st, sp in function() return string.find(str, div, pos, false) end do
		table.insert(arr, string.sub(replstr or str, pos, st - 1 + (includeDiv and #div or 0)))
		pos = sp + 1
	end
	table.insert(arr, string.sub(replstr or str, pos))
	return arr
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

local makePaintutilsAPI = function(term)
	local paintutils = {}

	local function drawPixelInternal( xPos, yPos )
		term.setCursorPos( xPos, yPos )
		term.write(" ")
	end

	local tColourLookup = {}
	for n=1,16 do
		tColourLookup[ string.byte( "0123456789abcdef",n,n ) ] = 2^(n-1)
	end

	local function parseLine( tImageArg, sLine )
		local tLine = {}
		for x=1,sLine:len() do
			tLine[x] = tColourLookup[ string.byte(sLine,x,x) ] or 0
		end
		table.insert( tImageArg, tLine )
	end

	function paintutils.parseImage( sRawData )
		if type( sRawData ) ~= "string" then
			error( "bad argument #1 (expected string, got " .. type( sRawData ) .. ")" )
		end
		local tImage = {}
		for sLine in ( sRawData .. "\n" ):gmatch( "(.-)\n" ) do -- read each line like original file handling did
			parseLine( tImage, sLine )
		end
		return tImage
	end

	function paintutils.loadImage( sPath )
		if type( sPath ) ~= "string" then
			error( "bad argument #1 (expected string, got " .. type( sPath ) .. ")", 2 )
		end

		local file = io.open( sPath, "r" )
		if file then
			local sContent = file:read("*a")
			file:close()
			return paintutils.parseImage( sContent ) -- delegate image parse to parseImage
		end
		return nil
	end

	function paintutils.drawPixel( xPos, yPos, nColour )
		if type( xPos ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( xPos ) .. ")", 2 ) end
		if type( yPos ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( yPos ) .. ")", 2 ) end
		if nColour ~= nil and type( nColour ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( nColour ) .. ")", 2 ) end
		if nColour then
			term.setBackgroundColor( nColour )
		end
		drawPixelInternal( xPos, yPos )
	end

	function paintutils.drawLine( startX, startY, endX, endY, nColour )
		if type( startX ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( startX ) .. ")", 2 ) end
		if type( startY ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( startY ) .. ")", 2 ) end
		if type( endX ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( endX ) .. ")", 2 ) end
		if type( endY ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( endY ) .. ")", 2 ) end
		if nColour ~= nil and type( nColour ) ~= "number" then error( "bad argument #5 (expected number, got " .. type( nColour ) .. ")", 2 ) end

		local alwaysRender = lddterm.alwaysRender
		lddterm.alwaysRender = false

		startX = math.floor(startX)
		startY = math.floor(startY)
		endX = math.floor(endX)
		endY = math.floor(endY)

		if nColour then
			term.setBackgroundColor( nColour )
		end
		if startX == endX and startY == endY then
			drawPixelInternal( startX, startY )
			if alwaysRender then lddterm.render() end
			lddterm.alwaysRender = alwaysRender
			return
		end

		local minX = math.min( startX, endX )
		local maxX, minY, maxY
		if minX == startX then
			minY = startY
			maxX = endX
			maxY = endY
		else
			minY = endY
			maxX = startX
			maxY = startY
		end

		local xDiff = maxX - minX
		local yDiff = maxY - minY

		if xDiff > math.abs(yDiff) then
			local y = minY
			local dy = yDiff / xDiff
			for x=minX,maxX do
				drawPixelInternal( x, math.floor( y + 0.5 ) )
				y = y + dy
			end
		else
			local x = minX
			local dx = xDiff / yDiff
			if maxY >= minY then
				for y=minY,maxY do
					drawPixelInternal( math.floor( x + 0.5 ), y )
					x = x + dx
				end
			else
				for y=minY,maxY,-1 do
					drawPixelInternal( math.floor( x + 0.5 ), y )
					x = x - dx
				end
			end
		end
		if alwaysRender then lddterm.render() end
		lddterm.alwaysRender = alwaysRender
	end

	function paintutils.drawBox( startX, startY, endX, endY, nColour )
		if type( startX ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( startX ) .. ")", 2 ) end
		if type( startY ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( startY ) .. ")", 2 ) end
		if type( endX ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( endX ) .. ")", 2 ) end
		if type( endY ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( endY ) .. ")", 2 ) end
		if nColour ~= nil and type( nColour ) ~= "number" then error( "bad argument #5 (expected number, got " .. type( nColour ) .. ")", 2 ) end

		local alwaysRender = lddterm.alwaysRender
		lddterm.alwaysRender = false

		startX = math.floor(startX)
		startY = math.floor(startY)
		endX = math.floor(endX)
		endY = math.floor(endY)

		if nColour then
			term.setBackgroundColor( nColour )
		end
		if startX == endX and startY == endY then
			drawPixelInternal( startX, startY )
			if alwaysRender then lddterm.render() end
			lddterm.alwaysRender = alwaysRender
			return
		end

		local minX = math.min( startX, endX )
		local maxX, minY, maxY
		if minX == startX then
			minY = startY
			maxX = endX
			maxY = endY
		else
			minY = endY
			maxX = startX
			maxY = startY
		end

		for x=minX,maxX do
			drawPixelInternal( x, minY )
			drawPixelInternal( x, maxY )
		end

		if (maxY - minY) >= 2 then
			for y=(minY+1),(maxY-1) do
				drawPixelInternal( minX, y )
				drawPixelInternal( maxX, y )
			end
		end
		if alwaysRender then lddterm.render() end
		lddterm.alwaysRender = alwaysRender
	end

	function paintutils.drawFilledBox( startX, startY, endX, endY, nColour )
		if type( startX ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( startX ) .. ")", 2 ) end
		if type( startY ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( startY ) .. ")", 2 ) end
		if type( endX ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( endX ) .. ")", 2 ) end
		if type( endY ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( endY ) .. ")", 2 ) end
		if nColour ~= nil and type( nColour ) ~= "number" then error( "bad argument #5 (expected number, got " .. type( nColour ) .. ")", 2 ) end

		local alwaysRender = lddterm.alwaysRender
		lddterm.alwaysRender = false

		startX = math.floor(startX)
		startY = math.floor(startY)
		endX = math.floor(endX)
		endY = math.floor(endY)

		if nColour then
			term.setBackgroundColor( nColour )
		end
		if startX == endX and startY == endY then
			drawPixelInternal( startX, startY )
			return
		end

		local minX = math.min( startX, endX )
		local maxX, minY, maxY
		if minX == startX then
			minY = startY
			maxX = endX
			maxY = endY
		else
			minY = endY
			maxX = startX
			maxY = startY
		end

		for x=minX,maxX do
			for y=minY,maxY do
				drawPixelInternal( x, y )
			end
		end
		if alwaysRender then
			lddterm.render()
		end
		lddterm.alwaysRender = alwaysRender
	end

	function paintutils.drawImage( tImage, xPos, yPos )
		if type( tImage ) ~= "table" then error( "bad argument #1 (expected table, got " .. type( tImage ) .. ")", 2 ) end
		if type( xPos ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( xPos ) .. ")", 2 ) end
		if type( yPos ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( yPos ) .. ")", 2 ) end

		local alwaysRender = lddterm.alwaysRender
		lddterm.alwaysRender = false

		for y=1,#tImage do
			local tLine = tImage[y]
			for x=1,#tLine do
				if tLine[x] > 0 then
					term.setBackgroundColor( tLine[x] )
					drawPixelInternal( x + xPos - 1, y + yPos - 1 )
				end
			end
		end
		if alwaysRender then
			lddterm.render()
		end
		lddterm.alwaysRender = alwaysRender
	end

	return paintutils
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
			cx = math.min(cx + 1, window.width + 1)
		end
		window.cursor = {cx, cy}
		if lddterm.alwaysRender and not ignoreAlwaysRender then
			lddterm.render()
		end
	end
	window.handle.writeWrap = function(text, x, y, ignoreAlwaysRender)
		local words = explode(" ", text, nil, true)
		local cx, cy = x or window.cursor[1], y or window.cursor[2]
		for i = 1, #words do
			if cx + #words[i] > window.width then
				cx = 1
				if cy >= window.height then
					window.handle.scroll(1)
					cy = window.height
				else
					cy = cy + 1
				end
			end
			window.handle.write(words[i], cx, cy, true)
			cx = cx + #words[i]
		end
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
		paintutils = makePaintutilsAPI(window.handle)
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
