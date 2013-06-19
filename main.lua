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
Bonus = require 'bonus'
Highscore = require 'highscore'
local score_future_color={255,0,0}
local score_color={255,255,255}
local score_font

local snake={}
local score={}
local evmgr={}
local bmgr={}

local state=nil
local playstate={}
local gameoverstate={}
local pausestate={}
local menustate={}


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

function score:add(incr,isfut,remain)
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
		if remain and remain > 0 then
			evmgr:addEvent(1,score,score.add,incr,true,remain-1)
		end
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
	menustate:init()
	Highscore.init()
    evmgr=Events()		
	--reset()
	state=menustate
	state:enter()
end

function reset()
	state=playstate
	evmgr:clean()
	score:reset()
	bmgr=Bonus(evmgr,10)
	snake=Snake(30, math.floor(SH/2),10)
end


function intersect(hb1,hb2)
	return not ((hb1[1]>hb2[3]) or (hb2[1]>hb1[3]) or (hb1[2]>hb2[4]) or (hb2[2]>hb1[4]))
end

function playstate:update(dt)
	evmgr:update(dt)
	snake:update(dt)
	local events = bmgr:genEvents(snake:getDisk(1))
	for _,e in ipairs(events) do
		if e == "FRUIT" then
			score:add(50)
			snake:addRing()
			evmgr:addEvent(5,score,score.add,math.floor(#snake/10),true,4)
			score:addFuture(math.floor(#snake/10)*5)
		end
	end
	if snake:selfhit() then
		state=gameoverstate
		state:enter()
	end	
end

function playstate:draw()
	bmgr:draw()
	snake:draw()
	score:draw()
end

function playstate:keypressed(key)
	if key == "p" then
		state = pausestate
	end
end

function menustate:init()

	self.titreBgColor = {0,0,196,128}
	self.titreFgColor= {255,255,255}
	self.titreFont = love.graphics.newFont(32) 
	self.titre = "OPHIDIAN CRAWLER"
	local titreHeight = math.floor(self.titreFont:getHeight()*1.5)
	self.titreY = 20 + math.floor(self.titreFont:getHeight()*0.25)
	self.titreRectangle = {0,20,SW,titreHeight}

	self.message="PRESS ANY KEY TO PLAY"
	self.font=love.graphics.newFont(20)
	self.messageY = SH - 1.5*self.font:getHeight()
	
	self.demoSnakes={}
	for i=1,5 do
		self.demoSnakes[i]=Snake(30, math.random(1,SH),30)
	end
	self.selectSnake = Snake(30, math.floor(SH/2),10)
	self.selectSnake.bodyColor={196,196,196}
	self.selectSnake.headColor={196,20,20}
end

function menustate:enter()
	self.showMessage=true
	evmgr:clean()
	evmgr:addEvent(0.5,self,self.flipMessage)
	for _,s in ipairs(self.demoSnakes) do
		s:setAutoPilot(evmgr)
		s.speed = math.random(200,300)
	end
end

function menustate:flipMessage()
	self.showMessage = not self.showMessage
	evmgr:addEvent(0.5,self,self.flipMessage)
end

function menustate:update(dt)
	evmgr:update(dt)
	for _,s in ipairs(self.demoSnakes) do
		s:update(dt)
	end
	--self.selectSnake:update(dt)
	
	
end

function menustate:draw()
	for _,s in ipairs(self.demoSnakes) do
		s:draw()
	end
	--self.selectSnake:draw()
	love.graphics.setColor(self.titreBgColor)
	love.graphics.rectangle('fill',unpack(self.titreRectangle))
	love.graphics.setColor(self.titreFgColor)
	love.graphics.setFont(self.titreFont)
	love.graphics.printf(self.titre,0,self.titreY,SW,"center")

	if self.showMessage then
		love.graphics.setColor({255,255,255})
		love.graphics.setFont(self.font)
		love.graphics.printf(self.message,0,self.messageY,SW,"center")
	end
	
end

function menustate:keypressed(key)
	reset()
end

function gameoverstate:init()
	self.font =  love.graphics.newFont(32) 
	self.message = "GAME OVER - PRESS ANY KEY TO PLAY"
	self.y = (SH-self.font:getHeight())/2
end

function gameoverstate:enter()
	evmgr:clean()
	self.showMessage=true
	evmgr:addEvent(0.5,self,self.flipMessage)
	evmgr:addEvent(3,self,self.startDemo)
end

function gameoverstate:startDemo()
	state = menustate
	state:enter()
end

function gameoverstate:flipMessage()
	self.showMessage = not self.showMessage
	evmgr:addEvent(0.5,self,self.flipMessage)
end

function gameoverstate:update(dt)
	evmgr:update(dt)
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
	if key==" " or key =="return" then
		state = playstate
	end
end

function love.update(dt)
	state:update(dt)
end

function love.draw()
	state:draw(dt)
	--love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 500)
end
--
function love.keypressed(key)
	state:keypressed(key)
end
--]]