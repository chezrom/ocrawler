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

function resources.load()
	loadFonts()
end

return resources