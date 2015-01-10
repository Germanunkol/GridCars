local chat = {
	lines = {},
	active = false,
	enterText = "",
	time = 0,
}

local CHAT_WIDTH = 300
local chatSide = "left"
local CHAT_INPUT_CHARACTERS = 100
-- Used for line breaking:
local letter = "[%z\1-\127\194-\244][\128-\191]*"
local word = "[%S]* "	-- not space followed by space

local colNormal = {255,255,255,255}
local colServer = {255,200,64,255}

local panel = require( "panel" )

function chat:init()
	CHAT_WIDTH = math.min(love.graphics.getWidth()/2 - 40, 500)
end

function chat:reset()
	self.lines = {} -- "", "", "", "", "", "", "", "Press enter to chat.", "Welcome!" }
	for k = 1, 9 do
		table.insert( self.lines, {txt = "", col=colNormal} )
	end
	table.insert( self.lines, {txt = "Press enter to chat.", col=colServer} )
	self.panel = panel:new( 0, 0, CHAT_WIDTH, 20*(#self.lines) + 10, 3)
end

function chat:show()
end

function chat:draw()
	local fontHeight = love.graphics.getFont():getHeight()
	local x
	local y = love.graphics.getHeight() - 20*(#self.lines+1) - 70

	if map.loaded and client and client:getID() then
		if map:hasCar( client:getID() ) then
			local c = map:getCar( client:getID() )
			if c.vY > 0 then
			if chatSide == "left" then
				if c.vX < 0 then
					chatSide = "right"
				end
			else
				if c.vX > 0 then
					chatSide = "left"
				end
			end
		end
		end
	end
	
	if chatSide == "left" then
		x = 20
	else
		x = love.graphics.getWidth() - 20 - CHAT_WIDTH
	end

	--love.graphics.rectangle( "fill", x, y,
			--CHAT_WIDTH, 20*(#self.lines) + 10 )
	self.panel:draw( x, y )

	x = x + 5
	y = y + 10
	for k = 1, #self.lines do
		love.graphics.setColor( self.lines[k].col )
		love.graphics.print( self.lines[k].txt, x, y )
		y = y + 20
	end

	local x, y = 20, love.graphics.getHeight() - 70
	if self.active then
		
		local str = self.enterText

		local inputLen = love.graphics.getFont():getWidth( "Say: " .. str )
		inputLen = math.max(inputLen, 50 )

		love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill",
			x, y, inputLen + 13, fontHeight + 10 )

		love.graphics.setColor( 255, 255, 255, 255 )
		if math.sin(self.time*3) > 0 then
			love.graphics.print( "Say: " .. str .. "|", x + 5, y + 5 )
		else
			love.graphics.print( "Say: " .. str, x + 5, y + 5 )
		end
	end

end

function chat:update( dt )
	if STATE == "Lobby" or STATE == "Game" then
		if self.active then
			self.time = self.time + dt
		end
	end
end

function chat:newLine( text, col )

	-- remove leading whitespace:
	text = text:match( "%s*(.*)" )

	local font = love.graphics.getFont()

	local restStr
	-- Wrap text if necessary:
	local wLines = {}	-- lines that have been wrapped

	if font:getWidth( text ) <= CHAT_WIDTH - 10 then
		table.insert( wLines, text )
	else
		local restLine = text .. " "
		local tmpLine, shortLine
		while #restLine > 0 do
			local i = 1
			local breakingCondition = false
			tmpLine = nil
			shortLine = nil
			repeat		-- look for spaces!
				tmpLine = restLine:match( word:rep(i) )
				if tmpLine then
					if font:getWidth(tmpLine) > CHAT_WIDTH - 10 then
						breakingCondition = true
					else
						shortLine = tmpLine
					end
				else
					breakingCondition = true
				end
				i = i + 1
			until breakingCondition
			if not shortLine then -- if there weren't enough spaces then:
				breakingCondition = false
				i = 1
				repeat			-- ... look for letters:
					tmpLine = restLine:match( letter:rep(i) )
					if tmpLine then
						if font:getWidth(tmpLine) > self.width then
							breakingCondition = true
						else
							shortLine = tmpLine
						end
					else
						breakingCondition = true
					end
					i = i + 1
				until breakingCondition
			end
			table.insert( wLines, shortLine )
			restLine = restLine:sub( #shortLine+1 )
		end
	end

	for k, l in ipairs(wLines) do

		-- Add the text to the table of text lines:
		for k = 1, #self.lines-1 do
			self.lines[k] = self.lines[k+1]
		end
		self.lines[#self.lines] = {txt = l, col = col}

	end
end

function chat:newLineSpeech( text )
	self:newLine( text, colNormal )
end
function chat:newLineServer( text )
	self:newLine( text, colServer )
end

function chat:keypressed( key )
	if STATE == "Game" or STATE == "Lobby" then
		if key == "return" then
			if self.active then
				if client then
					if #self.enterText > 0 then
						client:send( CMD.CHAT, self.enterText )
					end
				end
				self.enterText = ""
				self.active = false
			else
				if client then
					self.active = true
				end
			end
		elseif key == "backspace" then
			if #self.enterText > 0 then
				self.enterText = self.enterText:sub( 1, #self.enterText - 1 )
				-- Check if the last char is part of an umlaut or similar. If so, remove it:
				local last = self.enterText:sub(-1)
				local byte = string.byte(last)
				if byte and byte >= 194 then
					self.enterText = self.enterText:sub( 1, #self.enterText - 1 )
				end
			end
		elseif key == "escape" then
			self.enterText = ""
			self.active = false
		end
	end
end

function chat:textinput( letter )
	if STATE == "Game" or STATE == "Lobby" then
		if self.active then
			if letter ~= "|" then
				if love.graphics.getFont():getWidth( "Say: " .. self.enterText )
						< love.graphics.getWidth() - 60 then
					self.enterText = self.enterText .. letter
				end
			end
		end
	end
end

return chat
