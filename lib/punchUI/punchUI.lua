--local msgBox = require("Scripts/UI/uiMsgBox")
--local toolTip = require("Scripts/UI/uiToolTip")
local class = require("Scripts/middleclass")
UI = class("UI")
local Panel = require("Scripts/UI/panel")

local DEFAULT_FONT = love.graphics.newFont(12)
local MSG_BOX_WIDTH = 200
local MSG_TIME = 10
local COLOR_ERROR = {255, 80, 0, 255}
local COLOR_TOOLTIP = {255, 255, 255, 255}

function UI:initialize( name, font )
	self.name = name or "Default UI"
	self.font = font or DEFAULT_FONT
	self.curInput = false
	self.panelList = {}
	self.msgBoxList = {}
	self.msg = ""
	self.msgColor = COLOR_TOOLTIP
	self.msgTimer = 0
end

function UI:update( dt )
	self.msgTimer = self.msgTimer - dt
end

function UI:draw()
	love.graphics.setFont( self.font )
	
	if #self.msgBoxList > 0 then
		for k,p in ipairs( self.panelList ) do
			p:draw( false )
		end
		for k,p in ipairs( self.msgBoxList ) do
			p:draw( true )
		end
	else
		for k,p in ipairs( self.panelList ) do
			p:draw( true )
		end
	end
	if self.msgTimer > 0 then
		local width = love.graphics.getWidth() - 80
		local w, l = self.font:getWrap( self.msg, width )
		love.graphics.setColor( self.msgColor )
		love.graphics.printf( self.msg, 40, love.graphics.getHeight() - (l+1)*self.font:getHeight(),
								width )
	end
end

function UI:newTooltip( msg )
	self.msgTimer = MSG_TIME
	self.msg = msg
	self.msgColor = COLOR_TOOLTIP
end

function UI:newError( msg )
	self.msgTimer = MSG_TIME
	self.msg = msg
	self.msgColor = COLOR_ERROR
end

function UI:newFunction( panelName, name, x, y, centered, key, func, tooltip )
	for k, p in ipairs( self.panelList ) do
		if p.name == panelName then
			p:addFunction( name, x, y, centered, key, func, tooltip )
			return
		end
	end
end

function UI:newHeader( panelName, name, x, y, centered )
	for k, p in ipairs( self.panelList ) do
		if p.name == panelName then
			p:addHeader( name, x, y, centered )
			return
		end
	end
end

function UI:newText( panelName, name, x, y, width, text )
	for k, p in ipairs( self.panelList ) do
		if p.name == panelName then
			p:addText( name, x, y, width, text )
		end
	end
end

function UI:newPanel( name, x, y, minWidth, minHeight, padding )
	table.insert(self.panelList, Panel:new( name, x, y, minWidth, minHeight, padding, self.font ))
end

function UI:removePanel( panel )
	if type(panel) == "string" then
		local name = panel
		for k, p in ipairs( self.panelList ) do
			if p.name == name then
				table.remove( self.panelList, k)
				return
			end
		end
	elseif panel.class == Panel then
		for k, p in pairs( self.msgBoxList ) do
			if p == panel then
				table.remove( self.msgBoxList, k )
				return
			end
		end
		for k, p in pairs( self.panelList ) do
			if p == panel then
				table.remove( self.panelList, k )
			end
		end
	end
end

function UI:movePanel( name, x, y )
	for k, p in ipairs( self.panelList ) do
		if p.name == name then
			p.x = x
			p.y = y
		end
	end

end

function UI:newInput( panelName, name, x, y, width, lines, key, initialText, forbidden )
	print(panelName, name, x, y, width, lines, key, initialText, forbidden )
	for k, p in ipairs( self.panelList ) do
		if p.name == panelName then
			p:addInput( name, x, y, width, lines, key, initialText, forbidden )
			return
		end
	end
end

function UI:newMsgBox( header, txt, funcs )
	local msgBox = Panel:new( "msgBox", math.random(500), math.random(500), MSG_BOX_WIDTH, 0, 20, self.font )
	msgBox:addHeader( header or "", 0, 0, false)
	msgBox:addText( "info", 0, 0.01, MSG_BOX_WIDTH, txt )
	local a,b,c,d = msgBox:getElemPos( "info" )
	local y = b + d		-- y start pos plus element height
	y = y*0.01/self.font:getHeight()
	for k,f in ipairs( funcs ) do
		if not f.func then
			f.func = function() self:removePanel(msgBox) end
		end
		msgBox:addFunction( f.name, 10, y + 0.01*k, false, f.key, f.func, f.tooltip )
	end
	self.msgBoxList[#self.msgBoxList+1] = msgBox
end

-- check to see if an active function has the pressed key. If so, execute the function and return.
function UI:keypressed( key, unicode )
	if #self.msgBoxList > 0 then
		for k, p in ipairs(self.msgBoxList) do
			for k, v in pairs( p.funcList ) do
				if v.key == key then
					if love.keyboard.isDown("lshift") then
						self:newTooltip( v.tooltip )
					else
						v.func()
					end
					return true		-- stop looking for more keys!
				end
			end
		end
		return
	end
	if self.curInput then
		if key == "escape" then	-- abort
			if #self.curInput.content == 0 then
				self.curInput.txt = self.curInput.initialText
			else
				self.curInput.txt = self.curInput.content
			end
			self.curInput = false
		elseif key == "backspace" then
			local len = #self.curInput.txt1
			if len > 0 then
				self.curInput.txt1 = self.curInput.txt1:sub(1, len-1)
				self.curInput.txt = self.curInput.txt1 .. self.curInput.txt2
			end
		elseif key == "return" then
			self.curInput.content = self.curInput.txt
			self.curInput = false
		elseif unicode >= 32 and unicode < 127 then
			local chr = string.char(unicode)
			local newTxt = self.curInput.txt1 .. chr .. self.curInput.txt2
			--[[local w, l = self.font:getWrap( newTxt, self.curInput.textWidth )
			if l <= self.curInput.lines then
				self.curInput.txt = newTxt
				self.curInput.txt1 = self.curInput.txt1 .. chr
			end]]--
			self.curInput.setText()
		elseif key == "left" then
			local len = #self.curInput.txt1
			if len > 0 then
				self.curInput.txt2 = self.curInput.txt1:sub( len,len ) .. self.curInput.txt2
				self.curInput.txt1 = self.curInput.txt1:sub(1, len-1)
				self.curInput.txt = self.curInput.txt1 .. self.curInput.txt2
			end
		elseif key == "right" then
			local len = #self.curInput.txt2
			if len > 0 then
				self.curInput.txt1 = self.curInput.txt1 .. self.curInput.txt2:sub(1,1)
				self.curInput.txt2 = self.curInput.txt2:sub(2,len)
				self.curInput.txt = self.curInput.txt1 .. self.curInput.txt2
			end
		elseif key == "delete" then
			local len = #self.curInput.txt2
			if len > 0 then
				self.curInput.txt2 = self.curInput.txt2:sub(2,len)
				self.curInput.txt = self.curInput.txt1 .. self.curInput.txt2
			end
		elseif key == "home" then
			self.curInput.txt2 = self.curInput.txt1 .. self.curInput.txt2
			self.curInput.txt1 = ""
		elseif key == "end" then
			self.curInput.txt1 = self.curInput.txt1 .. self.curInput.txt2
			self.curInput.txt2 = ""
		end
	else
		for i, p in pairs( self.panelList ) do
			for k, v in pairs( p.funcList ) do
				if v.key == key then
					if love.keyboard.isDown( "lshift" ) then
						self:newTooltip( v.tooltip )
					else
						v.func()
					end
					return true		-- stop looking for more keys!
				end
			end
			for k, v in pairs( p.inputList ) do
				if v.key == key then
					if love.keyboard.isDown( "lshift" ) then
						self:newTooltip( v.tooltip )
					else
						self.curInput = v
						v.txt1 = v.content
						v.txt2 = ""
					end
					return true
				end
			end
		end
	end

	return false -- no active function with the given key present.
end


function UI:setInputActive( input )
	self.curInput = input
end
