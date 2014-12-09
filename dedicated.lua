-- Run this file to run a dedicated server.
-- Make sure the config.txt file is edited to fit the settings you want to have.

DEDICATED = true

STATE = "Menu"

-- Lua file system:
require("lfs")

network = require( "network.network" )
config = require( "config" )
game = require( "game" )
lobby = require( "lobby" )
map = require( "map" )
utility = require( "utility" )		-- helper functions
require( "callbacks" )		-- helper functions

local dedicated = {
	currentMapName = nil
}

config.load()

--lobby:init()
game:init()
map:load()

function dedicated:startServer()
	local success
	success, server = pcall( function()
		return network:startServer( MAX_PLAYERS, PORT )
	end)

	if success then
		-- set client callbacks:
		setServerCallbacks( server )
		lobby:show()
		dedicated:chooseMap()
	else
		-- If I can't start a server for some reason, let user know and exit:
		print(server)
		os.exit()
	end
end

function dedicated:update( dt )

	if STATE == "Lobby" then

		-- Wait for at least one user:
		if server:getNumUsers() > 0 then
			-- Check if all clients are ready and if so start game
			if lobby:attemptGameStart() then
				game:show()
			end
		end
	elseif STATE == "Game" then
		-- Let's hope it never gets below 0... :P
		if server:getNumUsers() <= 0 then
			lobby:show()
			dedicated:chooseMap()
		end
	end
end

function getDirectoryItems( dir )
	local f = {}
	for file in lfs.dir( dir ) do
		if file ~= "." and file ~= ".." then
			table.insert( f, file )
		end
	end
	return f
end

function dedicated:chooseMap()
	local files = getDirectoryItems( "maps/" )

	if #files < 1 then
		return
	end

	-- first map?
	if dedicated.currentMapName == nil then
		dedicated.currentMapName = files[1]
	else
		for k, f in ipairs(files) do
			if f == dedicated.currentMapName then
				if files[k+1] then
					dedicated.currentMapName = files[k+1]
				else
					dedicated.currentMapName = files[1]
				end
				break
			end
		end
	end
	lobby:chooseMap( dedicated.currentMapName )
end

-- Call the function to start the server right at startup
dedicated:startServer()

function sleep(sec)
    socket.select(nil, nil, sec)
end
-- Continue running for ever:
local time = os.clock()
local dt = 0
local t = 0
while true do
	network:update( dt )
	if STATE == "Game" then
		game:update( dt )
	elseif STATE == "Lobby" then
		lobby:update( dt )
	end

	dedicated:update( dt )

	dt = socket.gettime() - time
	time = socket.gettime()

	sleep( 0.05 )
end
