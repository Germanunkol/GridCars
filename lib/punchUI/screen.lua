
local PATH = (...):match("(.-)[^%.]+$")

local class = require(PATH .. "middleclass")
local Panel = require(PATH .. "panel")
local Screen = class("PunchUiScreen")

local TOOL_TIP_TIME = 6

function Screen:initialize( name, font, maxWidth, maxHeight )
	self.name = name or ""
	self.font = font

	self.panels = {}
	self.msgBox = nil
	self.menus = {}
	self.lists = {}

	self.tooltipPan = nil
	self.tooltipTime = 0

	self.maxWidth = maxWidth or love.graphics.getWidth()
	self.maxHeight = maxHeight or love.graphics.getHeight()
end

function Screen:enableToolTips()
	local width, height = love.graphics.getWidth(), self.font:getHeight()*2
	local x, y = 0, love.graphics.getHeight() - height
	local pan = Panel:new( "tooltip", x, y, width, height, self.font, 10, {3,3,0,0} )
	self.tooltipPan = pan
end
function Screen:disableToolTips()
	self.tooltipPan = nil
end

function Screen:newTooltip( msg )
	if self.tooltipPan then
		self.tooltipPan:addText( "tooltip", 0,0, nil, self.font:getHeight()*3, msg )
		self.tooltipTime = TOOL_TIP_TIME
	end
end

function Screen:addPanel( name, x, y, minWidth, minHeight, font, padding, corners )

	-- no duplicate panels allowed!
	local old = self:panelByName( name )
	if old then
		self:removePanel( name )
	end
	local pan = Panel:new( name, x, y, minWidth, minHeight, font or self.font, padding, corners )
	table.insert( self.panels, pan )
	return pan

end

function Screen:removePanel( name )
	for k, p in ipairs( self.panels ) do
		if p.name == name then
			table.remove( self.panels, k )
			return
		end
	end
end

function Screen:panelByName( name )
	for k,p in ipairs(self.panels) do
		if p.name == name then
			return p
		end
	end
end

function Screen:addInput( panelName, name, x, y, width, height, key, event, content, maxLetters )
	local p = self:panelByName( panelName )
	i = p:addInput( name, x, y, width, height, key, event, false, content, maxLetters )
	return i
end
function Screen:addPassword( panelName, name, x, y, width, height, key, event, maxLetters )
	local p = self:panelByName( panelName )
	i = p:addInput( name, x, y, width, height, key, event, true, nil, maxLetters )
	return i
end
function Screen:addText( panelName, name, x, y, width, height, txt )
	local p = self:panelByName( panelName )
	t = p:addText( name, x, y, width, height, txt )
	return t 
end
function Screen:addHeader( panelName, name, x, y, txt )
	local p = self:panelByName( panelName )
	h = p:addHeader( name, x, y, txt )
	return h
end

function Screen:activateInput( panelName, name )
	local p = self:panelByName( panelName )
	local inp = p:inputByName( name )

	if p.activeInput then p.activeInput:setActive( false ) end

	p.activeInput = inp
	inp:setActive( true )
	
end

function Screen:tabToNextInput()
	
end

function Screen:draw()
	love.graphics.setLineWidth(1)

	local inactive = self.msgBox and true or false
	local inactiveMenu = #self.menus > 0
	if self.tooltipPan and self.tooltipTime > 0 then
		self.tooltipPan:draw()
	end

	for k,p in ipairs(self.panels) do
		p:draw( inactive or inactiveMenu )
	end
	for k,l in ipairs(self.lists) do
		l:draw( inactive or inactiveMenu )
	end
	for k,m in ipairs(self.menus) do
		if k == #self.menus then
			m:draw( inactive )
		else
			-- always draw lower menus as
			-- inactive, because the active
			-- menu is always the top one.
			m:draw( true )
		end
	end

	if self.msgBox then
		self.msgBox:draw( false )
	end
end

function Screen:addFunction( panelName, name, x, y, txt, key, event, tooltip )
	local tooltipEv
	if tooltip then
		tooltipEv = function()
			self:newTooltip( tooltip )
		end
	end

	local p = self:panelByName( panelName )
	f = p:addFunction( name, x, y, txt, key, event, tooltipEv )
	return f
end
function Screen:removeFunction( panelName, name )
	local p = self:panelByName( panelName )
	p:removeFunction( name )
end

function Screen:keypressed( key, unicode )
	if self.msgBox then
		return self.msgBox:keypressed( key, unicode )
	elseif #self.menus > 0 then
		if key == "escape" then
			self.menus[#self.menus] = nil
			return true
		else
			return self.menus[#self.menus]:keypressed( key, unicode )
		end
	else
		for k, p in pairs( self.panels ) do
			if p.activeInput then
				p:keypressed( key, unicode )
				return true
			end
		end

		for k, l in pairs( self.lists ) do
			-- allow only one panel to react to the input:
			if l:keypressed( key, unicode ) then
				return true
			end
		end

		for k, p in pairs( self.panels ) do
			-- allow only one panel to react to the input:
			if p:keypressed( key, unicode ) then
				return true
			end
		end
	end
end
function Screen:textinput( letter )
	for k, p in pairs( self.panels ) do
		if p.activeInput then
			p:textinput( letter )
			return true
		end
	end
end

function Screen:update( dt )
	self.tooltipTime = self.tooltipTime - dt
	for k, p in pairs(self.panels) do
		p:update( dt )
	end
	for k, m in pairs(self.menus) do
		m:update( dt )
	end
	for k, l in pairs(self.lists) do
		l:update( dt )
	end
	if self.msgBox then self.msgBox:update(dt) end
end

function Screen:newMsgBox( header, msg, x, y, width, commands )

	width = width or love.graphics.getWidth()/4 + 40
	x = x or (love.graphics.getWidth() - width)/2
	y = y or 2*love.graphics.getHeight()/5
	local msgBox = Panel:new( "msgBox", x, y, width, 100, self.font, 20 )
	local curY = 0
	msgBox:addHeader( "header", curY, 0, header )
	curY = curY + self.font:getHeight()
	local t, width, height = msgBox:addText( "text", 10, curY, nil, 1, msg )
	curY = curY + height + 10
	
	for k, c in ipairs( commands ) do
		msgBox:addFunction( tostring(k), 10, curY, c.txt, c.key, 
							function()
								self:removeMsgBox()
								if c.event then
									c.event()
								end
							end )
		curY = curY + self.font:getHeight()
	end

	msgBox.h = (#commands+2)*self.font:getHeight() + height + 30
	msgBox:calcBorder()
	self.msgBox = msgBox
end

function Screen:removeMsgBox()
	self.msgBox = nil
end

function Screen:newMenu( x, y, minWidth, list )
	width = love.graphics.getWidth()/5 + 8
	x = x or 10
	y = y or 10
	local ID = #self.menus + 1
	local menuPanel = Panel:new( "menuPanel" .. ID, x, y, width, 100, self.font, 4, {0,0,3,3} )
	
	local curY = 0
	local ev, w, h
	local maxWidth = minWidth or 0
	for k, v in ipairs( list ) do

		local ev = function()
			local numMenus = #self.menus

			if v.event then
				v.event()
			end

			-- if the event did NOT create a sub menu, then
			-- remove all menus. Otherwise, keep displaying
			-- the menus.
			if numMenus >= #self.menus then
				self.menus = {}
			else
				-- consider the newly added menu a sub-menu
				-- of the last one:
				local cur = #self.menus
				if self.menus[cur - 1] then
					self.menus[cur].x = self.menus[cur-1].x + self.menus[cur-1].w
					self.menus[cur].y = self.menus[cur-1].y + (4+self.font:getHeight())*k
					if self.menus[cur].x + self.menus[cur].w > self.maxWidth then
						self.menus[cur].x = self.menus[cur-1].x - self.menus[cur].w
					end
					if self.menus[cur].y + self.menus[cur].h > self.maxHeight then
						self.menus[cur].y = self.menus[cur].y - self.menus[cur].h
					end
				end
			end
		end
		local tip = v.tooltip or "Choose option " .. k .. "."
		local tooltipEv = function()
			self:newTooltip( tip )
		end

		ev, w, h = menuPanel:addFunction( tostring(k), 0, curY, v.txt, tostring(k), ev, tooltipEv )
		maxWidth = math.max( maxWidth, w )
		curY = curY + self.font:getHeight() + 8
	end

	curY = 0
	for k, v in ipairs( list ) do
		curY = curY + self.font:getHeight() + 8
		if k < #list then
			menuPanel:addLine( 4, curY , maxWidth + 4, curY )
		end
	end
	
	menuPanel.h = curY
	menuPanel.w = 8 + maxWidth
	menuPanel:calcBorder()
	self.menus[ID] = menuPanel
end

function Screen:newList( x, y, minWidth, list )
	width = love.graphics.getWidth()/5 + 8
	x = x or 10
	y = y or 10
	local ID = #self.lists + 1
	local listPanel = Panel:new( "listPanel" .. ID, x, y, width, 100, self.font, 4, {0,0,3,3} )
	
	local curY = 0
	local ev, w, h
	local maxWidth = minWidth or 0
	for k, v in ipairs( list ) do

		local ev = function()
			if v.event then
				v.event()
			end
		end
		local tip = v.tooltip or "Choose option " .. k .. "."
		local tooltipEv = function()
			self:newTooltip( tip )
		end

		local key = v.key or tostring(k)

		ev, w, h = listPanel:addFunction( key, 0, curY, v.txt, key, ev, tooltipEv )
		maxWidth = math.max( maxWidth, w )
		curY = curY + self.font:getHeight() + 8
	end

	curY = 0
	for k, v in ipairs( list ) do
		curY = curY + self.font:getHeight() + 8
		if k < #list then
			listPanel:addLine( 4, curY , maxWidth + 4, curY )
		end
	end
	
	listPanel.h = curY
	listPanel.w = 12 + maxWidth
	listPanel:calcBorder()
	self.lists[ID] = listPanel
	return listPanel
end

function Screen:removeList( name )
	for k, l in ipairs( self.lists ) do
		if l.name == name then
			table.remove( self.lists, k )
			return
		end
	end
end

return Screen
