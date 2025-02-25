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

---@param bufnr number
---@param line string
local append_line = function(bufnr, line)
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

---@return number
M.create = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, "fileencoding", "utf-8")
    return bufnr
end

---@param bufnr number
---@param data string
M.append = function(bufnr, data)
    if data then
        -- split on newlines and clean up trailing whitespace
        local lines = vim.tbl_map(function(line)
            return line:gsub("%s+$", "")
        end, vim.split(data, "\n", { plain = true, trimempty = true }))

        vim.schedule(function()
            for _, line in ipairs(lines) do
                append_line(bufnr, line)
            end
        end)
    end
end

M.setup = function()
    for _, name in pairs(ansi_to_hl) do
        vim.cmd(string.format("highlight Ansi%s guifg=%s", name, name:lower()))
    end
end

return M
