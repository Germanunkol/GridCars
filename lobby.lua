local lobby = {
	camMoveTime = 5,
	currentLevel = nil,
}

local scr

-- The first level in the list to display:
local levelListStart = 1
local levelNameList = nil

function lobby:init()
	
	scr = ui:newScreen( "lobby" )

	scr:addPanel( "topPanel",
			0, 0, 
			love.graphics.getWidth(), 40 )

	scr:addFunction( "topPanel", "close", 20, 0, "Leave", "q", lobby.close )

end

function lobby:show()
	STATE = "Lobby"
	ui:setActiveScreen( scr )

	-- If I'm the server, then let me choose the map:
	if server then
		levelListStart = 1	
		self:createLevelList()
		self:chooseMap( "map1.stl" )
	end
end

function lobby:update( dt )
	self.camMoveTime = self.camMoveTime + dt
	if self.camMoveTime > 5 then
		--local x = math.random( map.Boundary.minX, map.Boundary.maxX )
		--local y = math.random( map.Boundary.minY, map.Boundary.maxY )
		--map:swingCameraTo( x, y, 3 )
		self.camMoveTime = self.camMoveTime - 5	
	end
end

function lobby:draw()
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
			if u.userData.ready == true then
				local dx = love.graphics.getFont():getWidth( u.playerName )
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
		scr:removeList( levelNameList )
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

	map:new( "maps/" .. levelname )

	self.currentLevel = levelname
	self:sendMap()
end
function lobby:sendMap( user )
	-- SERVER ONLY!
	if not server then return end

	if self.currentLevel then

	-- Mapstring is the map, in serialized form:
	local mapstring = love.filesystem.read( "maps/" .. self.currentLevel )
	-- Remove linebreaks and replace by pipe symbol for sending.
	mapstring = mapstring:gsub( "\n", "|" )


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

return lobby
