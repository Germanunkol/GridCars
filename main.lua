--[[print = function(...)
	local args = {...}
	origPrint( unpack(args) )
	local str = ""
	for k, v in pairs(args) do
		str = str .. v .. "\t"
	end
	love.filesystem.append( "log.txt", str .. "\r\n" )
end]]

network = require( "network.network" )
config = require( "config" )
game = require( "game" )
lobby = require( "lobby" )
map = require( "map" )
if not DEDICATED then
	ui = require( "lib/punchUI" )
	menu = require( "menu" )
	images = require( "images" )	-- loads all images.
	chat = require( "chat" )
end
utility = require( "utility" )		-- helper functions
require( "callbacks" )		-- helper functions
Timer = require("timer")
Sounds = require("sounds")

server = nil
client = nil

STATE = "Menu"

MAX_PLAYERS = 16
PORT = 3410
MAIN_SERVER_URL = "http://germanunkol.de/gridcars/serverlist"
GAME_ID = "GridCars" .. VERSION

function love.load( args )

	config.load()

	images:load()	-- preload all images
	Sounds:load()
	chat:init()
	lobby:init()
	menu:init()
	game:init()
	map:load()

	menu:show()

	--[[local startServer = false
	local startClient = false
	if args[2] == "client" then
		startClient = true
	elseif args[2] == "server" then
		startServer = true
	end
	if startServer then
		-- Start a server with a maximum of 16 users.
		server = network:startServer( MAX_PLAYERS, PORT )
		-- Connect to the server.
		client = network:startClient( 'localhost', PLAYERNAME, PORT )

		-- set server callbacks:
		setServerCallbacks( server )

		-- set client callbacks:
		setClientCallbacks( client )

		lobby:show()
	elseif startClient then
		if args[3] then
			client = network:startClient( args[3], PLAYERNAME, PORT )
			setClientCallbacks( client )
		else
			print( "Error. To start as client, you should give the address as the argument after 'client'." )
		end
	end]]

	--love.graphics.setBackgroundColor(25,25,25,255)
	love.graphics.setBackgroundColor( 20,80,20,255)
end

function love.update( dt )
	network:update( dt )
	if STATE == "Game" then
		game:update( dt )
		chat:update( dt )
	elseif STATE == "Lobby" then
		lobby:update( dt )
		chat:update( dt )
	elseif STATE == "Menu" then
		menu:update( dt )
	end
	ui:update( dt )
	ui:mousemoved( love.mouse.getPosition() )
end

function love.keypressed( key, unicode )
	--chat:keypressed( key )
	if chat.active then
		chat:keypressed( key )
	elseif not ui:keypressed( key, unicode ) then
		map:keypressed( key )
		chat:keypressed( key )
	end
end

function love.textinput( letter )
	--chat:textinput( letter )
	if chat.active then
		chat:textinput( letter )
	elseif (not ui:textinput( letter )) then
	end
end

function love.mousepressed( x, y, button )
	if ui:mousepressed( x, y, button ) then
		return
	end
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

