local map = {triangles = {}}

local Camera = require "lib/hump.camera"
local startPos = {x = 0, y = 0}
local CameraGolX = 0
local CameraGolY = 0
local cameraSpeed = 300
local cam = nil

function map:load()
	cam = Camera(startPos.x, startPos.x)
	map:import("testtrackstl.stl") -- temp hier
end

function map:update( dt )
	local dx = (love.keyboard.isDown('d') and 1 or 0) - (love.keyboard.isDown('a') and 1 or 0)
	local dy = (love.keyboard.isDown('s') and 1 or 0) - (love.keyboard.isDown('w') and 1 or 0)
	local mul = 1 + ((love.keyboard.isDown('y') and 1 or 0) - (love.keyboard.isDown('x') and 1 or 0))*dt
	dx = dx*dt*cameraSpeed
	dy = dy*dt*cameraSpeed
    cam:move(dx, dy)
    cam:zoom(mul)
end

function map:draw()
	cam:attach()
	-- draw World
	 -- draw ground
	 		for key, value in pairs(map.triangles) do
	 			love.graphics.polygon( 'fill',
	 				map.triangles[key].vertices[1].x,
	 				map.triangles[key].vertices[1].y,
	 				map.triangles[key].vertices[2].x,
	 				map.triangles[key].vertices[2].y,
	 				map.triangles[key].vertices[3].x,
	 				map.triangles[key].vertices[3].y
	 			)
	 		end
	 -- draw movement-lines
	 -- draw player
	cam:detach()
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

function map:import(Dateiname)
	-- testen, ob alles Triangel sind und keine Polygone
	cam = Camera(startPos.x, startPos.x)
	map.triangles = {}
	local vertices = {}
	local positions = {"x", "y", "z"}
	local counterT = 1 -- Counter für Triangle
	local counterV = 1 -- Counter für Vertices
	local startpos, endpos
	for line in love.filesystem.lines(Dateiname) do
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
			print("Vertex  No",counterV, vertices[counterV].x, vertices[counterV].y,  vertices[counterV].z)
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
  	print (map.getBoundary)
end

function map:setCameraPosition(x,y)
	cameraGolX = x
	cameraGolY = y
end

function map:swingCameraPosition(x,y)

end

function map:getBoundary() -- liefert maximale x und y Koordinaten
	local max_x, max_y
	for key, value in pairs(map.triangles) do
		max_x = math.max(map.triangles.vertices.x, max_x)
		max_y = math.max(map.triangles.vertices.y, max_y)
	end
	return max_x, max_y
end
return map
