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

local filename="hiscore.lst"
local hs={}
local scores={}
local lastScore=0

local function sort()
	table.sort(scores,function (a,b) return a.score > b.score end)
end

local function write()
	sort()
	local f = love.filesystem.newFile(filename)
	f:open('w')
	for _,sp in ipairs(scores) do
		f:write(sp.name .. "=" .. sp.score.."\r\n")
	end
	f:close()
end

function hs.init()
	scores={}
	if love.filesystem.exists(filename) then
		local i=1
		for line in love.filesystem.lines(filename) do
			n,s = line:match("(%w+)=(%d+)")
			scores[i] = {score=tonumber(s),name=n}
			i=i+1
		end
	else
		for i = 1,5 do
			scores[i]={score=1000,name="NOBODY"}
		end
	end
	sort()
end

function hs.setLastScore(score)
	sort()
	for _,sc in ipairs(scores) do
		sc.last=nil
	end
	lastScore=score
	if score > scores[#scores].score then
		return true
	else
		return false
	end
end

function hs.recordHighScore(score,name)
	sort()
	if score > scores[#scores].score then
		scores[#scores] = {score=score,name=name,last=true}
		write()
	end	
end

function hs.getLastScore()
	return lastScore
end

function hs.getHighScores()
	return scores
end

return hs