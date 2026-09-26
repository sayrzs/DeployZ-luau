local fs = require("@lune/fs")
local Static = require("./static")
local Reload = require("./reload")

local Router = {}

local function globToPattern(glob: string): string
	local p = string.gsub(glob, "[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0")
	p = string.gsub(p, "%*", ".*")
	return "^" .. p .. "$"
end

function Router.new(config, log)
	local blocked = {}
	for _, g in config.blockedFiles or {} do
		table.insert(blocked, globToPattern(g))
	end

	local function isBlocked(rel: string): boolean
		if not config.blockFeature or string.match(rel, "%.css$") then
			return false -- CSS is never blocked, same as original DeployZ
		end
		local name = string.match(rel, "[^/]+$") or rel
		for _, pat in blocked do
			if string.match(rel, pat) or string.match(name, pat) then
				return true
			end
		end
		return false
	end

	local function text(status: number, body: string)
		return { status = status, headers = { ["content-type"] = "text/plain; charset=utf-8" }, body = body }
	end

	return function(req)
		local host = string.lower(string.match(req.headers.host or "", "^[^:]+") or "")
		local path = req.path

		local function done(res)
			log:request(req.method, host, path, res.status)
			return res
		end

		if path == "/__deployz/version" then
			return { status = 200, headers = { ["cache-control"] = "no-store" }, body = tostring(Reload.version) }
		end

		local target = config.redirects and config.redirects[host]
		if target then
			return done({ status = 301, headers = { location = target }, body = "" })
		end

		if req.method ~= "GET" and req.method ~= "HEAD" then
			return done(text(405, "Method Not Allowed"))
		end

		local rel = Static.clean(path)
		if not rel then
			return done(text(400, "Bad Request"))
		end
		if isBlocked(rel) then
			log:blocked(host, path)
			return done(text(403, "Forbidden"))
		end

		-- A domain maps to a site folder, or (original behaviour) to a single HTML file.
		local root = config.webroot
		local mapped = config.domains and config.domains[host]
		local file
		if mapped and string.match(mapped, "%.html?$") then
			file = if rel == "" then mapped else Static.resolve(config.webroot, rel)
		else
			root = mapped or root
			file = Static.resolve(root, rel)
		end

		if not file then
			local notFound = Static.resolve(root, "404.html")
			local body = if notFound then fs.readFile(notFound) else "404 Not Found"
			log:debug("info", "not found", { host = host, path = path })
			return done({ status = 404, headers = { ["content-type"] = "text/html; charset=utf-8" }, body = body })
		end

		local body = fs.readFile(file)
		local mime = Static.mime(file)
		if config.liveReload and string.find(mime, "text/html", 1, true) then
			body = Reload.inject(body)
		end
		return done({ status = 200, headers = { ["content-type"] = mime }, body = if req.method == "HEAD" then "" else body })
	end
end

return Router
