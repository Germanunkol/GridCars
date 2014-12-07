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
local dx, dy, ZoomIs, mul, ZoomTarget, ZoomStart = 0, 0, 1, 1, 0, 1
local cam = nil
local CamOffset = -0.05
local GridColorSmall = {255, 255, 160, 25}
local GridColorBig = {50, 255, 100, 75}
local GridSizeSmallStep = 100
local GridSizeBigStep = 500
-- different Subjects:
local maxS_OnePivot = 200  -- trees, ...
local maxS_QuadPivot = 30 -- houses, ...
local SubjectListOnePivot = {"Baum1", "Baum2", "Baum3", "BaumKl1", "BaumKl2", "BaumKl3"}
local SubjectListQuadPivot = {"house1", "house2"}
GRIDSIZE = GridSizeSmallStep
local MapScale = 500

--wird einmalig bei Spielstart aufgerufen
function map:load()
	map.View.x = 0
	map.View.y = 0
	cam = Camera(map.View.x, map.View.y)
end

--wird zum laden neuer Maps öfters aufgerufen
function map:new(dateiname) -- Parameterbeispiel: "testtrackstl.stl"

	-- Read full file and save it in mapstring:
	local mapstring = love.filesystem.read( dateiname )

	self:newFromString( mapstring )

end

function map:newFromString( mapstring )

	local success, msg = map:import(mapstring)
	if not success then
		print("error loading map: ", msg)
		lobby:errorMsg( msg )
		map:reset()
	else
		map:getBoundary()
		ZoomTarget = 50/MapScale -- startzoom depends on MapScale

		-- create Environment
		-- plant Subjects with one Pivot
		for i = 1, maxS_OnePivot, 1 do
			--search fitting positon
			local x = math.random(map.Boundary.minX, map.Boundary.maxX)
			local y = math.random(map.Boundary.minY, map.Boundary.maxY)
			--[[while map:isPointOnRoad(x, y, 0) == true do
				x = math.random(map.Boundary.minX, map.Boundary.maxX)
				y = math.random(map.Boundary.minY, map.Boundary.maxY)
			end]]
			local nSubject = math.random(1, utility.tablelength(SubjectListOnePivot))
			local s = mapSubject:new(SubjectListOnePivot[nSubject], x, y) -- choose random subject
			table.insert( map.subjects, s )
		end
	end

end

function map:update( dt )
	-- Make sure a map is loaded first!
	if not map.loaded then return end

	cam.rot = CamOffset
	cam:zoomTo(ZoomTarget)
	--[[if CamZoomTime then
		CamZoomTimePassed = CamZoomTimePassed + dt
		if CamZoomTimePassed < CamZoomTime then
			local amount = utility.interpolateCos(CamZoomTimePassed/CamZoomTime)
			mul = ZoomStart + (ZoomTarget - ZoomStart) * amount
		else
			--mul = ZoomTarget
			ZoomIs = ZoomTarget
			CamZoomTime = nil
		end
		cam:zoomTo(mul)
	else
		cam:zoom(mul)
	end

		cam:zoomTo(ZoomTarget)
	--else
	--	cam:zoom(mul)
	end]]
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
		local dx = (love.keyboard.isDown('d') and 1 or 0) - (love.keyboard.isDown('a') and 1 or 0)
		local dy = (love.keyboard.isDown('s') and 1 or 0) - (love.keyboard.isDown('w') and 1 or 0)
		dx = dx*GridSizeSmallStep--*dt
		dy = dy*GridSizeSmallStep--*dt
	    cam:move(dx, dy)
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
		love.graphics.setLineWidth( 3 )
		love.graphics.setColor( 50, 50, 50, 255 )
		love.graphics.polygon( "fill", 
			self.startTriangle[1].x,
			self.startTriangle[1].y,
			self.startTriangle[2].x,
			self.startTriangle[2].y,
			self.startTriangle[3].x,
			self.startTriangle[3].y
		)
		love.graphics.setColor( 150, 150, 150, 255 )
		love.graphics.line( self.startLine.p1.x, self.startLine.p1.y,
				self.startLine.p2.x, self.startLine.p2.y )
		love.graphics.circle( "fill", self.startProjPoint.x, self.startProjPoint.y, 5 )

		love.graphics.setColor( 0, 255,0, 255 )
		love.graphics.circle( "fill", self.startPoint.x, self.startPoint.y, 5 )
		love.graphics.setColor( 255,0,0, 255)
		love.graphics.circle( "fill", self.endPoint.x, self.endPoint.y, 5 )
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
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setLineWidth(1)
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
	love.graphics.setColor( r, g, b, a) 
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
			for key, value in ipairs(positions) do
				startpos = string.find(line," ")
				line = string.sub(line, startpos+1)
				startpos = 0
				endpos = string.find(line," ")
				vertices[counterV][value] = string.sub(line, startpos, endpos) * MapScale
			end
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

					map.triangles[counterT] = {}
					map.triangles[counterT].vertices = {
						vertices[counterV-2],
						vertices[counterV-1],
						vertices[counterV]
					}
					


					--utility.printTable( map.triangles )
					counterT = counterT + 1
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


					end
				elseif vertices[counterV].z == MapScale*3 and vertices[counterV-1].z == MapScale*3 and
						vertices[counterV-2].z == MapScale*3 then

					local x = math.floor(vertices[counterV].x/GRIDSIZE)*GRIDSIZE
					local y = math.floor(vertices[counterV].y/GRIDSIZE)*GRIDSIZE
					local found = false
					for k, s in pairs( map.startPositions ) do
						if s.x == x and s.y == y then
							found = true
							print("\tduplicate start pos", x, y)
							break
						end
					end
					if not found then
						table.insert( map.startPositions, {x = x, y = y} )
						print("\tnew start pos", x, y)
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
--[[
function map:camZoom(zoom, time)
	if (not CamZoomTime) then
		ZoomTarget = zoom
		ZoomStart = ZoomIs
		CamZoomTime = time
		CamZoomTimePassed = 0
	end
end]]
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

	print(map.Boundary.minX, map.Boundary.maxX)
end

function map:keypressed( key )
	if key == "p" then
		--print(map.grid[x][y].pxlX, map.grid[x][y].pxlY)
		--map:setCarPos(1, map.grid[x][y].pxlX, map.grid[x][y].pxlY)
		local x = -math.random(0,5)
		local y = math.random(0,5)
		map:setCarPos(1, x, y)
	end
end

function map:mousepressed( x, y, button )
	if button == "wu" then
		--map:camZoom(.2, 1)
		ZoomTarget = ZoomTarget + 0.01
	end
	if button == "wd" then
		--map:camZoom(-.2, 1)
		ZoomTarget = ZoomTarget - 0.01
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
	map:camSwingToPos(posX, posY, 1)

	map:checkRoundTransition( id )
end

function map:setCarPosDirectly(id, posX, posY) --car-id as number, pos as Gridpos
	posX = map:TransCoordGtP(posX)
	posY = map:TransCoordGtP(posY)
	map.cars[id]:setPos(posX, posY)
end

function map:getCarPos(id)
	local x = map.cars[id].x/GRIDSIZE
	local y = map.cars[id].y/GRIDSIZE
	return x, y
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
	if intersects then

		local distToEnd = utility.dist( p, map.endPoint )
		local distToStart = utility.dist( p, map.startPoint )

		print( "dist to end:", distToEnd)
		print( "dist to start:", distToStart)

		if car.closerToEnd then
			if distToStart < distToEnd then
				car.closerToEnd = false
				car.round = car.round + 1
			end
		else
			if distToEnd < distToStart then
				car.closerToEnd = true
				car.round = car.round - 1
			end
		end
	end
end

function map:newCar( id, x, y, color )
	print("new car!", id, x, y, color[1], color[2], color[3], color[4] )
	map.cars[id] = Car:new( x, y, color )
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

function map:clickAtTargetPosition( id, x, y )
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

return map
