local M = {}

local ansi_to_hl = {
    ["30"] = "Black",
    ["31"] = "Red",
    ["32"] = "Green",
    ["33"] = "Yellow",
    ["34"] = "Blue",
    ["35"] = "Magenta",
    ["36"] = "Cyan",
    ["37"] = "White",
    ["90"] = "BrightBlack",
    ["91"] = "BrightRed",
    ["92"] = "BrightGreen",
    ["93"] = "BrightYellow",
    ["94"] = "BrightBlue",
    ["95"] = "BrightMagenta",
    ["96"] = "BrightCyan",
    ["97"] = "BrightWhite",
}

---@type integer?
local _bufnr = nil

---@return number
local get_run_buffer = function()
    if _bufnr == nil or not vim.api.nvim_buf_is_valid(_bufnr) then
        print("creating buffer")
        _bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(_bufnr, "fileencoding", "utf-8")
    end
    print("using buffer " .. _bufnr)
    return _bufnr
end

---@param line string
---@param bufnr number
local append_ansi_line = function(line, bufnr)
    local col = 0
    local plain_text = ""
    local last_color = nil
    local hl_start = nil
    local chunks = {}
    local has_ansi = false

    local new_line = line .. "\27[0m"
    for text, esc_code in new_line:gmatch("([^\27]*)\27%[([%d;]*)m") do
        has_ansi = true

        if text ~= "" then
            table.insert(chunks, { text = text, hl = last_color })
            plain_text = plain_text .. text
            col = col + vim.fn.strdisplaywidth(text)
        end

        local color = esc_code:match("3%d") or esc_code:match("9%d")
        if color and ansi_to_hl[color] then
            last_color = ansi_to_hl[color]
        end
    end

    if not has_ansi then
        plain_text = line
    end

    local row = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { plain_text })

    for _, chunk in ipairs(chunks) do
        if chunk.hl then
            vim.api.nvim_buf_add_highlight(bufnr, 0, "Ansi" .. chunk.hl, row, hl_start or 0, col)
        end
    end
end

---@param cmd string
---@param bufnr number
local run_in_buffer = function(cmd, bufnr)
    --- @param data string
    local append_data = function(_, data)
        if data then
            -- split on newlines and clean up trailing whitespace
            local lines = vim.tbl_map(function(line)
                return line:gsub("%s+$", "")
            end, vim.split(data, "\n", { plain = true, trimempty = true }))

            vim.schedule(function()
                -- vim.bo[bufnr].ro = false
                for _, line in ipairs(lines) do
                    append_ansi_line(line, bufnr)
                end
                -- vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
                -- vim.bo[bufnr].modified = false
                -- vim.bo[bufnr].ro = true
            end)
        end
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "=== running " .. ": " .. cmd })
    vim.system({ "powershell", "-Command", cmd }, {
        text = true,
        stdout = append_data,
        stderr = append_data
    })
end

---@param bufnr number
local show_buffer = function(bufnr)
    local win_id = vim.fn.bufwinnr(bufnr)
    if win_id ~= -1 then
        return
    end

    local current_win = vim.api.nvim_get_current_win()

    vim.cmd("botright vsplit")
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_set_current_win(current_win)
end

M.setup = function()
    for _, name in pairs(ansi_to_hl) do
        vim.cmd(string.format("highlight Ansi%s guifg=%s", name, name:lower()))
    end
end

---@param cmd string
M.run = function(cmd)
    local bufnr = get_run_buffer()
    run_in_buffer(cmd, bufnr)
    show_buffer(bufnr)
end


return M
