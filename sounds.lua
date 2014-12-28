local Sounds = {
	sources = {}
}

function Sounds:load()
	local files = love.filesystem.getDirectoryItems( "sounds" )
	for k, f in pairs( files ) do
		if f:match( ".wav$" ) then
			local name = f:match( "(.*).wav" )
			local s = love.audio.newSource( "sounds/" .. f )
			Sounds.sources[name] = s
		end
	end
end

function Sounds:play( name )
	if Sounds.sources[name] then
		Sounds.sources[name]:play()
	end
end

return Sounds
