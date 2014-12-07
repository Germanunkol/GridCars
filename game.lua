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

	if server then
		server:send( CMD.GAMESTATE, "move" )
	end
end

function game:update( dt )
	map:update( dt )
end

function game:draw()
	if client then
		map:draw()
		if GAMESTATE == "move" then
			map:drawCarPoints( client:getID() )
		end
	end
end

function game:keypressed( key )
end

function game:mousepressed( button, x, y )
	if client then
		map:moveCar( client.getID(), x, y )
	end
end

function game:setState( state )
	self.GAMESTATE = state
end

return game
