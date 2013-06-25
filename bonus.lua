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

local rsc=require 'resources'
local fruit_color_prehide={196,15,15}
local fruit_color={196,196,15}
local heart_color={196,196,196,196}
local fruit_radius=8

-- vertical speed of number (pixel/s)
local vspeed=100
local fmethods={}

function fmethods:draw()
	lg.setColor(self.color)
	lg.circle('fill',self.x,self.y,self.r,32)
end

function fmethods:genEvent(evmgr,hb,x,y,r) 
	if intersect(self.hbox,	hb) then
		local fx,fy,fr = self.x,self.y,self.r
		local d = (x-fx)*(x-fx)+(y-fy)*(y-fy)
		if d < (r+fr)*(r+fr) then
			-- intersect !!
			local score = (self.mature and 100) or 50
			--table.insert(self.scores,{x=fx,y=fy,t=string.format("%d",score),c=self.color})
			table.insert(self.scores,{x=fx,y=fy,t=string.format("%d",score),fade=0})
			self:invalid(evmgr)
			return {"FRUIT",score}
		end
	end
end

function fmethods:show(evmgr)
	if not self.sleep then
		self.color=fruit_color
		local x,y,r = math.random(SW*0.1,SW*0.9),math.random(SH*0.1,SH*0.9),math.random(8,16)
		self.hbox = {x-r,y-r,x+r,y+r}
		self.x=x
		self.y=y
		self.r=r
		self.valid=true
		self.mature=false
		evmgr:addEvent(math.random(5,8),self,self.prehide,evmgr)
	end
end

function fmethods:prehide(evmgr)
	if self.sleep then
		self:invalid()
	else
		self.color=fruit_color_prehide
		self.mature=true
		evmgr:addEvent(2,self,self.invalid,evmgr)
	end
end

function fmethods:invalid(evmgr)
		self.valid=nil
		self.events={}
		if not self.sleep then
			evmgr:addEvent(math.random(1,3),self,self.show,evmgr)
		end
end

local methods={}

function methods:sleep()
	for _,f in ipairs(self.fruits) do
		f.sleep=true
	end
end

function methods:wakeup(evmgr)
	for _,f in ipairs(self.fruits) do
		f.sleep=nil
		if not f.valid then
			f:invalid(evmgr)
		end
	end
end

function methods:update(dt)
	
end

function methods:draw()
	for _,f in ipairs(self.fruits) do
		if f.valid then
			f:draw()
		end
	end
	lg.setFont(rsc.tinyFont)
	--[[
	for _,s in ipairs(self.scores) do
		lg.setColor(s.c)
		lg.print(s.t,s.x,s.y)
	end
	--]]
	for _,s in ipairs(self.scores) do
		lg.setColor({255,255,255,255-s.fade})
		lg.print(s.t,s.x,s.y)
	end
	
end

function methods:update(dt)

	local toRemove={}
	for i,s in ipairs(self.scores) do
		s.y = s.y - vspeed * dt
		if s.y < -20 then
			table.insert(toRemove,i)
		else
			s.fade = s.fade + 128*dt
			if s.fade > 255 then
				table.insert(toRemove,i)
			end
		end
		
	end

	if #toRemove then
		for ii = #toRemove,1,-1 do
			table.remove(self.scores,toRemove[ii])
		end
	end

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
	bmgr.scores={}
	for i=1,maxFruits do
		local f=setmetatable({scores=bmgr.scores},{__index=fmethods})
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