pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

-- public domain, cc0

poke(0x5f5c, 6, 6) -- note: set auto-repeat delay for btnp

function clone(table)
 local result = {}
 for key, value in pairs(table) do
  result[key] = value
 end
 return result
end

function sortbyy(table)
 for i = 1, #table do
  local j = i
  while j > 1 and table[j - 1].y > table[j].y do
   table[j], table[j - 1] = table[j - 1], table[j]
   j = j - 1
  end
 end
end

function isaabbscolliding(a, b)
 return a.x - a.hw < b.x + b.hw and a.x + a.hw > b.x - b.hw and
        a.y - a.hh < b.y + b.hh and a.y + a.hh > b.y - b.hh
end

function newhero()
 return {
  x = 60,
  y = 116,
  hw = 2,
  hh = 4,
  tick = 0,
  dirx = 0,
  diry = 0,
 }
end

function addparticle(x, y, c)
 add(particles, {
  x = x,
  y = y,
  c = c,
  vx = rnd() - 0.5,
  vy = -(rnd(2) + 1),
 })
end

function addhit(x, y)
 add(hits, {
  x = x,
  y = y,
  counter = 2,
 })
end

function addzombie()
 add(zombies, {
  x = rnd() < 0.5 and -8 or 128,
  y = 16 + rnd() * 32,
  hw = 2,
  hh = 4,
  dx = (rnd() - 0.5) * 0.1,
 })
end

function gameinit()
 reload()

 _update = gameupdate
 _draw = gamedraw

 hero = newhero()

 bullets = {}
 zombies = {}
 particles = {}
 hits = {}

 for i = 0, 30 do
  addzombie()
  local z = zombies[i + 1]
  z.x = i * 4
  z.y = 12 + rnd(16)
 end

 walls = {}
 for i = 0, 15 do
  add(walls, {
   x = i * 8,
   y = 8,
   hw = 4,
   hh = 4,
   hp = 30,
  })
 end

 zombiets = t()
end

function gameupdate()

 hero.tick += 1

 if hero.dead then
  addparticle(hero.x + 2, hero.y + 6, 8)
  addparticle(hero.x + 3, hero.y + 6, 8)
  hero.dirx = 0
  hero.diry = 0

  if btnp(5) then
   gameinit()
   return
  end

 else
  local heronext = clone(hero)

  -- player input
  if btn(0) then
   heronext.x -= 2
  end
  if btn(1) then
   heronext.x += 2
  end

  if btn(2) then
   heronext.y -= 2
  end
  if btn(3) then
   heronext.y += 2
  end

  heronext.x = mid(0, heronext.x, 120)

  for w in all(walls) do
   if isaabbscolliding(heronext, w) and w.removeme == nil then
    heronext.x = hero.x
   end
  end

  heronext.y = mid(0, heronext.y, 120)

  for w in all(walls) do
   if isaabbscolliding(heronext, w) and w.removeme == nil then
    heronext.y = hero.y
   end
  end

  hero.dirx = 0
  if hero.x != heronext.x then
   hero.dirx = heronext.x - hero.x
  end

  hero.diry = 0
  if hero.y != heronext.y then
   hero.diry = heronext.y - hero.y
  end

  hero.x = heronext.x
  hero.y = heronext.y

  if btnp(4) then
   add(bullets, {
    x = hero.x + 3,
    y = hero.y,
    hw = 2,
    hh = 2,
   })
  end
 end

 if hero.y < 4 then
  if time() - transitionts > 2 then
   bossinit()
  end
  return
 end

 transitionts = time()

 -- hero collisions
 for z in all(zombies) do
  if isaabbscolliding(hero, z) and z.removeme == nil then
   hero.dead = true
  end
 end

 -- update bullets
 for b in all(bullets) do
  b.y -= 3

  if b.y < -8 then
   del(bullets, b)
  end
 end

 -- update zombies
 for z in all(zombies) do
  local a = atan2(hero.x - z.x, hero.y - z.y)
  z.x += cos(a) * 0.25
  z.y += sin(a) * 0.2
 end

 -- add zombies
 local currenttime = time()
 if currenttime - zombiets > 0.25 and #zombies < 60 then
  zombiets = currenttime
  addzombie()
 end

 -- bullet collisions
 for b in all(bullets) do
  for z in all(zombies) do
   if isaabbscolliding(b, z) and z.removeme == nil and b.removeme == nil then
    b.removeme = true
    del(bullets, b)

    sset(96 + flr((z.x + 4) / 4), 16 + flr(z.y) - 8, 2)

    addhit(b.x, b.y)

    for i = 0, 20 + flr(rnd(5)) do
     addparticle(z.x + 4 + rnd(2) - 1, z.y + 5, 2)
    end
    z.removeme = true
    del(zombies, z)
   end
  end

  for w in all(walls) do
   if isaabbscolliding(b, w) and w.removeme == nil and b.removeme == nil then
    b.removeme = true
    del(bullets, b)

    for i = 0, 3 + flr(rnd(4)) do
     addparticle(w.x + rnd(2) - 1, w.y + 5, 9)
    end

    addhit(b.x, b.y)

    w.hp -= 1
    if w.hp <= 0 then
     w.removeme = true
     del(walls, w)
    end
   end
  end
 end

 -- update particles
 for p in all(particles) do
  p.x += p.vx
  p.vy += 0.5
  p.y += p.vy
  if p.vy > 2.5 then
   del(particles, p)
  end
 end

 -- update hits
 for h in all(hits) do
  h.counter -= 1
  if h.counter <= 0 then
   del(hits, h)
  end
 end

end

function gamedraw()
 cls(0)
 sspr(96,16,32,112,0,16,128,112)

 -- draw wall
 for w in all(walls) do
  spr(flr(w.hp / 2), w.x, w.y)
 end

 -- draw zombies
 sortbyy(zombies)
 for z in all(zombies) do
  spr(24 + (hero.tick / 4) % 2, z.x, z.y, 1, 1, sgn(hero.x - z.x) < 0)
 end

 -- draw bullets
 for b in all(bullets) do
  spr(22, b.x + 1, b.y)
 end

 -- draw hero
 local frameoffset = 0
 if hero.dirx < 0 then
  frameoffset = 3 + (hero.tick / 4) % 2
 elseif hero.dirx > 0 or hero.diry != 0 then
  frameoffset = 1 + (hero.tick / 4) % 2
 end

 local herodx = 0
 if hero.dead then
  frameoffset = 5
  if hero.tick % 2 == 0 then
   herodx = rnd(2) - 1
  end
 end
 spr(16 + frameoffset, hero.x + herodx, hero.y + herodx)

 -- draw particles
 for p in all(particles) do
  pset(p.x, p.y, p.c)
 end

 -- draw hits
 for h in all(hits) do
  circfill(h.x, h.y, 2 + rnd(2), 7)
 end

 -- draw game over message
 if hero.dead then
  print('de mumsar upp dig\n     tryck x', 29, 2, 10)
 end
end



function bossinit()
 reload()

 _update = bossupdate
 _draw = bossdraw
 
 hero = newhero()
 boss = {
  x = 56,
  y = 4,
  hw = 8,
  hh = 8,
  state = 'fart',
  statec = 0,
  hp = 40,
 }

 bullets = {}
 farts = {}
 zombies = {}
 particles = {}
 hits = {}

 for i = 0, 10 do
  addzombie()
  local z = zombies[i + 1]
  z.x = rnd(128)
  z.y = 28 + rnd(8)
 end

 zombiets = t()
end

function bossupdate()

 hero.tick += 1

 if boss.hp <= 0 then
  zombies = {}
  boss.state = 'hurt'
  boss.statec = 10

  for i = 0, 20 + flr(rnd(5)) do
   addparticle(boss.x + 4 + rnd(2) - 1, boss.y + 12, 8)
  end

  if btnp(5) then
   endinit()
   return
  end
 end

 if hero.tick < 60 then
  return
 end

 if hero.dead then

  hero.dirx = 0
  hero.diry = 0

  if hero.dead == 'zombie' then
   addparticle(hero.x + 2, hero.y + 6, 8)
   addparticle(hero.x + 3, hero.y + 6, 8)
  elseif hero.dead == 'fart' then
   addparticle(hero.x + 3, hero.y + 6, 10)
   addparticle(hero.x + 2, hero.y + 6, 15)
  end

  if btnp(5) then
   gameinit()
   return
  end

 else
  local heronext = clone(hero)

  -- player input
  if btn(0) then
   heronext.x -= 2
  end
  if btn(1) then
   heronext.x += 2
  end

  if btn(2) then
   heronext.y -= 2
  end
  if btn(3) then
   heronext.y += 2
  end

  heronext.x = mid(0, heronext.x, 120)
  heronext.y = mid(28, heronext.y, 120)

  hero.dirx = 0
  if hero.x != heronext.x then
   hero.dirx = heronext.x - hero.x
  end

  hero.diry = 0
  if hero.y != heronext.y then
   hero.diry = heronext.y - hero.y
  end

  hero.x = heronext.x
  hero.y = heronext.y

  if btnp(4) then
   add(bullets, {
    x = hero.x + 3,
    y = hero.y,
    hw = 2,
    hh = 2,
   })
  end
 end

 transitionts = time()

 -- hero collisions
 for z in all(zombies) do
  if isaabbscolliding(hero, z) and z.removeme == nil then
   hero.dead = 'zombie'
  end
 end

 for f in all(farts) do
  if isaabbscolliding(hero, f) and f.removeme == nil then
   hero.dead = 'fart'
  end
 end

 -- update bullets
 for b in all(bullets) do
  b.y -= 3

  if b.y < -8 then
   del(bullets, b)
  end
 end

 -- update zombies
 if hero.dead != 'fart' then
  for z in all(zombies) do
   local a = atan2(hero.x - z.x, hero.y - z.y)
   z.x += cos(a) * 0.6
   z.y += sin(a) * 0.7
  end
 end

 -- add zombies
 local currenttime = time()
 if currenttime - zombiets > 0.25 and #zombies < 12 and boss.hp > 0 then
  zombiets = currenttime
  addzombie()
 end

 -- update boss
 if boss.statec <= 0 then
  if boss.state == 'moveright' or boss.state == 'moveleft' or boss.state == 'hurt' then
   boss.state = 'fart'
   boss.statec = 60

  elseif boss.state == 'fart' then
   local possiblestates = {}
   if boss.x > 20 then
    add(possiblestates, 'moveleft')
   end
   if boss.x < 108 - 16 then
    add(possiblestates, 'moveright')
   end
   boss.state = rnd(possiblestates)
   boss.statec = 90
  end
 end

 boss.statec -= 1

 if boss.state == 'hurt' then
  -- pass

 elseif boss.state == 'moveright' then
  if boss.statec <= 30 then
   boss.x += boss.statec / 30
  end

 elseif boss.state == 'moveleft' then
  if boss.statec <= 30 then
   boss.x -= boss.statec / 30
  end

 elseif boss.state == 'fart' then
  if boss.statec <= 0 then
   if rnd() > 0.5 then
    add(farts, {
     x = boss.x + 4,
     y = boss.y + 12,
     hw = 3,
     hh = 3,
     dy = 2,
     dx = 0,
    })
   else
    add(farts, {
     x = boss.x + 4,
     y = boss.y + 12,
     hw = 3,
     hh = 3,
     dy = 1.5,
     dx = 1.5,
    })
    add(farts, {
     x = boss.x + 4,
     y = boss.y + 12,
     hw = 3,
     hh = 3,
     dy = 1.5,
     dx = -1.5,
    })
   end
  end
 end

 -- update farts
 for f in all(farts) do
  f.x += f.dx
  f.y += f.dy

  if f.y > 136 then
   del(farts, f)
  end
 end

 -- bullet collisions
 for b in all(bullets) do
  if isaabbscolliding(b, boss) and b.removeme == nil then
   b.removeme = true
   del(bullets, b)

   boss.hp -= 1

   if boss.state != 'fart' then
    boss.state = 'hurt'
    boss.statec = 12
   end

   addhit(b.x, b.y)

   for i = 0, 20 + flr(rnd(5)) do
    addparticle(b.x + 4 + rnd(2) - 1, b.y + 5, 8)
   end
  end

  for z in all(zombies) do
   if isaabbscolliding(b, z) and z.removeme == nil and b.removeme == nil then
    b.removeme = true
    del(bullets, b)

    sset(96 + flr((z.x + 4) / 4), 16 + flr(z.y) - 8, 2)

    addhit(b.x, b.y)

    for i = 0, 20 + flr(rnd(5)) do
     addparticle(z.x + 4 + rnd(2) - 1, z.y + 5, 2)
    end
    z.removeme = true
    del(zombies, z)
   end
  end
 end

 -- update particles
 for p in all(particles) do
  p.x += p.vx
  p.vy += 0.5
  p.y += p.vy
  if p.vy > 2.5 then
   del(particles, p)
  end
 end

 -- update hits
 for h in all(hits) do
  h.counter -= 1
  if h.counter <= 0 then
   del(hits, h)
  end
 end

end

function bossdraw()
 cls(0)
 sspr(96,16,32,112,0,16,128,112)

 -- draw stage
 rectfill(0,0,128,28,1)
 rectfill(0,0,128,24,5)

 -- draw boss
 if boss.state == 'moveright' then
  if boss.statec > 30 and boss.statec < 60 then
   sspr(32,16,16,16,boss.x - 4,boss.y)
  else
   sspr(0,16,16,16,boss.x - 4,boss.y)
  end

 elseif boss.state == 'moveleft' then
  if boss.statec > 30 and boss.statec < 60 then
   sspr(16,16,16,16,boss.x - 4,boss.y)
  else
   sspr(0,16,16,16,boss.x - 4,boss.y)
  end

 elseif boss.state == 'fart' then
  sspr(48 + flr((hero.tick / 2) % 2) * 16,16,16,16,boss.x - 4,boss.y)

 elseif boss.state == 'hurt' then
  sspr(80,16,16,16,boss.x - 4,boss.y)
 end

 -- draw zombies
 sortbyy(zombies)
 for z in all(zombies) do
  spr(27 + (hero.tick / 4) % 2, z.x, z.y, 1, 1, sgn(hero.x - z.x) < 0)
 end

 -- draw bullets
 for b in all(bullets) do
  spr(22, b.x + 1, b.y)
 end

 -- draw hero
 local frameoffset = 0
 if hero.dirx < 0 then
  frameoffset = 3 + (hero.tick / 4) % 2
 elseif hero.dirx > 0 or hero.diry != 0 then
  frameoffset = 1 + (hero.tick / 4) % 2
 end

 local herodx = 0
 if hero.dead then
  frameoffset = 5
  if hero.tick % 2 == 0 then
   herodx = rnd(2) - 1
  end
 end
 spr(16 + frameoffset, hero.x + herodx, hero.y + herodx)

 -- draw farts
 for f in all(farts) do
  spr(29, f.x, f.y, 1, 1, hero.tick % 2 == 0, hero.tick % 2 == 1)
 end

 -- draw particles
 for p in all(particles) do
  pset(p.x, p.y, p.c)
 end

 -- draw hits
 for h in all(hits) do
  circfill(h.x, h.y, 2 + rnd(2), 7)
 end

 -- draw game end message
 if hero.dead == 'zombie' then
  print('de mumsar upp dig\n     tryck x', 29, 2, 10)
 elseif hero.dead == 'fart' then
  print('du fick en fis i fejset och spyr\n         tryck x', 1, 2, 10)
 elseif boss.hp <= 0 then
  print('du vann!\ntryck x', 1, 2, 10)
 end

 -- draw boss taunt
 if hero.tick < 60 then
  rectfill(4, 2, 50, 16, 7)
  spr(30, 51, 6)
  print('ching chong\nchang!', 6, 4, 1)

 else
  -- draw boss hp
  rectfill(4, 0, 124 * (boss.hp / 40), 1, 8)
 end

end


function splashinit()
 _update = splashupdate
 _draw = splashdraw
 splashts = time()
end

function splashupdate()
 if btnp(5) then
  gameinit()
 end
end

function splashdraw()
 cls(2)
 sspr(0,32,37,33,42,26)

 print('styr med pilarna\n   skjut med c', 30, 90, 4)

 if (time() * 2) % 2 > 1 then
  print('starta spelet - tryck x', 19, 120, 9)
 end
end

function endinit()
 _update = endupdate
 _draw = enddraw
end

function endupdate()
 if btnp(5) then
  splashinit()
 end
end

function enddraw()
 cls(12)

 rectfill(0,90,128,128,3)

 circfill(100,24,7,10)

 spr(160,60,93)

 rectfill(26,72,88,83,7)
 spr(31,60,84)

 sspr(0,72,55,8,30,74)

end

_init = splashinit


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000004400000044000004440000044400042444004424442444244
00000000000000000000000000000000000000000000002200000022000000220000002220000022220000222200022222002222220022222202222222222222
00000000000000000000000000000000000000000000004200000042400000424000044244400442444004424440444244424442444244424442444244424442
00000000000000000000000000000000000000220200002222000222222002222220222222202222222022222222222222222222222222222222222222222222
00000000000000000000004400000044420000444200024442400244424402444244424442444244424442444244424442444244424442444244424442444244
00000000020000002200022222200222222002222220022222222222222222222222222222222222222222222222222222222222222222222222222222222222
00000002044000424400044244424442444244424442444244424442444244424442444244424442444244424442444244424442444244424442444244424442
02222022022220222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
00005500000055000000550000005500000055000000000077000000000000000000000000000000000000000000000000000000000000007000000000000777
000ff500000ff500000ff500000ff500000ff500f00ff00077000000000dd000000dd000000dd000000660000006600000066000000444007700000000000770
000ff500000ff500000ff500000ff500000ff500e00ff00f77000000000dd000000dd000000dd000000660000006600000066000004444407770000000000700
00eeeef0000eeef0000eeef0000eeef0000eeef00eeeeee0000000000ddddd0000ddddd000ddddd0066666000066666000666660044444400000000000000000
00eeeee0000eeee0000eeee0000eeee0000eeee0000eee000000000000dddd0000dddd0000dddd00006666000066660000666600044444440000000000000000
00eeee00000eee00000eee00000eee00000eee00000eee000000000000dddd0000dddd0000dddd00006666000066660000666600044444440000000000000000
00dddd0000ddddd0000ddd0000ddddd0000ddd00000ddd000000000000555500005555000055550000dddd0000dddd0000dddd00004444400000000000000000
00d00d00000000d00000dd0000d00000000dd0000ddd00d00000000000500500005000000000050000d00d0000d0000000000d00000444000000000000000000
000000000000000000000000000000000000000000000000000000bebe000e0e000000caca000a0a000000000000000000000000000000000000000000000000
0000000ff00000000000000ff00000000000000ff0000000000000eeee000eee000000aaaa000aaa00f0f000ff00000000000000000000000000000000000000
000000ffff000000000000ffff000000000000ffff0000000eee00888e00eeee0aaa00eeea00aaaa0fff000ffff00f0f00000000000000000000000000000000
000000bfbf000000000000bfbf000000000000fbfb000000eeee00888ee00eeeaaaa00eeeaa00aaafffff00bfbf000ff00000000000000000000000000000000
000000ffff000000000000ffff000000000000ffff000000eee0ee888eeeeeeeaaa0aaeeeaaaaaaafff0000ffff00fff00000000000000000000000000000000
00ffffffffffff0000ffffffffffff0000ffffffffffff00eeeeeeeeeeeeeee0aaaaaaaaaaaaaaa0ffff00feeef000ff00000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffff0eeeeeeeeeeeee000aaaaaaaaaaaaa000ffffffeeefffff000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffff000eeeeeeeeeee00000aaaaaaaaaaa00000fffffffffff0000000000000000000000000000000000
0ff6ffffffff6ff00006ffffffff60000006ffffffff60000006eeeeeeee6000000faaaaaaaaf0000006ffffffff600000000000000000000000000000000000
0006666666666000000666666666600000066666666660000006666666666000000ffffffffff000000666666666600000000000000000000000000000000000
0fff66666666fff00fff66666666fff00fff66666666fff00eee66666666eee00aaaffffffffaaa00fff66666666fff000000000000000000000000000000000
fffffff66ffffffffffffff66ffffffffffffff66fffffffeeeeeee66eeeeeeeaaaaaaaffaaaaaaafffffff66fffffff00000000000000000000000000000000
fffffff66ffffffffffffff66ffffffffffffff66fffffffeeeeeee66eeeeeeeaaaaaaaffaaaaaaafffffff66fffffff00000000000000000000000000000000
fffff000000fffff0fffff00000ffffffffff00000fffff0eeeee000000eeeeeaaaaa000000aaaaa0fffff00000fffff00000000000000000000000000000000
00ffff0000ffff00ffffff0000ffff0000ffff0000ffffff00eeee0000eeee0000aaaa0000aaaa00ffffff0000ffff0000000000000000000000000000000000
ffffff0000ffffff0000000000ffffffffffff0000000000eeeeee0000eeeeeeaaaaaa0000aaaaaa0000000000ffffff00000000000000000000000000000000
000000000000a00000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaa00aa00aa0aaaa0aa00aa00aaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaa0aa00aa0aaaa0aa00aa0aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa11110aa00aa01aa10aaa0aa0aa1111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa00000aaaaaa00aa00aaa0aa0aa0aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa00000aaaaaa00aa00aaaaaa0aa0aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa00000aa11aa00aa00aaaaaa0aa01aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaa0aa00aa0aaaa0aa1aaa0aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1aaaa10aa00aa0aaaa0aa01aa01aaaa1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111100a10011011110a100110011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000009000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900990099009999009900990099990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990990099099999909900990999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09911110990099099119909990990991111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09900000999999099009909990990990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09900000999999099009909999990990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09900000991199099009909999990990199000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990990099099999909919990999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01999910990099019999109901990199991000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100910011001111009100110011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000080000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888008800880088880088008800888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088888808800880888888088008808888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088111108800880881188088808808811110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000008888880880088088808808808880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000008888880888888088888808808880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000008811880881188088888808801880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088888808800880880088088188808888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00018888108800880180088088018801888810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111008100110010081081001100111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001000000000010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101100000011101100110011101100000010101110111010001100000000000000000000000000000000000000000000000000000000000000000000000000
10001010000010101010101010101010000010101010101010001010000000000000000000000000000000000000000000000000000000000000000000000000
11001010000011101010101011101010000010101110110010001010000000000000000000000000000000000000000000000000000000000000000000000000
10001010000010101010101010101010000011101010101010001010000000000000000000000000000000000000000000000000000000000000000000000000
11101010000010101010101010101010000001001010101011101110000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeef50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddd050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
