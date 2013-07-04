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

local resources={}

local lg=love.graphics

local fontFilename= "assets/diavlo.otf"
--local bgimageFilename="assets/bg.png"

local function loadFonts()
	--[[
	resources.tinyFont=lg.newFont(16)
	resources.font=lg.newFont(20)
	resources.titleFont=lg.newFont(32)
	resources.menuFont=lg.newFont(24)
	--]]
	--
	resources.tinyFont=lg.newFont(fontFilename,16)
	resources.font=lg.newFont(fontFilename,20)
	resources.titleFont=lg.newFont(fontFilename,32)
	resources.menuFont=lg.newFont(fontFilename,24)
end
--[[
local function getVitaminImage(radius)
	--local id = love.image.newImageData(2*radius,2*radius)
	local id = love.image.newImageData(32,32)
	local xc = (2*radius-1)/2
	local yc = xc
	local r2=radius*radius
	for x=0,2*radius-1 do
		local u2 = (x-xc)*(x-xc)
		for y=0,2*radius-1 do
			local d2=u2+(y-yc)*(y-yc)
			if d2 <=r2 then
				--id:setPixel(x,y,255-128*d2/r2,255-128*d2/r2,255,255)
				id:setPixel(x,y,255-128*d2/r2,255-128*d2/r2,255,255-(128+64)*d2/r2)
				--id:setPixel(x,y,255,255,255,255-128*math.sqrt(d2/r2))
			end
		end
	end
	return lg.newImage(id)
end
--]]
local function getVitaminImage(radius)
	--local id = love.image.newImageData(2*radius,2*radius)
	local id = love.image.newImageData(32,32)
	local xc = (2*radius-1)/2
	local yc = xc
	local r2=radius*radius
	for x=0,2*radius-1 do
		local u2 = (x-xc)*(x-xc)
		for y=0,2*radius-1 do
			local d2=u2+(y-yc)*(y-yc)
			if d2 <=r2 then
				z=math.sqrt(r2-d2)
				local l=((xc-x)+(yc-y)+z*math.sqrt(2))*0.5/radius
				if l<0 then
					l=0
				end
				id:setPixel(x,y,64+(255-64)*l,64+(255-64)*l,64+(255-64)*l,255)
			end
		end
	end
	return lg.newImage(id)
end

local function getSnakeImage(radius)
	--local id = love.image.newImageData(2*radius,2*radius)
	local id = love.image.newImageData(32,32)
	local xc = (2*radius-1)/2
	local yc = xc
	local r2=radius*radius
	local hr2=r2/3
	local lflat = math.sqrt(2)/2
	for x=0,2*radius-1 do
		local u2 = (x-xc)*(x-xc)
		for y=0,2*radius-1 do
			local d2=u2+(y-yc)*(y-yc)
			if d2 <=hr2 then
				id:setPixel(x,y,64+(255-64)*lflat,64+(255-64)*lflat,64+(255-64)*lflat,255)
			elseif d2 <=r2 then
				z=math.sqrt(r2-d2)
				local l=((xc-x)+(yc-y)+z*math.sqrt(2))*0.5/radius
				if l<0 then
					l=0
				end
				id:setPixel(x,y,64+(255-64)*l,64+(255-64)*l,64+(255-64)*l,255)
			end
		end
	end
	return lg.newImage(id)
end

local function computeGraphics()
	resources.vitamins={}
	for i=8,16 do
		resources.vitamins[i]=getVitaminImage(i)
	end
	resources.snake={}
	resources.snake[7]=getSnakeImage(7)
end

function resources.load()
	loadFonts()
	computeGraphics()
end

return resources