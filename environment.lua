local 	MapSubject = {}
MapSubject.__index = MapSubject


Images = require "images"

function MapSubject:new(item, x, y)
	local o = {}
	setmetatable( o, MapSubject )
	o.x = x
	o.y = y
	o.color =  {255, 255, 255, 255}
	--o.boundaryX
	o.r = 0 -- rotation
	o.body = images["car.png"]--[item .. ".png"]
	return o
end

function MapSubject:draw()
	love.graphics.setColor(self.color)
	love.graphics.draw(self.body, self.x, self.y, self.r, 1, 1, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	 -- draw decoration
	--love.graphics.draw(self.detail, self.x, self.y, self.r, 1, 1, self.detail:getWidth()/2, self.detail:getHeight()/2, 0, 0)
	 -- draw heads
	--love.graphics.draw(self.head, self.x, self.y, self.r, 1, 1, self.head:getWidth()/2, self.head:getHeight()/2, 0, 0)
end

function MapSubject:update( dt )
end

return MapSubject