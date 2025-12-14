local ffi = zune.ffi

local BIN_PATH = `bin/webview.{ffi.suffix}`

local WEBVIEW_ERROR_T = ffi.types.i32
local WEBVIEW_T = ffi.types.pointer
local cstring = ffi.types.pointer

local structs = {}
structs.webview_version_t = ffi.struct({
	{ major = ffi.types.u32 },
	{ minor = ffi.types.u32 },
	{ patch = ffi.types.u32 },
})

structs.webview_version_info_t = ffi.struct({
	{ version = structs.webview_version_t },
	{ version_number = ffi.types.u8:array(32) },
	{ pre_release = ffi.types.u8:array(48) },
	{ build_metadata = ffi.types.u8:array(48) },
})

local lib = ffi.dlopen(BIN_PATH, {
	webview_create = {
		returns = WEBVIEW_T,
		args = { ffi.types.i32, ffi.types.pointer },
	},
	webview_destroy = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T },
	},
	webview_run = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T },
	},
	webview_terminate = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T },
	},
	webview_dispatch = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, ffi.types.pointer, ffi.types.pointer },
	},
	webview_get_window = {
		returns = ffi.types.pointer,
		args = { WEBVIEW_T },
	},
	webview_get_native_handle = {
		returns = ffi.types.pointer,
		args = { WEBVIEW_T, ffi.types.i32 },
	},
	webview_set_title = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_set_size = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	webview_navigate = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_set_html = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_init = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_eval = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_bind = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring, ffi.types.pointer, ffi.types.pointer },
	},
	webview_unbind = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring },
	},
	webview_return = {
		returns = WEBVIEW_ERROR_T,
		args = { WEBVIEW_T, cstring, ffi.types.i32, cstring },
	},
	webview_version = {
		returns = ffi.types.pointer,
		args = {},
	},
})

local c = {
	lib = lib,
	enum = {
		webview_error_t = {
			WEBVIEW_ERROR_MISSING_DEPENDENCY = -5,
			WEBVIEW_ERROR_CANCELED = -4,
			WEBVIEW_ERROR_INVALID_STATE = -3,
			WEBVIEW_ERROR_INVALID_ARGUMENT = -2,
			WEBVIEW_ERROR_UNSPECIFIED = -1,
			WEBVIEW_ERROR_OK = 0,
			WEBVIEW_ERROR_DUPLICATE = 1,
			WEBVIEW_ERROR_NOT_FOUND = 2,
		},
		webview_hint_t = {
			WEBVIEW_HINT_NONE = 0,
			WEBVIEW_HINT_MIN = 1,
			WEBVIEW_HINT_MAX = 2,
			WEBVIEW_HINT_FIXED = 3,
		},
		webview_native_handle_kind_t = {
			WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW = 0,
			WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET = 1,
			WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER = 2,
		},
	},
	structs = structs,
}

return c
