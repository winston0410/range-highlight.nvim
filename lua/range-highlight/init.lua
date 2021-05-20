local v = vim.api
local ns = v.nvim_create_namespace('rang-highlight')
local opts, cache = {highlight = "Visual"}, {}
local get_total_increment =
    require('range-highlight.helper').get_total_increment

local function cleanup()
    v.nvim_buf_clear_namespace(0, ns, 0, -1)
    cache = {}
end

local function get_range(text)
	-- print('check count', vim.v.count)
    local start_line, end_line, start_text = 0, 0, text
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    local start_index, _, start_special, start_mark, start_anchor, end_special,
          end_mark, end_anchor = string.find(text,
                                             "^([%%%$']?)(%l?)(%d*)[;,]?([%%%$']?)(%l?)(%d*)")

    if start_special == '%' then
        return true, 0, line_count
    elseif start_special == '$' then
        start_line = line_count
    elseif start_special == "'" then
        if start_mark ~= "" then
            -- local mark_line = vim.api.nvim_buf_get_mark(0, start_mark)[1]
            -- if mark_line ~= 0 then
            --     start_line = mark_line
            -- else
            --     return false
            -- end
        else
            start_line = current_line
        end
    else
        start_line = current_line
    end

    if start_index == 0 then return false end

    if start_anchor ~= "" then start_line = tonumber(start_anchor) end

    local start_comma_index = string.find(text, '[;,]')

    if start_comma_index ~= nil then
        start_text = string.sub(text, 1, start_comma_index)
    end

    start_line = start_line + get_total_increment(start_text)

    start_line = start_line - 1

    if start_comma_index == nil then return true, start_line, start_line + 1 end

    if end_special == "%" then
        return true, 0, line_count
    elseif end_special == "$" then
        end_line = line_count
    elseif end_special == "'" then
        if end_mark ~= "" then
            local mark_line = vim.api.nvim_buf_get_mark(0, end_mark)[1]
            if mark_line ~= 0 then
                end_line = mark_line
            else
                return false
            end
        else
            end_line = current_line
        end
    else
        end_line = current_line
    end

    if end_anchor ~= "" then end_line = tonumber(end_anchor) end

    local end_text = string.sub(text, start_comma_index, -1)

    end_line = end_line + get_total_increment(end_text)

    return true, start_line, end_line

end

local function add_highlight()
    local text = vim.fn.getcmdline()

	if vim.fn.getcmdtype() ~= ':' then
		return
	end

    local has_number, start_line, end_line = get_range(text)

    -- print('check has_number value', has_number)

    if not has_number then return end

    -- print('check values', text, start_line, end_line)
	if start_line < 0 or end_line < 0 then return end

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
