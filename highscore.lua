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
local playerName=""
local nbScores=5

local function sort(listname)
	table.sort(scores[listname],scores[listname].def.comp)
end

local function comp_score_desc(a,b)
	return a.score > b.score
end

local function comp_score_asc(a,b)
	return a.score < b.score
end

local function format_nb(x)
	return string.format("%d",x)
end
local function format_time(x)
	return string.format("%2d:%02d",math.floor(x/60),x%60)
end

local lists = {
	{name='freegame',title='GAME HIGHSCORES',defScore=100,comp=comp_score_desc,format=format_nb},
	{name='firstminute',title='FIRST MINUTE HIGHSCORES',defScore=100,comp=comp_score_desc,format=format_nb},
	{name='len100',title='LENGTH 100 BEST TIMES',defScore=15*60,comp=comp_score_asc,format=format_time},
}

local function write()
	for ln,sr in pairs(scores) do
		sort(ln)
	end
	local f = love.filesystem.newFile(filename)
	f:open('w')
	for ln,sl in pairs(scores) do
		for _,sp in ipairs(sl) do
			f:write("@" .. ln .. "@" .. sp.name .. "@" .. sp.score .. "@\r\n")
		end
	end
	if playerName then
		f:write(playerName.."=00000\r\n")
	end	
	f:close()
end

local function inHighScore(listname,score)
	sort(listname)
	local stub={score=score}
	return scores[listname].def.comp(stub,scores[listname][#scores[listname]])
end

local function addHighScore(listname,score,name)
	if inHighScore(listname,score) then
		playerName=name
		scores[listname][#scores[listname]] = {score=score,name=name,last=true}
		write()
	end	
end

local function setLastScore(listname,score)
	for _,sc in ipairs(scores[listname]) do
		sc.last=nil
	end
	scores[listname].lastScore=score
	return inHighScore(listname,score) 
end

function hs.init()
	for _,l in ipairs(lists) do
		scores[l.name] = {lastScore=0,title=l.title,def=l,fmt=l.format}
	end

	if love.filesystem.getInfo(filename) then
		local i=1
		for line in love.filesystem.lines(filename) do
			if string.sub(line,1,1) == "@" then
				ln,n,s = line:match("@(%w+)@(%w+)@(%d+)@")
				if scores[ln] then
					table.insert(scores[ln],{score=tonumber(s),name=string.upper(n)})
				end
			else
				n,s = line:match("(%w+)=(%d+)")
				if s == "00000" then
					playerName=string.upper(n)
				else
					table.insert(scores.freegame,{score=tonumber(s),name=string.upper(n)})
				end
			end
		end
	end
	
	for ln,sr in pairs(scores) do
		local defScore=scores[ln].def.defScore
		if #sr < nbScores then
			for i = #sr+1,nbScores do
				scores[ln][i]={score=defScore,name="NOBODY"}
			end
		end
	end
	
	for ln,sr in pairs(scores) do
		sort(ln)
		if #sr > nbScores then
			scores[nbScores+1]=nil
		end
	end
	
end

function hs.setLastScore(listname,score)
	return setLastScore(listname,score)
end

function hs.recordHighScore(listname,score,name)
	name=string.upper(name)
	addHighScore(listname,score,name)
end

function hs.getHighScores(listname)
	return scores[listname]
end

function hs.getPlayerName()
	return playerName
end

function hs.getNbScores()
	return nbScores
end

function hs.getListNames()
	local names={}
	for _,l in ipairs(lists) do
		table.insert(names,l.name)
	end
	return names
end
return hs