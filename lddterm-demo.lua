local lddterm = dofile("lddterm.lua")

local baseSize = {46, 12}

lddterm.alwaysRender = true


drawDemo = function(window)
	lddterm.setLayer(window, 1)
	local term = window.handle
	local colors = window.ccapi.colors

	local sleep = lddterm.sleep

	local i = 0

	term.setBackgroundColorRGB(0x262626)
	term.clear(".")

	sleep(1)

	term.setBackgroundColor(colors.blue)
	term.setTextColor(colors.yellow)

	term.write("Hello!", 9, 5)
	sleep(0.5)

	term.setBackgroundColor(colors.orange)
	term.setTextColorRGB(0x0000FF)

	term.write("This is a test of 'LDDTerm'!", 4, 7)
	sleep(0.8)

	term.setBackgroundColorRGB(255, 0, 0)
	term.setTextColorRGB(0x000000)

	term.write("It's an API that provides basic \"windows\" that you can write in.", 5, 9)
	sleep(0.5)

	term.write("similar to the ComputerCraft's own term and window APIs!", 6, 10)
	sleep(1)

	term.setBackgroundColorRGB(0x262626)
	term.setTextColor(colors.white)

	for i = 1, 3 do
		term.scroll(-1)
--		sleep(0.05)
	end

	for i = 1, 3 do
		term.scrollX(-1)
--		sleep(0.05)
	end

	for i = 1, 6 do
		term.scroll(1)
--		sleep(0.05)
	end

	for i = 1, 6 do
		term.scrollX(1)
--		sleep(0.05)
	end

	for i = 1, 3 do
		term.scroll(-1)
--		sleep(0.05)
	end

	for i = 1, 3 do
		term.scrollX(-1)
--		sleep(0.05)
	end

	sleep(1)

	for i = 1, 5 do
		term.scroll(1)
--		sleep(0.05)
	end

	term.write("Supports 'term.scroll' and 'term.scrollX',", 2, 6)
	term.write("amongst other things!", 2, 7)
	term.write("You can also move windows.", 2, 9)

	sleep(1)

	for i = 1, 4 do
		term.moveWindow(window.x + 1, window.y)
	end

	for i = 1, 8 do
		term.moveWindow(window.x - 1, window.y)
	end

	for i = 1, 4 do
		term.moveWindow(window.x + 1, window.y)
	end

	for i = 1, 3 do
		term.moveWindow(window.x, window.y - 1)
	end

	for i = 1, 6 do
		term.moveWindow(window.x, window.y + 1)
	end

	for i = 1, 3 do
		term.moveWindow(window.x, window.y - 1)
	end

	sleep(1)

	for i = 1, 100 do
		term.setTextColorRGB(math.random(0, 0xFFFFFE))
		term.setBackgroundColorRGB(math.random(0, 0xFFFFFF))
		term.write((" "):rep(math.random(0, 12)) .. "Fuck you")
	end

	sleep(1)
end

for i = 1, 1024 do
	drawDemo(lddterm.newWindow(baseSize[1], baseSize[2], math.random(1, 20), math.random(1, 12)))
end
