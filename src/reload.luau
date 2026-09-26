-- Live reload: polls file modification times; browsers poll /__deployz/version.
local fs = require("@lune/fs")
local task = require("@lune/task")

local Reload = { version = 0 }

local SCRIPT = [[
<script>(()=>{let v=null;setInterval(async()=>{try{const r=await fetch("/__deployz/version");const n=await r.text();if(v!==null&&n!==v)location.reload();v=n}catch{}},1000)})()</script>
]]

local function snapshot(dir: string, acc: { [string]: number })
	for _, name in fs.readDir(dir) do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			snapshot(p, acc)
		else
			local ok, meta = pcall(fs.metadata, p)
			if ok and meta.modifiedAt then
				acc[p] = meta.modifiedAt.unixTimestampMillis
			end
		end
	end
end

local function signature(dirs: { string }): string
	local acc = {}
	for _, d in dirs do
		if fs.isDir(d) then
			snapshot(d, acc)
		end
	end
	local keys = {}
	for k in acc do
		table.insert(keys, k)
	end
	table.sort(keys)
	local out = {}
	for _, k in keys do
		table.insert(out, k .. acc[k])
	end
	return table.concat(out, "|")
end

function Reload.start(dirs: { string })
	task.spawn(function()
		local last = signature(dirs)
		while true do
			task.wait(1)
			local now = signature(dirs)
			if now ~= last then
				last = now
				Reload.version += 1
			end
		end
	end)
end

function Reload.inject(html: string): string
	local injected, n = string.gsub(html, "</body>", SCRIPT .. "</body>", 1)
	return if n > 0 then injected else html .. SCRIPT
end

return Reload
