
network = require( "network.network" )
config = require( "config" )
game = require( "game" )
lobby = require( "lobby" )
chat = require( "chat" )
map = require( "map" )
ui = require( "lib/punchUI" )
menu = require( "menu" )

server = nil
client = nil

STATE = "Menu"
CMD = {
	CHAT = 128,
}

port = 3410

function love.load( args )

	PLAYERNAME = config.getValue( "PLAYERNAME" ) or "Unknown"
	print( "Player name: '" .. PLAYERNAME .. "'" )

	chat:init()
	lobby:init()
	menu:init()
	map:load()

	local startServer = false
	if args[2] ~= "server" and args[2] ~= "client" then
		print("Invalid mode, defaulting to server")
		startServer = true
	elseif args[2] == "server" then
		startServer = true
	end
	if startServer then
		-- Start a server with a maximum of 16 users.
		server = network:startServer( 16, port )
		-- Connect to the server.
		client = network:startClient( 'localhost', "Germanunkol", port )

		-- set server callbacks:
		server.callbacks.received = serverReceived
		-- set client callbacks:
		client.callbacks.received = clientReceived
		client.callbacks.connected = connected

		lobby:show()
	else
		if args[3] then
			client = network:startClient( args[3], "Germanunkol", port )

			-- set client callbacks:
			client.callbacks.received = clientReceived
			client.callbacks.connected = connected
		end
		menu:show()
	end

	map:new( "maps/map2.stl" )

	love.graphics.setBackgroundColor(25,25,25,255)
end

function connected()
	lobby:show()
end

function love.update( dt )
	network:update( dt )
	if STATE == "Game" then
		map:update( dt )
		game:update( dt )
	elseif STATE == "Lobby" then
		map:update( dt )
		lobby:update( dt )
	elseif STATE == "Menu" then
		menu:update( dt )
	end
	ui:update( dt )
end

local chatLines = { "", "", "", "", "", "", "" }
local text = ""

function love.keypressed( key, unicode )
	--chat:keypressed( key )
	ui:keypressed( key, unicode )
	map:keypressed( key )
end

function love.textinput( letter )
	--chat:textinput( letter )
	ui:textinput( letter )
end

function love.mousepressed( x, y, button )
	map:mousepressed( x, y, button )
end

function love.draw()

	if STATE == "Game" then
		game:draw()
	elseif STATE == "Lobby" then
		map:draw()
		lobby:draw()
	end

	if STATE == "Game" or STATE == "Lobby" then
		chat:draw()
	end

	ui:draw()
end

local text = ""
local chatting = false

function serverReceived( command, msg, user )
	if command == CMD.CHAT then
		-- broadcast chat messages on to all players
		server:send( command, user.playerName .. ": " .. msg )
	end
end

function clientReceived( command, msg )
	if command == CMD.CHAT then
		chat:newLine( msg )
	end
end
