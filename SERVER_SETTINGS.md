Setting up a GridCars server
============================================

Normal Server:
-----------------------
A normal server is one with a graphical interface (where you also play along). Usually used in LAN settings.
- Edit your config.txt file in _%APPDATA%\GridCars\_ or _~/.local/share/GridCars/_ (Options: see below)
- If you want to play on the internet, port-forward the Port (Default: TCP 3140) on your router
- Start the Game, and select one of the two server options.

Dedicated server:
-----------------------
A dedicated server is run from the console, usually on online servers.
- Download the source code version of the game [from github](https://github.com/Germanunkol/GridCars/)
- Edit the config.txt file _in the root directory of the game_. (Options: see below)
- Make sure Lua and luasocket are installed.
- Run "lua dedicated.lua" in the root directory.

Options:
----------------------
The server has the following options which you can set in the config.txt file:

- MAP_CYCLE: Comma-sperated list of the maps. These files must be in the maps/ subfolder. Names are case-sensitive.
- LAPS: Number of laps a player needs to finish in order to win.
- ROUND_TIME: Number of seconds a player has 
- MAX_PLAYERS: Number of players allowed to join this server. All standard maps support at least 16 players, maps 5 and 6 support at least 64 players.
- SKIP_ROUNDS_CAR_CAR: Number of rounds a player has to wait after crashing into another car.
- SKIP_ROUNDS_COLLISION_PER_10_KMH: After a crash, the greater the player's speed was, the longer they have to wait. This value tells the game how much to add to the waiting time, per 10 km/h of the player's speed. Set this to zero if you don't want the number of skipped rounds to depend on the player's speed.
- SKIP_ROUNDS_COLLISION_MIN: Minimum number of rounds player has to wait after crashing into the wall.
- PORT: TCP port to use. This port must be opened on your router if you want to play over the internet!
- COUNTDOWN: Number of seconds to wait before starting a new round, after at least one player is ready.
- WELCOME_MSG: Chat message sent to new players
- SERVER_NAME: Name of the server to display in serverlist.


Here's an example along with the default values:
```
MAP_CYCLE = map1.stl, map2.stl, map4.stl, map5.stl, map6.stl
LAPS = 0
ROUND_TIME = 10
MAX_PLAYERS = 16
SKIP_ROUNDS_CAR_CAR = 1
SKIP_ROUNDS_COLLISION_PER_10_KMH = 0.5
SKIP_ROUNDS_COLLISION_MIN = 1
PORT = 3410
COUNTDOWN = 60
WELCOME_MSG = "Welcome!"
SERVER_NAME = My Server
```
