local fs = require("@lune/fs")
local serde = require("@lune/serde")
local datetime = require("@lune/datetime")

local LEVELS = { error = 1, warn = 2, info = 3, debug = 4 }

local Log = {}
Log.__index = Log

function Log.new(config)
	if not fs.isDir("logs") then
		fs.writeDir("logs")
	end
	return setmetatable({ config = config }, Log)
end

local function append(path: string, line: string)
	local existing = if fs.isFile(path) then fs.readFile(path) else ""
	fs.writeFile(path, existing .. line .. "\n")
end

local function stamp(): string
	return datetime.now():toIsoDate()
end

function Log:request(method: string, host: string, path: string, status: number)
	if self.config.requestLogsEnabled then
		append("logs/requests.log", `[{stamp()}] {status} {method} {host}{path}`)
	end
end

function Log:blocked(host: string, path: string)
	if self.config.logsEnabled then
		append("logs/blocked.log", `[{stamp()}] BLOCKED {host}{path}`)
	end
end

function Log:debug(level: string, msg: string, data: any?)
	if not self.config.debugLogsEnabled then
		return
	end
	local max = LEVELS[self.config.debugLogLevel or "info"] or 3
	if (LEVELS[level] or 4) > max then
		return
	end
	local line = `[{stamp()}] [{string.upper(level)}] {msg}`
	if data ~= nil then
		line ..= " " .. serde.encode("json", data)
	end
	append("logs/debug.log", line)
end

return Log
