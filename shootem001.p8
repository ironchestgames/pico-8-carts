pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- utils
function norm(n)
	if n==0 then
		return 0
	elseif n>0 then
		return 1
	else return -1
	end
end

-->8
-- particles
--[[
	p.x - starting position x
	p.y - starting position y
	p.spdx - speed in x axis
	p.spdy - speed in y axis
	p.colors - colors of lifespan
	p.life - lifetime in updates
--]]

function initp(ps,p)
	p._l=p.life
	add(ps,p)
end

function updateps(ps)
	for p in all(ps) do
		p.x+=p.spdx
		p.y+=p.spdy
		p._l-=1
		p._c=p.colors[flr(#p.colors*((p.life-p._l)/p.life))+1]
		if p._l<0 then
			del(ps,p)
		end
	end
	return ps
end
-->8
ship={}
ship.x=64
ship.y=100
ship.spd=1
ship.bulletcolor={7,7,7,1}
ship.firespd=10
ship.firetim=0

bullets={}

function shoot(x,y,spdx,spdy,s,f)
	bullet={}
	bullet.x=x
	bullet.y=y
	bullet.spdx=spdx
	bullet.spdy=spdy
	bullet.s=s -- sprite
	bullet.flipped=f or false
	add(bullets,bullet)
end

stars={}
for i=1,100 do
	star={}
	star.x=flr(rnd()*128)
	star.y=flr(rnd()*128)
	star.spd=rnd()*2+0.5
	add(stars,star)
end

ps={}
function newexhaustp(x,y)
	p={}
	p.x=x
	p.y=y
	p.spdx=(rnd()-0.5)*0.01
	p.spdy=0.1+rnd()-0.1
	p.colors={6,12,1}
	p.life=rnd()*2+2
	initp(ps,p)
end

function newbulletp(x,y)
	p={}
	p.x=x
	p.y=y
	p.spdx=0
	p.spdy=rnd()*-0.1
	p.colors={9,4}
	p.life=rnd()*4+4
	initp(ps,p)
end

exhaust=true -- for anim

t=0
function _update60()
	t+=1
	
	-- ship moving
	newx=ship.x
	newy=ship.y
	
	if btn(0) then
		newx+=-ship.spd
	end
	if btn(1) then
		newx+=ship.spd
	end
	if btn(2) then
		newy+=-ship.spd
	end
	if btn(3) then
		newy+=ship.spd
	end
	
	ship.x=newx
	ship.y=newy
	
	-- ship fire
	ship.justfired=false
	if btn(4) then
		ship.firetim-=1
		if ship.firetim<=0 then
 		shoot(ship.x,ship.y+2,0,-2,2)
 		shoot(ship.x+7,ship.y+2,0,-2,2)
 		ship.firetim=ship.firespd
 		ship.justfired=true
 	end
 else
  ship.firetim=0
	end
	
	-- bullets
	for b in all(bullets) do
		b.x+=b.spdx
		b.y+=b.spdy
		newbulletp(b.x,b.y+4)
		if b.x<0 or	b.x>128 or
				b.y<0 or b.y>128 then
			del(bullets,b)
		end
	end
	
	-- stars
	for star in all(stars) do
		star.y+=star.spd
		if star.y>130 then
			star.y=-3
			star.x=flr(rnd()*128)
		end
	end
	
	-- particles
	newexhaustp(ship.x+4,ship.y+8)
	newexhaustp(ship.x+4,ship.y+8)

	updateps(ps)
end

function _draw()
	pal()
	cls(0)
	
	-- stars
	for star in all(stars) do
		if star.spd<=1 then
			pset(star.x,star.y,1)
		end
	end
	
	-- particles
	for p in all(ps) do
		pset(p.x,p.y,p._c)
	end
	
	-- ship
	if ship.justfired==true then
		spr(1,ship.x,ship.y)
	else
		spr(0,ship.x,ship.y)
	end
	
	-- bullets
	for b in all(bullets) do
		spr(b.s,b.x-3,b.y)
	end
end
__gfx__
00077000000770000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc000000770000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006cc600007777000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006cc600007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70677607707777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76677667777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76677667777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
