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
local Highscore = require 'highscore'
local events = require 'events'
local rsc = require 'resources'

local score={}


local score_future_color={255,0,0}
local score_color={255,255,255}

local fminute_fmtscore = "FIRST MINUTE : %5d"
local gtime_fmt = "%2d:%02d"
local slength_fmt = "L %3d"
local l100_fmt = "100@%d:%02d"

local value,future
local vstring,fstring
local length=0
local lendisplay,mdisplay,mhscore,mscore,tdisplay,tnext
local l100display,l100score,l100hs

local hscores,gclock,fmclock

local function setFirstMinuteScore() 
	mscore = value
	mdisplay = string.format(fminute_fmtscore,mscore)
	mhscore = Highscore.setLastScore('firstminute',value)
	if mhscore then
		mdisplay = mdisplay .. " (HS)"
	end
end

function score.reset()
	value=0
	future=0
	score.add(0,true)

	length=10
	lendisplay=string.format(slength_fmt,length)
	mdisplay=""
	mhscore=false
	mscore=0

	tdisplay=string.format(gtime_fmt,0,0)
	tnext=1

	l100display=""
	l100score=20*60
	l100hs = Highscore.setLastScore('len100',l100score)
	
	hscores={}
	
	gclock=events.clock()
	fmclock=events.rclock(60,setFirstMinuteScore)


end


function score.grow(incr)
	length = length+incr
	lendisplay=string.format(slength_fmt,length)
	events.addEvent(5,nil,score.add,math.floor(length/10),true,4)
	score.addFuture(math.floor(length/10)*5)
	
	if length == 100 then
		l100score = math.ceil(gclock())
		l100display=string.format(l100_fmt,math.floor(l100score/60),math.floor(l100score) % 60)
		l100hs = Highscore.setLastScore('len100',l100score)
		if l100hs then
			l100display = l100display .. "(HS)"
		end
	end
end


function score.setLastScore()
	hscores={}
	local gtime=gclock()
	gclock = function () return gtime; end
	if fmclock() > 0 then
		setFirstMinuteScore()
	end
	if mhscore then
		table.insert(hscores,{listname='firstminute',score=mscore})
	end
	if l100hs then
		table.insert(hscores,{listname='len100',score=l100score})
	end
	if Highscore.setLastScore('freegame',value) then
		table.insert(hscores,{listname='freegame',score=value})
	end
	return #hscores>0
end

function score.recordHighScore(name)
	for _,hsr in ipairs(hscores) do
		Highscore.recordHighScore(hsr.listname,hsr.score,name)
	end
end


function score.addFuture(incr)
	future = future + incr
	fstring=string.format("+%04d",future)
end

function score.add(incr,isfut,remain)
	value = value + incr
	vstring=string.format("%06d",value)
	if isfut then
		future = future - incr
		if future>0 then
			fstring=string.format("+%04d",future)
		else
			future=0
			fstring=""
		end
		if remain and remain > 0 then
			events.addEvent(1,nil,score.add,incr,true,remain-1)
		end
	end
end

function score.draw()

	if gclock() >= tnext then
		tdisplay=string.format(gtime_fmt,math.floor(tnext/60),tnext % 60)
		tnext=tnext+1
	end


	lg.setFont(rsc.font)
	lg.setColor(score_color)
	lg.print(vstring,0,0)


	lg.setColor(score_future_color)
	lg.print(fstring,100,0)

	lg.setColor(score_color)

	lg.print(tdisplay,200,0)
	lg.print(lendisplay,280,0)
	lg.print(l100display,350,0)
	
	lg.setColor({196,196,196})
	lg.print(mdisplay,520,0)
	
end

function score.value() 
	return value
end

return score