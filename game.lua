local game = {
	GAMESTATE = "",
	SERVERGAMESTATE = "",
	usersMoved = {},
	newUserPositions = {},
	crashedUsers = {},		-- remembers how many rounds the user has to wait
	time = 0,
	maxTime = 0,
	timerEvent = nil,
	time2 = 0,
	maxTime2 = 0,
	timerEvent2 = nil,
	roundTime = 10,
	winnerID = nil
}

local tease = {
	"Server: Hah, you crashed, ",
	"Server: Drunk driving, ",
	"Server: Come on, ",
	"Server: ",
}
local tease2 = {
	"!",
	"!",
	", what was that?!",
	", that was embarrassing...",
}

-- Possible gamestates:
-- "startup": camera should move to start line
-- "move": players are allowed to make their move.
-- "wait": waiting for server or other players, or for animtion

local scr = nil
local panel = require( "panel" )

function game:init()
	scr = ui:newScreen( "game" )

	scr:addPanel( "topPanel",
		0, 0, 
		love.graphics.getWidth(), 35 )

	scr:addFunction( "topPanel", "leave", 20, 0, "Leave", "q", game.close )
	scr:addFunction( "topPanel", "help", love.graphics.getWidth() -160, 0, "Help", "h", game.toggleHelp )

	self.winnerPanel = panel:new( love.graphics.getWidth()/3, love.graphics.getHeight()/2 - 100,
					love.graphics.getWidth()/3, love.graphics.getFont():getHeight() + 10 )

	self.userPanel = panel:new( 0, 0, 450, 19 )
end

function game:toggleHelp()
	if scr:panelByName( "helpPanel" ) ~= nil then
		scr:removePanel( "helpPanel" )
	else
		local width = 300
		local x = love.graphics.getWidth() - 370
		local y = 0
		scr:addPanel( "helpPanel",
			x,
			80,
			width, 410 )
		scr:addHeader( "helpPanel", "h1", 0, y, "Help:" )
		y = y + 30

		scr:addText( "helpPanel", "helpText", 10, y, nil, 7, "Move your car by clicking the fields around it. Once every player has planned their move, the cars start driving. The places you can drive to this round depends on how your carr drove during the last movement phase: The same vector you moved last round will be added onto your car's position; from the resulting point, all neighbouring fields are available.\nBe the first to finsih the race, but don't leave the road or crash into other cars!\n\nUse W-A-S-D or cursor keys to move the camera, use mouse wheel or + and - to zoom.\n\nCrashes:\nStay on the road! If you leave the road, you will crash. The time you have to wait afterwards depends on how fast you were.\nYou can crash into other player's cars if you click on the same position. Whoever clicks second, crashes." )

		scr:addFunction( "helpPanel", "close", 10, 360, "Close", "h", nil )
	end
end

function game:show()
	STATE = "Game"

	game.winnerID = nil
	map:removeAllCars()
	
	if server then

		-- For exery player who's playing, add one start position to the list of available positions:
		local availablePositions = {}
		local i = 1
		for id, u in pairs( server:getUsers() ) do
			if u.customData.ingame then
				-- add one start position to the list of available positions:
				table.insert( availablePositions, map.startPositions[i] )
				i = i + 1
			end
		end

		for id, u in pairs( server:getUsers() ) do
			if u.customData.ingame then
				local col = {
					u.customData.red,
					u.customData.green,
					u.customData.blue,
					255
				}

				local x, y = 0,0

				local startPosNum = math.random(1,#availablePositions)
				if availablePositions[startPosNum] then
					x, y = availablePositions[startPosNum].x, availablePositions[startPosNum].y
					table.remove( availablePositions, startPosNum )
				end

				map:newCar( u.id, x, y, col )

				server:send( CMD.NEW_CAR, u.id .. "|" .. x .. "|" .. y )
			else
				-- If the client is not racing this round, let him look like he's 
				-- already moved:
				server:setUserValue( u, "moved", true )
			end
			server:setUserValue( u, "crashed", false )
			server:setUserValue( u, "numCrashes", 0 )
			server:setUserValue( u, "topCrashSpeed", 0 )

			server:setUserValue( u, "speed", 0 )
			server:setUserValue( u, "maxSpeed", 0 )
		end

		game.crashedUsers = {}

		-- Start the round after 3 seconds!
		self.timerEvent = function()
			game:startMovementRound()
		end
		self.maxTime = 3
		self.time = 0

		server:send( CMD.SERVERCHAT,
			"Game starting. You have " .. ROUND_TIME .. " seconds for each move." )

		updateAdvertisementInfo()
	end

	if not DEDICATED then
		ui:setActiveScreen( nil )

		stats:clear()

		-- Do a cool camera startup swing:
		map:camSwingAbort()
		map:camSwingToPos( map.startProjPoint.x, map.startProjPoint.y, 1.5 )
		map:camZoom( 0.6, 1.5 )
		self.timerEvent2 = function()
			if client then
				game:camToCar( client:getID() )
			end
		end
		self.maxTime2 = 2
		self.time2 = 0

		ui:setActiveScreen( scr )
	end
end

function game:camToCar( id )
	if client then
		if map:hasCar( id ) then
			local x, y = map:getCarPos( id )
			x = x*GRIDSIZE
			y = y*GRIDSIZE
			map:camSwingToPos( x, y, 1 )
			map:camZoom( 0.5, 1 )
		end
	end
end

function game:update( dt )
	map:update( dt )
	-- Timer1:
	if self.maxTime > 0 then
		self.time = self.time + dt
		if self.time >= self.maxTime then
			self.maxTime = 0
			self.time = 0
			self.timerEvent()
		end
	end
	-- Timer2:
	if self.maxTime2 > 0 then
		self.time2 = self.time2 + dt
		if self.time2 >= self.maxTime2 then
			self.maxTime2 = 0
			self.time2 = 0
			self.timerEvent2()
		end
	end
end

function game:draw()
	if client then
		map:draw()
		if self.GAMESTATE == "move" then
			map:drawTargetPoints( client:getID() )
		end
		--[[if love.keyboard.isDown( " " ) then
			map:drawCarInfo()
		end]]
		game:drawUserList()

		if game.winnerID then
			local users = network:getUsers()
			if users and users[game.winnerID] then
				self.winnerPanel:draw()
				love.graphics.setColor( 64,255,64, 255 )
				love.graphics.printf( users[game.winnerID].playerName .. " wins the round!",
					love.graphics.getWidth()/3, love.graphics.getHeight()/2-95,
					love.graphics.getWidth()/3, "center" )
			end
		end

		map:drawDebug()
	end
end

function game:drawUserList()
	-- Print list of users:
	local users, num = network:getUsers()
	local x, y = 20, 60
	local i = 1
	if client and users then
		for k, u in pairs( users ) do

			self.userPanel:draw( x - 5, y - 3 )

			love.graphics.setColor( 255,255,255, 255 )
			love.graphics.printf( i .. ":", x, y, 20, "right" )
			love.graphics.printf( u.playerName, x + 25, y, 250, "left" )

			local dx = love.graphics.getFont():getWidth( u.playerName ) + 40

			local lapString = ""
			if map:hasCar( u.id ) then

				local speedString = (u.customData.speed or 0).. " km/h"
				love.graphics.print( speedString, x + dx, y )
				dx = dx + love.graphics.getFont():getWidth( speedString ) + 15

				lapString = "Lap: " .. map:getCarRound( u.id ) .. "/" .. (self.numberOfLaps or LAPS)
				love.graphics.print( lapString, x + dx, y )
			end

			-- Show crashed users in list:
			if u.customData.crashed == true then
				love.graphics.setColor( 255, 128, 128, 255 )
				dx = dx + love.graphics.getFont():getWidth( lapString ) + 20
				local rounds = u.customData.waitingRounds or 1
				love.graphics.print( "[Crashed! (" .. rounds .. ")]", x + dx, y )
			elseif not u.customData.moved == true then
				love.graphics.setColor( 255, 255, 128, 255 )
				dx = dx + love.graphics.getFont():getWidth( lapString ) + 20
				love.graphics.print( "[Waiting for move]", x + dx, y )
			elseif not u.customData.ingame == true then
				love.graphics.setColor( 128, 128, 255, 255 )
				dx = dx + love.graphics.getFont():getWidth( lapString )
				love.graphics.print( "[spectate]", x + dx, y )
			end

			if map:hasCar( u.id) then
				map:getCar( u.id ):drawOnUI( 435, y + 5, 0.2 )
			end

			y = y + 20
			i = i + 1
		end
	end
end

function game:keypressed( key )
end

function game:mousepressed( x, y, button )
	if button == "l" then
		if client then
			if self.GAMESTATE == "move" then
				-- Turn screen coordinates into grid coordinates:
				local gX, gY = map:screenToGrid( x, y )
				gX = math.floor( gX + 0.5 )
				gY = math.floor( gY + 0.5 )
				print( "Grid position clicked:", gX, gY )
				if map:isThisAValidTargetPos( client:getID(), gX, gY ) then
					print("\t->is valid.")
					self:sendNewCarPosition( gX, gY )
				end
			end
		end
	end
end

function game:setState( state )
	self.GAMESTATE = state
	--[[if self.GAMESTATE == "move" then
		if client then
			map:resetCarNextMovement( client:getID() )
		end
	end]]
end

function game:newCar( msg )
	if not server then
		local id, x, y = msg:match( "(.*)|(.*)|(.*)")
		id = tonumber(id)
		x = tonumber(x)
		y = tonumber(y)
		local users = client:getUsers()
		local u = users[id]
		if u then
			local col = {
				u.customData.red,
				u.customData.green,
				u.customData.blue,
				255
			}
			map:newCar( id, x, y, col )
		end
	end
end

function game:sendNewCarPosition( x, y )
	-- CLIENT ONLY!
	if client then
		client:send( CMD.MOVE_CAR, x .. "|" .. y )
		print("\t->Sent:", CMD.MOVE_CAR, x .. "|" .. y, os.time())
		--map:setCarNextMovement( client:getID(), x, y )
	end
end

function game:startMovementRound()
	--SERVER ONLY!
	if server then
		self.SERVERGAMESTATE = "move"
		game.usersMoved = {}
		for k, u in pairs( server:getUsers() ) do

			-- On all crashed users, count one down because we're starting a new round...
			if game.crashedUsers[u.id] then

				-- If this is the first crash round:
				--[[if game.crashedUsers[u.id] == SKIP_ROUNDS_ON_CRASH + 1 then
					if math.random(20) == 1 then
						local i = math.random(#tease)
						server:send( CMD.SERVERCHAT, tease[i] .. u.playerName .. tease2[i] )
					end
				end]]
				game.crashedUsers[u.id] = game.crashedUsers[u.id] - 1
				if game.crashedUsers[u.id] <= 0 then
					-- If I've waited long enough, let me rejoin the game:
					server:setUserValue( u, "crashed", false )
					game.crashedUsers[u.id] = nil
				end
			end

			-- If a user crashed, let everyone know:
			if game.crashedUsers[u.id] then
				server:setUserValue( u, "waitingRounds", game.crashedUsers[u.id] )
				server:setUserValue( u, "crashed", true )
				-- Consider this user to be finished...
				game.usersMoved[u.id] = true
			else

				-- Only let users move if they haven't crashed and aren't spectating:
				if u.customData.ingame then
					server:send( CMD.GAMESTATE, "move", u )
					server:setUserValue( u, "moved", false )
				end

			end
		end

		self.timerEvent = function() game:roundTimeout() end
		self.maxTime = ROUND_TIME
		self.time = 0

		print("----------------------------------------")
		print("New round starting:", os.time())

		-- If all users crashed, continue:
		game:checkForRoundEnd()
	end
end

function game:roundTimeout()
	local found = false
	if server then
		for k, u in pairs( server:getUsers() ) do

			-- If the user did not move their car in time, move it according to last velocity:
			if not self.usersMoved[u.id] and u.customData.ingame == true then
				print("Round timeout for user:", u.id )
				print("\tUser Data:")
				for k, v in pairs( u.customData ) do
					print("\t", k, v)
				end
				local x, y = map:getCarCenterVel( u.id )

				-- Check for crashes:
				game:validateCarMovement( u.id, x, y )
				found = true
			end
		end
		if found then
			server:send( CMD.SERVERCHAT, "Server: Time up. Moving on..." )
		end
	end
end

function game:moveAll()
	if server then
		for k, u in pairs( server:getUsers() ) do
			if u.customData.ingame and map:hasCar( u.id ) then
				--local x, y = map:getCarPos( u.id )
				local x,y = self.newUserPositions[u.id].x, self.newUserPositions[u.id].y
				server:send( CMD.MOVE_CAR, u.id .. "|" .. x .. "|" .. y )

				-- Calculate and send car speed:
				local car = map:getCar( u.id )
				local vX = x - map:TransCoordPtG(car.x)
				local vY = y - map:TransCoordPtG(car.y)
				local speed = math.floor( math.sqrt(vX*vX + vY*vY)*100 )/10
				server:setUserValue( u, "speed", speed )

				if not u.customData.maxSpeed or u.customData.maxSpeed < speed then
					server:setUserValue( u, "maxSpeed", speed )
				end

				if DEDICATED then
					map:setCarPosDirectly( u.id, x, y )
				end

			end
		end

		self.timerEvent = function()
			game:checkForWinner()

			if not game.winnerID then
				game:startMovementRound()
			else
				game:sendWinner( game.winnerID )
				local winner = server:getUsers()[game.winnerID]
				if winner then
					server:setUserValue( winner, "roundsWon", winner.customData.roundsWon + 1 )
				end
				self.timerEvent = game.sendBackToLobby
				self.maxTime = 5
				self.time = 0
				if DEDICATED then
					if server:getUsers()[game.winnerID] and
						server:getUsers()[game.winnerID].playerName then

						utility.log( "[" .. os.time() .. "] Winner: " ..
						server:getUsers()[game.winnerID].playerName )
					end
				end
			end
		end
		self.maxTime = 1.2
		self.time = 0
	end
end

function game:validateCarMovement( id, x, y )
	--SERVER ONLY!
	if server then
		-- if this user has not moved yet:
		if self.usersMoved[id] == nil then
			--			map:setCarPos( id, x, y )
			--map:setCarPosDirectly(id, x, y) --car-id as number, pos as Gridpos
			local oldX, oldY = map:getCarPos( id )
			local user = server:getUsers()[id]

			print("\tValidating at:", os.time())
			print("\tPrevious positions:", id, map:getCar(id), oldX, oldY)
			if map:isThisAValidTargetPos( id, x, y ) then
				print("\tPossition is valid.")
			else
				print("\tPossition is NOT valid. Traceback:", debug.traceback())
				server:send( CMD.SERVERCHAT,
					"DEBUG: Something went wrong. " .. server:getUsers()[id].playerName .. "'s movement was invalid.")
			end

			if not oldX or not oldY then
				print("\tWARNING: oldX or oldY aren't set!", debug.traceback())
				server:send( CMD.SERVERCHAT, "DEBUG: somthing went wrong with the car position of " .. server:getUsers()[id].playerName .. "." )
				oldX, oldY = 0, 0
			end

			-- Step along the path and check if there's a collision. If so, stop there.
			local p = {x = oldX, y = oldY }
			local diff = {x = x-oldX, y = y-oldY}
			local dist = utility.length( diff )
			local speed = math.floor( dist*100 )/10
			print("\tDelta:", diff.x, diff.y)
			print("\tSpeed:", speed )
			diff = utility.normalize(diff)
			print("\tDist:", dist)

			-- Step forward in steps of 0.5 length - this makes sure no small gaps are jumped!
			local crashed, crashSiteFound = false, false
			local movedDist = 0
			for l = 0.5, dist, 0.5 do
				p = {x = oldX + l*diff.x, y = oldY + l*diff.y }
				if not map:isPointOnRoad( p.x*GRIDSIZE, p.y*GRIDSIZE, 0 ) then
					crashed = true
					break
				end
				movedDist = l
			end

			-- Also check the end position!!
			if not crashed then
				-- I have managed to move the entire distance!
				movedDist = dist
				if not map:isPointOnRoad( x*GRIDSIZE, y*GRIDSIZE, 0 ) then
					crashed = true
				end
			end

			local crashedIntoCar = false
			-- If I managed to move the full distance, then check if there's already a car there
			if movedDist == dist then
				for id2, bool in pairs( self.usersMoved ) do
					if bool then
						if self.newUserPositions[id2] then
							if self.newUserPositions[id2].x == x and
								self.newUserPositions[id2].y == y then

								crashedIntoCar = true
								crashed = true
								break
							end
						end
					end
				end
			end

			if crashed then
				print("\tCrashed")
				-- Step backwards:
				for lBack = movedDist-0.5, 0, -0.5 do
					p = {x = oldX + lBack*diff.x, y = oldY + lBack*diff.y }
					p.x = math.floor(p.x)
					p.y = math.floor(p.y)
					if map:isPointOnRoad( p.x*GRIDSIZE, p.y*GRIDSIZE, 0 ) then
						crashSiteFound = true
						x, y = p.x, p.y
						break
					end
				end

				-- remembers how many rounds the user has to wait
				if crashedIntoCar then
					game.crashedUsers[id] = SKIP_ROUNDS_CAR_CAR + 1
				else
					game.crashedUsers[id] = game:speedToCrashTimeout( speed )
				end

				if user then
					server:setUserValue( user, "numCrashes", user.customData.numCrashes + 1 )
					if speed > user.customData.topCrashSpeed then
						server:setUserValue( user, "topCrashSpeed", speed )
					end
				end
			end

			if crashed and not crashSiteFound then
				x, y = oldX, oldY
				print("\tNo crash site found, placed to old pos:", oldX, oldY)
			end

			self.usersMoved[id] = true
			self.newUserPositions[id] = {x=x, y=y}

			if user then
				-- tell this user to wait!
				server:send( CMD.GAMESTATE, "wait", user )
				-- Let all users know this user has already moved:
				server:setUserValue( user, "moved", true )
			end

			game:checkForRoundEnd()
		end
	end
end

function game:checkForRoundEnd()
	-- Check if all users have sent their move:
	local doneMoving = true
	for k, u in pairs( server:getUsers() ) do
		if u.customData.ingame and not self.usersMoved[u.id] then
			doneMoving = false
			break
		end
	end
	-- If all users have sent the move, go on to next round:
	if doneMoving then
		self:moveAll()
	end
end

-- This function checks for a winner. A winner is found if a user has passed the startline
-- LAP times. If more than one players have done so, the winner is the one who is _furthest_
-- from the start line (i.e. crossed the line with the most speed/first)
function game:checkForWinner()
	if server and not game.winnerID then
		local potentialWinners = {}
		for k, u in pairs( server:getUsers() ) do
			if u.customData.ingame then
				if map:getCarRound( u.id ) >= LAPS + 1 then
					table.insert( potentialWinners, u.id )
				end
			end
		end

		-- Find the winner who has the least 
		local winnerID
		local maxDist = -math.huge
		for k, id in pairs( potentialWinners ) do
			local car = map:getCar( id )
			if car then
				local x,y = car:getPos()
				local p = {x=x, y=y}
				local dist = utility.linePointDist( map.startLine.p1,map.startLine.p2, p )
				print( x, y, map.startLine.p1.x, map.startLine.p1.y )
				if dist > maxDist then	-- so far the first player:
					winnerID = id
					maxDist = dist
				end
			end
		end
		if winnerID then
			game.winnerID = winnerID
			print("WINNER FOUND!", game.winnerID )
		else
			-- Fallback, just in case:
			if #potentialWinners > 0 then
				game.winnerID = potentialWinners[1]
			end
		end
	end
end

function game:moveCar( msg )
	-- CLIENT ONLY!
	if client then
		local id, x, y = msg:match( "(.*)|(.*)|(.*)" )
		id = tonumber(id)
		x = tonumber(x)
		y = tonumber(y)
		map:setCarPos( id, x, y )
	end
end

function game:playerWins( msg )
	if client then
		game.winnerID = tonumber(msg)	
		game:camToCar( game.winnerID )
		self.timerEvent2 = game.zoomOut
		self.maxTime2 = 3
		self.time2 = 0
	end
end

function game:sendWinner()
	if server then
		server:send( CMD.PLAYER_WINS, game.winnerID )
	end
end
function game:sendBackToLobby()
	if server then
		-- Create and send statustics:
		game:sendStats()

		server:send( CMD.BACK_TO_LOBBY, "" )

		if DEDICATED then
			lobby:show()	-- must be called AFTER generating the stats!
		end
	end
end

function game:sendStats()
	-- SERVER ONLY!
	if not server then return end

	local users = network:getUsers()

	-- Create and send top speed string:
	local statStr = "Top Speed:|km/h|"
	for k, u in pairs( users ) do
		if u.customData.ingame then
			statStr = statStr .. u.id .. " " .. u.customData.maxSpeed .. "|"
		end
	end
	server:send( CMD.STAT, statStr )

	-- Create and send crashes string:
	local statStr = "Crashes:||"
	for k, u in pairs( users ) do
		if u.customData.ingame then
			statStr = statStr .. u.id .. " " .. u.customData.numCrashes .. "|"
		end
	end
	server:send( CMD.STAT, statStr )

	-- Create and send top speed at crashes:
	local statStr = "Worst crash:|km/h|"
	for k, u in pairs( users ) do
		if u.customData.ingame then
			statStr = statStr .. u.id .. " " .. u.customData.topCrashSpeed .. "|"
		end
	end
	server:send( CMD.STAT, statStr )

	-- Create and send top speed at crashes:
	local statStr = "Rounds won:||"
	for k, u in pairs( users ) do
		if u.customData.ingame then
			statStr = statStr .. u.id .. " " .. u.customData.roundsWon .. "|"
		end
	end
	server:send( CMD.STAT, statStr )
end

function game:zoomOut()
	local cX = map.Boundary.minX + (map.Boundary.maxX - map.Boundary.minX)*0.5
	local cY = map.Boundary.minY + (map.Boundary.maxY - map.Boundary.minY)*0.5
	map:camSwingToPos( cX, cY )
end

function game:synchronizeCars( user )
	if server then
		for k, u in pairs( server:getUsers() ) do
			if u.customData.ingame then
				if map:hasCar( u.id ) then
					local c = map:getCar( u.id )
					server:send( CMD.NEW_CAR, u.id .. "|" .. c.targetX .. "|" .. c.targetY, user )
				end
			end
		end
	end
end

function game:speedToCrashTimeout( speed )
	return SKIP_ROUNDS_COLLISION_MIN + math.floor(speed*SKIP_ROUNDS_COLLISION_PER_10_KMH/10) + 1
end

function game:getNumUsersPlaying()
	local num = 0
	for k, u in pairs( server:getUsers() ) do
		if u.customData.ingame == true then
			num = num + 1
		end
	end
	return num
end

function game:close()
	local commands = {}
	commands[1] = { txt = "Yes", key = "y", event = function() network:closeConnection() end }
	commands[2] = { txt = "No", key = "n" }
	scr:newMsgBox( "Game in progress!", "Are you sure you want to leave?", nil, nil, nil, commands)
end

return game
