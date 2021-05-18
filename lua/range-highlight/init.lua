local v = vim.api
local ns = v.nvim_create_namespace('rang-highlight')
local opts, cache = {highlight = "Visual"}, {}

local function cleanup()
    v.nvim_buf_clear_namespace(0, ns, 0, -1)
    cache = {}
end

local function get_range(text)
    local start_line, end_line = 0, 0
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    local start_index, end_index, start_special, start_anchor,
          start_operator, start_increment, separator, end_special,
          end_anchor, end_operator, end_increment =
        string.find(text,
                    "^([%%%$]?)(%d*)([+-]?)(%d*)(,?)([%%%$]?)(%d*)([+-]?)(%d*)")

    if start_special == '%' then
        return true, 0, line_count
    elseif start_special == '$' then
        start_line = line_count
    else
        start_line = current_line
    end

    if start_index == 0 or end_index == 0 then return false end

    if start_anchor ~= "" then start_line = tonumber(start_anchor) end

    if start_increment ~= "" then
        start_line = start_line + tonumber(start_operator .. start_increment)
    end

    start_line = start_line - 1

    if separator == "" then return true, start_line, start_line + 1 end

    if end_special == "%" then
        return true, 0, line_count
    elseif end_special == "$" then
        end_line = line_count
    else
        end_line = current_line
    end

    if end_anchor ~= "" then end_line = tonumber(end_anchor) end

    if end_increment ~= "" then
        end_line = end_line + tonumber(end_operator .. end_increment)
    end

    return true, start_line, end_line

end

local function add_highlight()
    local text = vim.fn.getcmdline()

    local has_number, start_line, end_line = get_range(text)

    if not has_number then return end

    -- print('check values', text, start_line, end_line)

    if end_line < start_line then
        start_line, end_line = end_line, start_line
        start_line = start_line - 1
        end_line = end_line + 1
    end
    -- -- if cache[1] == start_line and cache[2] == end_line then return end
    if cache[1] and cache[2] then
        if cache[1] ~= start_line or cache[2] ~= end_line then
            v.nvim_buf_clear_namespace(0, ns, cache[1], cache[2])
        end
    end
    cache[1], cache[2] = start_line, end_line
    vim.highlight.range(0, ns, opts.highlight, {start_line, 0}, {end_line, 0},
                        'V', false)
    vim.cmd('redraw')
end

local function setup(user_opts)
    opts = vim.tbl_extend('force', opts, user_opts or {})
    v.nvim_exec([[ 
		augroup Ranger
		autocmd!
		au CmdlineChanged * lua require('range-highlight').add_highlight()
		au CmdlineLeave * lua require('range-highlight').cleanup()
		augroup END
		]], true)
end

return {setup = setup, cleanup = cleanup, add_highlight = add_highlight}
