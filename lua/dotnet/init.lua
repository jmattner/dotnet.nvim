local drawer = require("dotnet.drawer")
local buffer = require("dotnet.terminal-buffer")

local M = {}

local BUILD_DRAWER_NAME = "dotnet-build"
local WindowConfigs = {
    BOTTOM = "bottom",
    SIDE = "side",
}

---@type table<string, string>
local artifact_paths = {}

---@param output string
local parse_build_artifact = function(output)
    if not output then return end
    for line in output:gmatch("[^\r\n]+") do
        local name, path = line:match('%s*(.-)%s+->%s+(.+%.dll)')
        if not name or not path then
            name, path = line:match('%s*(.-)%s+→%s+(.+%.dll)')
        end
        if name and path then
            artifact_paths[name] = path
        end
    end
end

---@param drawer_name string
---@return fun(data: string)
local get_append_handler = function(drawer_name)
    return function(data)
        drawer.with_drawer(drawer_name, function(bufnr)
            buffer.append(bufnr, data)
        end)
    end
end

---@param cmd string
---@param stdout_handlers fun(data: string)[]
---@param stderr_handlers fun(data: string)[]
local run = function(cmd, stdout_handlers, stderr_handlers)
    local handle_stdout = function(_, data)
        for _, handler in ipairs(stdout_handlers) do
            handler(data)
        end
    end

    local handle_stderr = function(_, data)
        for _, handler in ipairs(stderr_handlers) do
            handler(data)
        end
    end

    handle_stdout(nil, "❯ " .. cmd)
    vim.system({ "powershell", "-Command", cmd }, {
        text = true,
        stdout = handle_stdout,
        stderr = handle_stderr
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

M.build = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM)
    local append_handler = get_append_handler(BUILD_DRAWER_NAME)
    run("dotnet build", { parse_build_artifact, append_handler }, { append_handler })
end

M.clean = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM)
    local append_handler = get_append_handler(BUILD_DRAWER_NAME)
    run("dotnet clean", { append_handler }, { append_handler })
end

M.restore = function()
    drawer.show(BUILD_DRAWER_NAME, WindowConfigs.BOTTOM)
    local append_handler = get_append_handler(BUILD_DRAWER_NAME)
    run("dotnet restore", { append_handler }, { append_handler })
end

M.toggle = function()
    drawer.toggle_visibility(BUILD_DRAWER_NAME)
end

---@return table<string, string> a dictionary of project names to artifact paths generated in this session
M.getArtifactPaths = function()
    return vim.deepcopy(artifact_paths)
end

return M
