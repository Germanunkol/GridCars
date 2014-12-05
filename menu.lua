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

	scr:addInput( "centerPanel", "ip", 10, 130, nil, 20, "i", menu.ipEntered )
	scr:addFunction( "centerPanel", "close", 10, 180, "Quit", "q", love.event.quit )
end

function menu:show()
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

function menu.ipEntered( ip )
	print( "New IP:", ip )

	local success
	success, client = pcall( function()
		return network:startClient( ip, PLAYERNAME, port )
	end)

	if success then
		-- set client callbacks:
		client.callbacks.received = clientReceived
		client.callbacks.connected = connected
	else
		local commands = {}
		commands[1] = { txt = "Ok", key = "o" }
		scr:newMsgBox( "Error:",client, nil, nil, nil, commands)
	end

	ui:setActiveScreen( nil )
end

return menu
