local menu = {
	ip = ""
}

local scr
Images = require "images"
local playernameInput, addressInput

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

	y = y + 40
	playernameInput = scr:addInput( "centerPanel", "name", 10, y, nil, 20, "p", menu.playername )
	playernameInput:setContent( PLAYERNAME )

	y = y + 40

	--scr:addText( "centerPanel", "h1", 10, y, nil, 7, "{h}Server:")
	scr:addHeader( "centerPanel", "h1", 0, y, "Server:" )
	y = y + 20
	scr:addFunction( "centerPanel", "server", 10, y, "Start Server", "s", menu.startServer )
	y = y + 40

	--scr:addText( "centerPanel", "h2", 10, y, nil, 7, "{h}Client:")
	scr:addHeader( "centerPanel", "h2", 0, y, "Client:" )
	y = y + 20
	addressInput = scr:addInput( "centerPanel", "ip", 10, y, nil, 20, "i", menu.ipEntered )
	addressInput:setContent( ADDRESS )
	y = y + 20
	scr:addFunction( "centerPanel", "connect", 10, y, "Connect", "c", menu.connect )
	y = y + 40

	scr:addFunction( "centerPanel", "help", 10, y, "Help", "h", menu.toggleHelp )
	y = y + 20
	scr:addFunction( "centerPanel", "close", 10, y, "Quit", "q", love.event.quit )

end

function menu.playername( name )
	name = name:gsub( "|", "" )
	name = name:gsub( " ", "" )
	if #name > 0 then
		PLAYERNAME = name
	end
	if playernameInput then
		playernameInput:setContent( PLAYERNAME )
	end
end

function menu:show()
	STATE = "Menu"
	ui:setActiveScreen( scr )
	menu.ip = ADDRESS
	if addressInput then
		addressInput:setContent( ADDRESS )
	end
end

function menu:update( dt )
end

function menu:draw()
	x, y, tbl = love.window.getMode()
	love.graphics.setColor( 255,255,255,255 )
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
		return network:startServer( MAX_PLAYERS, PORT )
	end)

	if success then
		-- set client callbacks:
		setServerCallbacks( server )
	else
		menu:errorMsg( "Error:", server )
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

	scr:addPanel( "connectPanel",
			love.graphics.getWidth()/2 - 50,
			love.graphics.getHeight()-100,
			100, 50 )
	scr:addHeader( "connectPanel", "hConnect", 0, y, "Connecting" )
	scr:addText( "connectPanel", "connectTxt", 10, y, nil, 7, "Connecting to: '" .. menu.ip .. "'.")


	local success
	success, client = pcall( function()
		return network:startClient( menu.ip, PLAYERNAME, PORT )
	end)

	scr:removePanel( "connectPanel" )

	if success then
		-- set client callbacks:
		setClientCallbacks( client )
		config.setValue( "ADDRESS", menu.ip )
		ui:setActiveScreen( nil )
	else
		print("Could not conect:", client )
		scr:errorMsg( "Error:", "Could not connect." )
	end

end

function menu:authorized( auth, reason )
	if not auth then
		self:errorMsg( "Could not connect: ", reason )
	end
end

function menu:errorMsg( header, msg )
	local commands = {}
	commands[1] = { txt = "Ok", key = "y" }
	scr:newMsgBox( header, msg, nil, nil, nil, commands)
end

function menu:toggleHelp()
	if scr:panelByName( "helpPanel" ) ~= nil then
		scr:removePanel( "helpPanel" )
	else
		local width = 600
		local x = math.min( 450, love.graphics.getWidth() - width - 50 )
		local y = 0
		scr:addPanel( "helpPanel",
			x,
			love.graphics.getHeight()/2-150,
			width, 320 )
		scr:addHeader( "helpPanel", "h1", 0, y, "Help:" )
		y = y + 30

		--scr:addText( "helpPanel", "helpText1", 10, y, nil, 7, "Press {f}'p'{p}")
		scr:addText( "helpPanel", "helpText", 10, y, nil, 7, "To change a server's setting or your window size, go to:{g}\n    " .. love.filesystem.getSaveDirectory() .. "/config.txt{p}\n\nPress {f}'p'{p} to change your playername.\n{f}'s'{p} starts a server.\nUsing {f}'i'{p} you can enter an IP (v4) address of the server you want to join.\nIf the server is not in your LAN, but on the web, then the server must probably port-forward port " .. PORT .. " on his/her router.\n\nTo play your own maps, put them into the following folder:\n{g}    " ..love.filesystem.getSaveDirectory() .. "/maps/" )
	end
end

return menu
