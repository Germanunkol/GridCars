local Car = {}

function Car:new( x, y, color )
	local c = {}
	c.x = x
	c.y = y
	c.vX = 0
	c.vY = 0

	return c
end

function Car:draw()
	love.graphics.color( 255, 128, 128, 255 )
	love.graphics.circle( "fill", self.x, self.y, 10 )
end

function Car:update( dt )
end

function Car:setPosition( x, y )
	self.x = x
	self.y = y
end

return Car
