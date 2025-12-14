local process = zune.process
local fs = zune.fs

local webview = require("../src")

local window = webview.new(false)
process.onSignal("INT", function()
	window:terminate()
	window:destroy()
	process.exit(0)
end)

window:setTitle("Webview HTML File Example")

window:bind("getWebviewVersion", function()
	local webviewVersion = webview.version()
	return webviewVersion :: any
end)

window:navigate(fs.realPath("examples/example.html"))

window:run()
