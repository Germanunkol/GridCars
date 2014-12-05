local lobby = {}

local scr

function lobby:init()
	
	scr = ui:newScreen( "lobby" )

	scr:addPanel( "topPanel",
			0, 0, 
			love.graphics.getWidth(), 40 )

	scr:addFunction( "topPanel", "close", 20, 0, "Leave", "q", lobby.close )

--	ui:setActiveScreen( scr )
end

function lobby:show()
	STATE = "Lobby"

	ui:setActiveScreen( scr )
end

function lobby:update( dt )
end

function lobby:draw()
	-- Print list of users:
	love.graphics.setColor( 255,255,255, 255 )
	local users = network:getUsers()
	local x, y = 20, 10
	if (server or client) and users then
		for k, u in pairs( users ) do
			love.graphics.print( u.playerName, x, y )
			y = y + 20
		end
	end

end

function lobby:keypressed( key )
end

function lobby:mousepressed( button, x, y )
end

function lobby:close()
	network:closeConnection()
	menu:show()
end

return lobby
