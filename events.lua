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
 
local function up(heap,j)
	while true do
		local i = math.floor(j/2) -- parent node
		if i == 0 or heap[i] <= heap[j] then
			break
		end
		local t = heap[i]
		heap[i]=heap[j]
		heap[j]=t
		j=i
	end
end

local function down(heap,i,n)
	local j,j1,j2
	while true do
		j1 = 2*i
		if j1 > n then
			break
		end
		j = j1 -- left child
		j2 = j1 + 1
		if j2 <= n and heap[j1] > heap[j2] then
			j = j2 -- right child
		end
		if heap[i] <= heap[j] then
			break
		end
		
		local t = heap[i]
		heap[i] = heap[j]
		heap[j] = t
		
		i = j
	end
end

local function push(heap,elem)
	table.insert(heap,elem)
	up(heap,#heap)
end

local function pop(heap)
	
	local t = heap[1]
	heap[1]=heap[#heap]
	heap[#heap]=t
	
	down(heap,1,#heap-1)
	return table.remove(heap)
end


local next_event_id = 1

local evt_metatable = {
	__lt = function (a,b) return a.time < b.time end,
	__le = function (a,b) return a.time <= b.time end,
	__call= function(evt)
		local obj = evt.object
		if obj then
			if obj.events and obj.events[evt.event_id] then
				obj.events[evt.event_id]=nil
				evt.func(obj,unpack(evt.args))
			end
		else
			evt.func(unpack(evt.args))
		end
	end
}

local methods={}

function methods:addEvent(delay,obj,func,...)
	local eid = next_event_id
	next_event_id = next_event_id + 1
	local evt = setmetatable({
		time = delay + self.time, 
		object = obj,
		func = func,
		event_id = eid,
		args = {...}},evt_metatable)
	if obj then
		if obj.events then
			obj.events[eid]=1
		else
			obj.events = {[eid]=1}
		end
	end
	push(self.heap,evt)
end

function methods:update(dt)
	local ctime = self.time + dt
	local heap = self.heap
	while #heap > 0 and heap[1].time < ctime do
		local evt = pop(heap)
		evt(evt.object,unpack(evt.args))
	end
	self.time = ctime
	
end

function methods:clean()
	self.heap={}
end

local function newEventsManager ()
	local evmgr={}
	for k,v in pairs(methods) do
		evmgr[k]=v
	end
	evmgr.heap={}
	evmgr.time=0
	return evmgr
end

return newEventsManager
