
NUM_CAR_IMAGES = 4
local Car = {}
Car.__index = Car

--[[Car.draw = function() .... end
Car["draw"]
t = {}
Car[t] = 4

c = Car:new(...)
c:updqte( dt )
Car.update( c, dt )
function Car:update( dt )
function Car.update( self, dt )]]

Images = require "images"

function Car:new( x, y, color, angle, bodyType )
	local c = {}
	setmetatable( c, Car )
	c.x = x
	c.y = y
	c.r = angle or 0 -- rotation
	c.vX = 0
	c.vY = 0
	c.color = color
	c.scale = 0.5
	c.body = images["car.png"]
	bodyType = bodyType or 1
	c.detail = images["detail" .. bodyType .. ".png"]
	c.head = images["head" .. bodyType .. ".png"]
	c.driveTime = nil
	c.driveTimePassed = 0
	c.targetX = x
	c.targetY = y
	c.startX = x
	c.startY = y
	c.route = {}
	c.routeIndex = 1
	c.closerToEnd = true
	c.round = 0
	return c
end

function Car:draw()
	love.graphics.setColor(self.color)
	-- draw driven route
	if self.routeIndex > 2 then
		for i = self.routeIndex, 3, -1 do
			love.graphics.line(self.route[i-1][1], self.route[i-1][2],
				self.route[i-2][1], self.route[i-2][2])
			end
	end
	love.graphics.setColor(self.color)
	if self.routeIndex > 1 then
		love.graphics.line(self.route[self.routeIndex-1][1], self.route[self.routeIndex-1][2],
				self.x, self.y)
	end
	-- draw Car
	love.graphics.push()
	--love.graphics.scale(self.scale, self.scale)
	 -- draw body
	love.graphics.setColor(self.color)
	love.graphics.draw(self.body, self.x, self.y, self.r, 1, 1, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	love.graphics.setColor(255,255,255,255)
	 -- draw decoration
	love.graphics.draw(self.detail, self.x, self.y, self.r, 1, 1, self.detail:getWidth()/2, self.detail:getHeight()/2, 0, 0)
	 -- draw heads
	love.graphics.draw(self.head, self.x, self.y, self.r, 1, 1, self.head:getWidth()/2, self.head:getHeight()/2, 0, 0)
	love.graphics.pop()

end

function Car:drawInfo()
	local info = "Round: " .. self.round
	info = info .. "\nx: " .. self.targetX
	info = info .. "\ny: " .. self.targetY
	local w, numLines = love.graphics.getFont():getWrap( info, 70 )
	love.graphics.setColor( 0,0,0,128 )
	love.graphics.rectangle( "fill", self.x, self.y + 10, 80, 10 + numLines*love.graphics.getFont():getHeight() )
	love.graphics.setColor( self.color )
	love.graphics.printf( info, self.x + 5, self.y + 15, 70 )
end

function Car:drawTargetPoints()
	if not self.driveTime then		 -- Don't show while moving.
	-- draw targets to move
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4]/3)
	love.graphics.polygon("fill",
		self.x+self.vX -GRIDSIZE, self.y+self.vY-GRIDSIZE,
		self.x+self.vX-GRIDSIZE, self.y+self.vY+GRIDSIZE,
		self.x+self.vX+GRIDSIZE, self.y+self.vY+GRIDSIZE,
		self.x+self.vX+GRIDSIZE, self.y+self.vY-GRIDSIZE)

	love.graphics.setColor( self.color )

	for x = -1, 1 do
		for y = -1, 1 do
			love.graphics.circle( "fill",
				self.x + self.vX + GRIDSIZE*x,
				self.y + self.vY + GRIDSIZE*y,
				10 )
		end
	end
end

	if self.route[self.routeIndex-1] and self.routeIndex > 1 then
		love.graphics.circle( "fill",
			self.route[self.routeIndex-1][1],
			self.route[self.routeIndex-1][2], 20 )
		end
end

function Car:update( dt )
	if self.driveTime then
		self.driveTimePassed = self.driveTimePassed + dt
		if self.driveTimePassed < self.driveTime then
			local amount = self.driveTimePassed/self.driveTime
			self.x = self.startX + (self.targetX - self.startX) * amount
			self.y = self.startY + (self.targetY - self.startY) * amount
		else
			self.x = self.targetX
			self.y = self.targetY
			self.driveTime = nil
		end
	end
end

function Car:MoveToPos( x, y, time )
	if (not self.driveTime) then
		self.route[self.routeIndex] = {self.x, self.y}
		self.routeIndex = self.routeIndex + 1
		if self.routeIndex > TRAIL_LENGTH then
			self.routeIndex = self.routeIndex - 1
			table.remove( self.route, 1 )
		end
		self.targetX = x
		self.targetY = y
		self.vX = x - self.x
		self.vY = y - self.y
		self.startX = self.x
		self.startY = self.y
		self.driveTime = time
		self.driveTimePassed = 0
		--rotate to Target
		self.r = math.atan2(self.y - self.targetY, self.x - self.targetX) - math.pi/2
	end
end

function Car:setPos( x, y )
	self.vX = x - self.x
	self.vY = y - self.y
	self.startX = self.x
	self.startY = self.y
	self.targetX = x
	self.targetY = y
	self.startX = self.x
	self.startY = self.y

	--rotate to Target
	self.r = math.atan2(self.y - self.targetY, self.x - self.targetX) - math.pi/2

	-- Directly set position:
	self.x = x
	self.y = y
end

function Car:isThisAValidTargetPos( x, y )
	x = x*GRIDSIZE
	y = y*GRIDSIZE
	if (x == self.targetX + self.vX - GRIDSIZE or
		x == self.targetX + self.vX or
		x == self.targetX + self.vX + GRIDSIZE ) and
	 (y == self.targetY + self.vY - GRIDSIZE or
		y == self.targetY + self.vY or
		y == self.targetY + self.vY + GRIDSIZE ) then
		return true
	end
	return false
end

return Car
