local menu = {
	ip = ""
}

local scr, listScr
Images = require "images"
local playernameInput, addressInput

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
	scr:addFunction( "centerPanel", "server", 10, y, "Start Server", "s", menu.startServer )
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
end

function menu.showServerList()
	if serverList ~= nil then
		scr:removeList( serverList.name )
	end

	network.callbacks.newServerEntryRemote = newServerListEntryRemote
	network.callbacks.newServerEntryLocal = newServerListEntryLocal

	local list = {}
	serverList = listScr:newList( 60, 120, love.graphics.getWidth() - 132, list )

	network:requestServerList( GAME_ID, MAIN_SERVER_URL )
	network:requestServerListLAN( GAME_ID )

	ui:setActiveScreen( listScr )
end

function newServerListEntryRemote( entry )
	if serverList then
		-- Event to be called when clicking the button:
		local event = function()
			menu.connect( entry.address, entry.port)
		end
		entry.info:gsub("\'", "'")
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
		entry.info:gsub("\'", "'")
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
		menu:errorMsg( "Error:", "Could not connect." )
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
		scr:addText( "helpPanel", "helpText", 10, y, nil, 7, "To change a server's setting or your window size, go to:{g}\n    " .. love.filesystem.getSaveDirectory() .. "/config.txt{p}\n\nPress {f}'p'{p} to change your playername.\n{f}'s'{p} starts a server.\nUsing {f}'i'{p} you can enter an IP (v4) address of the server you want to join.\nIf the server is not in your LAN, but on the web, then the server must probably port-forward port " .. PORT .. " on his/her router.\n\nTo play your own maps, put them into the following folder:\n{g}    " ..love.filesystem.getSaveDirectory() .. "/maps/" )
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

return menu
