-- This defines all the callbacks needed by server and client.
-- Callbacks are called when certain events happen.

VERSION = "0.5"

-- These are all possible commands clients of the server can send:
CMD = {
	CHAT = 128,
	MAP = 129,
	START_GAME = 130,
	GAMESTATE = 131,
	NEW_CAR = 132,
	MOVE_CAR = 133,
	PLAYER_WINS = 134,
	BACK_TO_LOBBY = 135,
	LAPS = 136,
	SERVERCHAT = 138,
	STAT = 139,
}

function setServerCallbacks( server )
	server.callbacks.received = serverReceived
	server.callbacks.synchronize = synchronize
	server.callbacks.authorize = function( user, msg ) return lobby:authorize( user, msg ) end
	server.callbacks.userFullyConnected = newUser
	server.callbacks.disconnectedUser = disconnectedUser

	-- Called when there's an error advertising (only on NON-DEDICATED server!):
	network.advertise.callbacks.advertiseWarnings = advertisementMsg
end
function setClientCallbacks( client )
	-- set client callbacks:
	client.callbacks.received = clientReceived
	client.callbacks.connected = connected
	client.callbacks.disconnected = disconnected
	client.callbacks.newUser = newUserClient
	-- Called when user is authorized or not (in the second case, a reason is given):
	client.callbacks.authorized = function( auth, reason ) menu:authorized( auth, reason ) end
end

-- Called when client is connected to the server
function connected()
	lobby:show()
	menu:closeConnectPanel()
end
-- Called on server when client is connected to server:
function newUser( user )
	lobby:setUserColor( user )
	server:setUserValue( user, "moved", true )
	server:setUserValue( user, "roundsWon", 0 )
	server:send( CMD.SERVERCHAT, WELCOME_MSG, user )
	if DEDICATED then
		utility.log( "[" .. os.time() .. "] New user: " ..
			user.playerName .. " (" .. server:getNumUsers() .. ")" )
	end
	
	-- update advertisement:
	updateAdvertisementInfo()
end

-- Called when client is disconnected from the server
function disconnected( msg )
	menu:show()
	if msg and #msg > 0 then
		menu:errorMsg( "You have been kicked:", msg )
	end
	client = nil
	server = nil
end

-- Called on server when user disconnects:
function disconnectedUser( user )
	if DEDICATED then
		utility.log( "[" .. os.time() .. "] User left: " ..
			user.playerName .. " (" .. server:getNumUsers() .. ")" )
	end

	-- update advertisement:
	updateAdvertisementInfo()
end

-- Called on server when new client is in the process of
-- connecting.
function synchronize( user )
	-- If the server has a map chosen, let the new client know
	-- about it:
	lobby:sendMap( user )
	if STATE == "Game" then
		server:send( CMD.START_GAME, "", user )
		game:synchronizeCars( user )
	end
end

function newUserClient( user )
	if client and client.authorized then
		Sounds:play( "beep" )
	end
end

function serverReceived( command, msg, user )
	if command == CMD.CHAT then
		-- broadcast chat messages on to all players
		server:send( command, user.playerName .. ": " .. msg )
	elseif command == CMD.MOVE_CAR then
		local x, y = msg:match( "(.*)|(.*)" )
		print( "move car:", user.id, x, y, msg)
		game:validateCarMovement( user.id, x, y )
	end
end

function clientReceived( command, msg )
	if command == CMD.CHAT then
		chat:newLineSpeech( msg )
	elseif command == CMD.SERVERCHAT then
		chat:newLineServer( msg )
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
	elseif command == CMD.LAPS then
		lobby:receiveLaps( msg )
	elseif command == CMD.STAT then
		stats:add( msg )
	end
end

function updateAdvertisementInfo()
	if server then
		local players, num = network:getUsers()
		if num then
			serverInfo.numPlayers = num
		end
		if STATE == "Game" then
			serverInfo.state = "Game"
		else
			serverInfo.state = "Lobby"
		end
		serverInfo.map = map:getName()
		network.advertise:setInfo( utility.createServerInfo() )
	end
end

function advertisementMsg( msg )
	if STATE == "Lobby" then
		lobby:newWarning( "Could not advertise your game online:\n" .. msg )
	end
end

