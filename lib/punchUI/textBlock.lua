
-- Takes a string of text and wraps it at a certain width.
-- Takes into account colours, newlines, font type.
-- Returns a table of line fragments.

local PATH = (...):match("(.-)[^%.^/]+$")
local class = require( PATH .. "middleclass" )
local col = require(PATH .. "colors")
local COLORS, COLORS_INACTIVE = col[1], col[2]
col = nil
local TextBlock = class("TextBlock")

function TextBlock:initialize( name, x, y, width, height, text, font, renderImg )

	self.name = name or ""
	self.x = x or 0
	self.y = y or 0
	self.width = width or 100
	self.font = font
	self.original = text or ""
	self.renderImg = renderImg

	self.maxLines = math.huge
	self.trueWidth = 0
	
	self.plain = self.original:gsub("{.-}", "")
	self.lines = self:wrap()

	self.fragments = self:colorSplit()

	self.height = #self.lines*self.font:getHeight()
	
	if self.renderImg then
		self:render()
	end
end

function TextBlock:wrap()
	local lines = {}
	self.plain = self.plain .. "\n"
	for line in self.plain:gmatch( "([^\n]-\n)" ) do
		if self.password then
			line = string.rep("*", #line-1)
		end
		table.insert( lines, line )
	end

	local wLines = {}	-- lines that have been wrapped
	local shortLine
	local restLine
	local word = "[^ ]* "	-- not space followed by space
	local tmpLine
	local letter = "[%z\1-\127\194-\244][\128-\191]*"

	for k, line in ipairs(lines) do
		if self.font:getWidth( line ) <= self.width then
			table.insert( wLines, line )
		else
			restLine = line .. " " -- start with full line
			while #restLine > 0 do
				local i = 1
				local breakingCondition = false
				tmpLine = nil
				shortLine = nil
				repeat		-- look for spaces!
					tmpLine = restLine:match( word:rep(i) )
					if tmpLine then
						if self.font:getWidth(tmpLine) > self.width then
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
							if self.font:getWidth(tmpLine) > self.width then
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
	end

	self.trueWidth = 0
	local w = 0
	for k, l in pairs( wLines ) do
		w = self.font:getWidth(l)
		if w > self.trueWidth then
			self.trueWidth = w
		end
	end

	return wLines
end

function TextBlock:colorSplit()

	-- if the text doesn't start with a color,
	-- then start it with white:
	local startsWithCol = false
	for k,col in pairs(COLORS) do
		if self.original:find( col.ID ) == 1 then
			startsWithCol = true
			break
		end
	end
	if not startsWithCol then
		self.original = COLORS.WHITE.ID .. self.original
	end
	
	local split = {}
	-- look for all occurances of the id of all colors in the text:
	for k,col in pairs(COLORS) do
		for s,e in self.original:gmatch( "()" .. col.ID .. "()" ) do
			table.insert( split, {start = s, color = col} )
		end
	end

	table.sort( split, function( a, b)
							return a.start < b.start
						end )

	for k,s in ipairs(split) do
		s.start = s.start - (k-1)*3
		if split[k-1] then
			split[k-1].finish = s.start - 1
		end
	end
	split[#split].finish = #self.plain

	local fragments = {}
	local curColor = split[1].color
	local x = 0
	local y = 0
	local curPos = 0
	local curSplit = split[1]
	local cur
	local txt
	local start
	for k,l in ipairs( self.lines ) do
		start = curPos + 1
		x = 0
		y = (k-1)*self.font:getHeight()
		for i,s in ipairs( split ) do
			-- full line is same color?
			if s.start <= start and s.finish >= start + #l then
				table.insert(fragments, {x=x, y=y, color=s.color, txt = l } )
				break
			-- overlapping from left?
			elseif s.start <= start and s.finish <= start + #l and s.finish >= start then
				txt = l:sub(1, s.finish-start + 1 )
				table.insert(fragments, {x=x, y=y, color=s.color, txt=txt } )
				x = x + self.font:getWidth( txt )
			-- fully inside:
			elseif s.start >= start and s.finish <= start + #l then
				txt = l:sub(s.start - start +1, s.finish - start + 1)
				table.insert(fragments, {x=x, y=y, color=s.color, txt=txt } )
				x = x + self.font:getWidth( txt )
			-- overlapping from right:
			elseif s.start >= start and s.finish >= start + #l and s.start <= start + #l then
				txt = l:sub( s.start - start + 1 )
				table.insert(fragments, {x=x, y=y, color=s.color, txt=txt } )
				x = x + self.font:getWidth( txt )
			end
		end
		curPos = curPos + #l
	end

	return fragments
end

function TextBlock:setText( text )
	self.original = text
	self.plain = self.original:gsub("{.-}", "")
	self.lines = self:wrap()
	if #self.lines <= self.maxLines then
		self.fragments = self:colorSplit()

		self.height = #self.lines*self.font:getHeight()

		if self.renderImg then
			self:render()
		end
		return true
	else
		return false
	end
end

function TextBlock:setDimensions( width, height )
	self.maxWidth = width
	self.maxHeight = height
end

function TextBlock:render()
	self.canvas = nil
	self.canvasWidth = self.trueWidth
	self.canvasHeight = self.height
	if self.canvasWidth > 0 and self.canvasHeight > 0 then
		love.graphics.setColor( 255,255,255,255 )
		self.canvas = love.graphics.newCanvas( self.canvasWidth, self.canvasHeight )
		love.graphics.setCanvas( self.canvas )
		love.graphics.setFont( self.font )
		for k, f in ipairs(self.fragments) do
			love.graphics.setColor( f.color )
			love.graphics.print( f.txt, f.x, f.y )
		end
		--self.canvas:getImageData():encode( love.timer.getTime() .. ".png" )
		love.graphics.setCanvas()
	end
end

function TextBlock:draw( inactive )
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.push()
	love.graphics.translate( self.x, self.y )
	local COLORS = COLORS
	if inactive then
		COLORS = COLORS_INACTIVE
	end
	if self.canvas then

		love.graphics.setColor( COLORS.RENDERED_TEXT )
		local prevMode = love.graphics.getBlendMode()
		love.graphics.setBlendMode("premultiplied")

		love.graphics.draw( self.canvas, 0, 0)

		love.graphics.setBlendMode( prevMode )
		love.graphics.setColor(255,255,255,255)
	else
		for k, f in ipairs(self.fragments) do
			love.graphics.setColor( f.color )
			love.graphics.print( f.txt, f.x, f.y )
		end
	end
	love.graphics.pop()
end

function TextBlock:getHeight()
	return self.height
end

function TextBlock:getWidth()
	return self.width
end

function TextBlock:getCharPos( num )
	local i = 0
	local k = 1
	local x, y = 0,0
	while i < num do
		if i + #self.fragments[k].txt >= num then
			local part = self.fragments[k].txt:sub(1, num - i)
			x = self.font:getWidth( part ) + self.fragments[k].x
			y = self.fragments[k].y
			break
		else
			i = i + #self.fragments[k].txt
			k = k + 1
		end
	end
	return x, y
end

return TextBlock
