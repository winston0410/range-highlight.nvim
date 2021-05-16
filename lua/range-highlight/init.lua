local v = vim.api
local ns = v.nvim_create_namespace('rang-highlight')
local opts, cache = {highlight = "Visual"}, {}

local function cleanup()
    v.nvim_buf_clear_namespace(0, ns, 0, -1)
    cache = {}
end

local function add_highlight()
    local text = vim.fn.getcmdline()
    local index = 1
    local start_line, end_line = nil, nil
    local arr = {}
    for value in string.gmatch(text, "%d+") do
        arr[index] = value
        index = index + 1
        if index > 2 then break end
    end

	if #arr == 0 then return end

    start_line, end_line = tonumber(arr[1]) - 1, tonumber(arr[2])

    if end_line == nil then end_line = start_line + 1 end
    if start_line < 1 or end_line < 1 then return end
    -- if cache[1] == start_line and cache[2] == end_line then return end
    if cache[1] and cache[2] then
        if cache[1] ~= start_line or cache[2] ~= end_line then
            v.nvim_buf_clear_namespace(0, ns, cache[1], cache[2])
        end
    end
    if end_line < start_line then return end
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
