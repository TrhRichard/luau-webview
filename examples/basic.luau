local process = zune.process

local webview = require("../src")

local window = webview.new(false)
process.onSignal("INT", function()
	window:terminate(window)
	window:destroy()
	process.exit(0)
end)

window:setTitle("Basic Example")
window:setSize(vector.create(480, 320), webview.enum.hint.NONE)
window:setHtml("Thanks for using webview!")

window:run()
