-- Run this file to run a dedicated server.
-- Make sure the config.txt file is edited to fit the settings you want to have.

--[[print = function(...)
	local args = {...}
	origPrint( unpack(args) )
	local str = ""
	for k, v in pairs(args) do
		str = str .. v .. "\t"
	end
	--love.filesystem.append( "log.txt", str .. "\r\n" )
	local file = io.open( "printLog.txt", "a")
	file:write( str .. "\n" )
	file:close()
end]]

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
Timer = require("timer")

dedicated = {
	currentMapName = nil
}

config.load()

--lobby:init()
--game:init()
map:load()

MAIN_SERVER_URL = "http://germanunkol.de/gridcars/serverlist"
GAME_ID = "GridCars" .. VERSION

function dedicated:startServer()
	local success
	success, server = pcall( function()
		return network:startServer( MAX_PLAYERS, PORT )
	end)

	if success then
		-- set client callbacks:
		setServerCallbacks( server )
		lobby:show()

		updateAdvertisementInfo()
		network.advertise:setURL( MAIN_SERVER_URL )
		network.advertise:setID( GAME_ID )

		network.advertise:start( server, "both" )

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
			if not self.postMatchLocked then
				if lobby:attemptGameStart() then
					game:show()
				end
			end
		end
	elseif STATE == "Game" then
		-- Let's hope it never gets below 0... :P
		if game:getNumUsersPlaying() <= 0 then
			game:sendBackToLobby()
		end
	end
end

-- Show the old map for a set period of time.
function dedicated:postMatchLock()
	self.postMatchLocked = true
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
	if self.currentMapName == nil then
		self.currentMapName = files[1]
	else
		for k, f in ipairs(files) do
			if f == self.currentMapName then
				if files[k+1] then
					self.currentMapName = files[k+1]
				else
					self.currentMapName = files[1]
				end
				break
			end
		end
	end
	lobby:chooseMap( self.currentMapName )

	self.postMatchLocked = false
end

-- Call the function to start the server right at startup
dedicated:startServer()

function sleep(sec)
    socket.select(nil, nil, sec)
end
-- Continue running for ever:
local time = socket.gettime()
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
