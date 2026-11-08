VECTOR - standalone release

1. Open Roblox and run the complete VECTOR.lua in your compatible Lua host.
2. No MCP, Python server or HeadlessBridge is needed.
3. The script creates VECTOR/ inside the host's workspace and saves main.lua,
   combat.json, animations.json, playtime.json and config.json there as used.
4. Press minus (-) or Right Shift to show/hide the UI.

Requires loadstring. Rayfield UI downloads from https://sirius.menu/gen2,
so an internet connection and HttpGet support are still required.
Persistent storage requires makefolder/readfile/writefile support. Without it,
session controls can still run, but saving and teleport resume are unavailable.
Teleport resume additionally requires queue_on_teleport or queueonteleport.
Running VECTOR again cleans up its previous standalone session.
