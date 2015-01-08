local menu = {
	ip = ""
}

local scr, listScr
Images = require "images"
local playernameInput, addressInput

local ERROR_MSG = nil
local ERROR_TIMER = 0

function menu:init()

	scr = ui:newScreen( "menu" )

	scr:addPanel( "centerPanel",
			50,
			love.graphics.getHeight()/2-200,
			300, 350 )

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
	scr:addFunction( "centerPanel", "serverOnline", 10, y, "Start Server (Online)", "s", function() menu.startServer("online") end )
	y = y + 20
	scr:addFunction( "centerPanel", "serverLAN", 10, y, "Start Server (LAN)", "a", function() menu.startServer("lan") end )
	y = y + 40

	--scr:addText( "centerPanel", "h2", 10, y, nil, 7, "{h}Client:")
	scr:addHeader( "centerPanel", "h2", 0, y, "Client:" )
	y = y + 20
	--addressInput = scr:addInput( "centerPanel", "ip", 10, y, nil, 20, "i", menu.ipEntered )
	--addressInput:setContent( ADDRESS )
	--y = y + 20
	scr:addFunction( "centerPanel", "connect", 10, y, "Connect", "c", menu.showServerList )
	y = y + 40

	scr:addFunction( "centerPanel", "options", 10, y, "Options", "o", menu.toggleOptions )
	y = y + 20
	scr:addFunction( "centerPanel", "help", 10, y, "Help", "h", menu.toggleHelp )
	y = y + 20
	scr:addFunction( "centerPanel", "close", 10, y, "Quit", "q", love.event.quit )

	listScr = ui:newScreen( "Serverlist" )
	listScr:addPanel( "headerPanel",
			60, 60,
			love.graphics.getWidth()-120, 50 )
	listScr:addHeader( "headerPanel", "h", 20, 10, "Servers:" )
	listScr:addFunction( "headerPanel", "return", love.graphics.getWidth() - 260, 10, "Return", "q", menu.show )
	listScr:addFunction( "headerPanel", "refresh", love.graphics.getWidth() - 360, 10, "Refresh", "r", menu.showServerList )
end

function menu.playername( name )
	name = name:gsub( "|", "" )
	name = name:gsub( " ", "" )
	if #name > 0 then
		PLAYERNAME = name
		config.setValue( "PLAYERNAME", PLAYERNAME )
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
	chat:reset()
	map:reset()
	menu:closeConnectPanel()

	network.advertise:stop()

	ERROR_TIMER = 0
end

function menu.showServerList()
	if serverList ~= nil then
		listScr:removeList( serverList.name )
	end

	network.advertise.callbacks.newEntryOnline = newServerListEntryRemote
	network.advertise.callbacks.newEntryLAN = newServerListEntryLocal

	network.advertise.callbacks.requestWarnings = function( msg )
		menu:newWarning( "Could not load online list:\n" .. msg ) end

	local list = {}
	serverList = listScr:newList( 60, 120, love.graphics.getWidth() - 132, list, 15 )

	--network:requestServerList( GAME_ID, MAIN_SERVER_URL )
	--network:requestServerListLAN( GAME_ID )
	network.advertise:setURL( MAIN_SERVER_URL )
	network.advertise:setID( GAME_ID )

	network.advertise:request( "both" )

	ui:setActiveScreen( listScr )
end

function newServerListEntryRemote( entry )
	if serverList then
		-- Event to be called when clicking the button:
		local event = function()
			menu.connect( entry.address, entry.port)
		end
		local item = {
			txt = "(Online) " .. entry.address .. "\t" .. entry.info:gsub(",","\t"):gsub(":", ": "),
			event = event
		}
		serverList:addListItem( item )
	end
end

function newServerListEntryLocal( entry )
	if serverList then
		-- Event to be called when clicking the button:
		local event = function()
			menu.connect( entry.address, entry.port)
		end
		local item = {
			txt = "(LAN) " .. entry.address .. "\t" .. entry.info:gsub(",","\t"):gsub(":", ": "),
			event = event
		}
		serverList:addListItem( item )
	end
end


function menu:closeConnectPanel()
	scr:removePanel( "connectPanel" )
end

function menu:update( dt )
	if ERROR_TIMER > 0 then
		ERROR_TIMER = ERROR_TIMER - dt
	end
end

function menu:draw()
	x, y, tbl = love.window.getMode()
	love.graphics.setColor( 255,255,255,255 )
	love.graphics.draw(images["Logo.png"], x/2, 50, 0, 1, 1, 0, 0, 0, 0)
--love.graphics.draw(images["Logo.png"], 0, 0, 0, 1, 1, 0, 0, 0, 0)
	if ERROR_TIMER > 0 then
		love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill", 60, love.graphics.getHeight() - 70,
				love.graphics.getWidth() - 120, 60 )
		love.graphics.setColor( 255,128,0, 200 )
		love.graphics.printf( ERROR_MSG, 60, love.graphics.getHeight() - 60,
				love.graphics.getWidth() - 120, "center" )
	end
end

function menu:keypressed( key )
end

function menu:mousepressed( button, x, y )
end

function menu.startServer( lan )

	if lan == "lan" then
		LAN_ONLY = true
	else
		LAN_ONLY = false
	end

	local success
	success, server = pcall( function()
		return network:startServer( MAX_PLAYERS, PORT )
	end)

	if success then
		-- set client callbacks:
		setServerCallbacks( server )

		updateAdvertisementInfo()
		network.advertise:setURL( MAIN_SERVER_URL )
		network.advertise:setID( GAME_ID )
		if LAN_ONLY then
			network.advertise:start( server, "lan" )
		else
			network.advertise:start( server, "both" )
		end
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

function menu.connect( ip, port )

	local y = 0
	scr:addPanel( "connectPanel",
			love.graphics.getWidth()/2 - 175,
			love.graphics.getHeight()-100,
			350, 50 )
	scr:addHeader( "connectPanel", "hConnect", 0, 0, "Connecting" )
	scr:addText( "connectPanel", "connectTxt", 10, 15, nil, 7, "Connecting to: '" ..
			(ip or menu.ip) .. "'...")

	local success
	success, client = pcall( function()
		return network:startClient( ip or menu.ip, PLAYERNAME, port or PORT, VERSION )
	end)

	if success then
		-- set client callbacks:
		setClientCallbacks( client )
		if not server then		-- only save address if this is not a server (in this case ADDRESS would be localhost)
			config.setValue( "ADDRESS", menu.ip )
		end
		--ui:setActiveScreen( nil )
	else
		print("Could not conect:", client )
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		listScr:newMsgBox( "Error:", "Could not connect.", nil, nil, nil, commands)
		menu:closeConnectPanel()
	end

end

function menu:authorized( auth, reason )
	if not auth then
		self:errorMsg( "Could not connect: ", reason )
		menu:closeConnectPanel()
	end
end

function menu:errorMsg( header, msg )
	local commands = {}
	commands[1] = { txt = "Ok", key = "y" }
	scr:newMsgBox( header, msg, nil, nil, nil, commands)
end

function menu:toggleHelp()
	if scr:panelByName( "optionsPanel" ) ~= nil then
		scr:removePanel( "optionsPanel" )
	end
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
		scr:addText( "helpPanel", "helpText", 10, y, nil, 7, "To change a server's setting go to:{g}\n    " .. love.filesystem.getSaveDirectory() .. "/config.txt{p}\n\nPress {f}'p'{p} to change your playername.\n{f}'s'{p} starts a server.\nUse {f}'c'{p} to see a server list.\nIf the server is not in your LAN, but on the web, then the server must probably port-forward port " .. PORT .. " on his/her router.\n\nTo play your own maps, put them into the following folder:\n{g}    " ..love.filesystem.getSaveDirectory() .. "/maps/" )
	end
end

function menu:toggleOptions()
	if scr:panelByName( "helpPanel" ) ~= nil then
		scr:removePanel( "helpPanel" )
	end
	if scr:panelByName( "optionsPanel" ) ~= nil then
		scr:removePanel( "optionsPanel" )
	else
		local width = 300
		local x = math.min( 450, love.graphics.getWidth() - width - 50 )
		local y = 0
		scr:addPanel( "optionsPanel",
			x,
			love.graphics.getHeight()/2-150,
			width, 320 )
		scr:addHeader( "optionsPanel", "h1", 0, y, "Options:" )
		y = y + 30

		scr:addHeader( "optionsPanel", "h2", 0, y, "Width and Height:" )
		y = y + 20
		local input
		local w, h, flags = love.window.getMode()
		input = scr:addInput( "optionsPanel", "width", 10, y, nil, 20, "1", menu.widthEntered )
		input:setContent( tostring(w) )
		y = y + 20
		input = scr:addInput( "optionsPanel", "height", 10, y, nil, 20, "2", menu.heightEntered )
		input:setContent( tostring(h) )
		y = y + 40

		if flags.fullscreen then
			scr:addFunction( "optionsPanel", "fullscreen", 10, y, "Fullscreen (on)", "f", menu.fullscreen )
		else
			scr:addFunction( "optionsPanel", "fullscreen", 10, y, "Fullscreen (off)", "f", menu.fullscreen )
		end

	end
end

function menu.widthEntered( txt )
	local num = tonumber(txt)
	if num then
		ok = pcall( love.window.setMode, num, HEIGHT, {fullscreen = FULLSCREEN} )
		if ok then
			WIDTH = num
			config.setValue( "WIDTH", num )
			love.load()
			menu:toggleOptions()
		end
	end
end

function menu.heightEntered( txt )
	local num = tonumber(txt)
	if num then
		ok = pcall( love.window.setMode, WIDTH, num, {fullscreen = FULLSCREEN} )
		if ok then
			HEIGHT = num
			config.setValue( "HEIGHT", num )
			love.load()
			menu:toggleOptions()
		end
	end
end

function menu.fullscreen()
	local w, h, flags = love.window.getMode()
	local fscr = not flags.fullscreen
	ok = pcall( love.window.setMode, WIDTH, HEIGHT, {fullscreen = fscr} )
	if ok then
		config.setValue( "FULLSCREEN", fscr )
		FULLSCREEN = fscr
		love.load()
		menu:toggleOptions()
	end
end

function menu:newWarning( msg )
	ERROR_MSG = msg
	ERROR_TIMER = 10
end

return menu
