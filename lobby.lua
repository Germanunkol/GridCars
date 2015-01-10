local lobby = {
	camMoveTime = 5,
	currentMapString = nil,
	ready = false,
	--locked = false,
	timers = {},
	countdown = nil,
}

lobby.colors = {
	{ 0, 0, 0 },
	{ 25, 25, 25 },
	{ 255, 255, 255 },

	{ 255, 0, 0 },
	{ 0, 255, 0 },
	{ 0, 0, 255 },

	{ 255, 255, 0 },
	{ 0, 255, 255 },
	{ 255, 0, 255 },

	{ 128, 0, 0 },
	{ 0, 128, 0 },
	{ 0, 0, 128 },

	{ 255, 128, 0 },
	{ 128, 255, 0 },
	{ 128, 0, 255 },
	{ 255, 0, 128 },
	{ 0, 255, 128 },
	{ 0, 128, 255 },

	{ 255, 128, 128 },
	{ 128, 255, 128 },
	{ 128, 128, 255 },
	{ 255, 128, 128 },
	{ 128, 255, 128 },
	{ 128, 128, 255 },

	{ 0, 128, 128 },
	{ 128, 0, 128 },
	{ 128, 128, 0 },

	{ 0, 64, 128 },
	{ 0, 128, 64 },
	{ 64, 0, 128 },
	{ 128, 0, 64 },
	{ 64, 128, 0 },
	{ 128, 64, 0 },
}

local scr

-- The first level in the list to display:
local levelListStart = 1
local levelNameList = nil
local ERROR_MSG = nil
local ERROR_TIMER = 0

function lobby:init()
	
	scr = ui:newScreen( "lobby" )

	scr:addPanel( "topPanel",
			0, 0, 
			love.graphics.getWidth(), 35 )

	scr:addFunction( "topPanel", "close", 20, 0, "Leave", "q", lobby.close )

	scr:addFunction( "topPanel", "ready", love.graphics.getWidth() - 100, 0, "Ready", "r",
		function() lobby:toggleReady() end )
end

function lobby:show()
	print("Starting lobby")
	STATE = "Lobby"

	--self.currentMapString = nil
	--self.locked = false

	self.timers = {}
	self.countdown = nil

	if server then
		for k, u in pairs( server:getUsers() ) do
			server:setUserValue( u, "ready", false )
			server:setUserValue( u, "ingame", false )
		end
		if DEDICATED then
			--[[local t = Timer:new( 5, function() dedicated:chooseMap() end )
			table.insert( self.timers, t )
			dedicated:postMatchLock()]]
			dedicated:chooseMap()
		end

		updateAdvertisementInfo()
	end

	if client then
		ui:setActiveScreen( scr )
		self.ready = false
		-- In case I was a server before, remove the server settings:
		if levelNameList ~= nil then
			scr:removeFunction( "topPanel", "start" )
			scr:removeList( levelNameList.name )
			levelNameList = nil
		end
		chat:show()
		if map.loaded then
			map:zoomOut()
		end

		ERROR_TIMER = 0
	end

	-- If I'm the server, then let me choose the map:
	if server and client then
		self:createLevelList()
		levelListStart = 1	

		scr:addFunction( "topPanel", "start", love.graphics.getWidth()/2 - 20, 0, "Start", "s",
			function() lobby:attemptGameStart() end )
	end
end

function lobby:update( dt )
	map:update( dt )

	if map.loaded then
		self.camMoveTime = self.camMoveTime + dt
		if self.camMoveTime > 4 then
			local x = math.random( map.Boundary.minX, map.Boundary.maxX )
			local y = math.random( map.Boundary.minY, map.Boundary.maxY )
			map:camSwingToPos( x, y, 2 )

			map:camZoom( 0.05 + math.random( 0, 1 )*0.05, 2)
			self.camMoveTime = self.camMoveTime - 4
		end
	end

	-- Continue any timers:
	for k, t in ipairs( self.timers ) do
		-- if the timer fires, delete it:
		if t:updateAndFire( dt ) then
			table.remove( self.timers, k )
		end
	end

	if self.countdown then
		self.countdown = self.countdown - dt
		if self.countdown < 5 and not self.sentCountdownTimes[math.ceil(self.countdown)] then
			if math.ceil(self.countdown) > 0 then
				server:send( CMD.SERVERCHAT, math.ceil(self.countdown))
				self.sentCountdownTimes[math.ceil(self.countdown)] = true
			end
		end
	end

	if ERROR_TIMER > 0 then
		ERROR_TIMER = ERROR_TIMER - dt
	end

	if client then
		stats:update( dt )
	end
end

function lobby:draw()
	
	map:draw()

	lobby:drawUserList()

	if ERROR_TIMER > 0 then
		love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill", 60, love.graphics.getHeight() - 70,
				love.graphics.getWidth() - 120, 60 )
		love.graphics.setColor( 255,128,0, 200 )
		love.graphics.printf( ERROR_MSG, 60, love.graphics.getHeight() - 60,
				love.graphics.getWidth() - 120, "center" )
	end

	if client then
		stats:draw()
	end
end

function lobby:drawUserList()
	-- Print list of users:
	love.graphics.setColor( 255,255,255, 255 )
	local users, num = network:getUsers()
	local x, y = 20, 60
	local i = 1
	if client and users then
		love.graphics.setColor( 0, 0, 0, 128 )
		love.graphics.rectangle( "fill", x - 5, y - 5, 300, num*20 + 5 )
		for k, u in pairs( users ) do
			love.graphics.setColor( 255,255,255, 255 )
			love.graphics.printf( i .. ":", x, y, 20, "right" )
			love.graphics.printf( u.playerName, x + 25, y, 250, "left" )
			if u.customData.ready == true then
				love.graphics.setColor( 128, 255, 128, 255 )
				local dx = love.graphics.getFont():getWidth( u.playerName ) + 30
				love.graphics.print( "[Ready]", x + dx, y )
			end
			y = y + 20
			i = i + 1
		end
	end
end

function lobby:keypressed( key )
end

function lobby:mousepressed( button, x, y )
end

function lobby:close()
	network:closeConnection()
end

function lobby:createLevelList()
	local levelnames = love.filesystem.getDirectoryItems( "maps" )
	if levelNameList then
		scr:removeList( levelNameList.name )
	end

	local list = {}
	--[[if levelListStart > 1 then
		local entry = { txt="Up", event=function() lobby:moveLevelList( -1 ) end, key = "u" }
		table.insert( list, entry )
	end]]
	-- Display up to 8 items in the list:
	for i = 1, #levelnames do
		if levelnames[i]:match("(.*).stl") or levelnames[i]:match("(.*).STL") then
			local entry = {
				txt=levelnames[i],
				event=function() self:chooseMap( levelnames[i] ) end,
			}
			table.insert( list, entry )
		end
	end
	--[[if levelListStart + 7 < #levelnames then
		local entry = { txt="Down", event=function() lobby:moveLevelList( 1 ) end, key = "d" }
		table.insert( list, entry )
	end]]

	levelNameList = scr:newList( love.graphics.getWidth() - 300, 60, 160, list, 9 )
end

function lobby:chooseMap( levelname )
	-- SERVER ONLY!
	if not server then return end

	print("Loading map: " .. levelname )

	self.currentMapString = nil

	-- Mapstring is the map, in serialized form:
	local mapstring
	if not DEDICATED then
		mapstring = love.filesystem.read( "maps/" .. levelname )
	else
		local f = io.open( "maps/" .. levelname, "r")
		if f then
			mapstring = f:read("*all")
			f:close()
		end
	end

	map:setName( levelname )

	map:newFromString(mapstring)

	if map.loaded then
		-- Remember for later:
		self.currentMapString = mapstring
		self:sendMap()
		print("\t->loaded!" )
		updateAdvertisementInfo()
	end
end

function lobby:sendMap( user )
	-- SERVER ONLY!
	if not server then return end

	if self.currentMapString then

		-- Remove linebreaks and replace by pipe symbol for sending.
		--mapstring = self.currentMapString:gsub( "\n", "|" )
		if user then
			-- Send to single user?
			server:send( CMD.MAP, self.currentMapString, user )
			server:send( CMD.LAPS, tostring(LAPS), user )
		else
			-- Broadcast to all:
			server:send( CMD.MAP, self.currentMapString )
			server:send( CMD.LAPS, tostring(LAPS) )
		end

	end
end

function lobby:receiveMap( mapstring )
	-- CLIENT ONLY!
	if not client then return end
	if server then return end
	-- Re-add line breaks (fallback for earlier versions:)
	if not mapstring:find( "\n" ) then
		mapstring = mapstring:gsub( "|", "\n" )
	end

	map:newFromString( mapstring )
end

function lobby:receiveLaps( laps )
	laps = tonumber(laps)
	game.numberOfLaps = laps
end

function lobby:toggleReady()
	if client then
		local ready = client:getUserValue( "ready" )
		client:setUserValue( "ready", not ready )
	end
end

function lobby:attemptGameStart()

	-- SERVER ONLY!
	if not server then return end

	if not map.loaded then
		if not DEDICATED then
			local commands = {}
			commands[1] = { txt = "Ok", key = "y" }
			scr:newMsgBox( "Cannot start:", "No valid map file loaded.", nil, nil, nil, commands)
		end
		return false
	end

	local allReady = true
	local usersReady = 0
	local users = network:getUsers()
	for k, u in pairs( users ) do
		if u.customData.ready then
			usersReady = usersReady + 1
		else
			allReady = false
		end
	end

	-- ON DEDICATED ONLY!
	if DEDICATED and not allReady then
		if usersReady == 0 then
			if self.countdown then
				self.countdown = nil
				server:send( CMD.SERVERCHAT, "Server halted countdown. No one is ready." )
			end
		else
			if self.countdown == nil then
				self.countdown = COUNTDOWN
				self.sentCountdownTimes = {}
				server:send( CMD.SERVERCHAT, "Round starts in " .. COUNTDOWN .. " seconds. Get ready to play! ('R' to join this round.)" )
			end
		end
	end

	-- If all clients are ready, then they must also all be synchronized.
	-- So we're ok to start.
	if allReady or (self.countdown and self.countdown <= 0 ) then
		lobby:startGame()
		return true
	elseif not DEDICATED then
		if usersReady >= 1 then
		local commands = {}
		commands[1] = { txt = "Yes", key = "y", event = function() lobby:startGame() end }
		commands[2] = { txt = "No, wait", key = "n" }
		scr:newMsgBox( "Are you sure you want to start?", "Some users aren't ready yet. They won't be part of the round if you start now.", nil, nil, nil, commands)
		else
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		scr:newMsgBox( "Cannot start:", "No one is ready yet.", nil, nil, nil, commands)
	end
	end
	return false
end

function lobby:startGame()
		--self.locked = true		-- don't let any more users join!
		server:send( CMD.START_GAME )
		--lobby:kickAllWhoArentReady()
		self.countdown = nil

		for k, u in pairs( server:getUsers() ) do
			if u.customData.ready then
				server:setUserValue( u, "ingame", true )	-- everyone else is spectating!
			end
		end
end

function lobby:authorize( user, authorizationRequest )
	--[[if self.locked then
		return false, "Game already started."
	else
		return true
	end]]
	-- Let only users running the correct version authorize:
	if authorizationRequest == VERSION then
		return true
	else
		return false, "Version mismatch. You're running version " .. authorizationRequest ..
		", server version is " .. VERSION .. "."
	end
end

function lobby:setUserColor( user )
	-- SERVER ONLY!
	if server then
		math.randomseed( os.time() )
		local col = lobby.colors[ math.random(#lobby.colors) ]
		server:setUserValue( user, "red", col[1] )
		server:setUserValue( user, "green", col[2] )
		server:setUserValue( user, "blue", col[3] )
		server:setUserValue( user, "body", math.random(NUM_CAR_IMAGES) )
	end
end

function lobby:errorMsg( msg )
	local commands = {}
	commands[1] = { txt = "Ok", key = "y" }
	scr:newMsgBox( "Error loading map:", msg, nil, nil, nil, commands)
end

function lobby:kickAllWhoArentReady()
	if server then
		local users = network:getUsers()
		for k, u in pairs( users ) do
			if not u.customData.ready then
				server:kickUser( u, "Game started, and you were not ready." )
			end
		end
	end
end

function lobby:newWarning( msg )
	ERROR_MSG = msg
	ERROR_TIMER = 10
end

return lobby
