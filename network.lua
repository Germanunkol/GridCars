
require( "lib/LUBE" )

local network = {}

local conn = nil
local connectionType = ""
local connected = false
local connectedUsers = 0

local users = {}

local PORT = 3410

function network:startServer()
	connectionType = "server"

	conn = lube.tcpServer()
	conn.handshake = "handshake"
	conn:setPing(true, 16, "ping?\n")
	conn:listen(PORT)
	conn.callbacks.recv = serverRecv
	conn.callbacks.connect = userConnected
	conn.callbacks.disconnect = userDisconnected
end

function network:startClient( address )
	connectionType = "client"

	if not address then
		print("No address found. Using default: 'localhost'")
		address = "localhost"
	end

	print( "Connecting to:", address )

	conn = lube.tcpClient()
	conn.handshake = "handshake"
	conn:setPing(true, 2, "ping?\n")
	assert(conn:connect(address, PORT, true))
	conn.callbacks.recv = clientRecv
end

function network:close()
end

function network:update( dt )
	if conn then
		conn:update( dt )
	end
end

function userForSocket( client )
	for k = 1, #users do
		if users[k].client == client then
			return users[k]
		end
	end
	return nil
end

function userConnected( client )
	local newID = findFreeID()
	local cl = {
		client = client,
		name = nil,
		id = newID,
	}
	users[newID] = cl
	print( "New user:", client, "ID:", cl.id )

	connectedUsers = connectedUsers + 1
end

function userDisconnected( client )
	local user = userForSocket( client )
	if user then
		-- TODO: Let other users know this client disconnected!
		users[user.id] = nil
		print( "Disconnected:", user.id )
	else
		print( "!! Trying to disconnect invalid user!" )
	end

	connectedUsers = connectedUsers - 1
end

function serverRecv( msg ,id )
	print("Received:\n\t", msg)
end

function clientRecv( msg, id )
	print("Received:\n\t", msg)
end

function network:sendText( text )
	print("sending:", text)
	if conn then
	print("\tsending:", text)
		conn:send( text )
	end
end

function findFreeID()
	for i = 1, connectedUsers+1 do
		if not users[i] then
			return i
		end
	end
end

return network
