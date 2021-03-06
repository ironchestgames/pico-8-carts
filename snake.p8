pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- happy apple worm
-- by ironchest games

-- utils and globals

version='1.0.0-1'
t=0 -- frame counter
chgscene=nil
right=0
down=1
left=2
up=3


printh('debug - started','debug',true)
debug=function(s1,s2,s3,s4)
	s1=tostr(s1)
	s2=tostr(s2)
	s3=tostr(s3)
	s4=tostr(s4)
	printh(s1..', '..
								s2..', '..
								s3..', '..s4,
			'debug',false)
end

clamp=function(n,mi,ma)
	return min(max(n,mi),ma)
end

trunct=function(t,maxlen)
	newt={}
	for i=1,min(#t,maxlen) do
		newt[i]=t[i]
	end
	return newt
end

shift=function(t)
	first=t[1]
	del(t,first)
	return first,t
end

unshift=function(t,e)
	newt={e}
	for v in all(t) do
		add(newt,v)
	end
	return newt
end

contains=function(t,v)
	for e in all(t) do
		if e==v then
			return true
		end
	end
	return false
end

uniq=function(t)
	newt={}
	for e in all(t) do
		if not contains(newt,e) then
			add(newt,e)
		end
	end
	return newt
end

-->8
-- apple, poop, beetles

-- apple
apples={}

apple={
	norm=1,
	fast=2,
	slow=3,
}

apple.new=function(typ)
	a={}
	a.x,a.y=getemptypos()
	a.rotten=false
	a.rottime=150
	a.typ=typ or apple.norm
	add(apples,a)
	return a
end

apple.hastyp=function(typ)
	for a in all(apples) do
		if a.typ==typ then
			return true
			end
	end
	return false
end

apple.nearany=function(x,y)
	for a in all(apples) do
		if abs(a.x-x)<=1 and
					abs(a.y-y)<=1 then
			return true
		end
	end
	return false
end

-- poop
poops={}

poop={}

poop.new=function(x,y)
	p={}
	p.x=x
	p.y=y
	p.active=true
	add(poops,p)
	return p
end

-- get random poop
poop.getrnd=function()
	return poops[flr(rnd(#poops-1))+1]
end

poop.getpoop=function(x,y)
	for p in all(poops) do
		if p.x==x and p.y==y then
			return p
		end
	end
	return nil
end

poop.remove=function(p)
	p.active=false
	del(poops,p)
end

-- get closest poop in column
poop.getincol=function(c)
	closest=nil
	dist=17
	for p in all(poop) do
		newdist=abs(c-p.x)
		if newdist<dist then
			closest=p
			dist=newdist
		end
	end
	return closest
end

-- get closest poop in row
poop.getinrow=function(r)
	closest=nil
	dist=17
	for p in all(poop) do
		newdist=abs(r-p.y)
		if newdist<dist then
			closest=p
			dist=newdist
		end
	end
	return closest
end

-- beetle
beetles={}

beetle={}

beetle.new=function(p)
	b={}
	b.scorefactor=1
	b.movespd=10
	b.movetime=b.movespd
	b.p=p

	i=0
	repeat
		b.d=flr(rnd(3))
		if b.d==right then
			b.x=0
			b.y=p.y
		elseif b.d==left then
			b.x=15
			b.y=p.y
		elseif b.d==down then
			b.x=p.x
			b.y=0
		elseif b.d==up then
			b.x=p.x
			b.y=15
		end
		i+=1
	until i==4 or isposempty(b.x,b.y)

	if isposempty(b.x,b.y) then
		add(beetles,b)
	end
end

-->8
-- game scene

-- helpers
isposempty=function(x,y)
	-- nothing below gui
	if y==0 and (
				x==0 or
				x==1 or
				x==2) then
		return false
	end
	for s in all(snake) do
		if s[1]==x and s[2]==y then
			return false
		end
	end
	for a in all(apples) do
		if a.x==x and a.y==y then
			return false
		end
	end
	for p in all(poops) do
		if p.x==x and p.y==y then
			return false
		end
	end
	return true
end

getemptypos=function()
	repeat
		x=flr(rnd()*16)
		y=flr(rnd()*16)
	until isposempty(x,y)
	return x,y
end

isnextto=function(x1,y1,x2,y2)
	if (x1==x2 and
				abs(y2-y1)<=1) or
				(y1==y2 and
				abs(x2-x1)<=1) then
		return true
	end
	return false
end

isoutside=function(x,y)
	return x<0 or
			x>15 or
			y<0 or
			y>15
end

-- snake
snaketimemax=15
snaketimemin=1
snaketime=10
snakecount=0
snakegrow=0
snakedir=down
snake={}

-- score
score=0
bestscore=0

-- messages
msgs={}
msg={}

msg.new=function(
			x,y,s,tim,move,blink)
	m={}
	m.x=x
	m.y=y
	m.s=s
	m.tim=tim
	m.move=move
	m.blink=blink
	add(msgs,m)
end

msg.newfaster=function(x,y)
	msg.new(x,y,54,40,true,true)
end

msg.newslower=function(x,y)
	msg.new(x,y,53,40,true,true)
end

msg.newscore=function(x,y,s)
	msg.new(x,y,tostr(s),22,true,false)
end

-- input
inputq={}

addinp=function(i)
	if #inputq>0 then
		last=inputq[#inputq]
		if
				(i==left and last!=right) or
				(i==right and last!=left) or
				(i==up and last!=down) or
				(i==down and last!=up) then
			add(inputq,i)
		end
	elseif
			(i==left and snakedir!=right) or
			(i==right and snakedir!=left) or
			(i==up and snakedir!=down) or
			(i==down and snakedir!=up) then
		add(inputq,i)
	end
end

-- init

gameinit=function()
	msgs={}

	snakecount=0
	snaketime=10
	snakegrow=1
	snakedir=down
	snake={
		{8,5},
		{8,4},
		{8,3},
	}

	score=0

	apples={}
	apple.new()
	apple.new(apple.fast)
	apple.new(apple.slow)

	poops={}

	beetles={}
end

gameupdate=function()
	
	if btnp(0) then
		addinp(left)
	elseif btnp(1) then
		addinp(right)
	elseif btnp(2) then
		addinp(up)
	elseif btnp(3) then
		addinp(down)
	end

	-- update snake time
	snakecount+=1
	
	-- update snake pos
	if snakecount>=snaketime then

		snakecount=0
	
		-- curate input queue
		inputq=uniq(inputq)
		inputq=trunct(inputq,2)
	
		if #inputq>0 then
			snakedir=shift(inputq)
		end
		
		-- calc new pos
		newx=snake[1][1]
		newy=snake[1][2]
		if snakedir==left then
			newx+=-1
		elseif snakedir==right then
			newx+=1
		elseif snakedir==up then
			newy+=-1
		elseif snakedir==down then
			newy+=1
		end
		
		-- grow snake
		if snakegrow>0 then
			snake=unshift(snake,{
				newx,
				newy,
			})
			snakegrow-=1
		-- ...or move it
		else
			for i=#snake,2,-1 do
				before=snake[i-1]
				cur=snake[i]
				cur[1]=before[1]
				cur[2]=before[2]
			end
			snake[1][1]=newx
			snake[1][2]=newy
		end
		
		-- game over check
		snake1x=snake[1][1]
		snake1y=snake[1][2]
		for i=2,#snake do
			s=snake[i]
			if snake1x==s[1] and
						snake1y==s[2] then
				deathreason='snake'
				chgscene('gameover')
			end
		end
		for p in all(poops) do
			if snake1x==p.x and
						snake1y==p.y then
				deathreason='poop'
				chgscene('gameover')
			end
		end
		for b in all(beetles) do
			if snake1x==b.x and
						snake1y==b.y then
				deathreason='beetle'
				chgscene('gameover')
			end
		end
		if snake1x<0 or snake1x>15 or
					snake1y<0 or snake1y>15 then
			deathreason='border'
				chgscene('gameover')
		end
	end

	-- update beetles
	if #poops>=1 and #beetles==0 then
		beetle.new(poop.getrnd())
		sfx(5,2)
	end

	for b in all(beetles) do
		if isoutside(b.x,b.y) then
			del(beetles,b)
			sfx(-2,2)
		elseif b.movetime<=0 then

			nextx=b.x
			nexty=b.y
			if b.d==right then
				nextx+=1
			elseif b.d==left then
				nextx-=1
			elseif b.d==down then
				nexty+=1
			elseif b.d==up then
				nexty-=1
			end

			p=poop.getpoop(nextx,nexty)
			if isposempty(nextx,nexty) then
				b.x=nextx
				b.y=nexty
			elseif p!=nil then
				poop.remove(p)
				_score=100*b.scorefactor
				score+=_score
				b.scorefactor+=1
				msg.newscore(p.x*8,p.y*8,_score..'')
			else
				b.d+=1 -- rotate direction
				if b.d>3 then
					b.d=0
				end
			end
			b.movetime=b.movespd
		else
			b.movetime-=1
		end
	end
	
	-- update apple
	for a in all(apples) do
	
		-- get eaten
		if a.x==snake[1][1] and
					a.y==snake[1][2] then
			del(apples,a)
			if a.typ==apple.norm then
				_score=200
				last=snake[#snake]
				if a.rotten==true then
						poop.new(last[1],last[2])
						sfx(3,1)
				else
					msg.newscore(a.x*8,a.y*8,'yum!')
					sfx(4,1)
				end
				apple.new(apple.norm)
			elseif a.typ==apple.fast then
				if snaketime>snaketimemin then
					snaketime-=1
					msg.newfaster(a.x*8,a.y*8)
				end
				sfx(2,1)
				_score=50
			elseif a.typ==apple.slow then
				if snaketime<snaketimemax then
					snaketime+=1
					msg.newslower(a.x*8,a.y*8)
				end
				sfx(1,1)
				_score=50
			end
			snakegrow+=1
			score+=_score
		end

		-- add new faster/slower
		if apple.hastyp(apple.slow)==false and
				 snaketime<snaketimemax then
			apple.new(apple.slow)
		end

		if apple.hastyp(apple.fast)==false and
				 snaketime>snaketimemin then
			apple.new(apple.fast)
		end
		
		-- go rotten
		if a.typ==apple.norm and
				a.rotten==false then
			a.rottime-=1
			if a.rottime<=0 then
				a.rotten=true
			end
		end

	end
	
	-- update messages
	for m in all(msgs) do
		m.tim-=1
		if m.tim<=0 then
			del(msgs,m)
		end
		if m.move==true then
			m.y-=0.5
		end
	end
end

gamedraw=function()
	-- reset
	cls(15)
	
	-- draw poop
	for p in all(poops) do
		spr(52,p.x*8,p.y*8)
	end

	-- draw snake body
	for i=2,#snake-1 do
		s=snake[i]
		sx=s[1]
		sy=s[2]
	
		bx=snake[i-1][1]
		by=snake[i-1][2]
		ax=snake[i+1][1]
		ay=snake[i+1][2]
		sp=27
		
		-- w->e
		if bx>sx and sx>ax then
			sp=17
		-- e->w
		elseif ax>sx and sx>bx then
			sp=16
		-- n->s
		elseif by>sy and sy>ay then
			sp=33
		-- s->n
		elseif ay>sy and sy>by then
			sp=32
		-- s->w
		elseif ay>sy and sx>bx then
			sp=21
		-- w->s
		elseif ax<sx and sy<by then
			sp=19
		-- n->w
		elseif ay<sy and sx>bx then
			sp=35
		-- w->n
		elseif ax<sx and sy>by then
			sp=37
		-- n->e
		elseif ay<sy and sx<bx then
			sp=36
		-- e->n
		elseif ax>sx and sy>by then
			sp=34
		-- s->e
		elseif ay>sy and sx<bx then
			sp=18
		-- e->s
		elseif ax>sx and sy<by then
			sp=20
		end
		spr(sp,sx*8,sy*8)
	end
	
	-- draw snake tail
	s=snake[#snake]
	sx=s[1]
	sy=s[2]
	bx=snake[#snake-1][1]
	by=snake[#snake-1][2]
	sp=23
	if bx>sx then
		sp=23
	elseif bx<sx then
		sp=22
	elseif by>sy then
		sp=38
	elseif by<sy then
		sp=39
	end
	spr(sp,sx*8,sy*8)
	
	-- draw snake head
	s=snake[1]
	sx=s[1]
	sy=s[2]
	if apple.nearany(sx,sy) then
		spr(snakedir+8,sx*8,sy*8)
	else
		spr(snakedir,sx*8,sy*8)
	end
	
	-- draw apples
	for a in all(apples) do
		if a.rotten then
			spr(49,a.x*8,a.y*8)
		elseif a.typ==apple.fast then
			spr(50,a.x*8,a.y*8)
		elseif a.typ==apple.slow then
			spr(51,a.x*8,a.y*8)
		else
			if a.rottime<45 and a.rottime%4<2 then
				spr(49,a.x*8,a.y*8)
			else
				spr(48,a.x*8,a.y*8)
			end
		end
	end

	-- draw beetles
	for b in all(beetles) do
		if t%8<4 then
			spr(24+b.d*2,b.x*8,b.y*8)
		else
			spr(25+b.d*2,b.x*8,b.y*8)
		end
	end
	
	-- draw messages
	for m in all(msgs) do
		_blink=true
		if m.blink==true then
			if m.tim%8>4 then
				_blink=false
			end
		end
		if _blink==true then
			if type(m.s)=='number' then
				spr(m.s,m.x,m.y)
			else
				print(m.s,
						clamp(m.x,0,
								120-min(2,#s)*4),m.y,7)
			end
		end
	end

	-- draw score
	print(score,3,2,7)
end

-->8
-- callbacks

curscene='splash'
function chgscene(s)
	t=0
	if s=='game' then
		curscene=s
		gameinit()
	else
		sfx(-2,2) -- stop beetle sound loop
		if s=='gameover' and
					score>bestscore then
			bestscore=score
			sfx(0)
		end
		curscene=s
	end
end

function _init()
	-- music(0,3)
end

function _update()
	t+=1
	if curscene=='game' then
		gameupdate()
	elseif curscene=='splash' then
		if btn(4) or btn(5) then
			chgscene('game')
		end
	elseif curscene=='gameover' then
		if	t>60 and (
					btn(0) or
					btn(1) or
					btn(2) or
					btn(3) or
					btn(4) or
					btn(5)) then
			chgscene('game')
		end
	end
end

function _draw()
	--reset
	pal()
	
	
	if curscene=='game' then
		cls(0)
		gamedraw()
	elseif curscene=='splash' then
		cls(15)

		for y=0,10 do
			for x=0,15 do
				spr(80+x+y*16,x*8,y*8+21)
			end
		end
		
		if t%20<10 then
			print('press 🅾️ to start',
					30,110,7)
		end

		print('v'..version,1,122,7)
	elseif curscene=='gameover' then
		pal(14,13)
		pal(7,15)
		gamedraw()

		deaths={
			beetle='beetles are poisonous',
			poop='that\'s disgusting',
			border='you can\'t go outside',
			snake='don\'t eat yourself',
		}
		s='game over'
		print(s,64-#s*2,30,8)
		s=deaths[deathreason]
		print(s,64-#s*2,50,1)

		c=12
		if score==bestscore then
			c=({8,10,11})[flr(t%9/3)+1]
		end
		s='score '..score
		x=64-#s*2
		print(s,x,80,c)
		s=' best '..bestscore
		print(s,x,90,c)
	end
end

__gfx__
02222200e2eeee2000222220000000000000000000000000000000000000000002222200e2eeee20002222200022220000000000000000000000000000000123
2eeeee20e2eeee2002eeeee200222200000000000000000000000000000000002eeeee20e222222002eeeee20211112000000000000000000000000000004567
ee1ee120e2e22220021ee1ee02eeee2000000000000000000000000000000000ee1ee120e2eeeee2021ee1ee02111120000000000000000000000000000089ab
eeeeee20e2eeeee202eeeeee021ee12000000000000000000000000000000000eeeeee20e2e1ee1202eeeeee021111200000000000000000000000000000cdef
eeeeee20e2e1ee1202eeeeee02eeee2000000000000000000000000000000000ee111120e2eeeee2021111ee02eeee2000000000000000000000000000000000
eeeee200e2eeeee20e2eeeeee2eeee2000000000000000000000000000000000ee111100e2e111120e1111ee021ee12000000000000000000000000000000000
22222000e2eeeee200e22222e2eeee200000000000000000000000000000000022111100e2e111100011112202eeee2000000000000000000000000000000000
eeee00000e222220000eeeeee2eeee2000000000000000000000000000000000eeee00000e222200000eeeee02eeee2000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000100110000001100100000000000000000010010000100100
222222222222222200022222222220000002222222222000222000000000022200000010000000101011d1011011d10101000000010000000001100110011000
eeeeeeeeeeeeeeee002eeeeeeeeee200002eeeeeeeeee200eee2220000222eee001110010011100101111d1111111d1010011100100111001011d1011011d101
eeeeeeeeeeeeeeee02eeeeeeeeeeee2002eeeeeeeeeeee20eeeeee2222eeeeee011dd101011dd10101111d1001111d101011dd101011dd1011111d1001111d11
eeeeeeeeeeeeeeee02eeeeeeeeeeee2002eeeeeeeeeeee20eeeeee2ee2eeeeee11111d1111111d1111111d1001111d11111111d1111111d101111d1001111d10
eeeeeeeeeeeeeeeee2eeeeeeeeeeee20e2eeeeeeeeeeee20eee222e00e222eee11111110111111101e1111011e111101011111110111111101111d1111111d10
2222222222222222e2eeeee22eeeee20e2eeeee22eeeee20222eee0000eee222010000100100010000e1100110e1100000100010010000101e1111011e111101
eeeeeeeeeeeeeeeee2eeee2ee2eeee20e2eeee2ee2eeee20eee0000000000eee10eee0010e1e1e00001001000010010000e1e1e0100eee0110e1100000e11001
e2eeee20e2eeee20e2eeee20e2eeee20e2eeee20e2eeee2000020000e2eeee200000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee20e2eeeee22eeeee20e2eeeee22eeeee2000e22000e2eeee200000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee20e2eeeeeeeeeeee20e2eeeeeeeeeeee20002ee200e2eeee200000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee20e2eeeeeeeeeeee20e2eeeeeeeeeeee200e2ee2000e2ee2000000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee20e2eeeeeeeeeeee20e2eeeeeeeeeeee200e2ee2000e2ee2000000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee200e2eeeeeeeeee2000e2eeeeeeeeee20002eeee200e2ee2000000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee2000e2222222222e0000e2222222222e00e2eeee2000e220000000000000000000000000000000000000000000000000000000000000000000
e2eeee20e2eeee20000eeeeeeeeee000000eeeeeeeeee000e2eeee20000e20000000000000000000000000000000000000000000000000000000000000000000
00000500000005000000050000000500000020000004444033033000000000000000000000000000000000000000000000000000000000000000000000000000
0000500000005000000050000000500000029200004a4a403a33a300000000000000000000000000000000000000000000000000000000000000000000000000
0028888000244440003bbbb0004999900024492004aa4a403aa3aa30000000000000000000000000000000000000000000000000000000000000000000000000
02888e880244494403bbbabb04999a9902444220499949403bbbbbb3000000000000000000000000000000000000000000000000000000000000000000000000
028888880244444403bbbbbb0499999924222492049949403bb3bb30000000000000000000000000000000000000000000000000000000000000000000000000
0228888202244442033bbbb3044999942444442e004949403b33b300000000000000000000000000000000000000000000000000000000000000000000000000
00228820002244200033bb3000449940e22222e00004444033033000000000000000000000000000000000000000000000000000000000000000000000000000
0ee222ee0ee222ee0ee333ee0ee444ee0eeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000aa0000aa0000000000777000000000077777700000000777777000000aa00000007a0000000000000000000000000
0000000000000000000000000000000000777000077700000000777770000000a77777777a0000a77777777a000a770000007770000000000000000000000000
000000000000000000000000000000000a7770000777a000000777777a00000077777777770000777777777700077700000a7770000000000000000000000000
00000000000000000000000000000000077770000777a0000007777777000000777a00a777a000777a00a777a00777a000077770000000000000000000000000
00000000000000000000000000000000077770000777a00000777707770000007770000a77a0007770000a77a00777a000777700000000000000055000000000
00000000000000000000000000000000077770000a77a00000777a07770000007770000a77a0007770000a77a00a777000777000000000000000555000000000
000000000000000000000000000000000777a0000a77a0000a77700777000000777000077700007770000777000a77700777a000000000000000550000000000
000000000000000000000000000000000777a0000a77a0000777700a77a0000077700a7777000077700a77770000777aa7770000000000000005500000000000
000000000000000000000000000000000777a000a77700000777a00a77a0000a777a777770000a777a7777700000777777700000000000000005000000000000
000000000000000000000000000000000777777777770000a777000a7770000a7777777700000a77777777000000a77777700000000000000055000000000000
00000000000002222000000000000000a7777777777700007777000a7770000a7777777000000a77777770000000077777000000000000000550000000000000
0000000000222eeee222200000000000a7777777777700007777aaaa7770000777777a0000000777777a00000000077777000000008888820500000000000000
0000000002eeeeeeeeeee20000000000777a0000a7770000777777777770000777700000000007777000000000000a7770000000888888882588888880000000
000000002eeeeeeeeeeeee2000000000777a0000a777000a777777777770000777000000000007770000000000000a7770000002888888888888888888800000
00000002eeeeeeeeeeeeeee200000000777a0000a77700077777aaa7777a000777000000000007770000000000000777a0000002888888888888888888880000
0000002eeeeeeeeeeeeeeeee2000000077700000a777000777700000777700077700000000000777000000000000a7770000002888888888888ee88888888000
0000002eeeeeeeeeeeeeeeee20000000a770000007770007770000007777000a7700000000000a77000000000000a777000000288888888888eeeee888888800
000002eeeeeeeeeeeeeeeeeee2000000a77000000777000a77000000a77a000a7700000000000a77000000000000a777000000288888888888ee7eee88888800
000002eee1111eeeee1111eee20000000a7000000a700000aa0000000aa00000a7000000000000a70000000000000770000002288888888888eeeeee88888800
000002ee177771eee177771ee20000000000000000000000000000000000000000000000000000000000000000000000000002288888888888eeeeee88888800
000002e17777771e17777771e200000000000000000000000000000000000000000000000000000000000000000000000000022888888888888eeee888888800
00002ee17771171e17771171e2000000000000000000000000000000000000000000000000000000000000000000000000000222888888888888888888888800
00002ee17711171e17711171e2000000000000000000000000000000000000000000000000000000000000000000000000000022288888888888888888888000
00002ee17711171e17711171e2000000000000000000000000000000000000000000000000000000000000000000000000000022222888888888888888888000
00002eee171111eee171111ee2000000000000a770000000000a7777a00000000a7777a0000000aa000000000000000a7777a002222228888888888888880000
00002eeee1111eeeee1111eee200000000000777770000000a7777777700000a7777777700000777000000000000a77777777a00222222288888888888820000
00002eeeeeeeeeeeeeeeeee1ee2000000000a77777a0000007777777777000077777777770000777a0000000000a777777777000002222222288888222200000
00002e1eeeeeeeeeeeeeee1eee200000000077777770000007777aa777700007777aa77770000777a000000000077777aaaa0000000022222222222222000000
00002ee1111eeeeeeeee111eee200000000a777a7770000007770000a77a0007770000a77a000777a0000000000777a000000000000002222222222200000000
00002ee111111111111111eeee200000000777a077700000a7770000a77a00a7770000a77a0007770000000000a7770000000000000000002222222000000000
000002ee11111111111111eeeee2000000a7770077700000a7770000777000a7770000777000077700000000007777a777777a00000000000000000000000000
000002eee111111111111eeeeee2000000777700777a0000a77a00a7777000a77a00a7777000a777000000000077777777777700000000000000000000000000
000002eeee11111111111eeeeeee200000777a00a77a0000a77a0777770000a77a0777770000a77a000000000077777777777000000000000000000000000000
000002eeeee111111111eeeeeeeee2200a777000a77a0000a7777777700000a7777777700000a77a000000000077777aa0000000000000000000000000000000
000002eeeeee1111111eeeeeeeeeeee227777000a777000077777777000000777777772200007770000000000a77770000000000000000000000000000000000
000002eeeeeee11111eeeeeeeeeeeeeee7777aaa77770000777777a0002222777777aeee22207770000000000a77700000000000000000000000000000000000
0000002eeeeeeeeeeeeeeeeeeeeeeeeee7777777777700007777a22222eeee7777aeeeeeeee277700000000007777000000aa000000000000000000000000000
0000002eeeeeeeeeeeeeeeeeeeeeeeeea777777777772222777eeeeeeeeeee777eeeeeeeeeee777000000000077770000a777700000000000000002222222000
00000002eeeeeeeeeeeeeeeeeeeeeeee777777777777eeee777eeeeeeeeeee777eeeeeeeeeee7772000777a00777700a7777770000000000000222eeeeeee222
00000002eeeeeeeeeeeeeeeeeeeeeeee777aeeeee777aeee777eeeeeeeeeee777eeeeeeeeeee777ea77777a007777a777777700000000000022eeeeeeeeeeeee
00000002eeeeeeeeeeeeeeeeeeeeeeee777aeeeee7777eee777eeeeeeeeeee777eeeeeeeeeee7777777777000a77777777700000000000022eeeeeeeeeeeeeee
000000002eeeeeeeeeeeeeeeeeeeeeeea77eeeeee777aeeea77eeeeeeeeeeea77eeeeeeeeeee77777777a20000a777777a0000000000022eeeeeeeeeeeeeeeee
000000002eeeeeeeeeeeeeeeeeeeeeeeea7eeeeee777eeeeea7eeeeeeeeeeeea7eeeeeeeeeeea77777aeee20000aa7700000000000022eeeeeeeeeeeeeeeeeee
0000000002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeee20000000000000000022eeeeeeeeeeeeeeeeeeeee
00000000002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22000000000000002eeeeeeeeeeeeeeeeeeeeeee
000000000002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22200000000022eeeeeeeeeeeeeeeeeeeeeeee
0000000000002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222222eeeeeeeeeeeeeeeeeeeeeeeeee
00000000000002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000022eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaeeeeeeeeeeaaaaaaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000000000000022eeeeeeeeeeeeeeee77eeeeeeeeeea7eeeeeeee777777aeeeeeea777777777eeeeeee777eeeeee77aeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000002eeeeeeeeeeeeeea777eeeeaeeee777eeeeee77777777eeeeee77777777777eeeeea777eeeeea777eeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000000000000000022eeeeeeeeeeeea777eeea77eee777eeeee7777777777eeeee77777777777eeeee7777aeeee7777aeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000000000000000022eeeeeeeeee7777eee777aee777eeeea777aeee777a222a777eeeee777eeeee77777eeea77777eeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000000000022eeeeeeee777aeea7777ea777eeee777aeee2a777000a777eeeee777eeeea77777eee777777eeeeeeeeeeeeeeeeeeeeeee222eee
0000000000000000000000000222eeeee777aee77777ea777eeea77722220a777000a77a2eee7777eeee777777eee777777eeeeeeeeeeeeeeeeee2222200022e
000000000000000000000000000022eee777eea777772a777222777a00000a777000a77a0227777eeeee777777ae7777777eeeeeeeeeeeeeeee2200000000002
00000000000000000000000000000022a7772277777707777000777000000a777000a777777777a2eeee777777ae7777777eeeeeeeeeeeee2220000000000000
00000000000000000000000000000000a7770a7777770777700a777000000a777000777777777a0022ee7777777a7777777eeeeeeeeeeee20000000000000000
00000000000000000000000000000000a77707777777a777700a777000000a7770007777777700000022777a777777a777aeeeeeeeeee2200000000000000000
00000000000000000000000000000000a777a777a7777777a00a777000000777700a7777777000000000777a777777e777aeeeeeee2220000000000000000000
00000000000000000000000000000000a7777777a7777777000a777000000777700a777a777700000000777077777a2777aeee22220000000000000000000000
00000000000000000000000000000000a777777a077777770000a77000000777a00a7770a7777000000077707777700777a22200000000000000000000000000
00000000000000000000000000000000a77777700a7777770000a77000007777000a77700a777700000077707777700777a00000000000000000000000000000
00000000000000000000000000000000a77777a0007777700000a777000a777a000a777000a7777000007770a777000a77a00000000000000000000000000000
00000000000000000000000000000000077777000077777000000a7777777770000a7770000a777700007770077a000a77a00000000000000000000000000000
0000000000000000000000000000000007777a0000a777a000000a7777777700000a77700000a7777000a7700770000a77000000000000000000000000000000
000000000000000000000000000000000077700000077700000000a7777770000000a77000000a77a0000aa000000000a7000000000000000000000000000000
0000000000000000000000000000000000a70000000a70000000000a777aa000000007a0000000aa000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaa000000000000000000000000000000000000000000000000000000000000000000000
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffaaffffaaffffffffff777ffffffffff777777ffffffff777777ffffffaafffffff7afffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffff777ffff777ffffffff77777fffffffa77777777affffa77777777afffa77ffffff777fffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffa777ffff777affffff777777affffff7777777777ffff7777777777fff777fffffa777fffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff7777ffff777affffff7777777ffffff777affa777afff777affa777aff777affff7777fffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff7777ffff777afffff7777f777ffffff777ffffa77afff777ffffa77aff777afff7777fffffffffffffff55fffffffff
fffffffffffffffffffffffffffffffff7777ffffa77afffff777af777ffffff777ffffa77afff777ffffa77affa777fff777fffffffffffffff555fffffffff
fffffffffffffffffffffffffffffffff777affffa77affffa777ff777ffffff777ffff777ffff777ffff777fffa777ff777afffffffffffffff55ffffffffff
fffffffffffffffffffffffffffffffff777affffa77affff7777ffa77afffff777ffa7777ffff777ffa7777ffff777aa777fffffffffffffff55fffffffffff
fffffffffffffffffffffffffffffffff777afffa777fffff777affa77affffa777a77777ffffa777a77777fffff7777777ffffffffffffffff5ffffffffffff
fffffffffffffffffffffffffffffffff77777777777ffffa777fffa777ffffa77777777fffffa77777777ffffffa777777fffffffffffffff55ffffffffffff
fffffffffffff2222fffffffffffffffa77777777777ffff7777fffa777ffffa7777777ffffffa7777777ffffffff77777fffffffffffffff55fffffffffffff
ffffffffff222eeee2222fffffffffffa77777777777ffff7777aaaa777ffff777777afffffff777777afffffffff77777ffffffff888882f5ffffffffffffff
fffffffff2eeeeeeeeeee2ffffffffff777affffa777ffff77777777777ffff7777ffffffffff7777ffffffffffffa777fffffff88888888258888888fffffff
ffffffff2eeeeeeeeeeeee2fffffffff777affffa777fffa77777777777ffff777fffffffffff777fffffffffffffa777ffffff28888888888888888888fffff
fffffff2eeeeeeeeeeeeeee2ffffffff777affffa777fff77777aaa7777afff777fffffffffff777fffffffffffff777affffff288888888888888888888ffff
ffffff2eeeeeeeeeeeeeeeee2fffffff777fffffa777fff7777fffff7777fff777fffffffffff777ffffffffffffa777ffffff2888888888888ee88888888fff
ffffff2eeeeeeeeeeeeeeeee2fffffffa77ffffff777fff777ffffff7777fffa77fffffffffffa77ffffffffffffa777ffffff288888888888eeeee8888888ff
fffff2eeeeeeeeeeeeeeeeeee2ffffffa77ffffff777fffa77ffffffa77afffa77fffffffffffa77ffffffffffffa777ffffff288888888888ee7eee888888ff
fffff2eee1111eeeee1111eee2fffffffa7ffffffa7fffffaafffffffaafffffa7ffffffffffffa7fffffffffffff77ffffff2288888888888eeeeee888888ff
fffff2ee177771eee177771ee2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2288888888888eeeeee888888ff
fffff2e17777771e17777771e2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22888888888888eeee8888888ff
ffff2ee17771171e17771171e2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2228888888888888888888888ff
ffff2ee17711171e17711171e2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22288888888888888888888fff
ffff2ee17711171e17711171e2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222888888888888888888fff
ffff2eee171111eee171111ee2ffffffffffffa77ffffffffffa7777affffffffa7777afffffffaafffffffffffffffa7777aff222222888888888888888ffff
ffff2eeee1111eeeee1111eee2fffffffffff77777fffffffa77777777fffffa77777777fffff777ffffffffffffa77777777aff22222228888888888882ffff
ffff2eeeeeeeeeeeeeeeeee1ee2fffffffffa77777affffff7777777777ffff7777777777ffff777affffffffffa777777777fffff22222222888882222fffff
ffff2e1eeeeeeeeeeeeeee1eee2fffffffff7777777ffffff7777aa7777ffff7777aa7777ffff777affffffffff77777aaaaffffffff22222222222222ffffff
ffff2ee1111eeeeeeeee111eee2ffffffffa777a777ffffff777ffffa77afff777ffffa77afff777affffffffff777affffffffffffff22222222222ffffffff
ffff2ee111111111111111eeee2ffffffff777af777fffffa777ffffa77affa777ffffa77afff777ffffffffffa777ffffffffffffffffff2222222fffffffff
fffff2ee11111111111111eeeee2ffffffa777ff777fffffa777ffff777fffa777ffff777ffff777ffffffffff7777a777777affffffffffffffffffffffffff
fffff2eee111111111111eeeeee2ffffff7777ff777affffa77affa7777fffa77affa7777fffa777ffffffffff777777777777ffffffffffffffffffffffffff
fffff2eeee11111111111eeeeeee2fffff777affa77affffa77af77777ffffa77af77777ffffa77affffffffff77777777777fffffffffffffffffffffffffff
fffff2eeeee111111111eeeeeeeee22ffa777fffa77affffa77777777fffffa77777777fffffa77affffffffff77777aafffffffffffffffffffffffffffffff
fffff2eeeeee1111111eeeeeeeeeeee227777fffa777ffff77777777ffffff7777777722ffff777ffffffffffa7777ffffffffffffffffffffffffffffffffff
fffff2eeeeeee11111eeeeeeeeeeeeeee7777aaa7777ffff777777afff2222777777aeee222f777ffffffffffa777fffffffffffffffffffffffffffffffffff
ffffff2eeeeeeeeeeeeeeeeeeeeeeeeee77777777777ffff7777a22222eeee7777aeeeeeeee2777ffffffffff7777ffffffaafffffffffffffffffffffffffff
ffffff2eeeeeeeeeeeeeeeeeeeeeeeeea777777777772222777eeeeeeeeeee777eeeeeeeeeee777ffffffffff7777ffffa7777ffffffffffffffff2222222fff
fffffff2eeeeeeeeeeeeeeeeeeeeeeee777777777777eeee777eeeeeeeeeee777eeeeeeeeeee7772fff777aff7777ffa777777fffffffffffff222eeeeeee222
fffffff2eeeeeeeeeeeeeeeeeeeeeeee777aeeeee777aeee777eeeeeeeeeee777eeeeeeeeeee777ea77777aff7777a7777777ffffffffffff22eeeeeeeeeeeee
fffffff2eeeeeeeeeeeeeeeeeeeeeeee777aeeeee7777eee777eeeeeeeeeee777eeeeeeeeeee7777777777fffa777777777ffffffffffff22eeeeeeeeeeeeeee
ffffffff2eeeeeeeeeeeeeeeeeeeeeeea77eeeeee777aeeea77eeeeeeeeeeea77eeeeeeeeeee77777777a2ffffa777777afffffffffff22eeeeeeeeeeeeeeeee
ffffffff2eeeeeeeeeeeeeeeeeeeeeeeea7eeeeee777eeeeea7eeeeeeeeeeeea7eeeeeeeeeeea77777aeee2ffffaa77ffffffffffff22eeeeeeeeeeeeeeeeeee
fffffffff2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeee2fffffffffffffffff22eeeeeeeeeeeeeeeeeeeee
ffffffffff2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22ffffffffffffff2eeeeeeeeeeeeeeeeeeeeeee
fffffffffff2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222fffffffff22eeeeeeeeeeeeeeeeeeeeeeee
ffffffffffff2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222222eeeeeeeeeeeeeeeeeeeeeeeeee
fffffffffffff2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ffffffffffffff22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaeeeeeeeeeeaaaaaaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ffffffffffffffff22eeeeeeeeeeeeeeee77eeeeeeeeeea7eeeeeeee777777aeeeeeea777777777eeeeeee777eeeeee77aeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ffffffffffffffffff2eeeeeeeeeeeeeea777eeeeaeeee777eeeeee77777777eeeeee77777777777eeeeea777eeeeea777eeeeeeeeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffffff22eeeeeeeeeeeea777eeea77eee777eeeee7777777777eeeee77777777777eeeee7777aeeee7777aeeeeeeeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffffffff22eeeeeeeeee7777eee777aee777eeeea777aeee777a222a777eeeee777eeeee77777eeea77777eeeeeeeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffffffffff22eeeeeeee777aeea7777ea777eeee777aeee2a777fffa777eeeee777eeeea77777eee777777eeeeeeeeeeeeeeeeeeeeeee222eee
fffffffffffffffffffffffff222eeeee777aee77777ea777eeea7772222fa777fffa77a2eee7777eeee777777eee777777eeeeeeeeeeeeeeeeee22222fff22e
ffffffffffffffffffffffffffff22eee777eea777772a777222777afffffa777fffa77af227777eeeee777777ae7777777eeeeeeeeeeeeeeee22ffffffffff2
ffffffffffffffffffffffffffffff22a77722777777f7777fff777ffffffa777fffa777777777a2eeee777777ae7777777eeeeeeeeeeeee222fffffffffffff
ffffffffffffffffffffffffffffffffa777fa777777f7777ffa777ffffffa777fff777777777aff22ee7777777a7777777eeeeeeeeeeee2ffffffffffffffff
ffffffffffffffffffffffffffffffffa777f7777777a7777ffa777ffffffa777fff77777777ffffff22777a777777a777aeeeeeeeeee22fffffffffffffffff
ffffffffffffffffffffffffffffffffa777a777a7777777affa777ffffff7777ffa7777777fffffffff777a777777e777aeeeeeee222fffffffffffffffffff
ffffffffffffffffffffffffffffffffa7777777a7777777fffa777ffffff7777ffa777a7777ffffffff777f77777a2777aeee2222ffffffffffffffffffffff
ffffffffffffffffffffffffffffffffa777777af7777777ffffa77ffffff777affa777fa7777fffffff777f77777ff777a222ffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffa777777ffa777777ffffa77fffff7777fffa777ffa7777ffffff777f77777ff777afffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffa77777afff77777fffffa777fffa777afffa777fffa7777fffff777fa777fffa77afffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff77777ffff77777ffffffa777777777ffffa777ffffa7777ffff777ff77afffa77afffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff7777affffa777affffffa77777777fffffa777fffffa7777fffa77ff77ffffa77ffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffff777ffffff777ffffffffa777777fffffffa77ffffffa77affffaafffffffffa7ffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffa7fffffffa7ffffffffffa777aaffffffff7afffffffaaffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff777f777f777ff77ff77ffffff77777ffffff777ff77ffffff77f777f777f777f777fffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff7f7f7f7f7fff7fff7fffffff77fff77ffffff7ff7f7fffff7ffff7ff7f7f7f7ff7ffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff777f77ff77ff777f777fffff77f7f77ffffff7ff7f7fffff777ff7ff777f77fff7ffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff7fff7f7f7fffff7fff7fffff77fff77ffffff7ff7f7fffffff7ff7ff7f7f7f7ff7ffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff7fff7f7f777f77ff77fffffff77777fffffff7ff77ffffff77fff7ff7f7f7f7ff7ffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f7f7f77ffffff777fffff777fffff77fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f7f7ff7ffffff7f7fffff7f7ffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f7f7ff7ffffff7f7fffff7f7f777ff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f777ff7ffffff7f7fffff7f7ffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff7ff777ff7ff777ff7ff777fffff777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__sfx__
0002000015250152501425014250142501325013250122501125010250102500e2500d2500c2500c2500a25007250012500125001250012500125001250012500125001250012500125001250012500125001250
000200002905001010200500100017040000000f0000d040090000600001000070400000000000000000000000000020300000000000000000000000000010200000002000000000000000000000000000000000
0002000002050000000905000000130500000017050000001f0500000029040290001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001200002c0503005001250012001a600106000d60007600066000000002600000001a600000000000000000000000000014600000000000000000000000d6000000000000000000000000000000000000000000
001200002c050300602c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000c1c61001600016001761001600016001c61029000016001561000000000001960000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100020060500000008050000000d050000000805000000060500000008050000000d050000000f05008000060500000008050000000d05000000080500000006050000000d0500000008050000000605000000
001000202575005700277502b7002774004700047002b7002c7402c7002d7002d7002a7302d7002d7002d700257402c700277502b700277502b7002c7002d7002c750147000d70004700277502c7002e7002e700
00100020015500c5000c5000c50001550005000050000500015500050001500035500050000500015400050000500005000155001500005000020001550000000000001550000000000003550000000155000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f77
__music__
00 0a4b0c44
02 0a4b0c44
00 0a0b0c44
00 0a0b0c44

