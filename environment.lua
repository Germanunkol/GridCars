local 	MapSubject = {}
MapSubject.__index = MapSubject

local col_shadow = { 0, 0, 0, 100 }
local shadowOffsetX = 50
local shadowOffsetY = 50
local shadowSize = 1

function MapSubject:new(item, x, y)
	local o = {}
	setmetatable( o, MapSubject )
	o.x = x
	o.y = y
	o.color =  {255, 255, 255, 255}
	--o.boundaryX
	o.r = math.random(0, math.pi*2) -- rotation
	o.body = images[item .. ".png"]
	o.castshadow = true
	o.shadow = images[item .. ".png"]
	o.name = item
	return o
end

function MapSubject:draw()
	-- first draw shadow
	if self.castshadow then
		love.graphics.setColor(col_shadow)
		love.graphics.draw(self.shadow, self.x+shadowOffsetX, self.y+shadowOffsetY, self.r, shadowSize, shadowSize, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	end
	love.graphics.setColor(self.color)
	love.graphics.draw(self.body, self.x, self.y, self.r, 1, 1, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
end

function MapSubject:update( dt )
end

return MapSubject
