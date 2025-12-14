local process = zune.process

local webview = require("../src")

local window = webview.create(false)
process.onSignal("INT", function()
	webview.terminate(window)
	process.exit(0)
end)

webview.setTitle(window, "Basic Example")
webview.setSize(window, 480, 320, webview.c.enum.hint.NONE)
webview.setHtml(window, "Thanks for using webview!")

webview.run(window)
