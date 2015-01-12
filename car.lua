
NUM_CAR_IMAGES = 4
local Car = {}
Car.__index = Car

local col_shadow = { 0, 0, 0, 100 }
local shadowOffsetX = 5
local shadowOffsetY = 5

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
local headoffsetMax = 10

function Car:new( x, y, color, angle, bodyType )
	local c = {}
	setmetatable( c, Car )
	c.x = x
	c.y = y
	c.r = angle or 0 -- rotation
	c.vX = 0
	c.vY = 0
	c.color = {
		color[1] or 0,
		color[2] or 0,
		color[3] or 0,
		255}
		c.scale = 0.5
		if not DEDICATED then
			c.body = images["car.png"]
			bodyType = bodyType or 1
			c.detail = images["detail" .. bodyType .. ".png"]
			c.head = images["head" .. bodyType .. ".png"]
		end
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
	c.headX = x
	c.headY = y
	return c
end

function Car:draw()
	love.graphics.setLineWidth( 5 )
		love.graphics.setColor(self.color)
	-- draw driven route
	if self.routeIndex > 2 then
		for i = self.routeIndex, 3, -1 do
			love.graphics.line(self.route[i-1][1], self.route[i-1][2],
				self.route[i-2][1], self.route[i-2][2])
		end
	end
	if self.routeIndex > 1 then
		love.graphics.setColor(self.color)
		love.graphics.line(self.route[self.routeIndex-1][1], self.route[self.routeIndex-1][2],
				self.x, self.y)
	end
	-- draw Car
	love.graphics.push()
	--love.graphics.scale(self.scale, self.scale)
	-- draw shadow:
	love.graphics.setColor(col_shadow)
	love.graphics.draw(self.body, self.x+shadowOffsetX, self.y+shadowOffsetY, self.r, 1, 1, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	 -- draw body
	love.graphics.setColor(self.color)
	love.graphics.draw(self.body, self.x, self.y, self.r, 1, 1, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	love.graphics.setColor(255,255,255,255)
	 -- draw decoration
	love.graphics.draw(self.detail, self.x, self.y, self.r, 1, 1, self.detail:getWidth()/2, self.detail:getHeight()/2, 0, 0)
	 -- draw heads
	love.graphics.draw(self.head, self.headX, self.headY, self.r, 1, 1, self.head:getWidth()/2, self.head:getHeight()/2, 0, 0)
	love.graphics.pop()
end

function Car:drawOnUI( x, y, scale )

	scale = scale or 1
	love.graphics.setColor(self.color)

	-- draw Car
	love.graphics.push()
	love.graphics.translate( x, y )
	--love.graphics.scale(self.scale, self.scale)
	 -- draw body
	love.graphics.setColor(self.color)
	love.graphics.draw(self.body, 0, 0, .5, scale, scale, self.body:getWidth()/2, self.body:getHeight()/2, 0, 0)
	love.graphics.setColor(255,255,255,255)
	 -- draw decoration
	love.graphics.draw(self.detail, 0, 0, .5, scale, scale, self.detail:getWidth()/2, self.detail:getHeight()/2, 0, 0)
	 -- draw heads
	love.graphics.draw(self.head, 0, 0, .5, scale, scale, self.head:getWidth()/2, self.head:getHeight()/2, 0, 0)
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
		love.graphics.setColor( self.color )
		love.graphics.circle( "fill",
		self.route[self.routeIndex-1][1],
		self.route[self.routeIndex-1][2], 20 )
	end

	-- If mouse is hovering over (or close to) a target point, draw the route to
	-- that target point:
	local gX, gY = map:screenToGrid( love.mouse.getPosition() )
	gX = math.floor( gX + 0.5 )
	gY = math.floor( gY + 0.5 )
	if self:isThisAValidTargetPos( gX, gY ) then
		self:drawMovementPrediction( gX, gY )
	end
end

function Car:drawMovementPrediction( x, y )
	-- NOTE: This would not have to be calculated every frame,
	-- but since it's only done for one car, it's fine:
	local oldX, oldY = self.x/GRIDSIZE, self.y/GRIDSIZE--map:getCarPos( self.id )

	-- Step along the path and check if there's a collision. If so, stop there.
	local p = {x = oldX, y = oldY }
	local diff = {x = x-oldX, y = y-oldY}
	local dist = utility.length( diff )
	diff = utility.normalize(diff)

	-- Step forward in steps of 0.5 length - this makes sure no small gaps are jumped!
	local crashed, crashSiteFound = false, false
	local movedDist = 0
	local crashSite = nil
	for l = 0.5, dist, 0.5 do
		p = {x = oldX + l*diff.x, y = oldY + l*diff.y }
		if not map:isPointOnRoad( p.x*GRIDSIZE, p.y*GRIDSIZE, 0 ) then
			crashSite = p
			crashed = true
			break
		end
		movedDist = l
	end

	-- Also check the end position!!
	if not crashed then
		-- I have managed to move the entire distance!
		movedDist = dist
		if not map:isPointOnRoad( x*GRIDSIZE, y*GRIDSIZE, 0 ) then
			crashSite = {x=x, y=y}
			crashed = true
		end
	end

	if crashed then
		love.graphics.setColor( 255,64,64,255 )
		love.graphics.line( x*GRIDSIZE, y*GRIDSIZE,
			self.x, self.y )
		
		-- Draw crash site:
		love.graphics.circle( "fill", crashSite.x*GRIDSIZE, crashSite.y*GRIDSIZE, 5 )
	else
		love.graphics.setColor( 64,255,64,255 )
		love.graphics.line( x*GRIDSIZE, y*GRIDSIZE,
			self.x, self.y )
	end
end

function Car:update( dt )
	if self.driveTime then
		self.driveTimePassed = self.driveTimePassed + dt
		if self.driveTimePassed < self.driveTime then
			local amount = self.driveTimePassed/self.driveTime
			self.x = self.startX + (self.targetX - self.startX) * amount
			self.y = self.startY + (self.targetY - self.startY) * amount
			dist = math.sqrt((self.headX - self.x)*(self.headX - self.x) + (self.headY - self.y)*(self.headY - self.y))
			if dist > headoffsetMax then
				self.headX = self.x
				self.headY = self.y
			end
		else
			self.x = self.targetX
			self.y = self.targetY
			self.headX = self.targetX
			self.headY = self.targetY
			self.driveTime = nil
		end
	end
	--print("headoffset:", headoffset)
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
function Car:getPos()
	return self.x, self.y
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
