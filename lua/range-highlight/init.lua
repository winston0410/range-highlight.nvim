local v = vim.api
local ns = v.nvim_create_namespace("range-highlight")
local opts, cache =
	{
		highlight = "Visual",
        -- Add command that takes range here
		highlight_with_out_range = {
			d = true,
			delete = true,
			m = true,
			move = true,
			y = true,
			yank = true,
			c = true,
			change = true,
			j = true,
			join = true,
			["<"] = true,
			[">"] = true,
			s = true,
			subsititue = true,
			sno = true,
			snomagic = true,
			sm = true,
			smagic = true,
			ret = true,
			retab = true,
			t = true,
			co = true,
			copy = true,
			ce = true,
			center = true,
			ri = true,
			right = true,
			le = true,
			left = true,
			sor = true,
			sort = true,
		},
	}, {}
local mark_to_number = require("range-highlight.helper").mark_to_number
local forward_search_to_number = require("range-highlight.helper").forward_search_to_number
local backward_search_to_number = require("range-highlight.helper").backward_search_to_number
local parse_cmd = require("cmd-parser").parse_cmd

local function cleanup()
	v.nvim_buf_clear_namespace(0, ns, 0, -1)
	cache = {}
end

local range_handlers = {
	number = tonumber,
	mark = mark_to_number,
	forward_search = forward_search_to_number,
	backward_search = backward_search_to_number,
}

local function get_range_number(cmd)
	local start_line, end_line = 0, 0
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local line_count = vim.api.nvim_buf_line_count(0)
	local result = parse_cmd(cmd)

	if not result.start_range then
		-- print('check command', cmd, opts.highlight_with_out_range[result.command])
		if not opts.highlight_with_out_range[result.command] then
			v.nvim_buf_clear_namespace(0, ns, 0, -1)
			vim.cmd("redraw")
			return -1, -1
		end
	end

	if result.start_range == "%" or result.end_range == "%" then
		return 0, line_count
	end

	if result.start_range then
		if result.start_range == "$" then
			start_line = line_count
		elseif result.start_range == "." then
			start_line = current_line
		else
			start_line = range_handlers[result.start_range_type](result.start_range)
		end
	else
		start_line = current_line
	end

	if result.start_increment then
		start_line = start_line + result.start_increment_number
	end

	if result.end_range then
		if result.end_range == "$" then
			end_line = line_count
		elseif result.end_range == "." then
			end_line = current_line
		else
			end_line = range_handlers[result.end_range_type](result.end_range)
		end
	else
		end_line = start_line
	end

	if result.end_increment then
		end_line = end_line + result.end_increment_number
	end

	-- print('check at the end or transformation', cmd, result.command, result.start_range, result.end_range)

	start_line = start_line - 1

	return start_line, end_line
end

local function add_highlight()
	local text = vim.fn.getcmdline()

	if vim.fn.getcmdtype() ~= ":" then
		return
	end

	local start_line, end_line = get_range_number(text)

	-- print('check values', text, start_line, end_line)
	if start_line < 0 or end_line < 0 then
		return
	end

	if end_line < start_line then
		start_line, end_line = end_line, start_line
		start_line = start_line - 1
		end_line = end_line + 1
	end

	if cache[1] == start_line and cache[2] == end_line then
		return
	end

	if cache[1] and cache[2] then
		if cache[1] ~= start_line or cache[2] ~= end_line then
			v.nvim_buf_clear_namespace(0, ns, cache[1], cache[2])
		end
	end
	cache[1], cache[2] = start_line, end_line
	vim.highlight.range(0, ns, opts.highlight, { start_line, 0 }, { end_line, 0 }, "V", false)
	vim.cmd("redraw")
end

local function setup(user_opts)
	opts = vim.tbl_extend("force", opts, user_opts or {})
	v.nvim_exec(
		[[ 
		augroup Ranger
		autocmd!
		au CmdlineChanged * lua require('range-highlight').add_highlight()
		au CmdlineLeave * lua require('range-highlight').cleanup()
		augroup END
		]],
		true
	)
end

return { setup = setup, cleanup = cleanup, add_highlight = add_highlight }
