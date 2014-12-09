local lobby = {
	camMoveTime = 5,
	currentMapString = nil,
	ready = false,
	locked = false,
	timers = {},
}

lobby.colors = {
	{ 255, 0, 0 },
	{ 255, 255, 0 },
	{ 0, 255, 255 },
	{ 0, 0, 128 },
	{ 0, 0, 255 },
	{ 0, 255, 0 },
	{ 255, 128, 0 },
	{ 25, 25, 25 },
	{ 255, 0, 255 },
	{ 255, 255, 255 },
}

local scr

-- The first level in the list to display:
local levelListStart = 1
local levelNameList = nil

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
	self.locked = false

	self.timers = {}

	if server then
		for k, u in pairs( server:getUsers() ) do
			server:setUserValue( u, "ready", false )
		end
		if DEDICATED then
			local t = Timer:new( 5, function() dedicated:chooseMap() end )
			table.insert( self.timers, t )
			dedicated:postMatchLock()
		end
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
end

function lobby:draw()
	
	map:draw()

	lobby:drawUserList()
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
	if levelListStart > 1 then
		local entry = { txt="Up", event=function() lobby:moveLevelList( -1 ) end, key = "u" }
		table.insert( list, entry )
	end
	-- Display up to 8 items in the list:
	for i = levelListStart, levelListStart + 7 do
		if levelnames[i] then
			local entry = {
				txt=levelnames[i],
				event=function() self:chooseMap( levelnames[i] ) end,
			}
			table.insert( list, entry )
		end
	end
	if levelListStart + 7 < #levelnames then
		local entry = { txt="Down", event=function() lobby:moveLevelList( 1 ) end, key = "d" }
		table.insert( list, entry )
	end

	levelNameList = scr:newList( love.graphics.getWidth() - 150, 60, nil, list )
end

function lobby:moveLevelList( amount )
	levelListStart = levelListStart + amount
	lobby:createLevelList()
end

-- SERVER ONLY!
function lobby:chooseMap( levelname )

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

	map:newFromString(mapstring)

	if map.loaded then
		-- Remember for later:
		self.currentMapString = mapstring
		self:sendMap()
		print("\t->loaded!" )
	end
end
function lobby:sendMap( user )
	-- SERVER ONLY!
	if not server then return end

	if self.currentMapString then

		-- Remove linebreaks and replace by pipe symbol for sending.
		mapstring = self.currentMapString:gsub( "\n", "|" )
		if user then
			-- Send to single user?
			server:send( CMD.MAP, mapstring, user )
		else
			-- Broadcast to all:
			server:send( CMD.MAP, mapstring )
		end
	end
end

function lobby:receiveMap( mapstring )
	-- CLIENT ONLY!
	if not client then return end
	if server then return end
	-- Re-add line breaks:
	mapstring = mapstring:gsub( "|", "\n" )

	map:newFromString( mapstring )
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
	local users = network:getUsers()
	for k, u in pairs( users ) do
		if not u.customData.ready then
			allReady = false
			break
		end
	end

	-- If all clients are ready, then they must also all be synchronized.
	-- So we're ok to start.
	if allReady then
		self.locked = true		-- don't let any more users join!
		server:send( CMD.START_GAME )
		return true
	elseif not DEDICATED then
		local commands = {}
		commands[1] = { txt = "Ok", key = "y" }
		scr:newMsgBox( "Cannot start:", "All users must be ready.", nil, nil, nil, commands)
	end
	return false
end

function lobby:authorize( user )
	if self.locked then
		return false, "Game already started."
	else
		return true
	end
end

function lobby:setUserColor( user )
	-- SERVER ONLY!
	if server then
		math.randomseed( os.time() )
		local col = lobby.colors[ math.random(#lobby.colors) ]
		print("COLOR:", col[1], col[2], col[3] )
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

return lobby
