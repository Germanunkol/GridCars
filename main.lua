
network = require( "network.network" )
config = require( "config" )
game = require( "game" )
lobby = require( "lobby" )
chat = require( "chat" )
map = require( "map" )

local server = nil
local client = nil

STATE = "Lobby"
CMD = {
	CHAT = 128,
}


function love.load( args )

	PLAYERNAME = config.getValue( "PLAYERNAME" ) or "Unknown"
	print( "Player name: '" .. PLAYERNAME .. "'" )

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
	else
		client = network:startClient( args[3], "Germanunkol", port )

		-- set client callbacks:
		client.callbacks.received = clientReceived
	end

	chat:init()
	STATE = "Lobby"
	map:load()
end


function love.update( dt )
	network:update( dt )
	map:update(dt)
	if STATE == "Game" then
		game:update( dt )
	elseif STATE == "Lobby" then
		lobby:update( dt )
	end
end

local chatLines = { "", "", "", "", "", "", "" }
local text = ""

function love.keypressed( key )
	chat:keypressed( key )
end

function love.textinput( letter )
	chat:textinput( letter )
end

function love.draw()

	-- Print list of users:
	love.graphics.setColor( 255,255,255, 255 )
	local users = network:getUsers()
	local x, y = 20, 10
	for k, u in pairs( users ) do
		love.graphics.print( u.playerName, x, y )
		y = y + 20
	end

	map:draw()

	if STATE == "Game" then
		game:draw()
	elseif STATE == "Lobby" then
		lobby:draw()
	end

	if STATE == "Game" or STATE == "Lobby" then
		chat:draw()
	end
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
