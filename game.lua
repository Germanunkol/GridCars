local game = {
	GAMESTATE = "",
	usersMoved = {},
	newUserPositions = {},
	time = 0,
	maxTime = 0,
	timerEvent = nil,
	roundTime = 10,
}

-- Possible gamestates:
-- "startup": camera should move to start line
-- "move": players are allowed to make their move.
-- "wait": waiting for server or other players, or for animtion

function game:init()
end

function game:show()
	STATE = "Game"
	ui:setActiveScreen( nil )

	map:removeAllCars()

	if server then
		for id, u in pairs( server:getUsers() ) do
			local col = {
				u.customData.red,
				u.customData.green,
				u.customData.blue,
				255
			}

			local x, y = 0,0
			if map.startPositions[id] then
				x, y = map.startPositions[id].x, map.startPositions[id].y
			end
			map:newCar( u.id, x, y, col )

			server:send( CMD.NEW_CAR, u.id .. "|" .. x .. "|" .. y )

		end
		game:startMovementRound()
	end
end

function game:update( dt )
	map:update( dt )

	-- Timer:
	if self.timerEvent then
		self.time = self.time + dt
		if self.time >= self.maxTime then
			self.timerEvent()
			self.timerEvent = nil
			self.time = 0
		end
	end
end

function game:draw()
	if client then
		map:draw()
		if self.GAMESTATE == "move" then
			map:drawTargetPoints( client:getID() )
		end
		if love.keyboard.isDown( " " ) then
			map:drawCarInfo()
		end
		game:drawUserList()
	end
end

function game:drawUserList()
	-- Print list of users:
	love.graphics.setColor( 255,255,255, 255 )
	local users, num = network:getUsers()
	local x, y = 20, 60
	local i = 1
	if client and users then
		love.graphics.setColor( 0, 0, 0, 128 )
		love.graphics.rectangle( "fill", x - 5, y - 5, 300, num*20 + 5 )
		for k, u in pairs( users ) do
			love.graphics.setColor( 255,255,255, 255 )
			love.graphics.printf( i .. ":", x, y, 20, "right" )
			love.graphics.printf( u.playerName, x + 25, y, 250, "left" )
			if not u.customData.moved == true then
				love.graphics.setColor( 255, 128, 128, 255 )
				local dx = love.graphics.getFont():getWidth( u.playerName ) + 30
				love.graphics.print( "[Waiting for move]", x + dx, y )
			end
			y = y + 20
			i = i + 1
		end
	end
end

function game:keypressed( key )
end

function game:mousepressed( x, y, button )
	if button == "l" then
	if client then
		if self.GAMESTATE == "move" then
			-- Turn screen coordinates into grid coordinates:
			local gX, gY = map:screenToGrid( x, y )
			gX = math.floor( gX + 0.5 )
			gY = math.floor( gY + 0.5 )
			if map:clickAtTargetPosition( client:getID(), gX, gY ) then
				self:sendNewCarPosition( gX, gY )
			end
		end
	end
end
end

function game:setState( state )
	self.GAMESTATE = state
	print("Set game state", state)
	if self.GAMESTATE == "move" then
		if client then
			map:resetCarNextMovement( client:getID() )
		end
	end
end

function game:newCar( msg )
	if not server then
		local id, x, y = msg:match( "(.*)|(.*)|(.*)")
		id = tonumber(id)
		x = tonumber(x)
		y = tonumber(y)
		print("new car?", id, x, y)
		local users = client:getUsers()
		local u = users[id]
		print("user:", u, users[id])
		if u then
			local col = {
				u.customData.red,
				u.customData.green,
				u.customData.blue,
				255
			}
			map:newCar( id, x, y, col )
		end
	end
end

function game:sendNewCarPosition( x, y )
	-- CLIENT ONLY!
	if client then
		print("SENDING POSITION")
		client:send( CMD.MOVE_CAR, x .. "|" .. y )

		map:setCarNextMovement( client:getID(), x, y )
	end
end

function game:startMovementRound()
	--SERVER ONLY!
	if server then
		server:send( CMD.GAMESTATE, "move" )
		self.GAMESTATE = "move"
		game.usersMoved = {}
		for k, u in pairs( server:getUsers() ) do
			server:setUserValue( u, "moved", false )
		end
	end
end

function game:moveAll()
	if server then
		for k, u in pairs( server:getUsers() ) do
			--local x, y = map:getCarPos( u.id )
			local x,y = self.newUserPositions[u.id].x, self.newUserPositions[u.id].y
			server:send( CMD.MOVE_CAR, u.id .. "|" .. x .. "|" .. y )
		end
	end
	self.timerEvent = function()
		game:startMovementRound()
	end
	self.maxTime = 1.2
end

function game:validateCarMovement( id, x, y )
	--SERVER ONLY!
	if server then
		-- if this user has not moved yet:
		if self.usersMoved[id] == nil then
--			map:setCarPos( id, x, y )
			print( "server moving car to:", x, y)
			--map:setCarPosDirectly(id, x, y) --car-id as number, pos as Gridpos
			local oldX, oldY = map:getCarPos( id )
	

			-- Step along the path and check if there's a collision. If so, stop there.
			local p = {x = oldX, y = oldY }
			local diff = {x = x-oldX, y = y-oldY}
			local dist = utility.length( diff )
			diff = utility.normalize(diff)

			print( "moving:", dist )
			print( "diff:", diff.x, diff.y )

			local crashed = false
			for l = 0.5, dist, 0.5 do
				p = {x = oldX + l*diff.x, y = oldY + l*diff.y }
				if not map:isPointOnRoad( p.x*GRIDSIZE, p.y*GRIDSIZE, 0 ) then
					crashed = true
					break
				end
			end

			if crashed then
				x, y = oldX, oldY
			end

			self.usersMoved[id] = true
			self.newUserPositions[id] = {x=x, y=y}

			local user = server:getUsers()[id]
			if user then
				-- tell this user to wait!
				server:send( CMD.GAMESTATE, "wait", user )
				-- Let all users know this user has already moved:
				server:setUserValue( user, "moved", true )
			end


			-- Check if all users have sent their move:
			local doneMoving = true
			for k, u in pairs( server:getUsers() ) do
				if not self.usersMoved[u.id] then
					doneMoving = false
					break
				end
			end
			-- If all users have sent the move, go on to next round:
			if doneMoving then
				self:moveAll()
			end
		end
	end
end

function game:moveCar( msg )
	-- CLIENT ONLY!
	if client then
		local id, x, y = msg:match( "(.*)|(.*)|(.*)" )
		id = tonumber(id)
		x = tonumber(x)
		y = tonumber(y)
		map:setCarPos( id, x, y )
	end
end
return game
