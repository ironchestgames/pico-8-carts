pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--[[
color positions
hero armor:
1 - head
2 - arms
3 - torso
4 - shoes

hero cape:
1 - head
2 - cape
3 - under garment

items:
1 - sword blade,
				spear tip,
				staff orb,
				bow,
				shield
2 - sword handle,
				spear,
				staff
				arrow,
				
item types:
- helmet
- armor/cape
- shoes
- sword
- shield
- spear
- bow
- staff
- ring
- amulet
--]]
a='5555'

hero={}
hero.x=10
hero.y=10
hero.spd=0.5

function _update60()
	if btn(0) then
		hero.x-=hero.spd
	elseif btn(1) then
		hero.x+=hero.spd
	end
	
	if btn(2) then
		hero.y-=hero.spd
	elseif btn(3) then
		hero.y+=hero.spd
	end
end

function _draw()
	cls(0)
	
	-- head
	pset(hero.x,hero.y-3,sub(a,1,1))
	
	-- arms
	pset(hero.x-1,hero.y-2,sub(a,2,2))
	pset(hero.x+1,hero.y-2,sub(a,2,2))
	
	-- torso
	pset(hero.x,hero.y-2,sub(a,3,3))
	pset(hero.x,hero.y-1,sub(a,3,3))
	
	-- legs
	pset(hero.x-1,hero.y,sub(a,4,4))
	pset(hero.x+1,hero.y,sub(a,4,4))
end
