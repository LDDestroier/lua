local lddterm = dofile("lddterm.lua")
local window = lddterm.newWindow(72, 16, 4, 4)
local term = window.handle
local colors = window.ccapi.colors

lddterm.alwaysRender = true

local sleep = lddterm.sleep

local i = 0

term.clear(".")

sleep(1)

term.setBackgroundColor(colors.red)
term.setTextColor(colors.yellow)

term.write("Hello!", 9, 5)
sleep(0.5)

term.setBackgroundColor(colors.blue)
term.setTextColor(colors.red)

term.write("This is a test of 'LDDTerm'!", 4, 7)
sleep(0.8)

term.setBackgroundColorRGB(255, 0, 0)
term.setTextColorRGB(0x000000)

term.write("It's an API that provides basic \"windows\" that you can write in.", 5, 9)
sleep(0.5)

term.write("similar to the ComputerCraft's own term and window APIs!", 6, 10)
sleep(1)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

for i = 1, 5 do
	term.scroll(-1)
	sleep(0.05)
end

for i = 1, 5 do
	term.scrollX(-1)
	sleep(0.05)
end

for i = 1, 10 do
	term.scroll(1)
	sleep(0.05)
end

for i = 1, 15 do
	term.scrollX(1)
	sleep(0.05)
end

for i = 1, 5 do
	term.scroll(-1)
	sleep(0.05)
end

for i = 1, 5 do
	term.scrollX(-1)
	sleep(0.05)
end

sleep(1)

term.write("Supports 'term.scroll' and 'term.scrollX',", 10, 13)
term.write("amongst other things!", 10, 14)

sleep(1)

for i = 1, 120 do
	term.setTextColorRGB(math.random(0, 0xFFFFFF))
	term.setBackgroundColorRGB(math.random(0, 0xFFFFFF))
	term.write((" "):rep(math.random(0, 12)) .. "Fuck you")
end

sleep(1)

term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)

for i = 1, 8 do
	term.scroll(1)
	sleep(0.05)
end

term.write("Look in the code to see what the functions!", 4, 16)
