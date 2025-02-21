local runner = require("dotnet.runner")

local M = {}

M.setup = function(_)
    runner.setup()
end

M.test = function()
    local cmd = vim.fn.input "Command: "
    runner.run(cmd)
end

return M
