
network = require( "network.network" )
config = require( "config" )
game = require( "game" )
lobby = require( "lobby" )
chat = require( "chat" )
map = require( "map" )
ui = require( "lib/punchUI" )
menu = require( "menu" )
utility = require( "utility" )		-- helper functions
images = require( "images" )	-- loads all images.

server = nil
client = nil

STATE = "Menu"
CMD = {
	CHAT = 128,
	MAP = 129,
	START_GAME = 130,
}

port = 3410

function love.load( args )

	PLAYERNAME = config.getValue( "PLAYERNAME" ) or "Unknown"
	print( "Player name: '" .. PLAYERNAME .. "'" )

	images:load()	-- preload all images
	chat:init()
	lobby:init()
	menu:init()
	game:init()
	map:load()

	menu:show()

	local startServer = false
	local startClient = false
	if args[2] == "client" then
		startClient = true
	elseif args[2] == "server" then
		startServer = true
	end
	if startServer then
		-- Start a server with a maximum of 16 users.
		server = network:startServer( 16, port )
		-- Connect to the server.
		client = network:startClient( 'localhost', PLAYERNAME, port )

		-- set server callbacks:
		setServerCallbacks( server )

		-- set client callbacks:
		setClientCallbacks( client )

		lobby:show()
	elseif startClient then
		if args[3] then
			client = network:startClient( args[3], PLAYERNAME, port )
			setClientCallbacks( client )
		else
			print( "Error. To start as client, you should give the address as the argument after 'client'." )
		end
	end

	--love.graphics.setBackgroundColor(25,25,25,255)
	love.graphics.setBackgroundColor( 20,80,20,255)
end

function setServerCallbacks( server )
	server.callbacks.received = serverReceived
	server.callbacks.synchronize = synchronize
	server.callbacks.authorize = function( user ) return lobby:authorize( user ) end
end
function setClientCallbacks( client )
	-- set client callbacks:
	client.callbacks.received = clientReceived
	client.callbacks.connected = connected
	client.callbacks.disconnected = disconnected
	-- Called when user is authorized or not (in the second case, a reason is given):
	client.callbacks.authorized = function( auth, reason ) menu:authorized( auth, reason ) end
end

-- Called when client is connected to the server
function connected()
	lobby:show()
end

-- Called when client is disconnected from the server
function disconnected()
	menu:show()
	client = nil
	server = nil
end

-- Called on server when new client is in the process of
-- connecting.
function synchronize( user )
	-- If the server has a map chosen, let the new client know
	-- about it:
	lobby:sendMap( user )
end

function love.update( dt )
	network:update( dt )
	if STATE == "Game" then
		game:update( dt )
	elseif STATE == "Lobby" then
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
	elseif command == CMD.MAP then
		lobby:receiveMap( msg )
	elseif command == CMD.START_GAME then
		game:show()
	end
end
