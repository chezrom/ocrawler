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

local methods={}

local max_move=10

local default={
	speed=250,
	--angspeed = math.pi, 
	angspeed = 5/4*math.pi, 
	bodyColor={50,196,50},
	headColor={196,196,50},
	snakeRadius=7,
    refdist=2*7 + 2,
	move=0,
	dir=0,
	dx=1,
	dy=0,
}

local snakeradius = 7
local refdist = 2*7+4

function methods:draw()
	--local snakeradius=self.snakeRadius
	local coord 
	love.graphics.setColor(self.bodyColor)
	for i=#self,2,-1 do
		coord=self[i]
		love.graphics.circle('fill',coord[1],coord[2],snakeradius,16)
	end
	coord=self[1]
	love.graphics.setColor(self.headColor)
	love.graphics.circle('fill',coord[1],coord[2],snakeradius,16)
end

function methods:playerPilot(dt)
	local newDir=nil
	if love.keyboard.isDown("left") then
		newDir = self.dir - self.angspeed * dt
	elseif love.keyboard.isDown("right") then
		newDir = self.dir + self.angspeed * dt
	end
	return newDir
end

function methods:autoPilot(dt)
	local newDir=nil
	local dir = self.dir
	local u = self.wantedDir - dir
	local da = math.min(math.abs(u),self.angspeed * dt)
	if da > 0 then
		if u>0 then
			newDir = dir + da
		else
			newDir = dir - da
		end
	end
	return newDir
end

function methods:computeWantedDir(evmgr)

	-- normalize angle between -pi .. pi
	local dir = self.dir
	while dir > math.pi do
		dir = dir - 2*math.pi
	end
	while dir < -math.pi do
		dir = dir + 2*math.pi
	end
	self.dir = dir

	local x,y = self[1][1],self[1][2]
	local wd = math.atan2(math.random(SH*0.1,SH*0.9)-y,math.random(SW*0.1,SW*0.9)-x)
	local dd = wd-dir
	if math.abs(dd) > math.abs(dd+2*math.pi) then
		wd = wd + 2*math.pi
	elseif math.abs(dd) > math.abs(dd-2*math.pi) then
		wd = wd - 2*math.pi
	end
	self.wantedDir = wd
	evmgr:addEvent(0.5 * math.random(1,5),self,self.computeWantedDir,evmgr)
end

function methods:setAutoPilot(evmgr)
	self.wantedDir=0
	self.pilot=self.autoPilot
	self:computeWantedDir(evmgr)
end

function methods:update(dt)

	--local snakeradius = self.snakeRadius
	--local refdist = self.refdist
	local newDir = self:pilot(dt)
	
	if newDir then
		self.dx = math.cos(newDir)
		self.dy = math.sin(newDir)
		self.dir = newDir
	end

	--[[
	self.move = self.move + self.speed * dt
	if self.move <1 then
		return
	end
	local d = math.min(math.floor(self.move),max_move)
	self.move = self.move - d
	--]]
	local d = self.speed * dt
	
	local dx = self.dx * d
	local dy = self.dy * d
	local lastx,lasty
	local is=1
	local first=true
	while is <= #self do
		local x,y = self[is][1],self[is][2]
		if first then
			lastx = x + dx
			lasty = y + dy
			first=nil
		else
			--
			local nd = math.sqrt((x-lastx)*(x-lastx)+(y-lasty)*(y-lasty))
			if nd > refdist then
				local k = 1 - refdist/nd
				x = x + (lastx-x) * k
				y = y + (lasty-y) * k
			end
			--]]
			lastx=x
			lasty=y
		end
		self[is][1] = lastx
		self[is][2] = lasty
		is = is + 1
	end
end

function methods:cellhitbox(icell) 
	--local snakeradius = self.snakeRadius
	local x,y=self[icell][1],self[icell][2]
	return {x-snakeradius,y-snakeradius,x+snakeradius,y+snakeradius}
end

function methods:getDisk(icell)
	return self[icell][1],self[icell][2],snakeradius
end

function methods:selfhit()
	local xh,yh = self[1][1],self[1][2]
	local hhb = self:cellhitbox(1)
	local dmin = snakeradius*snakeradius*4
	for is = 3,#self do
		if intersect(self:cellhitbox(is),hhb) then
			local xc,yc = self[is][1],self[is][2]
			local d = (xh-xc)*(xh-xc) + (yh-yc)*(yh-yc)
			if d < dmin then
				return true
			end
		end
	end
	return false
end

function methods:isOut()
	local x,y = self[1][1],self[1][2]
	return x<0 or x > SW or y<0 or y>SH
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
	s.pilot = s.playerPilot
	local is = 1
	while is <= len do
		s[is]={x,y}
		x = x - s.refdist
		is = is + 1
	end

	return s
end

return newSnake