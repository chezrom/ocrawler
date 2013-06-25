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

local Events = require 'events'
local Snake = require 'snake'
local Bonus = require 'bonus'
local Highscore = require 'highscore'
local rsc = require 'resources'

local score_future_color={255,0,0}
local score_color={255,255,255}

local snake={}
local score={}
local evmgr={}
local bmgr={}

local state=nil
local playstate={}
local gameoverstate={}
local pausestate={}
local hiscorestate={}

local fminute_fmttime = "FIRST MINUTE : %02d s"
local fminute_fmtscore = "FIRST MINUTE : %5d"

function score:reset()
	self.events={}
	self.value=0
	self.future=0
	self:add(0,true)

	self.length=10
	--
	self.mtime=60
	self.mdisplay=string.format(fminute_fmttime,self.mtime)
	self.mhscore=false
	self.mscore=0
	
	self.hscores={}
	
	evmgr:addEvent(1,score,score.secondTick)
	
end

function score:grow(incr)
	self.length = self.length+incr
	evmgr:addEvent(5,self,self.add,math.floor(self.length/10),true,4)
	self:addFuture(math.floor(self.length/10)*5)
end

function score:setFirstMinuteScore() 
	self.mscore = self.value
	self.mdisplay = string.format(fminute_fmtscore,self.mscore)
	self.mhscore = Highscore.setLastScore('firstminute',self.value)
	if self.mhscore then
		self.mdisplay = self.mdisplay .. " (HS)"
	end
end

function score:setLastScore()
	self.hscores={}
	if self.mtime > 0 then
		self:setFirstMinuteScore()
	end
	if self.mhscore then
		table.insert(self.hscores,{listname='firstminute',score=self.mscore})
	end
	if Highscore.setLastScore('freegame',self.value) then
		table.insert(self.hscores,{listname='freegame',score=self.value})
	end
	return #self.hscores>0
end

function score:recordHighScore(name)
	for _,hsr in ipairs(self.hscores) do
		Highscore.recordHighScore(hsr.listname,hsr.score,name)
	end
end

function score:secondTick()
	self.mtime = self.mtime - 1
	if self.mtime > 0 then
		self.mdisplay=string.format(fminute_fmttime,self.mtime)
		evmgr:addEvent(1,score,score.secondTick)
	else
		self:setFirstMinuteScore()
	end
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
	lg.setFont(rsc.font)
	lg.setColor(score_color)
	lg.print(self.string,0,0)

	lg.print(#snake,0,30)

	lg.setColor(score_future_color)
	lg.print(self.fstring,100,0)
	lg.setColor({196,196,196})
	lg.print(self.mdisplay,500,0)
end

function love.load()
	SW,SH = lg.getWidth(), lg.getHeight()
	rsc.load()
	Highscore.init()
	gameoverstate:init()
	hiscorestate:init()
    evmgr=Events()		
	state=hiscorestate
	state:enter()
end

function reset()
	state=playstate
	playstate.sleep=false
	
	
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
				score:add(e[2])
				snake:addRing()
				score:grow(1)
			end
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
	self.showMessage=true
	evmgr:clean()
	evmgr:addEvent(0.5,self,self.flipMessage)
	for _,s in ipairs(self.demoSnakes) do
		s:setAutoPilot(evmgr)
		s.speed = math.random(200,300)
	end
	self.listNames=Highscore.getListNames()
	self.iListe=1
	self.currentScores = Highscore.getHighScores(self.listNames[self.iListe])
	self.currentXOff = 0
	evmgr:addEvent(5,self,self.nextHighscoreList)
end

function hiscorestate:nextHighscoreList()
	self.iListe = self.iListe + 1
	if self.iListe > #self.listNames then
		self.iListe=1
	end
	self.oldScores = self.currentScores
	self.currentScores = Highscore.getHighScores(self.listNames[self.iListe])
	self.currentXOff=SW
	evmgr:addEvent(5,self,self.nextHighscoreList)
end

function hiscorestate:flipMessage()
	self.showMessage = not self.showMessage
	evmgr:addEvent(0.5,self,self.flipMessage)
end

function hiscorestate:update(dt)
	if self.currentXOff > 0 then
		self.currentXOff= self.currentXOff - SW/2*dt
	else
		self.currentXOff=0
	end
	evmgr:update(dt)
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
		lg.printf(sc.score,self.scoreX[3]+xoff,self.scoreY[i],self.scoreLastW,"right")
	end
	
	lg.setColor(self.scoreSelectColor)
	lg.print("LAST SCORE",self.scoreX[1]+xoff,self.scoreY[#s+1])
	lg.printf(s.lastScore,self.scoreX[3]+xoff,self.scoreY[#s+1],self.scoreLastW,"right")

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
	evmgr:clean()
	self.showMessage=true
	
	self.hscores={}
	self.text="GAME OVER\nFINAL SCORE : "..score.value.."\n\n"
		

	self.enterName=false
	if score:setLastScore() then
		self.text = self.text .. "HIGH SCORE - PLEASE ENTER NAME"
		self.enterName=true
		self.name = Highscore.getPlayerName()
	else
		evmgr:addEvent(0.5,self,self.flipMessage)
		evmgr:addEvent(3,self,self.startDemo)
		self.text = self.text .. "NO HIGH SCORE - TRY AGAIN"
	end
end

function gameoverstate:startDemo()
	state = hiscorestate
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

function gameoverstate:keypressed(key,unicode)
	if self.enterName then
		if key == "backspace" then
			if #self.name > 0 then
				self.name=string.sub(self.name,1,-2)
			end
		elseif key == "return" then
			score:recordHighScore(self.name)
			state=hiscorestate
			state:enter()
		elseif unicode > 31 and unicode < 127 then
			local ch = string.upper(string.char(unicode))
		    if (ch>="A" and ch<="Z" ) or (ch>="0" and ch <="9") then
				if #self.name < 8 then
					self.name = self.name .. ch
				end
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
	state:draw(dt)
end
--
function love.keypressed(key,unicode)
	state:keypressed(key,unicode)
end
--]]