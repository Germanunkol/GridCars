local Timer = {}
Timer.__index = Timer

function Timer:new( time, event )
	local o = {
		time = time,
		event = event,
	}
	setmetatable( o, self )
	return o
end

function Timer:updateAndFire( dt )
	self.time = self.time - dt
	if self.time <= 0 then
		self.event()
		return true
	end
	return false
end

return Timer
