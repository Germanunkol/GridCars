--[[print = function(...)
	args = {...}
	str = ""
	for k, v in pairs(args) do
		str = str .. v .. "\t"
	end
	love.filesystem.append( "log.txt", str .. "\r\n" )
end]]


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
	GAMESTATE = 131,
	NEW_CAR = 132,
	MOVE_CAR = 133,
	PLAYER_WINS = 134,
	BACK_TO_LOBBY = 135,
}

MAX_PLAYERS = 16
port = 3410

function love.load( args )

	love.filesystem.write("log.txt", "")

	PLAYERNAME = config.getValue( "PLAYERNAME" ) or "Unknown"
	ROUND_TIME = tonumber(config.getValue( "ROUND_TIME" )) or 10
	WIDTH = tonumber(config.getValue( "WIDTH" )) or love.graphics.getWidth()
	HEIGHT = tonumber(config.getValue( "HEIGHT" )) or love.graphics.getHeight()
	LAPS = tonumber(config.getValue( "LAPS" )) or 1
	MAX_PLAYERS = tonumber(config.getValue( "MAX_PLAYERS" )) or 16
	TRAIL_LENGTH = tonumber(config.getValue( "TRAIL_LENGTH" )) or 100
	SKIP_ROUNDS_ON_CRASH = tonumber(config.getValue( "SKIP_ROUNDS_ON_CRASH" )) or 2

	if WIDTH ~= love.graphics.getHeight() or HEIGHT ~= love.graphic.getWidth() then
		love.window.setMode( WIDTH, HEIGHT )
	end

	-- Remove any pipe symbols from the player name:
	PLAYERNAME = string.gsub( PLAYERNAME, "|", "" )
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
	server.callbacks.userFullyConnected = function( user ) lobby:setUserColor( user ) end
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
	if STATE == "Game" then
		game:mousepressed( x, y, button )
	end
end

function love.draw()

	if STATE == "Game" then
		game:draw()
	elseif STATE == "Lobby" then
		lobby:draw()
	elseif STATE == "Menu" then
		menu:draw()
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
	elseif command == CMD.MOVE_CAR then
		local x, y = msg:match( "(.*)|(.*)" )
		game:validateCarMovement( user.id, x, y )
	end
end

function clientReceived( command, msg )
	if command == CMD.CHAT then
		chat:newLine( msg )
	elseif command == CMD.MAP then
		lobby:receiveMap( msg )
	elseif command == CMD.START_GAME then
		game:show()
	elseif command == CMD.GAMESTATE then
		game:setState( msg )
	elseif command == CMD.NEW_CAR then
		game:newCar( msg )
	elseif command == CMD.MOVE_CAR then
		game:moveCar( msg )
	elseif command == CMD.PLAYER_WINS then
		game:playerWins( msg )
	elseif command == CMD.BACK_TO_LOBBY then
		lobby:show()
	end
end
