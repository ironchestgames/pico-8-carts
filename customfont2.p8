pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- font snippet generator
-- by zep

--[[

 to make a font:

 1. choose a fixed size (below)
 2. draw as many characters as
    needed in the spritesheet
 3. run this program
 4. paste the snippet into your
    cartridge to use it

 -- output looks like this:
 -- poke(0x5600,unpack(split"8,8,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,63,63,63,63,63,63,0,0,0,63,63,63,0,0,0,0,0,63,51,63,0,0,0,0,0,51,12,51,0,0,0,0,0,51,0,51,0,0,0,0,0,51,51,51,0,0,0,0,48,60,63,60,48,0,0,0,3,15,63,15,3,0,0,62,6,6,6,6,0,0,0,0,0,48,48,48,48,62,0,99,54,28,62,8,62,8,0,0,0,0,24,0,0,0,0,0,0,0,0,0,12,24,0,0,0,0,0,0,12,12,0,0,0,10,10,0,0,0,0,0,4,10,4,0,0,0,0,0,0,0,0,0,0,0,0,12,12,12,12,12,0,12,0,0,54,54,0,0,0,0,0,0,54,127,54,54,127,54,0,8,62,11,62,104,62,8,0,0,51,24,12,6,51,0,0,14,27,27,110,59,59,110,0,12,12,0,0,0,0,0,0,24,12,6,6,6,12,24,0,12,24,48,48,48,24,12,0,0,54,28,127,28,54,0,0,0,12,12,63,12,12,0,0,0,0,0,0,0,12,12,6,0,0,0,62,0,0,0,0,0,0,0,0,0,12,12,0,32,48,24,12,6,3,1,0,62,99,115,107,103,99,62,0,24,28,24,24,24,24,60,0,63,96,96,62,3,3,127,0,63,96,96,60,96,96,63,0,51,51,51,126,48,48,48,0,127,3,3,63,96,96,63,0,62,3,3,63,99,99,62,0,127,96,48,24,12,12,12,0,62,99,99,62,99,99,62,0,62,99,99,126,96,96,62,0,0,0,12,0,0,12,0,0,0,0,12,0,0,12,6,0,48,24,12,6,12,24,48,0,0,0,30,0,30,0,0,0,6,12,24,48,24,12,6,0,30,51,48,24,12,0,12,0,0,30,51,59,59,3,30,0,0,0,62,96,126,99,126,0,3,3,63,99,99,99,63,0,0,0,62,99,3,99,62,0,96,96,126,99,99,99,126,0,0,0,62,99,127,3,62,0,124,6,6,63,6,6,6,0,0,0,126,99,99,126,96,62,3,3,63,99,99,99,99,0,0,24,0,28,24,24,60,0,48,0,56,48,48,48,51,30,3,3,51,27,15,27,51,0,12,12,12,12,12,12,56,0,0,0,99,119,127,107,99,0,0,0,63,99,99,99,99,0,0,0,62,99,99,99,62,0,0,0,63,99,99,63,3,3,0,0,126,99,99,126,96,96,0,0,62,99,3,3,3,0,0,0,62,3,62,96,62,0,12,12,62,12,12,12,56,0,0,0,99,99,99,99,126,0,0,0,99,99,34,54,28,0,0,0,99,99,107,127,54,0,0,0,99,54,28,54,99,0,0,0,99,99,99,126,96,62,0,0,127,112,28,7,127,0,62,6,6,6,6,6,62,0,1,3,6,12,24,48,32,0,62,48,48,48,48,48,62,0,12,30,18,0,0,0,0,0,0,0,0,0,0,0,30,0,12,24,0,0,0,0,0,0,28,54,99,99,127,99,99,0,63,99,99,63,99,99,63,0,62,99,3,3,3,99,62,0,31,51,99,99,99,51,31,0,127,3,3,63,3,3,127,0,127,3,3,63,3,3,3,0,62,3,3,115,99,99,126,0,99,99,99,127,99,99,99,0,63,12,12,12,12,12,63,0,127,24,24,24,24,24,15,0,99,51,27,15,27,51,99,0,3,3,3,3,3,3,127,0,99,119,127,107,99,99,99,0,99,103,111,107,123,115,99,0,62,99,99,99,99,99,62,0,63,99,99,63,3,3,3,0,62,99,99,99,99,51,110,0,63,99,99,63,27,51,99,0,62,99,3,62,96,99,62,0,63,12,12,12,12,12,12,0,99,99,99,99,99,99,62,0,99,99,99,99,54,28,8,0,99,99,99,107,127,119,99,0,99,99,54,28,54,99,99,0,99,99,99,126,96,96,63,0,127,96,48,28,6,3,127,0,56,12,12,7,12,12,56,0,8,8,8,0,8,8,8,0,14,24,24,112,24,24,14,0,0,0,110,59,0,0,0,0"))

 -- you can then use it with:
 -- print"\14 alt font!"
 
 -- or: poke(0x5f58,0x81) to
 -- always print with the alt
 -- font

]]

-- size of character (width2
-- is user for chr >= 128)
char_width    = 4
char_width2   = 4
char_height   = 5

-- draw offset
char_offset_x = 0
char_offset_y = 0

function _init()
	memset(0x5600,0,0x800)
	local s=load_from_sprites()
	printh(s,"@clip")
end


function _draw()
cls(1)

poke(0x5f58,0x81)
color(7)
?"the quick brown"
?"fox jumps over "
?"the lazy dog."
?""
?"THE QUICK BROWN"
?"FOX JUMPS OVER"
?"THE LAZY DOG?"
?""
?"0123456789 +-*/"
?"█▒🐱⬇️░✽●♥☉웃⌂⬅️😐"
?"♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥"
poke(0x5f58,0)
color(13)
print(" [snippet copied to clipboard]",0,120)
cursor()

end

function load_from_sprites()
	
	--find maximum sprite index
	--(look for any set pixel)
	maxi=0
	for i=0,255 do
	 local x0=(i%16)*8
	 local y0=(i\16)*8
	  for y=0,7 do
	 	 for x=0,7 do
	 	  if(sget(x0+x,y0+y)>0) maxi=i
	 	 end
	 	end
	end
	
	-- grab bits from each sprite
	for i=0,maxi do
	
	 local x0=(i%16)*8
	 local y0=(i\16)*8
	
	 for y=0,7 do
	 	local val=0
	 	for x=0,7 do
	 	 if sget(x0+x,y0+y)>0 then
	 	  val |= (1<<x)
	 	 end
	 	end
	 	poke(0x5600+i*8+y,val)
	 	
	 end
	
	end
	
	-- font attributes are stored
	-- in character 0
	poke(0x5600,
	 char_width,
	 char_width2,
	 char_height,
	 char_offset_x,
	 char_offset_y)
	
	-- generate string
	local str="poke(0x5600,unpack(split\""
	
	for i=0,maxi*8+7 do
		str..= peek(0x5600+i)
		if (i<maxi*8+7) str..=","
	end
	
	return str.."\"))"
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000007070000000000000000000007070000000000000000000000070000070000000707000000000000000000000000000000000000000700000
00000000700000000000000000000000000000000770000000000000000000000700000007000000070000000700000000000000000000000000000007000000
00000000000000000000000000000000000000007700000000000000000000000700000007000000707000007770000007000000777000000000000007000000
00000000700000000000000000000000000000007070000000000000000000000070000070000000000000000700000070000000000000007000000070000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000770000007770000077700000007000007770000077700000777000007770000077700000000000000000000000000000000000000000000077700000
70700000070000000070000007700000707000007000000070000000007000007770000070700000700000000000000000000000777000000000000000700000
70700000070000007000000000700000777000000070000070700000007000007070000000700000000000000000000000000000000000000000000000000000
77700000777000007770000077700000007000007770000077700000007000007770000077700000700000000000000000000000777000000000000007000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000070000000770000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000007000000070000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000007000000070000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000700000770000000000000077700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777000007700000077700000770000007770000077700000777000007070000077700000777000007070000070000000777000007700000077700000
00000000707000007770000070000000707000007700000070000000700000007770000007000000007000007700000070000000777000007070000070700000
00000000777000007070000070000000707000007000000077000000707000007070000007000000007000007070000070000000707000007070000070700000
00000000707000007770000077700000777000007770000070000000777000007070000077700000770000007070000077700000707000007070000077700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000070000007770000077700000777000007070000070700000707000007070000070700000777000000000000000000000000000000000000000000000
70700000707000007070000077000000070000007070000070700000707000000700000077700000077000000000000000000000000000000000000000000000
77700000777000007700000000700000070000007070000077700000777000007070000000700000700000000000000000000000000000000000000000000000
70000000077000007070000077700000070000007770000007000000777000007070000077700000777000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077700000000000000000000000000000000000000000000007000000000000000070000000000000000000007770000000000000
00000000000000000000000007000000000000000000000000000000000000000000000077700000000000007770000000000000000000007000000000000000
00000000000000000000000007000000000000000000000000000000000000000000000007000000000000000070000000000000000000007770000000000000
00000000000000000000000000000000000000000000000000000000000000000000000070700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000000000000070000000000000000000000707000000000000000000000000000000000000000000000000000000000000000000000
00000000777000000000000000000000070000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000000000000777000000000000000000000707000000000000000000000000000000000000000000000000000000000000000000000
__label__
77777711771117717777777111111111177777117711177177777711177777117711177111111111777777117777771117777711771117717711177111111111
11771111771117717711111111111111771117717711177111771111771117717711771111111111771117717711177177111771771117717771177111111111
11771111771117717711111111111111771117717711177111771111771111117717711111111111771117717711177177111771771117717777177111111111
11771111777777717777771111111111771117717711177111771111771111117777111111111111777777117777771177111771771717717717177111111111
11771111771117717711111111111111771117717711177111771111771111117717711111111111771117717717711177111771777777717717777111111111
11771111771117717711111111111111771177117711177111771111771117717711771111111111771117717711771177111771777177717711777111111111
11771111771117717777777111111111177717711777771177777711177777117711177111111111777777117711177117777711771117717711177111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777771177777117711177111111111777777717711177177111771777777111777771111111111177777117711177177777771777777111111111111111111
77111111771117717711177111111111111771117711177177717771771117717711177111111111771117717711177177111111771117711111111111111111
77111111771117711771771111111111111771117711177177777771771117717711111111111111771117717711177177111111771117711111111111111111
77777711771117711177711111111111111771117711177177171771777777111777771111111111771117717711177177777711777777111111111111111111
77111111771117711771771111111111111771117711177177111771771111111111177111111111771117711771771177111111771771111111111111111111
77111111771117717711177111111111111771117711177177111771771111117711177111111111771117711177711177111111771177111111111111111111
77111111177777117711177111111111777711111777771177111771771111111777771111111111177777111117111177777771771117711111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777711771117717777777111111111771111111177711177777771771117711111111177777111177777111777771111111111111111111111111111111111
11771111771117717711111111111111771111111771771111111771771117711111111177117711771117717711111111111111111111111111111111111111
11771111771117717711111111111111771111117711177111117711771117711111111177111771771117717711111111111111111111111111111111111111
11771111777777717777771111111111771111117711177111777111177777711111111177111771771117717711777111111111111111111111111111111111
11771111771117717711111111111111771111117777777117711111111117711111111177111771771117717711177111111111111111111111111111111111
11771111771117717711111111111111771111117711177177111111111117711111111177117711771117717711177111771111111111111111111111111111
11771111771117717777777111111111777777717711177177777771777777111111111177777111177777111777777111771111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11771111771111111111111111111111111111111111111111111111111111117711111111111111771111111111111111111111111111111111111111111111
11771111771111111111111111111111111111111111111111177111111111117711111111111111771111111111111111111111111111111111111111111111
17777711777777111777771111111111177777717711177111111111177777117711771111111111777777111777771117777711771117717777771111111111
11771111771117717711177111111111771117717711177111777111771117717717711111111111771117717711177177111771771117717711177111111111
11771111771117717777777111111111771117717711177111177111771111117777111111111111771117717711111177111771771717717711177111111111
11771111771117717711111111111111177777717711177111177111771117717717711111111111771117717711111177111771777777717711177111111111
11177711771117711777771111111111111117711777777111777711177777117711771111111111777777117711111117777711177177117711177111111111
11111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11777771111111111111111111111111111177111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111177777117711177111111111111777117711177177111771777777111777771111111111177777117711177117777711177777111111111111111111
77777711771117711771771111111111111177117711177177717771771117717711111111111111771117717711177177111771771117711111111111111111
17711111771117711177711111111111111177117711177177777771771117711777771111111111771117711711171177777771771111111111111111111111
17711111771117711771771111111111111177117711177177171771777777111111177111111111771117711771771177111111771111111111111111111111
17711111177777117711177111111111771177111777777177111771771111111777771111111111177777111177711117777711771111111111111111111111
11111111111111111111111111111111177771111111111111111111771111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11771111771111111111111111111111117711111111111111111111111111111111111111111771111111111111111117777111111111111111111111111111
11771111771111111111111111111111117711111111111111111111111111111111111111111771111111111111111177117711111111111111111111111111
17777711777777111777771111111111117711111777771177777771771117711111111117777771177777111777777111117711111111111111111111111111
11771111771117717711177111111111117711111111177111117771771117711111111177111771771117717711177111177111111111111111111111111111
11771111771117717777777111111111117711111777777111777111771117711111111177111771771117717711177111771111111111111111111111111111
11771111771117717711111111111111117711117711177177711111177777711111111177111771771117711777777111111111111111111111111111111111
11177711771117711777771111111111111777111777777177777771111117711111111117777771177777111111177111771111111111111111111111111111
11111111111111111111111111111111111111111111111111111111177777111111111111111111111111111777771111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17777711111771117777771177777711771177117777777117777711777777711777771117777711111111111111111111111111111111111111171111111111
77111771117771111111177111111771771177117711111177111111111117717711177177111771111111111177111111111111177177111111771111111111
77117771111771111111177111111771771177117711111177111111111177117711177177111771111111111177111111111111117771111117711111111111
77171771111771111777771111777711177777717777771177777711111771111777771117777771111111117777771117777711777777711177111111111111
77711771111771117711111111111771111177111111177177111771117711117711177111111771111111111177111111111111117771111771111111111111
77111771111771117711111111111771111177111111177177111771117711117711177111111771111111111177111111111111177177117711111111111111
17777711117777117777777177777711111177117777771117777711117711111777771117777711111111111111111111111111111111117111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777771717171717111117117777711711171111171111111777111171117111717171111777111111711111777771117777711111111111111111111111111
77777771171717117711177177111771117111711177111117711711777177711177711111777111117771117771177177777771111111111111111111111111
77777771717171717777777177111771711171111177777177777171777777711771771117777711177777117711177171777171111111111111111111111111
77777771171717117177717177717771117111711777771177777171777777717771777171777171777777717771177171777171111111111111111111111111
77777771717171717177717117777711711171117777711177777771177777111771771111777111177777111777771177777771111111111111111111111111
77777771171717117771777171111171117111711117711117777711117771111177711111717111171717117111117177111771111111111111111111111111
77777771717171711777771117777711711171111111711111777111111711111717171111717111171777111777771117777711111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11177111177777111117111111111111177777111117111177777771177777111111111171117111177777117777777171717171111111111111111111111111
11177771771117711171711111111111771177711177711117111711777177711717111117171711771717711111111171717171111111111111111111111111
11171111771717711717171111111111771117717777777111717111771117711171111111711171777177717777777171717171111111111111111111111111
11171111771117717177717171717171771177711177711111171111771117711111111111111111771717711111111171717171111111111111111111111111
11171111177777111717171111111111177777111771771111717111177777111111717171117111177777117777777171717171111111111111111111111111
77771111711111711171711111111111711111711711171117111711711111711111171117171711711111711111111171717171111111111111111111111111
77711111177777111117111111111111177777111111111177777771177777111111111111711171177777117777777171717171111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111dd111dd1dd11ddd1ddd1ddd1ddd1ddd111111dd11dd1ddd1ddd1ddd1dd111111ddd11dd111111dd1d111ddd1ddd1ddd11dd1ddd1ddd1dd111dd111111111
1111d111d111d1d11d11d1d1d1d1d1111d111111d111d1d1d1d11d11d111d1d111111d11d1d11111d111d1111d11d1d1d1d1d1d1d1d1d1d1d1d111d111111111
1111d111ddd1d1d11d11ddd1ddd1dd111d111111d111d1d1ddd11d11dd11d1d111111d11d1d11111d111d1111d11ddd1dd11d1d1ddd1dd11d1d111d111111111
1111d11111d1d1d11d11d111d111d1111d111111d111d1d1d1111d11d111d1d111111d11d1d11111d111d1111d11d111d1d1d1d1d1d1d1d1d1d111d111111111
1111dd11dd11d1d1ddd1d111d111ddd11d1111111dd1dd11d111ddd1ddd1ddd111111d11dd1111111dd1ddd1ddd1d111ddd1dd11d1d1d1d1ddd11dd111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
