--[[
Copyright (c) 2013 Romain Meynet

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source
distribution.
--]]

Events = require 'events'
Snake = require 'snake'

local score_future_color={255,0,0}
local score_color={255,255,255}
local score_font

local fruit_color={196,15,15}
local fruit_radius=8


local snake={}
local fruits={}
local score={}
local evmgr={}

local state=nil
local playstate={}
local gameoverstate={}
local pausestate={}

function score:reset()
    score_font = love.graphics.newFont(18) 
	self.events={}
	self.value=0
	self.future=0
	self:add(0,true)
end

function score:addFuture(incr)
	local v = self.future + incr
	self.fstring=string.format("+%04d",v)
	self.future=v
end

function score:add(incr,isfut)
	local v = self.value + incr
	self.string=string.format("%06d",v)
	self.value=v
	if isfut then
		v = self.future - incr
		if v>0 then
			self.fstring=string.format("+%04d",v)
		else
			v=0
			self.fstring=""
		end
		self.future=v
	end
end

function score:draw()
	love.graphics.setFont(score_font)
	love.graphics.setColor(score_color)
	love.graphics.print(self.string,0,0)
	love.graphics.setColor(score_future_color)
	love.graphics.print(self.fstring,100,0)
end

function love.load()
	SW,SH = love.graphics.getWidth(), love.graphics.getHeight()
	gameoverstate:init()
    evmgr=Events()		
	reset()
end

function reset()
	state=playstate
	playstate.outDelay=0
	evmgr:clean()
	score:reset()
	snake=Snake(10, math.floor(SH/2),10)
	for i=1,5 do
		local f = {
			x = math.random(SW*0.1,SW*0.9),
			y = math.random(SH*0.1,SH*0.9),
			draw = fdraw,
			update = fupdate,
			hit = fhit
		}
		fruits[i]=f
	end
end

function fdraw(self)
	love.graphics.setColor(fruit_color)
	love.graphics.circle('fill',self.x,self.y,fruit_radius,32)
end

function fupdate(self,dt)

end

function fhit(self,hb)
	local x,y=self.x,self.y
	if intersect(
		{x-fruit_radius,y-fruit_radius,x+fruit_radius,y+fruit_radius},
		hb) then
		
		local hx,hy,hr = snake:getDisk(1)	
		local d = (x-hx)*(x-hx)+(y-hy)*(y-hy)
		if d < (hr+fruit_radius)*(hr+fruit_radius) then
			return true
		end
	end
	return false
end


function intersect(hb1,hb2)
	return not ((hb1[1]>hb2[3]) or (hb2[1]>hb1[3]) or (hb1[2]>hb2[4]) or (hb2[2]>hb1[4]))
end

function playstate:update(dt)
	evmgr:update(dt)
	snake:update(dt)
	local hhb = snake:cellhitbox(1)
	for _,f in ipairs(fruits) do
		if f:hit(hhb) then
			snake:addRing()
			f.x = math.random(SW*0.1,SW*0.9)
			f.y = math.random(SH*0.1,SH*0.9)
			
			score:add(50)
			for i=1,5 do
				evmgr:addEvent(5+i,score,score.add,math.floor(#snake/10),true)
			end
			score:addFuture(math.floor(#snake/10)*5)
		end
	end
	if snake:isOut() then
		if self.outDelay > 0 then
			self.outDelay = self.outDelay - dt
			if self.outDelay <= 0 then
				state=gameoverstate
				state:enter()
				return
			end
		else
			self.outDelay=5
		end
	else
		self.outDelay=0
	end
	if snake:selfhit() then
		state=gameoverstate
		state:enter()
	end	
end

function playstate:draw()
	for _,f in ipairs(fruits) do
		f:draw()
	end
	if self.outDelay >0 then
		love.graphics.setColor(255,255,255)
		love.graphics.rectangle("line",199,4,102,17)
		love.graphics.setColor(255,0,0)
		love.graphics.rectangle("fill",200,5,self.outDelay*20,15)
	end
	snake:draw()
	score:draw()
end

function playstate:keypressed(key)
	if key == "p" then
		state = pausestate
	end
end

function gameoverstate:init()
	self.font =  love.graphics.newFont(32) 
	self.message = "GAME OVER - PRESS ANY KEY TO PLAY"
	self.y = (SH-self.font:getHeight())/2
end

function gameoverstate:enter()
	evmgr:clean()
	self.showMessage=true
	self.showDemo=false
	evmgr:addEvent(0.5,self,self.flipMessage)
	evmgr:addEvent(3,self,self.startDemo)
end

function gameoverstate:startDemo()
	self.showDemo=true
	snake=Snake(0, math.floor(SH/2),100)
	snake:setAutoPilot(evmgr)
end

function gameoverstate:flipMessage()
	self.showMessage = not self.showMessage
	evmgr:addEvent(0.5,self,self.flipMessage)
end

function gameoverstate:update(dt)
	evmgr:update(dt)
	if self.showDemo then
		snake:update(dt)
	end
end

function gameoverstate:draw()
	playstate:draw()
	if self.showMessage then
		love.graphics.setColor({255,255,255})
		love.graphics.setFont(self.font)
		love.graphics.printf(self.message,0,self.y,SW,"center")
	end
end

function gameoverstate:keypressed(key)
	reset()
end

function pausestate:update(dt)
end

function pausestate:draw()
	playstate:draw()
end

function pausestate:keypressed(key)
	state = playstate
end

function love.update(dt)
	state:update(dt)
end

function love.draw()
	state:draw(dt)
end

--
function love.keypressed(key)
	state:keypressed(key)
end
--]]