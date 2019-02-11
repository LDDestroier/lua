local lddterm = dofile("lddterm.lua")
local window = lddterm.newWindow(70, 24, 4, 4)
local term = window.handle

lddterm.alwaysRender = true

local sleep = lddterm.sleep

local i = 0

term.clear(".")

sleep(1)

term.setBackgroundColor(1)

term.write("Hello!", 9, 5)
sleep(0.5)
term.setTextColor(2)
term.write("This is a test of 'LDDTerm'!", 4, 7)
sleep(0.8)
term.setTextColor(8)
term.setBackgroundColor(2)
term.write("It's an API that provides basic \"windows\" that you can write in.", 5, 9)
sleep(0.5)
term.write("similar to the ComputerCraft's own term and window APIs!", 6, 10)

term.setBackgroundColor(9)
term.setBackgroundColor(0)
sleep(1)

for i = 1, 10 do
	term.scroll(1)
	sleep(0.05)
end

sleep(1)

for i = 1, 20 do
	term.scroll(-1)
	sleep(0.05)
end

sleep(1)

for i = 1, 10 do
	term.scroll(1)
	sleep(0.05)
end

sleep(0.5)

term.write("Supports 'term.scroll',", 10, 16)
term.write("amongst other things!", 10, 17)

sleep(1)

term.write("Look in the code to see what the functions!", 4, 19)
