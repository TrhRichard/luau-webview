local process = zune.process
local serde = zune.serde

local webview = require("../src")

local exampleHtmlPath = zune.fs.realPath("examples/example.html")

local window = webview.create(false)
process.onSignal("INT", function()
	webview.terminate(window)
	process.exit(0)
end)

webview.setTitle(window, "Example Webview")

webview.bind(window, "getWebviewVersion", function(id: string, req, arg: FFIPointer)
	local versionInfo = webview.version()
	webview.return_(window, id, 0, serde.json.encode(versionInfo.version))
end)

webview.navigate(window, exampleHtmlPath)

webview.run(window)
