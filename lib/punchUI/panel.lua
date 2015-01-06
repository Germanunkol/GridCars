local START_X, START_Y, START_ALPHA = 0, 30, 0
local START_TIME = 0.3

local PATH = (...):match("(.-)[^%.^/]+$")
local class = require( PATH .. "middleclass" )
local utility = require( PATH .. "utility" )

local TextBlock = require( PATH .. "textBlock" )
local InputBlock = require( PATH .. "inputBlock" )
local col = require(PATH .. "colors")
local COLORS, COLORS_INACTIVE = col[1], col[2]

local Panel = class("PunchUiPanel")

function Panel:initialize( name, x, y, w, h, font, padding, corners )
	self.name = name or ""
	self.x = x or 0
	self.y = y or 0
	--width and height:
	self.w = w
	self.h = h
	self.font = font
	self.padding = padding or 10

	self.texts = {}
	self.events = {}
	self.inputs = {}

	self.lines = {}

	self.activeInput = nil
	self.corners = corners or {3,3,3,3}	
	self:calcBorder()

	self.startX = START_X
	self.startY = START_Y
	self.alpha = START_ALPHA
	self.startTime = 0
	self.animationTime = START_TIME
end

function Panel:calcBorder()

	self.border = {}

	-- top left:
	if self.corners[1] > 0 then
		table.insert( self.border, 0 )
		table.insert( self.border, 0 + self.corners[1] )
		table.insert( self.border, 0 + self.corners[1] )
		table.insert( self.border, 0 )
	else
		table.insert( self.border, 0 )
		table.insert( self.border, 0 )
	end
	-- top right
	if self.corners[2] > 0 then
		table.insert( self.border, self.w - self.corners[2] )
		table.insert( self.border, 0 )
		table.insert( self.border, self.w )
		table.insert( self.border, 0 + self.corners[2] )
	else
		table.insert( self.border, self.w )
		table.insert( self.border, 0 )
	end
	-- bottom right
	if self.corners[3] > 0 then
		table.insert( self.border, self.w )
		table.insert( self.border, self.h - self.corners[3] )
		table.insert( self.border, self.w - self.corners[3] )
		table.insert( self.border, self.h )
	else
		table.insert( self.border, self.w )
		table.insert( self.border, self.h )
	end
	-- bottom left:
	if self.corners[4] > 0 then
		table.insert( self.border, self.corners[4] )
		table.insert( self.border, self.h )
		table.insert( self.border, 0 )
		table.insert( self.border, self.h - self.corners[4] )
	else
		table.insert( self.border, 0 )
		table.insert( self.border, self.h )
	end
end

function Panel:addText( name, x, y, width, height, txt )

	self:removeText( name )

	-- if the width is not given, make sure text does not
	-- move outside of panel:
	x = x + self.padding
	y = y + self.padding
	local maxWidth = self.w - x - self.padding
	
	width = math.min( width or math.huge, maxWidth )
	local t = TextBlock:new( name, x, y, width, height, txt, self.font, true )
	table.insert( self.texts, t )
	return t, t.trueWidth or t.width, t.height
end

function Panel:removeText( name )
	for k, t in ipairs(self.texts) do
		if t.name == name then
			table.remove(self.texts, k)
		end
	end
end

function Panel:addHeader( name, x, y, txt )
	return self:addText( name, x, y, math.huge, 1, COLORS.HEADER.ID ..txt )
end

function Panel:update( dt )
	if self.startTime < self.animationTime then
		self.startTime = self.startTime + dt
		-- let amount go towards zero:
		local t = math.max(self.startTime/self.animationTime, 0)
		--local amount = math.pow( linear, 6)
		local amount = -2.5*t^2+3.5*t
		self.startX = START_X*(1-amount)
		self.startY = START_Y*(1-amount)
		self.alpha = t
		if self.startTime >= self.animationTime then
			self.startX = 0
			self.startY = 0
			self.alpha = 1
		end
	end
end

function Panel:draw( inactive )
	local COL = COLORS
	if inactive then
		COL = COLORS_INACTIVE
	end

	love.graphics.push()
	love.graphics.translate( self.x + self.startX, self.y + self.startY )
	love.graphics.setColor( COL.PANEL_BG[1], COL.PANEL_BG[2], COL.PANEL_BG[3], COL.PANEL_BG[4]*self.alpha )
	love.graphics.polygon( "fill", self.border )
	love.graphics.setColor( COL.BORDER[1], COL.BORDER[2], COL.BORDER[3], COL.BORDER[4]*self.alpha )
	love.graphics.polygon( "line", self.border )
	love.graphics.setColor( COL.BORDER[1], COL.BORDER[2], COL.BORDER[3], COL.BORDER[4]*self.alpha*0.5 )
	for k, l in ipairs( self.lines ) do
		love.graphics.line( l.x1, l.y1, l.x2, l.y2 )
	end
	for k, e in ipairs( self.events ) do
		if e.highlight then
			love.graphics.setColor( COL.HLIGHT[1], COL.HLIGHT[2], COL.HLIGHT[3], COL.HLIGHT[4]*self.alpha )
			love.graphics.rectangle( "fill", e.x, e.y,
				e.w, e.h )
		end
	end
	for k, v in ipairs( self.texts ) do
		v:draw( inactive )
	end
	for k, v in ipairs( self.inputs ) do
		v:draw( inactive )
	end
	love.graphics.pop()
end

function Panel:addFunction( name, x, y, txt, key, event, tooltip )
	local fullTxt = COLORS.FUNCTION.ID .. string.upper(key) .. " "
	fullTxt = fullTxt .. COLORS.PLAIN_TEXT.ID .. txt
	local t, w, h = self:addText( name, x, y, math.huge, 1, fullTxt )
	local newEvent = {
		name = name,
		key = key,
		event = event,
		tooltip = tooltip,
		x = x + self.padding - 1,
		y = y + self.padding - 1,
		w = w + 2,
		h = h + 2,
	}
	table.insert( self.events, newEvent )
	return newEvent, w, h
end

function Panel:removeFunction( name )
	for k, ev in pairs( self.events ) do
		if ev.name == name then
			table.remove( self.events, k )
			break
		end
	end
	-- Also remove the text which describes this function:
	self:removeText( name )
end

function Panel:addInput( name, x, y, width, height, key, returnEvent, password, content, maxLetters )
	-- add a function which will set the new input box to active:
	-- add the key infront of the input box:
	local event = function()
		self.activeInput = self:inputByName( name )
		self.activeInput:setActive( true )
	end
	self:addFunction( name, x, y, "", key, event )

	x = x + self.padding
	y = y + self.padding
	local maxWidth = self.w - x - self.padding
	local keyWidth = self.font:getWidth( key .. " " )
	
	width = math.min( width or math.huge, maxWidth )
	height = height or self.font:getHeight()

	local i = InputBlock:new( name, x + keyWidth, y, width-keyWidth, height, self.font, returnEvent, password, maxLetters )

	if content and type(content) == "string" then
		i:setContent( content )
	end

	table.insert(self.inputs, i)
	return i
end


function Panel:inputByName( name )
	for k, i in ipairs( self.inputs ) do
		if i.name == name then
			return i
		end
	end
end

function Panel:keypressed( key, unicode )
	if not self.activeInput then
		for k, f in pairs( self.events ) do
			if f.key == key then
				if love.keyboard.isDown("lshift") then
					if f.tooltip then
						f.tooltip()
					end
				elseif f.event then
					f.event( f )
				end
				return true
			end
		end
	else
		local re = self.activeInput:keypressed( key, unicode )
		-- if "esc" was pressed (or similar), stop:
		if re == "stop" then
			self.activeInput:setActive(false)
			self.activeInput = nil
		elseif re == "forward" then		-- tab pressed: go to next input
			self.activeInput:setActive(false)
			local current = self.activeInput
			self.activeInput = nil
			local found = false
			for k, inp in ipairs(self.inputs) do
				if found then
					self.activeInput = inp
					self.activeInput:setActive(true)
					break
				end
				if inp == current then
					found = true
				end
			end
		elseif re == "backward" then		-- tab pressed: go to next input
			self.activeInput:setActive(false)
			local current = self.activeInput
			self.activeInput = nil
			local found = false
			local inp
			for k = #self.inputs, 1, -1 do
				inp = self.inputs[k]
				if found then
					self.activeInput = inp
					self.activeInput:setActive(true)
					break
				end
				if inp == current then
					found = true
				end
			end
		end

	end
end

function Panel:textinput( key )
	if self.activeInput then
		-- type the key into the current input box:
		self.activeInput:textinput( key, true )
	end
end

function Panel:addLine( x1, y1, x2, y2 )
	self.lines[#self.lines+1] = {x1=x1, y1=y1, x2=x2, y2=y2 }
end

function Panel:addListItem( item )

	if #self.events > 0 then
		self:addLine( 4, self.h , self.w - 8, self.h )
	end

	local curY = self.h

	local ev = function()
		if item.event then
			item.event()
		end
	end
	local tip = item.tooltip or "Choose option " .. #self.events + 1 .. "."
	local tooltipEv = function()
		self:newTooltip( tip )
	end


	local key = item.key or tostring( #self.events + 1 )

	ev, w, h = self:addFunction( key, 5, curY, item.txt, key, ev, tooltipEv )
	maxWidth = math.max( self.w - 12, w )
	curY = curY + self.font:getHeight() + 8

	self.h = curY
	self.w = maxWidth + 12

	self:calcBorder()
end

------------------------------------------------------
-- Handle mouse input:

function Panel:mousemoved( x, y )
	for k, e in pairs( self.events ) do
		if utility.isInside( x, y, e.x + self.x, e.y + self.y, e.w, e.h ) then
			e.highlight = true
			return e
		end
	end
end

function Panel:mousepressed( x, y, button )
	for k, e in pairs( self.events ) do
		if utility.isInside( x, y, e.x + self.x, e.y + self.y, e.w, e.h ) then
			if e.event then
				e.event( e )
			end
			return e
		end
	end
end

return Panel
