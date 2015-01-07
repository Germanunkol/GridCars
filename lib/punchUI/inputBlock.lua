
local PATH = (...):match("(.-)[^%.%/]+$")
local class = require( PATH .. "middleclass" )
local TextBlock = require( PATH .. "textBlock" )
local col = require(PATH .. "colors")
local COLORS, COLORS_INACTIVE = col[1], col[2]
col = nil

local InputBlock = TextBlock:subclass("InputBlock")

function InputBlock:initialize( name, x, y, width, height, font, returnEvent, password, maxLetters )
	TextBlock.initialize( self, name, x, y, width, height, "", font, false )
	self.fullContent = ""
	self.front = ""
	self.back = ""
	self.cursorX = 0
	self.cursorY = 0
	self.password = password or false
	self.maxLetters = maxLetters or math.huge
	self.maxLines = math.floor(height/self.font:getHeight())
	self.returnEvent = returnEvent
end

function InputBlock:keypressed( key )
	-- back up text incase anything goes wrong:
	self.oldFront, self.oldBack = self.front, self.back
	local stop, jump


	if key == "backspace" then
		local len = #self.front
		if len > 0 then
			self.front = self.front:sub(1, len-1)
			self:update( "left" )
		end
	elseif key == "escape" then
		self.front = self.fullContent
		self.back = ""
		self:update()
		stop = true
	elseif key == "return" then
		self.fullContent = self.front .. self.back
		stop = true
		if self.returnEvent then
			self.returnEvent( self.fullContent )
		end
	elseif key == "left" then
		local len = #self.front
		
		if len > 0 then
			self.back = self.front:sub( len,len ) .. self.back
			self.front = self.front:sub(1, len-1)
			self:update( "left" )
		end
	elseif key == "right" then
		local len = #self.back
		if len > 0 then
			self.front = self.front .. self.back:sub(1,1)
			self.back = self.back:sub(2,len)
			self:update( "right" )
		end
	elseif key == "delete" then
		local len = #self.back
		if len > 0 then
			self.back = self.back:sub(2,len)
			self:update()
		end
	elseif key == "home" then
		self.back = self.front .. self.back
		self.front = ""
		self.cursorX, self.cursorY = self:getCharPos( #self.front )
	elseif key == "end" then
		self.front = self.front .. self.back
		self.back = ""
		self.cursorX, self.cursorY = self:getCharPos( #self.front )
	elseif key == "tab" then
		self.fullContent = self.front .. self.back
		self:update()
		if love.keyboard.isDown("lshift", "rshift") then
			jump = "backward"
		else
			jump = "forward"
		end
		if self.returnEvent then
			self.returnEvent( self.fullContent )
		end
	end

	if stop then
		return "stop"
	elseif jump then
		return jump
	end
end

function InputBlock:textinput( letter )

	-- make sure to ignore first letter that's input:
	if not self.ignoredFirst then
		self.ignoredFirst = true
		return
	end

	if #self.front + #self.back < self.maxLetters then
		self.oldFront, self.oldBack = self.front, self.back
		--local chr = string.char(unicode)
		self.front = self.front .. letter
		self:update( "right" )
	end
end

function InputBlock:setContent( txt )
	local success = self:setText( txt )
	if success then
		self.fullContent = txt
		self.front = txt
		self.back = ""
		self.cursorX, self.cursorY = self:getCharPos( #self.front )
	end
end

function InputBlock:update( cursorDirection )
	local lines = self.lines
	local original = self.original
	local plain = self.plain
	
	-- Check if the last operation split up an umlaut or
	-- similar:
	-- last is the last character on the front part
	-- first is the first character of the second part
	local last = self.front:sub(-1)
	local first = self.back:sub(1,1)
	local bLast = string.byte(last)
	local bFirst = string.byte(first)
	if bLast and bLast >= 194 then
		if bFirst and bFirst > 127 and bFirst < 194 then
			if cursorDirection == "left" then
				self.front = self.front:sub(1, #self.front - 1)
				self.back = last .. self.back
			else
				self.front = self.front .. self.back:sub(1,1)
				self.back = self.back:sub(2)
			end
		else
			self.front = self.front:sub(1, #self.front -1)
		end
	elseif bFirst and bFirst > 127 and bFirst < 194 then
		self.back = self.back:sub(2)
	end

	-- is the new text not too long?
	local success = self:setText( self.front .. self.back )
	if success then
		self.cursorX, self.cursorY = self:getCharPos( #self.front )
	else
		-- change back because text was too long
		self.lines = lines
		self.original = original
		self.plain = plain
		self.front = self.oldFront
		self.back = self.oldBack
	end
end

function InputBlock:setActive( bool )
	self.active = bool
	if self.active then
		self.canvas = nil
		self.renderImg = false
		self.ignoredFirst = false
		self.front = self.fullContent
		self.back = ""
	else
		self.renderImg = true
		self:render()
	end
end

function InputBlock:draw()
	love.graphics.setColor( COLORS.INPUT_BG )
	love.graphics.rectangle( "fill", self.x, self.y, self.width, self.height )
	TextBlock.draw( self )
	if self.active then
		love.graphics.print("|", self.x + self.cursorX, self.y+self.cursorY )
	end
end

return InputBlock
