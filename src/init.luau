local c = require("@self/c")
local serde = zune.serde
local ffi = zune.ffi
local mem = zune.mem

local WEBVIEW_T = ffi.types.pointer
local cstring = ffi.types.pointer

local webview = {
	prototype = {},
}
webview.meta = { __index = webview.prototype }

type WebviewWindowInstance = FFIPointer
export type WebviewError = number
export type WebviewWindow = setmetatable<{
	title: string,
	size: vector,
	handle: WebviewWindowInstance,
}, typeof(webview.meta)>
export type WebviewVersionInfo = {
	version: {
		major: number,
		minor: number,
		patch: number,
	},
	versionNumber: string,
	preRelease: string,
	buildMetadata: string,
}
type cstring = FFIPointer | string | buffer

--- Destroys a webview instance and closes the native window.
function webview.prototype.destroy(self: WebviewWindow): WebviewError
	return c.lib.webview_destroy(self.handle)
end

--- Runs the main loop until it's terminated.
function webview.prototype.run(self: WebviewWindow): WebviewError
	return c.lib.webview_run(self.handle)
end

--- Stops the main loop. It is safe to call this function from another background thread.
function webview.prototype.terminate(self: WebviewWindow): WebviewError
	return c.lib.webview_terminate(self.handle)
end

--- Schedules a function to be invoked on the thread with the run/event loop.
---
--- Since library functions generally do not have thread safety guarantees,
--- this function can be used to schedule code to execute on the main/GUI
--- thread and thereby make that execution safe in multi-threaded applications.
function webview.prototype.dispatch(self: WebviewWindow, fn: () -> ()): WebviewError
	local cFunc = ffi.closure({
		returns = ffi.types.void,
		args = { WEBVIEW_T, ffi.types.pointer },
	}, function(_: WebviewWindowInstance, _)
		fn()
	end)

	return c.lib.webview_dispatch(self.handle, cFunc, nil)
end

--- Returns the native handle of the window associated with the webview instance.
--- The handle can be a `GtkWindow` pointer (GTK), `NSWindow` pointer (Cocoa)
--- or `HWND` (Win32).
function webview.prototype.getWindow(self: WebviewWindow): FFIPointer
	return c.lib.webview_get_window(self.handle)
end

--- Get a native handle of choice.
function webview.prototype.getNativeHandle(self: WebviewWindow, kind: number): FFIPointer
	return c.lib.webview_get_native_handle(self.handle, kind)
end

--- Updates the title of the native window.
function webview.prototype.setTitle(self: WebviewWindow, title: cstring): WebviewError
	self.title = title :: string
	return c.lib.webview_set_title(self.handle, title)
end

--- Updates the size of the native window.
function webview.prototype.setSize(self: WebviewWindow, size: vector, hint: number): WebviewError
	self.size = size
	return c.lib.webview_set_size(self.handle, size.x, size.y, hint)
end

--- Navigates webview to the given URL. URL may be a properly encoded data URI.
function webview.prototype.navigate(self: WebviewWindow, url: cstring): WebviewError
	return c.lib.webview_navigate(self.handle, url)
end

--- Load HTML content into the webview.
function webview.prototype.setHtml(self: WebviewWindow, html: cstring): WebviewError
	return c.lib.webview_set_html(self.handle, html)
end

--- Injects JavaScript code to be executed immediately upon loading a page.
--- The code will be executed before `window.onload`.
function webview.prototype.init(self: WebviewWindow, js: cstring): WebviewError
	return c.lib.webview_init(self.handle, js)
end

--- Evaluates arbitrary JavaScript code.
---
--- Use bindings if you need to communicate the result of the evaluation.
function webview.prototype.eval(self: WebviewWindow, js: cstring): WebviewError
	return c.lib.webview_eval(self.handle, js)
end

type BindFn = (...any) -> any?
--- Binds a function pointer to a new global JavaScript function.
---
--- Internally, JS glue code is injected to create the JS function by the
--- given name. The callback function is passed a request identifier,
--- a request string and a user-provided argument. The request string is
--- a JSON array of the arguments passed to the JS function.
function webview.prototype.bind(self: WebviewWindow, name: cstring, fn: BindFn): WebviewError
	local cFunc = ffi.closure({
		returns = ffi.types.void,
		args = { WEBVIEW_T, cstring, cstring, ffi.types.pointer },
	}, function(id: FFIPointer, req: FFIPointer, arg: FFIPointer)
		local success, returnOrErr =
			pcall(fn, table.unpack(serde.json.decode(buffer.tostring(req:span()), { preserve_null = true })))

		c.lib.webview_return(self.handle, id, if success then 0 else 1, serde.json.encode(returnOrErr))
	end)
	return c.lib.webview_bind(self.handle, name, cFunc, nil)
end

--- Removes a binding created with webview.bind().
function webview.prototype.unbind(self: WebviewWindow, name: cstring): WebviewError
	return c.lib.webview_unbind(self.handle, name)
end

--- Get the webview library's version information.
local function webviewVersion(): WebviewVersionInfo
	local versionInfoPtr: FFIPointer = c.lib.webview_version()
	versionInfoPtr:size(c.structs.webview_version_info_t:size())

	local versionBfr = mem.slice(
		versionInfoPtr,
		c.structs.webview_version_info_t:offset("version"),
		c.structs.webview_version_t:size()
	)

	local emptyChar = buffer.create(4)

	return {
		version = {
			major = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("major")),
			minor = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("minor")),
			patch = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("patch")),
		},
		versionNumber = buffer.tostring(
			mem.trim(
				mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("version_number"), 32),
				emptyChar
			)
		),
		preRelease = buffer.tostring(
			mem.trim(mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("pre_release"), 48), emptyChar)
		),
		buildMetadata = buffer.tostring(
			mem.trim(
				mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("build_metadata"), 48),
				emptyChar
			)
		),
	}
end

--- Creates a new webview instance.
---
--- Size defaults to (800, 600) if not set.
local function createWebview(debug: boolean?, size: vector?, window: FFIPointer?): WebviewWindow
	local instanceHandle: WebviewWindowInstance = c.lib.webview_create(if debug then 1 else 0, window)
	local size = size or vector.create(800, 600)

	c.lib.webview_set_size(instanceHandle, size.x, size.y, c.enum.hint.NONE)

	return setmetatable({ handle = instanceHandle, title = "", size = size }, webview.meta)
end

return {
	c = c,
	enum = c.enum,
	version = webviewVersion,
	new = createWebview,
}
