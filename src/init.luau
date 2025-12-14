local c = require("@self/c")
local serde = zune.serde
local ffi = zune.ffi
local mem = zune.mem

local WEBVIEW_T = ffi.types.pointer
local cstring = ffi.types.pointer

local webview = {
	c = c,
}

export type WebviewWindowInstance = FFIPointer
export type WebviewError = number
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
type UserArgument = FFIPointer | string | buffer

--- Creates a new webview instance.
function webview.create(debug: boolean, window: FFIPointer?): WebviewWindowInstance
	return c.lib.webview_create(if debug then 1 else 0, window)
end

--- Destroys a webview instance and closes the native window.
function webview.destroy(window: WebviewWindowInstance): WebviewError
	return c.lib.webview_destroy(window)
end

--- Runs the main loop until it's terminated.
function webview.run(window: WebviewWindowInstance): WebviewError
	return c.lib.webview_run(window)
end

--- Stops the main loop. It is safe to call this function from another background thread.
function webview.terminate(window: WebviewWindowInstance): WebviewError
	return c.lib.webview_terminate(window)
end

type DispatchFn = (w: WebviewWindowInstance, arg: FFIPointer) -> ()

--- Schedules a function to be invoked on the thread with the run/event loop.
---
--- Since library functions generally do not have thread safety guarantees,
--- this function can be used to schedule code to execute on the main/GUI
--- thread and thereby make that execution safe in multi-threaded applications.
function webview.dispatch(window: WebviewWindowInstance, fn: DispatchFn, arg: UserArgument?): WebviewError
	local cFunc = ffi.closure({
		returns = ffi.types.void,
		args = { WEBVIEW_T, ffi.types.pointer },
	}, fn)

	return c.lib.webview_dispatch(window, cFunc, arg)
end

--- Returns the native handle of the window associated with the webview instance.
--- The handle can be a `GtkWindow` pointer (GTK), `NSWindow` pointer (Cocoa)
--- or `HWND` (Win32).
function webview.getWindow(window: WebviewWindowInstance): FFIPointer
	return c.lib.webview_get_window(window)
end

--- Get a native handle of choice.
function webview.getNativeHandle(window: WebviewWindowInstance, kind: number): FFIPointer
	return c.lib.webview_get_native_handle(window, kind)
end

--- Updates the title of the native window.
function webview.setTitle(window: WebviewWindowInstance, title: string): WebviewError
	return c.lib.webview_set_title(window, title)
end

--- Updates the size of the native window.
function webview.setSize(window: WebviewWindowInstance, width: number, height: number, hint: number): WebviewError
	return c.lib.webview_set_size(window, width, height, hint)
end

--- Navigates webview to the given URL. URL may be a properly encoded data URI.
function webview.navigate(window: WebviewWindowInstance, url: string): WebviewError
	return c.lib.webview_navigate(window, url)
end

--- Load HTML content into the webview.
function webview.setHtml(window: WebviewWindowInstance, html: string): WebviewError
	return c.lib.webview_set_html(window, html)
end

--- Injects JavaScript code to be executed immediately upon loading a page.
--- The code will be executed before `window.onload`.
function webview.init(window: WebviewWindowInstance, js: string): WebviewError
	return c.lib.webview_init(window, js)
end

--- Evaluates arbitrary JavaScript code.
---
--- Use bindings if you need to communicate the result of the evaluation.
function webview.eval(window: WebviewWindowInstance, js: string): WebviewError
	return c.lib.webview_eval(window, js)
end

type BindFn = (id: string, req: RequestData, arg: FFIPointer) -> ()
type RequestData = { any }
--- Binds a function pointer to a new global JavaScript function.
---
--- Internally, JS glue code is injected to create the JS function by the
--- given name. The callback function is passed a request identifier,
--- a request string and a user-provided argument. The request string is
--- a JSON array of the arguments passed to the JS function.
function webview.bind(window: WebviewWindowInstance, name: string, fn: BindFn, arg: UserArgument?): WebviewError
	local cFunc = ffi.closure({
		returns = ffi.types.void,
		args = { WEBVIEW_T, cstring, cstring, ffi.types.pointer },
	}, function(id: FFIPointer, req: FFIPointer, arg: FFIPointer)
		fn(buffer.tostring(id:span()), serde.json.decode(buffer.tostring(req:span()), { preserve_null = true }), arg)
	end)
	return c.lib.webview_bind(window, name, cFunc, arg)
end

--- Removes a binding created with webview.bind().
function webview.unbind(window: WebviewWindowInstance, name: string): WebviewError
	return c.lib.webview_unbind(window, name)
end

--- Responds to a binding call from the JS side.
---
--- This function is safe to call from another thread.
function webview.return_(window: WebviewWindowInstance, id: string, status: number, result: string): WebviewError
	return c.lib.webview_return(window, id, status, result)
end

--- Get the library's version information.
function webview.version(): WebviewVersionInfo
	local versionInfoPtr: FFIPointer = c.lib.webview_version()
	versionInfoPtr:size(c.structs.webview_version_info_t:size())

	local versionBfr = mem.slice(
		versionInfoPtr,
		c.structs.webview_version_info_t:offset("version"),
		c.structs.webview_version_t:size()
	)

	return {
		version = {
			major = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("major")),
			minor = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("minor")),
			patch = buffer.readu32(versionBfr, c.structs.webview_version_t:offset("patch")),
		},
		versionNumber = buffer.tostring(
			mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("version_number"), 32)
		),
		preRelease = buffer.tostring(
			mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("pre_release"), 48)
		),
		buildMetadata = buffer.tostring(
			mem.slice(versionInfoPtr, c.structs.webview_version_info_t:offset("build_metadata"), 48)
		),
	}
end

return webview
