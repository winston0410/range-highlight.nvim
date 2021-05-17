local v = vim.api
local ns = v.nvim_create_namespace('rang-highlight')
local opts, cache = {highlight = "Visual"}, {}

local function cleanup()
    v.nvim_buf_clear_namespace(0, ns, 0, -1)
    cache = {}
end

local function shorthand_range(text)
    local match = string.match(text, "^,(%d+)")
    if match == nil then return false end
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    return true, current_line - 1, tonumber(match)
end

local function relative_range(text)
	local arr, index = {}, 1

	if #arr == 0  then return false end
end

local function absolute_range(text)
    local arr = {}
    local index = 1
    for value in string.gmatch(text, "%d+") do
        arr[index] = tonumber(value)
        index = index + 1
        if index > 2 then break end
    end

    if #arr == 0 then return false end

    if arr[2] == nil then arr[2] = arr[1] end

    return true, arr[1] - 1, arr[2]
end

local function add_highlight()
    local text = vim.fn.getcmdline()
    local start_line, end_line, has_handled
    local handlers = {shorthand_range, relative_range, absolute_range}

    for _, callback in ipairs(handlers) do
        has_handled, start_line, end_line = callback(text)
        if has_handled then break end
    end

	if not has_handled then return end

    -- print('check result', text, start_line, end_line)
    if start_line < 1 or end_line < 1 then return end
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
