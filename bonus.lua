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

local events=require 'events'
local rsc=require 'resources'

local fruit_color_prehide={196,100,15}
local fruit_color={196,196,15}
local fruit_radius=8

-- vertical speed of number (pixel/s)
local vspeed=100
local fmethods={}

function fmethods:draw()
	local percent = self.clock()/self.lifetime
	lg.setColor(196,196 - 196 *percent,15)
	local x,y,r=self.x,self.y,self.r
	lg.draw(rsc.vitamins[r],x-r,y-r)
end

function fmethods:genEvent(hb,x,y,r) 
	if intersect(self.hbox,	hb) then
		local fx,fy,fr = self.x,self.y,self.r
		local d = (x-fx)*(x-fx)+(y-fy)*(y-fy)
		if d < (r+fr)*(r+fr) then
			-- intersect !!
			local sf = (16-self.r)/8
			local score = math.floor((self.clock()/self.lifetime * 50 + 50) * (1+sf) )
			table.insert(self.scores,{x=fx,y=fy,t=string.format("%d",score),fade=0})
			self:invalid()
			return {"FRUIT",score}
		end
	end
end

function fmethods:show()
	if not self.sleep then
		
		local room = table.remove(self.rooms,math.random(1,#self.rooms))
		local x = math.random(room.xmin,room.xmax)
		local y = math.random(room.ymin,room.ymax)
		local r = math.random(8,16)
		self.room = room
		self.hbox = {x-r,y-r,x+r,y+r}
		self.x=x
		self.y=y
		self.r=r
		self.valid=true
		self.lifetime = math.random(5,8)+2
		events.addEvent(self.lifetime,self,self.invalid)
		self.clock = events.clock()
	end
end


function fmethods:invalid()
		table.insert(self.rooms,self.room)
		self.room=nil
		self.valid=nil
		self.events={}
		if not self.sleep then
			events.addEvent(math.random(1,3),self,self.show)
		end
end

local methods={}

function methods:sleep()
	for _,f in ipairs(self.fruits) do
		f.sleep=true
	end
end

function methods:wakeup()
	for _,f in ipairs(self.fruits) do
		f.sleep=nil
		if not f.valid then
			f:invalid()
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
	local hbox={x-r,y-r,x+r,y+r}
	for _,f in ipairs(self.fruits) do
		local e = f.valid and f:genEvent(hbox,x,y,r)
		if e then
			table.insert(events,e)
		end
	end
	return events
end

function methods:genCollision(x,y,r)
	local hbox={x-r,y-r,x+r,y+r}
	for _,f in ipairs(self.fruits) do
		if f.valid and intersect(f.hbox,hbox) then
			local fx,fy,fr = f.x,f.y,f.r
			local d2 = (x-fx)*(x-fx)+(y-fy)*(y-fy)
			if d2 < (r+fr)*(r+fr) then
				-- INTERSECT !
				local d=math.sqrt(d2)
				local h=(r+fr-d)/(r+fr)
				return (x-fx)*h,(y-fy)*h
			end
		end
	end
	return nil	
end

local function newBonusManager(maxFruits)
	local bmgr = {}
	for k,v in pairs(methods) do
		bmgr[k] = v
	end
	bmgr.fruits={}
	bmgr.scores={}
	
	bmgr.rooms={}
	
	local n=2
	while n*n < maxFruits do n=n+1 end
	local w = 0.8*SW/n
	local h = 0.8*SH/n
	
	for x=0,n-1 do
		for y=0,n-1 do
			local room = {xmin = 0.1*SW + x * w, ymin = 0.1*SH+y*h,xmax = 0.1*SW + x * w + w, ymax = 0.1*SH+y*h+h, }
			table.insert(bmgr.rooms,room)
		end	
	end
	
	bmgr.cells = {}
	for x=1,n do
		bmgr.cells[x]={}
		for y=1,n do
			bmgr.cells[x][y]={}
		end
	end
	
	for i=1,maxFruits do
		local f=setmetatable({scores=bmgr.scores,rooms=bmgr.rooms,cells=bmgr.cells},{__index=fmethods})
		if math.random(1,2) == 1 then
			f:invalid()
		else
			f:show()
		end
		bmgr.fruits[i]=f
	end
	
	return bmgr
end

return newBonusManager