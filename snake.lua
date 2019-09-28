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
local lg=love.graphics
local abs=math.abs
local rsc=require 'resources'
local events=require 'events'
local methods={}

local max_move=10

local waitkeycount=5
local snakeradius = 7
local refdist = 2*7+4

local active_bodyColor={50/255,196/255,50/255}
local active_headColor={1,1,0.5}

local sleep_bodyColor={50/255,196/255,50/255,0.5}
local sleep_headColor={1,1,0.5,0.5}

-- for computing sqrt with "alpha max + beta min" method
local alpha=0.96043387
local beta=0.39782473

local default={
	speed=250,
	angspeed = 5/4*math.pi, 
	bodyColor=active_bodyColor,
	headColor=active_headColor,
	snakeRadius=7,
    refdist=2*7 + 2,
	move=0,
	dir=0,
	dx=1,
	dy=0,
	x=0,
	y=0,
	waitcount=waitkeycount,
}

function methods:sleep()
	self.bodyColor=sleep_bodyColor
	self.headColor=sleep_headColor
end

function methods:wakeup()
	self.bodyColor=active_bodyColor
	self.headColor=active_headColor
end

function methods:plot(i,x,y,color)
	self.batch:setColor(unpack(color))
	if self.bid[i] then
		self.batch:set(self.bid[i],x-snakeradius,y-snakeradius)
	else
		self.bid[i] = self.batch:add(x-snakeradius,y-snakeradius)
	end
end

function methods:draw_batch()
	lg.draw(self.batch,0,0)
end

function methods:playerPilot(dt)
	local newDir=nil
	self.waitcount = self.waitcount - dt
	if love.keyboard.isDown("left","a") then
		self.waitcount = waitkeycount
		newDir = self.dir - self.angspeed * dt
	elseif love.keyboard.isDown("right","d") then
		self.waitcount = waitkeycount
		newDir = self.dir + self.angspeed * dt
	end
	return newDir
end

function methods:autoPilot(dt)
	local newDir=nil
	local dir = self.dir
	local u = self.wantedDir - dir
	local da = math.min(abs(u),self.angspeed * dt)
	if da > 0 then
		if u>0 then
			newDir = dir + da
		else
			newDir = dir - da
		end
	end
	return newDir
end

function methods:computeWantedDir()

	-- normalize angle between -pi .. pi
	local dir = self.dir
	while dir > math.pi do
		dir = dir - 2*math.pi
	end
	while dir < -math.pi do
		dir = dir + 2*math.pi
	end
	self.dir = dir

	local x,y = self.x,self.y
	local wd = math.atan2(math.random(SH*0.1,SH*0.9)-y,math.random(SW*0.1,SW*0.9)-x)
	local dd = wd-dir
	if abs(dd) > abs(dd+2*math.pi) then
		wd = wd + 2*math.pi
	elseif abs(dd) > abs(dd-2*math.pi) then
		wd = wd - 2*math.pi
	end
	self.wantedDir = wd
	events.addEvent(0.5 * math.random(1,5),self,self.computeWantedDir)
end

function methods:setAutoPilot()
	self.noCheckSelfHit=true
	self.wantedDir=0
	self.pilot=self.autoPilot
	self:computeWantedDir()
end


function methods:update(dt)
	--local snakeradius = self.snakeRadius
	--local refdist = self.refdist
	local newDir = self:pilot(dt)
	local fcollision = self.fcollision
	
	if newDir then
		self.dx = math.cos(newDir)
		self.dy = math.sin(newDir)
		self.dir = newDir
	end

	local d = self.speed * dt
	
	local dx = self.dx * d
	local dy = self.dy * d

	local x,y = self.x + dx, self.y + dy
	if x < 0 then
		x = x + SW
	elseif x>SW then
		x = x - SW
	end
	if y < 0 then
		y = y + SH
	elseif y>SH then
		y = y - SH
	end
	self.x=x
	self.y=y
	local xv,yv=x,y
	local xh,yh=x,y
	
	--self.batch:bind()
	self:plot(1,self.x,self.y,self.headColor)
	
	
	local dmin=2*snakeradius
	local dmin2=dmin*dmin
	
	local lastx,lasty = 0,0
	local is=2
	--self.visucoord={}
	local hitByHead=0
	if self.noCheckSelfHit then
		hitByHead=1
	end
	while is <= #self do
		x,y = self[is][1],self[is][2]
		x = x - dx
		y = y - dy

		local ux = abs(x-lastx)
		local uy = abs(y-lasty)
		local nd=0
		if ux > uy then
			nd=alpha*ux+beta*uy
		else
			nd=alpha*uy+beta*ux
		end
		--local nd = math.sqrt((x-lastx)*(x-lastx)+(y-lasty)*(y-lasty))
		if nd > refdist then
			local k = 1 - refdist/nd
			x = x + (lastx-x) * k
			y = y + (lasty-y) * k
		end
		
		-- determine screen coordinates
		xv=xv+(x-lastx)
		yv=yv+(y-lasty)
		if xv < 0 then
			xv = xv + SW
		elseif xv>SW then
			xv = xv - SW
		end
		if yv < 0 then
			yv = yv + SH
		elseif yv>SH then
			yv = yv - SH
		end
		--table.insert(self.visucoord,{xv,yv})
		-- determine collision with vitamin/fruit
		if fcollision then
			local hx,hy = fcollision(xv,yv,snakeradius)
			if hx then
				xv = xv+hx
				yv = yv+hy
				x = x + hx
				y= y + hy
			end
		end
		
		self:plot(is,xv,yv,self.bodyColor)

		-- determine if collision with head
		if hitByHead<1 and is>4 then
			ux = abs(xv-xh)
			uy = abs(yv-yh)
			if ux < dmin and uy < dmin and ux*uy < dmin2 then
				hitByHead=is
			end
		end
		
		
		lastx=x
		lasty=y
	
		self[is][1] = lastx
		self[is][2] = lasty
		is = is + 1
	end

	--self.batch:unbind()

	
	self.hitByHead=hitByHead
end

function methods:cellhitbox(icell) 
	--local snakeradius = self.snakeRadius
	local x,y=self[icell][1] + self.x,self[icell][2] + self.y
	return {x-snakeradius,y-snakeradius,x+snakeradius,y+snakeradius}
end

function methods:getDisk(icell)
	return self[icell][1]+self.x,self[icell][2]+self.y,snakeradius
end

function methods:selfhit()
	return self.hitByHead > 0
end

function methods:addRing()
	local lastCell = self[#self]
	table.insert(self,{lastCell[1],lastCell[2]})
end

local function newSnake(x,y,len)
	local s = {}
	for k,v in pairs(methods) do
		s[k]=v
	end
	for k,v in pairs(default) do
		s[k]=v
	end
	s.x=x
	s.y=y
	s.pilot = s.playerPilot
	local is = 2
	s[1]={0,0}
	while is <= len do
		s[is]={-s.refdist,0}
		is = is + 1
	end
	
	s.batch=lg.newSpriteBatch(rsc.snake[snakeradius],1000,'stream')
	s.bid={}
	
	s.draw=s.draw_batch
	return s
end

return newSnake
