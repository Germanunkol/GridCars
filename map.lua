local map = {
	triangles = {},
	Boundary = {},
	nullpunkt = {},
	cars = {},
	subjects = {},
	View = {},
	loaded = false,
}

local Camera = require "lib/hump.camera"
local Car = require "car"
local mapSubject = require "environment"
local CamTargetX = 0
local CamTargetY = 0
local CamStartX = 0
local CamStartY = 0
local CamZoomTime = 0
local CamSwingTime = 0
local CamZoomTimePassed = 0
local CamSwingTimePassed = 0
local dx, dy, ZoomIs, mul, ZoomTarget, ZoomStart = 0, 0, 1, 1, 0.1, 0.1
local cam = nil
local CamOffset = -0.05
local GridColorSmall = {255, 255, 160, 25}
local GridColorBig = {255, 255, 160, 50}
local GridSizeSmallStep = 100
local GridSizeBigStep = 500
-- different Subjects:
local maxS_OnePivot = 200  -- trees, ...
local maxS_QuadPivot = 20 -- houses, ...
local SubjectListOnePivot = {"Baum1", "Baum2", "Baum3", "BaumKl1", "BaumKl2", "BaumKl3"}
local SubjectListQuadPivot = {"Haus1", "Haus2", "Haus3", "Haus4", "HausLang1", "HausLang2", "Kidz1", "Brunnen", "laternenumzug", "Markt1", "Markt2", "Schafe", "See", "Feld", "Traktor"}
local noShadows = {"Schafe", "See", "laternenumzug", "Markt1", "Markt2", "Kidz1", "Feld", "Traktor"}
GRIDSIZE = GridSizeSmallStep
local MapScale = 500

--wird einmalig bei Spielstart aufgerufen
function map:load()
	map.View.x = 0
	map.View.y = 0
	cam = Camera(map.View.x, map.View.y)
end

DEBUG_POINT_LIST = {}

--wird zum laden neuer Maps öfters aufgerufen
-- ACHTUNG: Bitte nur noch map:newFromString aufrufen!
--[[function map:new( mapstring ) -- Parameterbeispiel: "testtrackstl.stl"

	-- Read full file and save it in mapstring:
	local mapstring
	if not DEDICATED then
		mapstring = love.filesystem.read( dateiname )
	else
		local f = io.open(dateiname, "r")
		if f then
			mapstring = f:read("*all")
			f:close()
		end
	end

	self:newFromString( mapstring )
end]]

function map:newFromString( mapstring )

	map.loaded = false
	if not mapstring or #mapstring == 0 then
		print("Trying to load map from empty string!")
		return
	end

	local success, msg = map:import(mapstring)
	if not success then
		print("error loading map: ", msg)
		lobby:errorMsg( msg )
		map:reset()
		return
	else
		map:getBoundary()

		map:zoomOut()
		
		local cX = map.Boundary.minX + (map.Boundary.maxX - map.Boundary.minX)*0.5
		local cY = map.Boundary.minY + (map.Boundary.maxY - map.Boundary.minY)*0.5
		map:camSwingToPos( cX, cY, 5 )

		--[[if server and not map.msgSent then
			map.msgSent = true
			server:send( CMD.CHAT, WELCOME_MSG )
		end]]

		if not DEDICATED then
			math.randomseed( utility.numFromString( mapstring:sub(1, 100 ) ) )
			--ZoomTarget = 50/MapScale -- startzoom depends on MapScale
			-- create Environment
			-- plant Subjects with big Pivots
			for i = 1, maxS_QuadPivot, 1 do
				--search fitting positon
				local x = math.random(map.Boundary.minX, map.Boundary.maxX)
				local y = math.random(map.Boundary.minY, map.Boundary.maxY)
				-- check every pivot, ugly as shit but workes
				local onRoad = 0
				local pivotX = x + GridSizeBigStep
				local pivotY = y + GridSizeBigStep
				if map:isPointOnRoad(pivotX, pivotY, 0) == true then
					onRoad = onRoad + 1
				end
				local pivotX = x - GridSizeBigStep
				local pivotY = y + GridSizeBigStep
				if map:isPointOnRoad(pivotX, pivotY, 0) == true then
					onRoad = onRoad + 1
				end
				local pivotX = x + GridSizeBigStep
				local pivotY = y - GridSizeBigStep
				if map:isPointOnRoad(pivotX, pivotY, 0) == true then
					onRoad = onRoad + 1
				end
				local pivotX = x - GridSizeBigStep
				local pivotY = y - GridSizeBigStep
				if map:isPointOnRoad(pivotX, pivotY, 0) == true then
					onRoad = onRoad + 1
				end
				if onRoad == 0 then
					local nSubject = math.random(1, utility.tablelength(SubjectListQuadPivot))
					local s = mapSubject:new(SubjectListQuadPivot[nSubject], x, y) -- choose random subject
					for key, str in pairs(noShadows) do
						if str == SubjectListQuadPivot[nSubject] then
							s.castshadow = false
							--print(SubjectListQuadPivot[nSubject], "has no shadow")
						end
					end
					table.insert(map.subjects, s)
					--s.r = math.pi
				end
			end
			-- plant Subjects with one Pivot
			for i = 1, maxS_OnePivot, 1 do
				--search fitting positon
				local x = math.random(map.Boundary.minX, map.Boundary.maxX)
				local y = math.random(map.Boundary.minY, map.Boundary.maxY)
				while map:isPointOnRoad(x, y, 0) == true do
					x = math.random(map.Boundary.minX, map.Boundary.maxX)
					y = math.random(map.Boundary.minY, map.Boundary.maxY)
				end
				local nSubject = math.random(1, utility.tablelength(SubjectListOnePivot))
				local s = mapSubject:new(SubjectListOnePivot[nSubject], x, y) -- choose random subject
				table.insert(map.subjects, s)
			end
		end
	end
end

function map:update( dt )
	-- Make sure a map is loaded first!
	if not map.loaded then return end

	cam.rot = CamOffset
	--cam:zoomTo(ZoomTarget)
	if CamZoomTime then
		CamZoomTimePassed = CamZoomTimePassed + dt
		if CamZoomTimePassed < CamZoomTime then
			local amount = utility.interpolateCos(CamZoomTimePassed/CamZoomTime)
			ZoomIs = ZoomStart + (ZoomTarget - ZoomStart) * amount
		else
			--mul = ZoomTarget
			ZoomIs = ZoomTarget
			CamZoomTime = nil
		end
		cam:zoomTo(ZoomIs)
		--else
		--cam:zoom(mul)
	end

	if CamSwingTime then
		CamSwingTimePassed = CamSwingTimePassed + dt
		if CamSwingTimePassed < CamSwingTime then
			local amount = utility.interpolateCos(CamSwingTimePassed/CamSwingTime)
			CamX = CamStartX + (CamTargetX - CamStartX) * amount
			CamY = CamStartY + (CamTargetY - CamStartY) * amount
		else
			CamX = CamTargetX
			CamY = CamTargetY
			CamSwingTime = nil
		end
		cam:lookAt(CamX,CamY)
	else
		if not DEDICATED then
			if STATE == "Game" and not chat.active then
				local dx = ((love.keyboard.isDown('d') or love.keyboard.isDown('right')) and 1 or 0) 
					- ((love.keyboard.isDown('a') or love.keyboard.isDown('left')) and 1 or 0)
				local dy = ((love.keyboard.isDown('s') or love.keyboard.isDown('down')) and 1 or 0)
					- ((love.keyboard.isDown('w') or love.keyboard.isDown('up')) and 1 or 0)
				dx = dx * (map.Boundary.maxX-map.Boundary.minX)/5 *dt  --GridSizeSmallStep 	--*dt
				dy = dy * (map.Boundary.maxY-map.Boundary.minY)/5 *dt  --GridSizeSmallStep   --*dt
				cam:move(dx, dy)
			end
		end
	end
	--mul = 1

	for id, car in pairs(map.cars) do
		car:update(dt)
		--[[if self:isPointOnRoad( car.x, car.y, 0 ) then
		car.color = { 255, 128, 128, 255 }
		else
		car.color = blue
		end]]
	end
end

function map:draw()

	-- Make sure a map is loaded first!
	if not map.loaded then return end

	cam:attach()
	-- draw World
	-- draw ground
	love.graphics.setColor( 40, 40, 40, 255 )
	for key, triang in pairs(map.triangles) do
		love.graphics.polygon( 'fill',
		triang.vertices[1].x,
		triang.vertices[1].y,
		triang.vertices[2].x,
		triang.vertices[2].y,
		triang.vertices[3].x,
		triang.vertices[3].y
		)
	end

	if self.startLine then
		love.graphics.setLineWidth( 30 )
		love.graphics.setColor( 50, 50, 50, 100 )
		--[[love.graphics.polygon( "fill", 
		self.startTriangle[1].x,
		self.startTriangle[1].y,
		self.startTriangle[2].x,
		self.startTriangle[2].y,
		self.startTriangle[3].x,
		self.startTriangle[3].y
		)]]
		love.graphics.setColor( 150, 150, 150, 100 )
		love.graphics.line( self.startLine.p1.x, self.startLine.p1.y,
		self.startLine.p2.x, self.startLine.p2.y )
		love.graphics.circle( "fill", self.startProjPoint.x, self.startProjPoint.y, 5 )

		--[[love.graphics.setColor( 0, 255,0, 255 )
		love.graphics.circle( "fill", self.startPoint.x, self.startPoint.y, 5 )
		love.graphics.setColor( 255,0,0, 255)
		love.graphics.circle( "fill", self.endPoint.x, self.endPoint.y, 5 )]]
	end

	-- draw grid
	map:drawGrid()
	-- draw player
	for id, c in pairs(map.cars) do
		c:draw()
	end
	-- draw environment
	for id, s in ipairs(map.subjects) do
		s:draw()
	end

	cam:detach()
end

function map:addDebugPoint( x, y, col )
	table.insert( DEBUG_POINT_LIST, {x=x, y=y, color = col} )
end

function map:drawDebug()
	if client then
		cam:attach()
		love.graphics.setPointSize( 5 )
		for i, p in pairs( DEBUG_POINT_LIST ) do
			love.graphics.setColor( p.color )
			love.graphics.point( p.x, p.y )
		end
		cam:detach()
	end
end

function map:drawTargetPoints( id )
	cam:attach()
	local car = map.cars[id]
	if car then
		car:drawTargetPoints()	
	end
	cam:detach()
end

function map:drawCarInfo()
	cam:attach()
	for k, c in pairs( map.cars ) do
		c:drawInfo()
	end
	cam:detach()
end

function map:drawGrid()
	love.graphics.setLineWidth(1)
	if cam.scale > 0.14 then
		for i = 0, map.Boundary.maxX+math.abs(map.Boundary.minX), GridSizeSmallStep do
			if i % GridSizeBigStep == 0 then
				love.graphics.setColor(GridColorBig)
			else
				love.graphics.setColor(GridColorSmall)
			end
			love.graphics.line(i+map.Boundary.minX, map.Boundary.minY, i+map.Boundary.minX, map.Boundary.maxY)
		end
		for i = 0, map.Boundary.maxY+math.abs(map.Boundary.minY), GridSizeSmallStep do
			if i % GridSizeBigStep == 0 then
				love.graphics.setColor(GridColorBig)
			else
				love.graphics.setColor(GridColorSmall)
			end
			love.graphics.line(map.Boundary.minX, i+map.Boundary.minY, map.Boundary.maxX, i+map.Boundary.minY)
		end
	else
		love.graphics.setColor(GridColorSmall)
		for i = 0, map.Boundary.maxX+math.abs(map.Boundary.minX), GridSizeBigStep do
			love.graphics.line(i+map.Boundary.minX, map.Boundary.minY, i+map.Boundary.minX, map.Boundary.maxY)
		end
		for i = 0, map.Boundary.maxY+math.abs(map.Boundary.minY), GridSizeBigStep do
			love.graphics.line(map.Boundary.minX, i+map.Boundary.minY, map.Boundary.maxX, i+map.Boundary.minY)
		end
	end
end

function map:reset()
	map.cars = {}
	map.Boundary = {	minX = math.huge,
						minY = math.huge,
						maxX = -math.huge,
						maxY = -math.huge,
					}
	map.subjects = {}

	map.triangles = {}
	map.startLine = nil
	map.startPositions = {}
	map.driveAngle = 0

	map:camSwingAbort()

	map.loaded = false
end

function map:import( mapstring )

	map:reset()

	local vertices = {}
	local positions = {"x", "y", "z"}
	local counterT = 1 -- Counter für Triangle
	local counterV = 1 -- Counter für Vertices
	local startpos, endpos
	--for line in love.filesystem.lines(Dateiname) do
	for line in string.gmatch( mapstring, "(.-)\r?\n" ) do
		if(string.find(line,"vertex") ~= nil) then
			vertices[counterV] = {}
			-- separiere Koordinaten mit Hilfe der Leerzeichen
			-- Aufbau in stl: "vertex 2.954973 2.911713 1.000000"
			-- -> "vertex[leer](-)[8xNum][leer](-)[8xNum][leer](-)[8xNum]"
			local x,y,z = string.match( line, "vertex (-?%d*.?%d*) (-?%d*.?%d*) (-?%d*.?%d*)" )
			vertices[counterV].x = tonumber(x) * MapScale
			vertices[counterV].y = tonumber(y) * MapScale
			vertices[counterV].z = tonumber(z) * MapScale
			--[[
			for key, value in ipairs(positions) do
				startpos = string.find(line," ")
				line = string.sub(line, startpos+1)
				startpos = 0
				endpos = string.find(line," ")
				vertices[counterV][value] = tonumber(string.sub(line, startpos, endpos)) * MapScale
			end]]
			--print("Vertex  No",counterV, vertices[counterV].x, vertices[counterV].y,  vertices[counterV].z)
			-- jeder dritte Vertex ergibt ein Dreieck
			if counterV%3 == 0 then


				-- Round the vertices on the z axis:
				vertices[counterV].z = math.floor( vertices[counterV].z/MapScale + 0.5 )*MapScale
				vertices[counterV-1].z = math.floor( vertices[counterV-1].z/MapScale + 0.5 )*MapScale
				vertices[counterV-2].z = math.floor( vertices[counterV-2].z/MapScale + 0.5 )*MapScale

				-- flip y coordinate:
				vertices[counterV].y = -vertices[counterV].y
				vertices[counterV-1].y = -vertices[counterV-1].y
				vertices[counterV-2].y = -vertices[counterV-2].y

				-- Vertices on layer z = 0 are part of the base mesh:
				if vertices[counterV].z == 0 and vertices[counterV-1].z == 0 and
						vertices[counterV-2].z == 0 then

					local newTriangle = {
						vertices[counterV-2],
						vertices[counterV-1],
						vertices[counterV]
					}

					local area = utility.triangleArea( newTriangle )

					--print("Area", area)
					if area > 0 then
						counterT = counterT + 1
						map.triangles[counterT] = {}
						map.triangles[counterT].vertices = newTriangle
					end

				elseif vertices[counterV].z == MapScale and vertices[counterV-1].z == MapScale and
						vertices[counterV-2].z == MapScale then
					-- Vertices on layer z = 1 are on the higher layer...
				
				elseif vertices[counterV].z == MapScale*2 and vertices[counterV-1].z == MapScale*2 and
						vertices[counterV-2].z == MapScale*2 then
					if not map.startLine then
						local d1 = utility.dist( vertices[counterV], vertices[counterV-1] )
						local d2 = utility.dist( vertices[counterV-1], vertices[counterV-2] )
						local d3 = utility.dist( vertices[counterV-2], vertices[counterV] )
						local p1, p2, p3

						-- Look for the longest distance - that's the starting line!
						if d1 > d2 and d1 > d3 then
							p1 = vertices[counterV]
							p2 = vertices[counterV-1]
							p3 = vertices[counterV-2]
						elseif d2 > d1 and d2 > d3 then
							p1 = vertices[counterV-1]
							p2 = vertices[counterV-2]
							p3 = vertices[counterV]
						else
							p1 = vertices[counterV-2]
							p2 = vertices[counterV]
							p3 = vertices[counterV-1]
						end
						
						-- This is the line the players need to cross in order to win
						map.startLine = { p1 = p1, p2 = p2 }
						map.startTriangle = { p1, p2, p3 }

						if whichSideOfLine( p1,p2, p3 ) == 0 then
							map.startLine = nil
							return false, "Start line is not a proper triangle."
						end

						map.startProjPoint = projectPointOntoLine( p1,p2, p3 )

						local diff = {
							x = p3.x - map.startProjPoint.x,
							y = p3.y - map.startProjPoint.y
						}

						map.startPoint = p3
						map.endPoint = {
							x = p3.x - 2*diff.x,
							y = p3.y - 2*diff.y
						}
						
						local driveDir = {
							x = map.startPoint.x - map.startProjPoint.x,
							y = map.startPoint.y - map.startProjPoint.y
						}
						map.driveAngle = math.atan2( driveDir.x, -driveDir.y )
					end
				elseif vertices[counterV].z == MapScale*3 and vertices[counterV-1].z == MapScale*3 and
						vertices[counterV-2].z == MapScale*3 then

					local x = math.floor(vertices[counterV].x/GRIDSIZE)*GRIDSIZE
					local y = math.floor(vertices[counterV].y/GRIDSIZE)*GRIDSIZE
					local found = false
					for k, s in pairs( map.startPositions ) do
						if s.x == x and s.y == y then
							found = true
							print("\tDuplicate start pos! Removing.", x, y)
							break
						end
					end
					if not found then
						table.insert( map.startPositions, {x = x, y = y} )
					end
				end
			end
			counterV = counterV + 1
		end
	end

	-- Consider the map as "loaded" if the list of triangles is not empty
	if #map.triangles < 1 then
		return false, "Number of triangles is 0. Make sure to save the map file as ASCII stl."
	end

	if not map.startLine then
		return false, "No start line found."
	end

	if server then
		if #map.startPositions < MAX_PLAYERS then
			return false, "Map only has " .. #map.startPositions .. " start positions, but you allow up to " .. MAX_PLAYERS .. " players. Change MAX_PLAYERS in config.txt."
		end
	end

	table.sort( map.startPositions, sortStartPositions )

	map.loaded = true
	return true
end

-- Sort the start positions: the closer they are to the start line, the earlier they should come.
function sortStartPositions( a, b )
	if a and b then
		if utility.dist( a, map.startProjPoint ) < utility.dist( b, map.startProjPoint ) then
			return true
		else
			return false
		end
	else
		return false
	end
end


-- Check if the given coordinates are on the road:
function map:isPointOnRoad( x, y, z )
	local p = {x=x,y=y}
	for k, tr in pairs( self.triangles ) do
		-- if the point is in any of the triangles, then it's considered to be on the road:
		if utility.pointInTriangle( p, tr.vertices[1], tr.vertices[2], tr.vertices[3] ) then
			return true
		end
	end
	return false
end

function map:camZoom(zoom, time)
	if (not CamZoomTime) then
		ZoomTarget = zoom
		ZoomStart = cam.scale
		CamZoomTime = time
		CamZoomTimePassed = 0
	end
end
function map:camSwingToPos(x, y, time) --, zoom, time)
	if (not CamSwingTime) then
		CamTargetX = x
		CamTargetY = y
		CamStartX, CamStartY = cam:pos()
		CamSwingTime = time
		--ZoomTarget = zoom or ZoomIs -- zoom = nil or false -> ZoomIs
		--ZoomStart = ZoomIs
		--if zoom == nil then
		--	CamZoomTime = 0
		--else
		--	CamZoomTime = time
		--end
		--CamZoomTimePassed = 0
		CamSwingTimePassed = 0
	end
end

function map:camSwingAbort()
	CamSwingTime = nil
	CamZoomTime = nil
end

function map:updatecam(dt)
end

function map:getBoundary() -- liefert maximale und minimale x und y Koordinaten
	map.Boundary.minX = math.huge
	map.Boundary.minY = math.huge
	map.Boundary.maxX = -math.huge
	map.Boundary.maxY = -math.huge
	for key, value in pairs(map.triangles) do
		for i = 1, 3, 1 do
			map.Boundary.minX = math.min(map.triangles[key].vertices[i].x, map.Boundary.minX)
			map.Boundary.minY = math.min(map.triangles[key].vertices[i].y, map.Boundary.minY)
			map.Boundary.maxX = math.max(map.triangles[key].vertices[i].x, map.Boundary.maxX)
			map.Boundary.maxY = math.max(map.triangles[key].vertices[i].y, map.Boundary.maxY)
		end
	end
	map.nullpunkt = {
			x = map.Boundary.minX - 3*GridSizeBigStep,
			y = map.Boundary.minY - 3*GridSizeBigStep,
		}
	--local mapSizePixelX = math.abs(nullpunkt.x) + map.Boundary.maxX + 3*GridSizeBigStep
	--local mapSizePixelY = math.abs(nullpunkt.y) + map.Boundary.maxY + 3*GridSizeBigStep
	--local mapSizeGridX = mapSizePixelX / GridSizeSmallStep
	--local mapSizeGridY = mapSizePixelY / GridSizeSmallStep
	--print("mapSizePixelX:", mapSizePixelX, "mapSizePixelY:", mapSizePixelY)
	--print("mapSizeGridX:", mapSizeGridX, "mapSizeGridY:", mapSizeGridY)
	--for i = 1, mapSizeGridX, 1 do
	--	map.grid[i] = {}
	--	for j = 1, mapSizeGridY, 1 do
	--		map.grid[i][j] = {pxlX = i*GridSizeSmallStep, pxlY = j*GridSizeSmallStep}
	--	end
	--end
	--utility.printTable(map.grid)

	--print("Bound.: ", math.abs(map.Boundary.minX)+map.Boundary.maxX)
	--print("gerundet: ", (math.abs(map.Boundary.minX)+map.Boundary.maxX)%GridSizeSmallStep)
	map.Boundary.minX = map.Boundary.minX - map.Boundary.minX % GridSizeBigStep - 3*GridSizeBigStep
	map.Boundary.minY = map.Boundary.minY - map.Boundary.minY % GridSizeBigStep - 3*GridSizeBigStep
	map.Boundary.maxX = map.Boundary.maxX + 4*GridSizeBigStep
	map.Boundary.maxX = map.Boundary.maxX - map.Boundary.maxX % GridSizeBigStep
	map.Boundary.maxY = map.Boundary.maxY + 4*GridSizeBigStep
	map.Boundary.maxY = map.Boundary.maxY - map.Boundary.maxY % GridSizeBigStep

end

function map:keypressed( key )
	--if key == "p" then
		--print(map.grid[x][y].pxlX, map.grid[x][y].pxlY)
		--map:setCarPos(1, map.grid[x][y].pxlX, map.grid[x][y].pxlY)
	--	local x = -math.random(0,5)
	--	local y = math.random(0,5)
	--	map:setCarPos(1, x, y)
	--end
	if key == "+" then
		CamZoomTime = nil
		cam:zoom( 0.9 )
		if cam.scale < 0.01 then
			cam.scale = 0.01
		end
		--ZoomTarget = math.min(ZoomTarget + 0.1, 1)
		--map:camZoom(ZoomTarget, 1)
		--ZoomTarget = ZoomTarget + 0.01
	end
	if key == "-" then
		CamZoomTime = nil
		cam:zoom( 1.1 )
		if cam.scale > 1.5 then
			cam.scale = 1.5
		end
		--ZoomTarget = math.max(ZoomTarget - 0.1, 0.1)
		--map:camZoom(ZoomTarget, 1)
		--ZoomTarget = ZoomTarget - 0.01
	end
end

function map:mousepressed( x, y, button )
	if button == "wd" then
		CamZoomTime = nil
		cam:zoom( 0.9 )
		if cam.scale < 0.01 then
			cam.scale = 0.01
		end
		--ZoomTarget = math.min(ZoomTarget + 0.1, 1)
		--map:camZoom(ZoomTarget, 1)
		--ZoomTarget = ZoomTarget + 0.01
	end
	if button == "wu" then
		CamZoomTime = nil
		cam:zoom( 1.1 )
		if cam.scale > 1.5 then
			cam.scale = 1.5
		end
		--ZoomTarget = math.max(ZoomTarget - 0.1, 0.1)
		--map:camZoom(ZoomTarget, 1)
		--ZoomTarget = ZoomTarget - 0.01
	end
end

function map:TransCoordPtG(pos)
	pos = pos / GRIDSIZE
	return pos
end
function map:TransCoordGtP(pos)
	pos = pos * GRIDSIZE
	return pos
end

function map:setCarPos(id, posX, posY) --car-id as number, pos as Gridpos
	posX = map:TransCoordGtP(posX)
	posY = map:TransCoordGtP(posY)
	map.cars[id]:MoveToPos(posX, posY, 1)

	if client and client:getID() == id then
		map:camSwingToPos(posX, posY, 1)
	end

	map:checkRoundTransition( id )
end

function map:setCarPosDirectly(id, posX, posY) --car-id as number, pos as Gridpos
	posX = map:TransCoordGtP(posX)
	posY = map:TransCoordGtP(posY)
	map.cars[id]:setPos(posX, posY)
	map:checkRoundTransition( id )
end

function map:getCarPos(id)
	if map.cars[id] then
		local x = map.cars[id].x/GRIDSIZE
		local y = map.cars[id].y/GRIDSIZE
		return x, y
	else
		return nil,nil
	end
end

function map:hasCar(id)
	return map.cars[id] ~= nil
end
function map:getCar(id)
	return map.cars[id]
end

function map:getGridPos(GridNx,GridNy)
	local x = GridNx * GRIDSIZE
	local y = GridNy * GRIDSIZE
	return x, y
end 

function map:showCarTargets(id, show)
	--if show == true
		--local positions = {}
		--map.cars[id].x = map.cars[id].x + map.cars[id].vx
		--map.cars[id].y = map.cars[id].y + map.cars[id].vy
		--map.cars[id].targetX
	--end
end

-- Check if a car has moved into a new round:
function map:checkRoundTransition( id )

	local car = map.cars[id]
	local p = { x = car.targetX, y = car.targetY }
	local pStart = { x = car.startX, y = car.startY }

	local drivenLine = { p1=pStart, p2=p }

	local intersects = utility.segSegIntersection( map.startLine, drivenLine )

	local distToEnd = utility.dist( p, map.endPoint )
	local distToStart = utility.dist( p, map.startPoint )

	if car.closerToEnd then
		if distToStart < distToEnd then
			car.closerToEnd = false
			if intersects then
				car.round = car.round + 1
			end
		end
	else
		if distToEnd < distToStart then
			car.closerToEnd = true
			if intersects then
				car.round = car.round - 1
			end
		end
	end
end

function map:newCar( id, x, y, color )
	local users = network:getUsers()
	local bodyType = 1
	if users then
		if users[id] then
			bodyType = users[id].customData.body
		end
	end
	map.cars[id] = Car:new( x, y, color, map.driveAngle, bodyType )
	print("created car:", id, x, y, map.cars[id], #map.cars )
end

function map:removeAllCars()
	map.cars = {}
end

-- Turn screen coordinates into world (pixel) coordinates:
function map:screenToWorld( x, y )
	local wX, wY = cam:worldCoords( x, y )
	return wX, wY
end

-- Turn screen coordinates into grid coordinates:
function map:screenToGrid( x, y )
	local wX, wY = cam:worldCoords( x, y )
	return self:TransCoordPtG(wX), self:TransCoordPtG(wY)
end

function map:isThisAValidTargetPos( id, x, y )
	local car = map.cars[id]
	if car then
		return car:isThisAValidTargetPos( x, y )
	end
	return false
end

function map:setCarNextMovement( id, x, y )
end
function map:resetCarNextMovement( id )
end

function map:getCarRound( id )
	local car = map.cars[id]
	if car then
		return car.round or -1
	end
	return -2
end

function map:getCarCenterVel( id )
	local car = map.cars[id]
	if car then
		return (car.x + car.vX)/GRIDSIZE, (car.y + car.vY)/GRIDSIZE
	end
end

function map:getCarSpeed()
	local car = map.cars[id]
	if car then
		return math.squrt( car.vX*car.vX + car.vY*var.vY )
	else
		return 0
	end
end

function map:zoomOut()
	if map.loaded then
		local max = math.max( math.abs(map.Boundary.maxX - map.Boundary.minX),
			math.abs(map.Boundary.maxY - map.Boundary.minY ))
		max = math.max( max, 1000 )
		map:camZoom( 700/max, 4.5 )
	end
end

function map:setName( name )
	self.name = name
end
function map:getName()
	return self.name or "Unknown"
end

return map
