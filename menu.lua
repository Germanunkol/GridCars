local menu = {}

local scr

function menu:init()
	
	scr = ui:newScreen( "menu" )

	scr:addPanel( "centerPanel",
			50,
			love.graphics.getHeight()/2-120,
			300, 220 )

	scr:addHeader( "centerPanel", "welcome", 0, 0, "Welcome!" )
	scr:addText( "centerPanel", "welcometxt", 10, 30, nil, 7, "Please press 'I' to enter the IP of the server you would like to join.")

	scr:addFunction( "centerPanel", "server", 10, 90, "Start Server", "s", menu.startServer )
	scr:addInput( "centerPanel", "ip", 10, 110, nil, 20, "i", menu.ipEntered )
	scr:addFunction( "centerPanel", "help", 10, 130, "Help", "h", menu.startServer )

	scr:addFunction( "centerPanel", "close", 10, 180, "Quit", "q", love.event.quit )
end

function menu:show()
	STATE = "Menu"
	ui:setActiveScreen( scr )
end

function menu:update( dt )
end

function menu:draw()
end

function menu:keypressed( key )
end

function menu:mousepressed( button, x, y )
end

function menu.startServer()
	local success
	success, server = pcall( function()
		return network:startServer( 16, port )
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
end

function menu.ipEntered( ip )
	print( "New IP:", ip )

	local success
	success, client = pcall( function()
		return network:startClient( ip, PLAYERNAME, port )
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

return menu
