local fs = require("@lune/fs")

local MIME = {
	html = "text/html; charset=utf-8", htm = "text/html; charset=utf-8",
	css = "text/css; charset=utf-8", js = "text/javascript; charset=utf-8",
	mjs = "text/javascript; charset=utf-8", json = "application/json",
	txt = "text/plain; charset=utf-8", xml = "application/xml",
	svg = "image/svg+xml", png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
	gif = "image/gif", webp = "image/webp", ico = "image/x-icon", avif = "image/avif",
	woff = "font/woff", woff2 = "font/woff2", ttf = "font/ttf",
	mp4 = "video/mp4", webm = "video/webm", mp3 = "audio/mpeg", wasm = "application/wasm",
	pdf = "application/pdf",
}

local Static = {}

function Static.mime(path: string): string
	local ext = string.match(path, "%.([%w]+)$")
	return (ext and MIME[string.lower(ext)]) or "application/octet-stream"
end

-- Turns a URL path into a safe relative path, or nil if it tries to escape the root.
function Static.clean(urlPath: string): string?
	local decoded = string.gsub(urlPath, "%%(%x%x)", function(h)
		return string.char(tonumber(h, 16) :: number)
	end)
	local parts = {}
	for seg in string.gmatch(decoded, "[^/\\]+") do
		if seg == ".." or string.find(seg, "%z") then
			return nil
		elseif seg ~= "." then
			table.insert(parts, seg)
		end
	end
	return table.concat(parts, "/")
end

-- Resolves a relative path inside root to an existing file, trying index.html and .html.
function Static.resolve(root: string, rel: string): string?
	local base = if rel == "" then root else root .. "/" .. rel
	if fs.isFile(base) then
		return base
	end
	if fs.isDir(base) and fs.isFile(base .. "/index.html") then
		return base .. "/index.html"
	end
	if fs.isFile(base .. ".html") then
		return base .. ".html"
	end
	return nil
end

return Static
