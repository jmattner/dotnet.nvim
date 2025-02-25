local M = {}

---@alias SplitDirection "horizontal" | "vertical"

---@class WindowConfig
---@field name string
---@field direction SplitDirection
---@field size number?

---@class Drawer
---@field name string
---@field buffer number
---@field default_config string?
---@field window_configs table<string, WindowConfig>

---@type table<string, Drawer>
local drawers = {}

---@param buffer number
---@return number? win_id Returns window ID if found, otherwise nil
local function find_window_by_buffer(buffer)
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win_id) == buffer then
            return win_id
        end
    end
    return nil
end

M.SplitDirections = {
    HORIZONTAL = "horizontal",
    VERTICAL = "vertical",
}

---@param name string
---@param bufnr number
---@param window_configs table<string, WindowConfig>
---@param default_config string?
M.create = function(name, bufnr, window_configs, default_config)
    if drawers[name] then
        local choice = vim.fn.input("Drawer '" .. name ..
            "' already exists! Overwrite? (y/n): ")
        if choice:lower() ~= "y" then
            vim.notify("Operation canceled. Drawer '" .. name ..
                "' was not modified.", vim.log.levels.INFO)
            return
        end
    end
    drawers[name] = {
        name = name,
        buffer = bufnr,
        default_config = default_config,
        window_configs = window_configs,
    }
end

---@param drawer_name string
---@param win_config_name string?
---@param focus boolean? should focus be pulled to the specified drawer?
M.show = function(drawer_name, win_config_name, focus)
    local drawer = drawers[drawer_name]
    if not drawer then
        vim.notify("Drawer '" .. drawer_name .. "' not found!", vim.log.levels.ERROR)
        return
    end

    local config_name = win_config_name or drawer.default_config
    local config = drawer.window_configs[config_name]
    if not config then
        vim.notify(
            "Window config '" .. tostring(config_name) ..
            "' not found in drawer '" .. drawer_name .. "'!",
            vim.log.levels.ERROR
        )
        return
    end

    local existing_win = find_window_by_buffer(drawer.buffer)
    if existing_win then
        if focus then vim.api.nvim_set_current_win(existing_win) end

        if config.direction == M.SplitDirections.VERTICAL then
            vim.cmd("wincmd L")
            if config.size ~= nil then vim.cmd("vertical resize " .. config.size) end
        elseif config.direction == M.SplitDirections.HORIZONTAL then
            vim.cmd("wincmd J")
            if config.size ~= nil then vim.cmd("resize " .. config.size) end
        end

        return
    end

    if config.direction == M.SplitDirections.VERTICAL then
        vim.cmd("botright vsplit")
        if config.size ~= nil then vim.cmd("vertical resize " .. config.size) end
    elseif config.direction == M.SplitDirections.HORIZONTAL then
        vim.cmd("botright split")
        if config.size ~= nil then vim.cmd("resize " .. config.size) end
    end

    vim.api.nvim_win_set_buf(0, drawer.buffer)
    if not focus then vim.cmd("wincmd p") end
end

---@param drawer_name string
M.hide = function(drawer_name)
    local drawer = drawers[drawer_name]
    if not drawer then
        vim.notify("Drawer '" .. drawer_name .. "' not found!", vim.log.levels.ERROR)
        return
    end

    local win_id = find_window_by_buffer(drawer.buffer)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    else
        vim.notify("Drawer '" .. drawer_name .. "' is not currently open.", vim.log.levels.WARN)
    end
end

---@param drawer_name string
M.toggle_visibility = function(drawer_name)
    local drawer = drawers[drawer_name]
    if not drawer then
        vim.notify("Drawer '" .. drawer_name .. "' not found!", vim.log.levels.ERROR)
        return
    end

    local win_id = find_window_by_buffer(drawer.buffer)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        M.hide(drawer_name)
    else
        M.show(drawer_name)
    end
end

---@param drawer_name string
---@param action fun(bufnr: number)
M.with_drawer = function(drawer_name, action)
    local drawer = drawers[drawer_name]
    if not drawer then
        vim.notify("Drawer '" .. drawer_name .. "' not found!", vim.log.levels.ERROR)
        return
    end

    action(drawer.buffer)
end

return M
