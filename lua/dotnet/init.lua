local drawer = require("dotnet.drawer")
local buffer = require("dotnet.terminal-buffer")

local M = {}

local BUILD_DRAWER_NAME = "dotnet-build"
local WindowConfigs = {
    BOTTOM = "bottom",
    SIDE = "side",
}

---@param drawer_name string
---@param cmd string
local run = function(drawer_name, cmd)
    local append = function(_, data)
        drawer.with_drawer(drawer_name, function(bufnr)
            buffer.append(bufnr, data)
        end)
    end

    append(nil, "=== running: " .. cmd)
    vim.system({ "powershell", "-Command", cmd }, {
        text = true,
        stdout = append,
        stderr = append
    })
end

M.setup = function(_)
    buffer.setup()
    local bufnr = buffer.create()
    local configs = {}
    configs[WindowConfigs.BOTTOM] = {
        name = WindowConfigs.BOTTOM,
        direction = drawer.SplitDirections.HORIZONTAL,
        size = 15,
    }
    configs[WindowConfigs.SIDE] = {
        name = WindowConfigs.SIDE,
        direction = drawer.SplitDirections.VERTICAL,
    }
    drawer.create(BUILD_DRAWER_NAME, bufnr, configs)
end

---@return string the path to the produced artefact
M.build = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM) -- TODO - default value for focus?
    run(BUILD_DRAWER_NAME, "dotnet build")
    return "my/artefact/path"                            -- TODO - get this path from the build output
end

M.clean = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM)
    run(BUILD_DRAWER_NAME, "dotnet clean")
end

M.restore = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM)
    run(BUILD_DRAWER_NAME, "dotnet restore")
end

M.toggle = function()
    drawer.toggle_visibility(BUILD_DRAWER_NAME)
end

return M
