local map = {triangles = {}, Boundary = {}, cars = {}, View = {}}

local Camera = require "lib/hump.camera"
local Car = require "car"
local startPos = {x = 0, y = 0}
local CameraGolX = 0
local CameraGolY = 0
local cameraSpeed = 20
local dx, dy, mul = 0, 0, 1
local cam = nil
local CamOffset = -0.05
local GridColorSmall = {255, 255, 160, 100}
local GridColorBig = {50, 255, 100, 200}
local GridSizeSmallStep = 10
local GridSizeBigStep = 50
GRIDSIZE = GridSizeSmallStep

--wird einmalig bei Spielstart aufgerufen
function map:load()
	cam = Camera(startPos.x, startPos.x)
	map.View.x = startPos.x
	map.View.y = startPos.y
		-- Testzweck hier
		map:new("testtrackstl.stl")
		blue = { 0, 100, 255, 255 }
		map.cars[1] = Car:new( 50, 50, blue)
end

--wird zum laden neuer Maps öfters aufgerufen
function map:new(dateiname) -- Parameterbeispiel: "testtrackstl.stl"

	-- Read full file and save it in mapstring:
	local mapstring = love.filesystem.read( dateiname )

	map:import(mapstring)
	map:getBoundary()
	--print (printTable(map.Boundary))
end
function map:newFromString( mapstring )
	map:import( mapstring )
	map:getBoundary()
end

function map:update( dt )
	cam.rot = CamOffset
	local dx = (love.keyboard.isDown('d') and 1 or 0) - (love.keyboard.isDown('a') and 1 or 0)
	local dy = (love.keyboard.isDown('s') and 1 or 0) - (love.keyboard.isDown('w') and 1 or 0)
	dx = dx*cameraSpeed--*dt
	dy = dy*cameraSpeed--*dt
    cam:move(dx, dy)
    cam:zoom(mul)
--[[
    if CamSwingTime then
		CamSwingTimePassed = CamSwingTimePassed + dt
		if CamSwingTimePassed < CamSwingTime then
			local amount = CamSwingTimePassed/CamSwingTime
			CamX =CamStartX + (CamTargetX - CamStartX) * amount
			CamY = CamStartY + (CamTargetY - CamStartY) * amount
		else
			CamX = self.targetX
			CamY = self.targetY
			CamSwingTime = nil
		end
	end]]

    --map:swingToCameraPosition(220,220,dt)
    mul = 1
    for id in pairs(map.cars) do
    	map.cars[id]:update(dt)
    end
end

function map:draw()
	cam:attach()
	-- draw World
	 -- draw ground
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
	 -- draw grid
	map:drawGrid()
	 -- draw movement-lines
	 -- draw player
	for id in pairs(map.cars) do
    	map.cars[id]:draw()
    end
	cam:detach()
end

function map:drawGrid()
	local r, g, b, a = love.graphics.getColor()
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

function printTable( t, level )
	level = level or 1
	for k, v in pairs( t ) do
		if type(v) == "table" then
			print( string.rep( "\t", level ) .. k .. " = {")
			printTable( v, level + 1 )
			print( string.rep( "\t", level ) .. "}" )
		else
			print( string.rep( "\t", level ) .. k .. " = ", v )
		end
	end
end

function map:import( mapstring )

	map.cars = {}

	-- testen, ob alles Triangel sind und keine Polygone
	cam = Camera(startPos.x, startPos.x)
	map.triangles = {}
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
				vertices[counterV][value] = string.sub(line, startpos, endpos) * 50
			end
			--print("Vertex  No",counterV, vertices[counterV].x, vertices[counterV].y,  vertices[counterV].z)
			-- jeder dritte Vertex ergibt ein Dreieck
			if counterV%3 == 0 then
				map.triangles[counterT] = {}
				map.triangles[counterT].vertices = {
					vertices[counterV-2],
					vertices[counterV-1],
					vertices[counterV]
				}
				--printTable( map.triangles )
				counterT = counterT + 1
			end
			counterV = counterV + 1
		end
  	end
end


function map:swingCameraTo(x,y,time)
--[[	local cx, cy = cam:pos()
	--t counter
	print(cx, x, dx)
	local dx = (x - cx) * dt
	if math.abs(dx) < 10 then
		dx = 10
	end
	--local dy = math.max((y - cy),100) * dt
	cam:move(dx, dy) ]]

	if (not CamSwingTime) then
		CamTargetX = x
		CamTargetY = y
		CamStartX = self.x
		CamStartY = self.y
		CamSwingTime = time
		CamSwingTimePassed = 0
	end
end

function map:updatecam(dt)
end

function map:getBoundary() -- liefert maximale und minimale x und y Koordinaten
	map.Boundary.minX = 999
	map.Boundary.minY = 999
	map.Boundary.maxX = 0
	map.Boundary.maxY = 0
	--local minX, minY, maxX, maxY = 999 , 999, 0, 0
	for key, value in pairs(map.triangles) do
		for i = 1, 3, 1 do
			map.Boundary.minX = math.min(map.triangles[key].vertices[i].x, map.Boundary.minX)
			map.Boundary.minY = math.min(map.triangles[key].vertices[i].y, map.Boundary.minY)
			map.Boundary.maxX = math.max(map.triangles[key].vertices[i].x, map.Boundary.maxX)
			map.Boundary.maxY = math.max(map.triangles[key].vertices[i].y, map.Boundary.maxY)
		end
	end
	map.Boundary.minX = map.Boundary.minX - map.Boundary.minX % GridSizeBigStep
	map.Boundary.minY = map.Boundary.minY - map.Boundary.minY % GridSizeBigStep
	map.Boundary.maxX = map.Boundary.maxX + GridSizeBigStep
	map.Boundary.maxX = map.Boundary.maxX - map.Boundary.maxX % GridSizeBigStep
	map.Boundary.maxY = map.Boundary.maxY + GridSizeBigStep
	map.Boundary.maxY = map.Boundary.maxY - map.Boundary.maxY % GridSizeBigStep
end

function map:keypressed( key )
	if key == "p" then
		local x = math.random(0,400)
		local y = math.random(0,400)
		map:setCarPos(1, x, y)
	end
end

function map:mousepressed( x, y, button )
	if button == "wu" then
		mul = mul + 0.1
	end
	if button == "wd" then
		mul = mul - 0.1
	end
end

function map:setCarPos(id, posX, posY) --car-id as number
	posX = (posX + GRIDSIZE/2) - (posX + GRIDSIZE/2)%GRIDSIZE
	posY = (posY + GRIDSIZE/2) - (posY + GRIDSIZE/2)%GRIDSIZE
	map.cars[id]:MoveToPos(posX, posY, 1)
end

function map:getCarPos(id)
	local x = map.cars[id].x
	local y = map.cars[id].y
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

return map
