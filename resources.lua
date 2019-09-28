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
local lm=love.math
local fontFilename= "assets/diavlo.otf"
--local fontFilename= "assets/FiraMonoOT-Bold.otf"

local function loadFonts()
	resources.tinyFont=lg.newFont(fontFilename,16)
	resources.font=lg.newFont(fontFilename,20)
	resources.titleFont=lg.newFont(fontFilename,32)
	resources.menuFont=lg.newFont(fontFilename,24)
end

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
				id:setPixel(x,y,(64+(255-64)*l)/255,(64+(255-64)*l)/255,(64+(255-64)*l)/255,1)
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
				id:setPixel(x,y,(64+(255-64)*l)/255,(64+(255-64)*l)/255,(64+(255-64)*l)/255,1)
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

local function computeBackground()
	local abs=math.abs
	local id = love.image.newImageData(SW,SH)
	local c2={10/256,10/256,96/256}
	local c1={86/256,96/256,80/256}
	local maxr=1
	--local minr=0.8
	local minr=0.5
	--local yrad=maxr/minr
	local yrad=2*maxr - minr
	
	local ox= 200*math.random() - 10
	local oy= 20*math.random() - 10
	local oz= 20*math.random() - 10

	for x=0,SW-1 do
		local alpha = 2*x/SW*math.pi
		for y=0,SH-1 do
			local beta = 2 *y/SH*math.pi
			--local yy= oy+minr*math.sin(beta)
			local yy= oy+yrad*math.sin(beta)
			local ur = maxr - minr*math.cos(beta)
			local xx = ox+ur*math.cos(alpha)
			local zz = oz+ur*math.sin(alpha)
			local u1 = lm.noise(xx,yy,zz)
			local u2 = lm.noise(2*xx,2*yy,2*zz)
			local u3 = lm.noise(4*xx,4*yy,4*zz)
			--local u = 2*u1 + u2 + u3/2
			local u = u1 + u2/2 + u3/4
			--local u=2*u1
			--local u = u1
			if (u>1) then u=1 end
			--u=u*u
			id:setPixel(x,y,c1[1] + u*(c2[1]-c1[1]),c1[2] + u*(c2[2]-c1[2]),c1[3] + u*(c2[3]-c1[3]))
		end
	end
	local sx = math.random(100,300)
	local sy = math.random(100,300)
	resources.bgCanvas = lg.newCanvas(SW,SH)
	lg.setCanvas(resources.bgCanvas)
	--lg.draw(lg.newImage(id),0,0)
	lg.draw(lg.newImage(id),-sx,-sy)
	lg.draw(lg.newImage(id),SW-sx,-sy)
	lg.draw(lg.newImage(id),-sx,SH-sy)
	lg.draw(lg.newImage(id),SW-sx,SH-sy)
	lg.setCanvas()
end

function resources.load()
	loadFonts()
	computeGraphics()
	computeBackground()
end

return resources