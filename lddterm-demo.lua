local lddterm = dofile("lddterm.lua")

local baseSize = {46, 12}

lddterm.alwaysRender = true

drawDemo = function(window)
	local bg = 0x262626
	lddterm.setLayer(window, 1)
	local term = window.handle
	local colors = window.ccapi.colors
	local paintutils = window.ccapi.paintutils
	local sleep = lddterm.sleep

	local i = 0

	term.setBackgroundColorRGB(bg)
	term.setTextColor(colors.gray)
	term.clear(".")
	term.setTextColor(colors.white)
	term.write(lddterm.checkWindowOverlap(window, unpack(lddterm.windows)) and "Overlaps." or "Does not overlap.")
	sleep(0.5)

	for i = 1, 9, 0.1 do
		term.setBackgroundColorRGB(bg)
		term.setTextColor(colors.gray)
		term.clear(".", true)
		paintutils.drawLine(
			window.width / 2,
			window.height / 2,
			(window.width / 2) + math.sin(i) * (window.width / 2) + 1,
			(window.height / 2) + math.cos(i) * (window.height / 2) + 1,
			colors.red
		)
		sleep(0.05)
	end

	term.setBackgroundColor(colors.blue)
	term.setTextColor(colors.yellow)

	term.write("Hello!", 9, 4)
	sleep(0.5)

	term.setBackgroundColor(colors.orange)
	term.setTextColorRGB(0x0000FF)

	term.writeWrap("This is a test of 'LDDTerm'!", 4, 6)
	sleep(0.8)

	term.setBackgroundColorRGB(255, 0, 0)
	term.setTextColorRGB(0x000000)

	term.writeWrap("It's an API that provides basic \"windows\" that you can write in.", 5, 8)
	sleep(0.5)

	term.setBackgroundColorRGB(255, 255, 255)
	term.setTextColorRGB(0x330000)

	term.writeWrap("similar to the ComputerCraft's own term and window APIs!", 6, 10)
	sleep(1)

	term.setBackgroundColorRGB(bg)
	term.setTextColor(colors.white)

	for i = 1, 3 do
		term.scroll(-1)
		sleep(0.05)
	end

	for i = 1, 3 do
		term.scrollX(-1)
		sleep(0.05)
	end

	for i = 1, 6 do
		term.scroll(1)
		sleep(0.05)
	end

	for i = 1, 6 do
		term.scrollX(1)
		sleep(0.05)
	end

	for i = 1, 3 do
		term.scroll(-1)
		sleep(0.05)
	end

	for i = 1, 3 do
		term.scrollX(-1)
		sleep(0.05)
	end

	sleep(1)

	for i = 1, 5 do
		term.scroll(1)
		sleep(0.05)
	end

	term.writeWrap("Supports 'term.scroll' and 'term.scrollX',", 2, 6)
	term.writeWrap("amongst other things!", 2, 7)
	term.writeWrap("You can also move windows.", 2, 9)

	sleep(1)

	for i = 1, 4 do
		term.moveWindow(window.x + 1, window.y)
		sleep(0.05)
	end

	for i = 1, 8 do
		term.moveWindow(window.x - 1, window.y)
		sleep(0.05)
	end

	for i = 1, 4 do
		term.moveWindow(window.x + 1, window.y)
		sleep(0.05)
	end

	for i = 1, 3 do
		term.moveWindow(window.x, window.y - 1)
		sleep(0.05)
	end

	for i = 1, 6 do
		term.moveWindow(window.x, window.y + 1)
		sleep(0.05)
	end

	for i = 1, 3 do
		term.moveWindow(window.x, window.y - 1)
		sleep(0.05)
	end

	sleep(1)

	for i = 1, 100 do
		term.setTextColorRGB(math.random(0, 0xFFFFFE))
		term.setBackgroundColorRGB(math.random(0, 0xFFFFFF))
		term.writeWrap((" "):rep(math.random(0, 12)) .. "Fuck you")
	end

	sleep(1)

	term.setBackgroundColorRGB(0x262626)
	term.setTextColorRGB(math.random(1,30), math.random(1,30), math.random(1,30))
	term.setCursorPos(1,1)
	for i = 1, window.width * window.height do
		term.writeWrap(".", nil, nil, math.random(1,12) ~= 1)
	end
end

while true do
	for i = 1, 4 do
		drawDemo(lddterm.newWindow(baseSize[1], baseSize[2], math.random(1, lddterm.screenWidth - baseSize[1]), math.random(1, lddterm.screenHeight - baseSize[2])))
	end
	for y = 1, lddterm.screenHeight do

		for i = #lddterm.windows, 1, -1 do
			lddterm.windows[i].x = lddterm.windows[i].x + math.random(-2, 2)
			lddterm.windows[i].y = lddterm.windows[i].y + 1
			if lddterm.windows[i].y > lddterm.screenHeight then
				table.remove(lddterm.windows, i)
			end
		end
		lddterm.render()
		lddterm.sleep(0.05)
	end
	lddterm.windows = {}
end
