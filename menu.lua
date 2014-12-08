local menu = {
	ip = ""
}

local scr
Images = require "images"

function menu:init()
	
	scr = ui:newScreen( "menu" )

	scr:addPanel( "centerPanel",
			50,
			love.graphics.getHeight()/2-200,
			300, 320 )

	local y = 0
	scr:addHeader( "centerPanel", "welcome", 0, y, "Welcome!" )
	y = y + 30
	scr:addText( "centerPanel", "welcometxt", 10, y, nil, 7, "Start a server or join someone else's server. Press 'H' for help.")

	y = y + 80
	scr:addText( "centerPanel", "h1", 10, y, nil, 7, "{h}Server:")
	y = y + 20
	scr:addFunction( "centerPanel", "server", 10, y, "Start Server", "s", menu.startServer )
	y = y + 40

	scr:addText( "centerPanel", "h2", 10, y, nil, 7, "{h}Client:")
	y = y + 20
	scr:addInput( "centerPanel", "ip", 10, y, nil, 20, "i", menu.ipEntered )
	y = y + 20
	scr:addFunction( "centerPanel", "connect", 10, y, "Connect", "c", menu.connect )
	y = y + 40

	scr:addFunction( "centerPanel", "help", 10, y, "Help", "h", menu.showHelp )
	y = y + 20
	scr:addFunction( "centerPanel", "close", 10, y, "Quit", "q", love.event.quit )

end

function menu:show()
	STATE = "Menu"
	ui:setActiveScreen( scr )
end

function menu:update( dt )
end

function menu:draw()
	x, y, tbl = love.window.getMode()
	love.graphics.draw(images["Logo.png"], x/2, 50, 0, 1, 1, 0, 0, 0, 0)
--love.graphics.draw(images["Logo.png"], 0, 0, 0, 1, 1, 0, 0, 0, 0)
end

function menu:keypressed( key )
end

function menu:mousepressed( button, x, y )
end

function menu.startServer()
	local success
	success, server = pcall( function()
		return network:startServer( MAX_PLAYERS, port )
	end)

	if success then
		-- set client callbacks:
		setServerCallbacks( server )
	else
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		scr:newMsgBox( "Error:",server, nil, nil, nil, commands)
	end

	-- Also start a client!
	menu.ipEntered( 'localhost' )
	menu.connect()
end

function menu.ipEntered( ip )
	print( "New IP:", ip )
	menu.ip = ip
end

function menu.connect()

	local success
	success, client = pcall( function()
		return network:startClient( menu.ip, PLAYERNAME, port )
	end)

	if success then
		-- set client callbacks:
		setClientCallbacks( client )
	else
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		scr:newMsgBox( "Error:",client, nil, nil, nil, commands)
	end

	ui:setActiveScreen( nil )
end

function menu:authorized( auth, reason )
	if not auth then
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		scr:newMsgBox( "Could not connect:",reason, nil, nil, nil, commands)
	end
end

return menu
