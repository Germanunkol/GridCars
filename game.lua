local game = {
	GAMESTATE = "",
}

-- Possible gamestates:
-- "startup": camera should move to start line
-- "move": players are allowed to make their move.
-- "animation": cars are animating their movement
-- "waiting": waiting for server or other players

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

			local x, y = 0, 0
			map:newCar( u.id, 0, 0, col )
			
			server:send( CMD.NEW_CAR, u.id .. "|" .. x .. "|" .. y )

		end
		server:send( CMD.GAMESTATE, "move" )
	end
end

function game:update( dt )
	map:update( dt )
end

function game:draw()
	if client then
		map:draw()
		if self.GAMESTATE == "move" then
			map:drawTargetPoints( client:getID() )
		end
		lobby:drawUserList()
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
	end
end

function game:validateCarMovement( id, x, y )
	--SERVER ONLY!
	if server then
		print("server sending on")
		server:send( CMD.MOVE_CAR, id .. "|" .. x .. "|" .. y )
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
