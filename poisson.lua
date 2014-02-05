--[[
Copyright (c) 2014 Romain Meynet

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

--[[
Generator of Poisson disks

Generate a distribution of point with a minimum distance between any couple of those points.

The algorithm is described here : http://people.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf

--]]

local methods = {}
local floor = math.floor


function methods:getGridCoord(x,y)
	local sz = self.cellSize
	return floor(x/sz) + 1, math.floor(y/sz) + 1
end

function methods:init()
	self.cells={}
	local cellSize = self.radius / math.sqrt(2)
	local gridHeight = math.ceil(self.height/cellSize)
	local gridWidth = math.ceil(self.width/cellSize)
	for x = 1,gridWidth do
		local col = {}
		for y= 1, gridHeight do
			col[y]=0
		end
		self.cells[x]=col
	end
	self.cellSize = cellSize
	self.gridHeight = gridHeight
	self.gridWidth = gridWidth
	self.radius2 = self.radius * self.radius
	self.points={}
	self.actives={}
	
end

function methods:testAgainst(p,gx,gy)
	if gx < 1 or gy < 1 or gx > self.gridWidth or gy > self.gridHeight then
		return true
	end
	local pid = self.cells[gx][gy]
	if pid >0 then
		local tp = self.points[pid]
		local ux = p.x - tp.x
		local uy = p.y - tp.y
		return (ux*ux + uy * uy > self.radius2)
	else
		return true
	end
end

function methods:testPoint(p)
	if p.x<0 or p.x > self.width or p.y< 0 or p.y>self.height then
		return false
	end

	local gx,gy = self:getGridCoord(p.x,p.y)
	if self.cells[gx][gy]>0 then return false end

	if not self:testAgainst(p,gx,gy-1) then return false end
	if not self:testAgainst(p,gx,gy+1) then return false end

	if not self:testAgainst(p,gx+1,gy) then return false end
	if not self:testAgainst(p,gx+1,gy-1) then return false end
	if not self:testAgainst(p,gx+1,gy+1) then return false end
	
	if not self:testAgainst(p,gx-1,gy) then return false end
	if not self:testAgainst(p,gx-1,gy-1) then return false end
	if not self:testAgainst(p,gx-1,gy+1) then return false end

	if not self:testAgainst(p,gx+2,gy) then return false end
	if not self:testAgainst(p,gx+2,gy-1) then return false end
	if not self:testAgainst(p,gx+2,gy+1) then return false end

	if not self:testAgainst(p,gx-2,gy) then return false end
	if not self:testAgainst(p,gx-2,gy-1) then return false end
	if not self:testAgainst(p,gx-2,gy+1) then return false end
	
	if not self:testAgainst(p,gx,gy-2) then return false end
	if not self:testAgainst(p,gx+1,gy-2) then return false end
	if not self:testAgainst(p,gx-1,gy-2) then return false end

	if not self:testAgainst(p,gx,gy+2) then return false end
	if not self:testAgainst(p,gx+1,gy+2) then return false end
	if not self:testAgainst(p,gx-1,gy+2) then return false end
	
	return true
		
end

function methods:addPoint(p)
	local gx,gy = self:getGridCoord(p.x,p.y)
	table.insert(self.points,p)
	local idx = #self.points
	self.cells[gx][gy] = idx
	table.insert(self.actives,idx)
end

function methods:generate()
	local pt = { x = math.random() * self.width, y = math.random() * self.height }
	self:addPoint(pt)
	
	while #self.actives > 0 do
		local ida = math.random(1,#self.actives)
		local pt = self.points[self.actives[ida]]
		local deadPoint = true
		for i=1,self.nbTries do
			local ang = 2 * math.pi * math.random()
			local dist = (1 + math.random())*self.radius
			local np = {x = pt.x + dist * math.cos(ang), y=pt.y+dist*math.sin(ang)}
			if self:testPoint(np) then
				self:addPoint(np)
				deadPoint=false
			end
		end
		if deadPoint then
			table.remove(self.actives,ida)
		end
	end
	
end

local function genDisks(width,height,radius,nbTries) 
	nbTries = nbTries or 30
	local generator = setmetatable({width=width,height=height,radius=radius,nbTries=nbTries},{__index=methods})
	generator:init()
	generator:generate()
	return generator.points
end

return genDisks