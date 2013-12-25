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

local lg = love.graphics

local events = require 'events'
local Snake = require 'snake'
local Bonus = require 'bonus'
local Highscore = require 'highscore'
local rsc = require 'resources'
local score=require 'score'

local snake={}
local bmgr={}

local state=nil
local playstate={}
local gameoverstate={}
local pausestate={}
local hiscorestate={}


function love.load()
	love.keyboard.setTextInput(false)
	SW,SH = lg.getWidth(), lg.getHeight()
	lg.setBackgroundColor({0,64,64})
	rsc.load()
	Highscore.init()
	gameoverstate:init()
	hiscorestate:init()
	state=hiscorestate
	state:enter()
end

function reset()
	state=playstate
	playstate.sleep=false
	
	
	events.clean()
	score.reset()
	bmgr=Bonus(10)
	snake=Snake(30, math.floor(SH/2),10)
	
	snake.fcollision = function (x,y,r) return bmgr:genCollision(x,y,r) end
end


function intersect(hb1,hb2)
	return not ((hb1[1]>hb2[3]) or (hb2[1]>hb1[3]) or (hb1[2]>hb2[4]) or (hb2[2]>hb1[4]))
end

function playstate:update(dt)
	events.update(dt)
	snake:update(dt)
	bmgr:update(dt)
	if not self.sleep and snake.waitcount < 0 then
		self.sleep=true
		--bmgr:sleep()
		snake:sleep()
	elseif self.sleep and snake.waitcount > 0 then
		self.sleep=false
		--bmgr:wakeup(evmgr)
		snake:wakeup()
	end
	if not self.sleep then
		local events = bmgr:genEvents(snake:getDisk(1))
		for _,e in ipairs(events) do
			if e[1] == "FRUIT" then
				score.add(e[2])
				snake:addRing()
				score.grow(1)
			end
		end
	end
	if snake:selfhit() then
		state=gameoverstate
		state:enter()
	end	
end

function playstate:draw()
	snake:draw()
	bmgr:draw()
	score.draw()
end

function playstate:keypressed(key)
	if key == "p" then
		state = pausestate
	end
end

function hiscorestate:init()
	
	local titreOffset = 20

	self.titreBgColor = {0,0,196,128}
	self.titreFgColor= {255,255,255}
	self.titre = "OPHIDIAN CRAWLER"
	local titreHeight = math.floor(rsc.titleFont:getHeight()*1.5)
	self.titreY = titreOffset + math.floor(rsc.titleFont:getHeight()*0.25)
	self.titreRectangle = {0,titreOffset,SW,titreHeight}

	self.message="PRESS ANY KEY TO PLAY"
	self.messageY = SH - 1.5*rsc.font:getHeight()
	
	self.demoSnakes={}
	for i=1,5 do
		self.demoSnakes[i]=Snake(30, math.random(1,SH),30)
	end
	self.selectSnake = Snake(30, math.floor(SH/2),10)
	self.selectSnake.bodyColor={196,196,196}
	self.selectSnake.headColor={196,20,20}
	
	local ns = Highscore.getNbScores()
	self.scoreY={}
	local sh = (ns + 4)*1.2*rsc.menuFont:getHeight()
	self.scoreTitreY = (SH - titreHeight - titreOffset - sh) / 2 + titreHeight + titreOffset
	self.scoreY[1] = self.scoreTitreY + 2.4 * rsc.menuFont:getHeight()
	for i= 2 , ns do
		self.scoreY[i] = self.scoreY[i-1] + 1.2 * rsc.menuFont:getHeight()
	end
	self.scoreY[ns+1] = self.scoreY[ns] + 2.4 * rsc.menuFont:getHeight()

	self.scoreW = rsc.menuFont:getWidth("99. MMMMMMMMMM 999999")
	self.scoreX={}
	self.scoreX[1] = (SW - self.scoreW)/2
	self.scoreX[2] = self.scoreX[1] + rsc.menuFont:getWidth("99. ")
	self.scoreX[3] = self.scoreX[1] + rsc.menuFont:getWidth("99. MMMMMMMMMM ")
	self.scoreLastW = self.scoreX[1]+self.scoreW-self.scoreX[3]
	self.scoreColor = {255,255,255}
	self.scoreSelectColor = {255,255,0}

	
end

function hiscorestate:enter()
	love.keyboard.setTextInput(false)
	self.showMessage=true
	events.clean()
	events.addEvent(0.5,self,self.flipMessage)
	for _,s in ipairs(self.demoSnakes) do
		s:setAutoPilot()
		s.speed = math.random(200,300)
	end
	self.listNames=Highscore.getListNames()
	self.iListe=1
	self.currentScores = Highscore.getHighScores(self.listNames[self.iListe])
	self.currentXOff = 0
	events.addEvent(5,self,self.nextHighscoreList)
end

function hiscorestate:nextHighscoreList()
	self.iListe = self.iListe + 1
	if self.iListe > #self.listNames then
		self.iListe=1
	end
	self.oldScores = self.currentScores
	self.currentScores = Highscore.getHighScores(self.listNames[self.iListe])
	self.currentXOff=SW
	events.addEvent(5,self,self.nextHighscoreList)
end

function hiscorestate:flipMessage()
	self.showMessage = not self.showMessage
	events.addEvent(0.5,self,self.flipMessage)
end

function hiscorestate:update(dt)
	if self.currentXOff > 0 then
		self.currentXOff= self.currentXOff - SW/2*dt
	else
		self.currentXOff=0
	end
	events.update(dt)
	for _,s in ipairs(self.demoSnakes) do
		s:update(dt)
	end
	--self.selectSnake:update(dt)
end

function hiscorestate:drawScores(xoff,scores)
	-- display high scores
	local s = scores
	lg.setFont(rsc.menuFont)
	lg.setColor(self.scoreColor)
	lg.printf(s.title,xoff,self.scoreTitreY,SW,"center")
	for i,sc in ipairs(s) do
		if sc.last then
			lg.setColor(self.scoreSelectColor)
		else
			lg.setColor(self.scoreColor)
		end
		lg.print(i,self.scoreX[1]+xoff,self.scoreY[i])
		lg.print(sc.name,self.scoreX[2]+xoff,self.scoreY[i])
		lg.printf(s.fmt(sc.score),self.scoreX[3]+xoff,self.scoreY[i],self.scoreLastW,"right")
	end
	
	lg.setColor(self.scoreSelectColor)
	lg.print("LAST SCORE",self.scoreX[1]+xoff,self.scoreY[#s+1])
	lg.printf(s.fmt(s.lastScore),self.scoreX[3]+xoff,self.scoreY[#s+1],self.scoreLastW,"right")

end

function hiscorestate:draw()
	for _,s in ipairs(self.demoSnakes) do
		s:draw()
	end
	
	--self.selectSnake:draw()
	lg.setColor(self.titreBgColor)
	lg.rectangle('fill',unpack(self.titreRectangle))
	lg.setColor(self.titreFgColor)
	lg.setFont(rsc.titleFont)
	lg.printf(self.titre,0,self.titreY,SW,"center")

	if self.showMessage then
		lg.setColor({255,255,255})
		lg.setFont(rsc.font)
		lg.printf(self.message,0,self.messageY,SW,"center")
	end
	
	-- display high scores
	self:drawScores(self.currentXOff,self.currentScores)
	if self.currentXOff > 0 then
		self:drawScores(self.currentXOff-SW,self.oldScores)
	end
	
end


function hiscorestate:keypressed(key)
	reset()
end

function gameoverstate:init()

	self.message="PRESS ANY KEY TO PLAY"
	self.messageY = SH - 1.5*rsc.font:getHeight()
	self.y = (SH-rsc.font:getHeight())/2
		
end

function gameoverstate:enter()
	events.clean()
	self.showMessage=true
	
	self.hscores={}
	self.text="GAME OVER\nFINAL SCORE : "..score.value().."\n\n"

	self.enterName=false
	if score.setLastScore() then
		love.keyboard.setTextInput(true)
		self.text = self.text .. "HIGH SCORE - PLEASE ENTER NAME"
		self.enterName=true
		self.name = Highscore.getPlayerName()
	else
		events.addEvent(0.5,self,self.flipMessage)
		events.addEvent(3,self,self.startDemo)
		self.text = self.text .. "NO HIGH SCORE - TRY AGAIN"
	end
	
end

function gameoverstate:startDemo()
	state = hiscorestate
	state:enter()
end

function gameoverstate:flipMessage()
	self.showMessage = not self.showMessage
	events.addEvent(0.5,self,self.flipMessage)
end

function gameoverstate:update(dt)
	events.update(dt)
end

function gameoverstate:draw()
	playstate:draw()
	lg.setColor({255,255,255})
	lg.setFont(rsc.titleFont)
	lg.printf(self.text,0,100,SW,"center")
	if self.enterName then
		lg.setColor({0,0,196,128})
		local fh = rsc.titleFont:getHeight()
		local fw = rsc.titleFont:getWidth(self.name.."_")+30
		lg.rectangle('fill',(SW-fw)/2,self.y-fh*0.25,fw,fh*1.5)
		lg.setColor({255,0,0})
		lg.printf(self.name.."_",0,self.y,SW,"center")
	elseif self.showMessage then
		lg.setFont(rsc.font)
		lg.printf(self.message,0,self.messageY,SW,"center")
	end
end

function gameoverstate:keypressed(key)
	if self.enterName then
		if key == "backspace" then
			if #self.name > 0 then
				self.name=string.sub(self.name,1,-2)
			end
		elseif key == "return" then
			score.recordHighScore(self.name)
			state=hiscorestate
			state:enter()
		end
	else
		reset()
	end
end

function gameoverstate:textinput(unicode)
	if self.enterName then
		local ch = string.upper(unicode)
	    if (ch>="A" and ch<="Z" ) or (ch>="0" and ch <="9") then
			if #self.name < 8 then
				self.name = self.name .. ch
			end
		end
	else
		reset()
	end
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
	lg.draw(rsc.bgCanvas,0,0)
	state:draw(dt)
	
	lg.setFont(rsc.menuFont)
	lg.setColor({255,255,255})
	lg.print(love.timer.getFPS( ),0,SH-20)

end
--
function love.keypressed(key)
	state:keypressed(key)
end
--
function love.textinput(unicode)
	if state.textinput then
		state:textinput(unicode)
	end
end
--]]