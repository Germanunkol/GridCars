
require( "lib/class" )

map = require( "map" )
network = require( "network" )

local numConnected = 0
local server = 0


function love.load( args )
	local server = false
	if args[2] ~= "server" and args[2] ~= "client" then
		print("Invalid mode, defaulting to server")
		server = true
	end
	if args[2] == "server" then
		server = true
	end

	if server then
		network:startServer()
	else
		print(args[3], "args")
		network:startClient( args[3] )
	end
	map:load()
end

function love.update( dt )
	network:update( dt )

	map:update( dt )
end

local text = ""

function love.keypressed( key )
	if key == "return" then
		network:sendText( text )
		text = ""
	else
		text = text .. key
	end
end

function love.draw()
	map:draw()
end


