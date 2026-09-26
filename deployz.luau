-- DeployZ (Luau edition): a tiny static site host. Run with `lune run deployz`.
local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")

local Log = require("./src/log")
local Router = require("./src/router")
local Reload = require("./src/reload")

local configPath = process.args[1] or "config.json"
if not fs.isFile(configPath) then
	error(`config not found: {configPath}`)
end
local config = serde.decode("json", fs.readFile(configPath))
config.port = tonumber(process.env.PORT) or config.port or 8080
config.webroot = config.webroot or "webroot"

local log = Log.new(config)

if config.liveReload then
	local dirs = { config.webroot }
	for _, target in config.domains or {} do
		if not string.match(target, "%.html?$") then
			table.insert(dirs, target)
		end
	end
	Reload.start(dirs)
end

net.serve(config.port, Router.new(config, log))
log:debug("info", "server started", { port = config.port })
print(`DeployZ running on http://localhost:{config.port}`)
