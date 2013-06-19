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

local fruit_color_prehide={196,15,15}
local fruit_color={196,196,15}
local heart_color={196,196,196,196}
local fruit_radius=8

local fmethods={}

function fmethods:draw()
	love.graphics.setColor(self.color)
	love.graphics.circle('fill',self.x,self.y,self.r,32)
end

function fmethods:genEvent(evmgr,hb,x,y,r) 
		if intersect(self.hbox,	hb) then
			local fx,fy,fr = self.x,self.y,self.r
			local d = (x-fx)*(x-fx)+(y-fy)*(y-fy)
			if d < (r+fr)*(r+fr) then
				-- intersect !!
				self:invalid(evmgr)
				return "FRUIT"
			end
		end

end

function fmethods:show(evmgr)
	self.color=fruit_color
	local x,y,r = math.random(SW*0.1,SW*0.9),math.random(SH*0.1,SH*0.9),math.random(8,16)
	self.hbox = {x-r,y-r,x+r,y+r}
	self.x=x
	self.y=y
	self.r=r
	self.valid=true
	evmgr:addEvent(math.random(5,8),self,self.prehide,evmgr)
end

function fmethods:prehide(evmgr)
	self.color=fruit_color_prehide
	evmgr:addEvent(2,self,self.invalid,evmgr)
end

function fmethods:invalid(evmgr)
		self.valid=nil
		self.events={}
		evmgr:addEvent(math.random(1,3),self,self.show,evmgr)
end

local methods={}

function methods:update(dt)

end

function methods:draw()
	for _,f in ipairs(self.fruits) do
		if f.valid then
			f:draw()
		end
	end
end

function methods:update(dt)

end

function methods:genEvents(x,y,r)
	local events={}
	local evmgr=self.evmgr
	local hbox={x-r,y-r,x+r,y+r}
	for _,f in ipairs(self.fruits) do
		local e = f.valid and f:genEvent(evmgr,hbox,x,y,r)
		if e then
			table.insert(events,e)
		end
	end
	return events
end

local function newBonusManager(evmgr,maxFruits)
	local bmgr = {}
	for k,v in pairs(methods) do
		bmgr[k] = v
	end
	bmgr.evmgr=evmgr
	bmgr.fruits={}

	for i=1,maxFruits do
		local f=setmetatable({},{__index=fmethods})
		if math.random(1,4) == 1 then
			f:invalid(evmgr)
		else
			f:show(evmgr)
		end
		bmgr.fruits[i]=f
	end
	
	return bmgr
end



return newBonusManager