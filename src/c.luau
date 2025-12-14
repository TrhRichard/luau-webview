local ffi = zune.ffi

local BIN_PATH = `bin/{ffi.prefix}webview.{ffi.suffix}`

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
		error = {
			MISSING_DEPENDENCY = -5,
			CANCELED = -4,
			INVALID_STATE = -3,
			INVALID_ARGUMENT = -2,
			UNSPECIFIED = -1,
			OK = 0,
			DUPLICATE = 1,
			NOT_FOUND = 2,
		},
		hint = {
			NONE = 0,
			MIN = 1,
			MAX = 2,
			FIXED = 3,
		},
		native_handle_kind = {
			UI_WINDOW = 0,
			UI_WIDGET = 1,
			BROWSER_CONTROLLER = 2,
		},
	},
	structs = structs,
}

return c
