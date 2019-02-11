local lddterm = {}

lddterm.alwaysRender = false	-- renders after any and all screen-changing functions.
lddterm.useColors = true		-- use "tput" for colors. looks swood, but decreases performance

lddterm.windows = {}

local isUnix = package.config:sub(1,1) == "/"

if not isUnix then
	error("Linux or Unix is required to use. I'm not sorry.")
end

local scr_x, scr_y

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
	scr_y = capture("tput lines") - 1
end

lddterm.newWindow = function(width, height, x, y)
	local window = {
		width = width,
		height = height,
		cursor = {1, 1},
		colors = {9, 9},
		clearChar = " ",
		x = x or 1,
		y = y or 1,
		buffer = {{},{},{}},
	}
	for c = 1, 3 do
		for y = 1, height do
			window.buffer[c][y] = {}
			for x = 1, width do
				window.buffer[c][y][x] = " "
			end
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
	window.handle.write = function(text, x, y, ignoreAlwaysRender)
		text = text and tostring(text)
		local cx, cy = math.floor(x or window.cursor[1]), math.floor(y or window.cursor[2])
		if cx > window.width or cy > window.height then
			return
		else
			text = text:sub(math.max(0, -cx - 1))
			for i = 1, #text do
				window.buffer[1][cy][cx] = text:sub(i,i)
				window.buffer[2][cy][cx] = window.colors[1]
				window.buffer[3][cy][cx] = window.colors[2]
				if cx >= window.width then
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
		if color >= 0 and color <= 9 then
			window.colors[1] = color
		end
	end
	window.handle.setBackgroundColor = function(color)
		if color >= 0 and color <= 9 then
			window.colors[2] = color
		end
	end
	window.handle.getTextColor = function()
		return window.colors[1]
	end
	window.handle.getBackgroundColor = function()
		return window.colors[2]
	end

	window.layer = #lddterm.windows + 1
	lddterm.windows[window.layer] = window

	return window
end

lddterm.layerAlter = function(window, layerMod)
	local you = lddterm.windows[window.layer]
	local nou = lddterm.windows[window.layer + layerMod]
	if you then
		you, you.layer, nou, nou.layer = nou, nou.layer, you, you.layer
		return true
	else
		return false
	end
	if lddterm.alwaysRender then
		lddterm.render()
	end
end

local colors = {
	black 		= "$(tput setaf 0)",
	red 		= "$(tput setaf 1)",
	green 		= "$(tput setaf 2)",
	yellow 		= "$(tput setaf 3)",
	lime 		= "$(tput setaf 190)",
	lightBlue 	= "$(tput setaf 153)",
	blue 		= "$(tput setaf 4)",
	magenta 	= "$(tput setaf 5)",
	cyan 		= "$(tput setaf 6)",
	white 		= "$(tput setaf 7)"
}

lddterm.render = function()
	local sx, sy
	local c, t, b
	local lt, lb
	determineScreenSize()
	lddterm.clear()
	local line
	for y = 1, scr_y do
		line = ""
		for x = 1, scr_x do

			c = " "
			lt, lb = t, b
			t, b = 9, 0
			for l = 1, #lddterm.windows do
				sx = x - lddterm.windows[l].x + 1
				sy = y - lddterm.windows[l].y + 1
				if lddterm.windows[l].buffer[1][sy] then
					if lddterm.windows[l].buffer[1][sy][sx] then
						c = lddterm.windows[l].buffer[1][sy][sx]
						t = lddterm.windows[l].buffer[2][sy][sx]
						b = lddterm.windows[l].buffer[3][sy][sx]
						break
					end
				end
			end
			if lddterm.useColors then
				if lt ~= t then
					line = line .. "$(tput setaf " .. t .. ")"
				end
				if lb ~= b then
					line = line .. "$(tput setab " .. b .. ")"
				end
			end

			line = line .. c

		end
		os.execute("echo \"" .. line:gsub("\"", "”") .. "\"")
	end
end

return lddterm
