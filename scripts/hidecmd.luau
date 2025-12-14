local process = zune.process
local mem = zune.mem
local fs = zune.fs

-- Code adapted from https://github.com/tr1ckydev/webview-bun/blob/main/scripts/hidecmd.ts

local PE_SIGNATURE = 0x00004550 -- "PE\0\0"
local IMAGE_SUBSYSTEM_WINDOWS_GUI = 2 -- Subsystem type for Windows GUI

function modifyExeSubsystem(filePath: string)
	local exeBuffer: buffer = fs.readFileSync(filePath, true) :: any

	-- Check for PE signature
	local dosHeader = mem.slice(exeBuffer, 0, 64)
	local peOffset = buffer.readu32(dosHeader, 60)
	local peHeader = mem.slice(exeBuffer, peOffset, peOffset + 4)

	if buffer.readu32(peHeader, 0) ~= PE_SIGNATURE then
		error("Not a valid PE file")
	end

	-- Locate the subsystem field in the PE header
	local subsystemOffset = peOffset + 0x5c -- Subsystem is at offset 0x5C from PE header
	local currentSubsystem = buffer.readu16(exeBuffer, subsystemOffset)

	print(`Current subsystem: {currentSubsystem}`)

	-- Modify the subsystem to Windows GUI
	buffer.writeu16(exeBuffer, subsystemOffset, IMAGE_SUBSYSTEM_WINDOWS_GUI)

	fs.writeFileSync(filePath, exeBuffer)
	print("Subsystem modified to Windows GUI.")
end

if #process.args < 2 then
	error("Executable path not received")
end

local success, err = pcall(modifyExeSubsystem, process.args[2])
if not success then
	error(`Error modifying EXE subsystem:\n{err}`)
end
