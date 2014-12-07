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

function Car:new( x, y, color )
	local c = {}
	setmetatable( c, Car )
	c.x = x
	c.y = y
	c.vX = 0
	c.vY = 0
	c.color = color
	c.driveTime = 0
	c.driveTimePassed = 0
	c.targetX = 0
	c.targetY = 0
	c.showTarget = true
	c.startX = 0
	c.startY = 0
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
	if self.routeIndex > 1 then
		love.graphics.line(self.route[self.routeIndex-1][1], self.route[self.routeIndex-1][2],
				self.x, self.y)
	end
	-- draw targets to move
	if self.showTarget then
		love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4]/3)
		love.graphics.polygon("fill",
			self.targetX-GRIDSIZE, self.targetY-GRIDSIZE,
			self.targetX-GRIDSIZE, self.targetY+GRIDSIZE,
			self.targetX+GRIDSIZE, self.targetY+GRIDSIZE,
			self.targetX+GRIDSIZE, self.targetY-GRIDSIZE)
	end
	-- draw Car
	love.graphics.circle( "fill", self.x, self.y, 5)

	local info = "Round: " .. self.round
	info = info .. "\nx: " .. self.targetX
	info = info .. "\ny: " .. self.targetY
	local w, numLines = love.graphics.getFont():getWrap( info, 70 )
	love.graphics.setColor( 0,0,0,128 )
	love.graphics.rectangle( "fill", self.x, self.y + 10, 80, 10 + numLines*love.graphics.getFont():getHeight() )
	love.graphics.setColor( self.color )
	love.graphics.printf( info, self.x + 5, self.y + 15, 70 )
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
		self.targetX = x
		self.targetY = y
		self.startX = self.x
		self.startY = self.y
		self.driveTime = time
		self.driveTimePassed = 0
	end
end

return Car
