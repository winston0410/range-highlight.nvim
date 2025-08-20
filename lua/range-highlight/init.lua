local ns = "range-highlight"
local ns_id = vim.api.nvim_create_namespace(ns)
local M = {}

local function debounce(ms, fn)
	if ms == 0 then
		return fn
	end
	local timer = vim.loop.new_timer()

	return function(...)
		local argv = { ... }
		if timer == nil then
			return
		end
		timer:start(ms, 0, function()
			timer:stop()
			vim.schedule_wrap(fn)(unpack(argv))
		end)
	end
end

---@alias SetupOpts { highlight: { group: string, priority: integer, to_eol: boolean}, excluded: { cmd: string[]}, debounce: { wait: integer }}
---@type SetupOpts
local default_opts = {
	highlight = {
		group = "Visual",
		priority = 10,
		-- if you want to highlight empty line, set it to true
		to_eol = false,
	},
	-- the command here does not accept shorthand
	excluded = { cmd = {} },
	debounce = {
		-- how long to debounce, set to 0 to disable
		wait = 100,
	},
}

---@param cmdline string
---@return integer|nil, integer, integer|nil, integer
function M.get_linewise_range(cmdline)
	---@type integer|nil
	local selection_start_row = nil
	---@type integer
	local selection_start_col = 0

	---@type integer|nil
	local selection_end_row = nil
	---@type integer
	local selection_end_col = 0
	local DEFAULT_COMMAND_WITH_RANGE = "print"
	local ok, result = pcall(function()
		return vim.api.nvim_parse_cmd(cmdline, {})
	end)

	-- Example invalid commands that would end up here
	-- E481: No range allowed
	-- 1. 20map
	-- E464: Ambiguous use of user-defined command
	-- 2. 10C
	-- command not inputted yet
	-- 3. 10,20
	if not ok then
		local start_idx = nil
		repeat
			local sub_idx = start_idx
			if sub_idx ~= nil then
				sub_idx = sub_idx - 1
			end
			local sliced_cmdline = cmdline:sub(1, sub_idx)
			ok, result = pcall(function()
				return vim.api.nvim_parse_cmd(sliced_cmdline .. DEFAULT_COMMAND_WITH_RANGE, {})
			end)
			if ok then
				break
			end

			local search_idx = start_idx
			if search_idx ~= nil then
				search_idx = search_idx + 1
			end
			local match_start_idx = string.find(cmdline, "%a+", search_idx)

			if match_start_idx == nil then
				break
			end
			start_idx = match_start_idx
		until ok
	end

	if not ok then
		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
	end

	if vim.list_contains(M.opts.excluded.cmd, result.cmd) then
		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
	end

	-- TODO nvim_parse_cmd seems to mix up count and range, so we cannot highlight implicit range now.
	-- if result.range == nil or #result.range == 0 then
	-- 	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	-- 	local cmdline_with_range = string.format("%s%s", "15", "messages")
	-- 	-- local cmdline_with_range = string.format("%s%s", row, cmdline)
	-- 	local ok2, result2 = pcall(function()
	-- 		return vim.api.nvim_parse_cmd(cmdline_with_range, {})
	-- 	end)
	-- 	vim.print("result", result2.count, result2.range)
	-- 	-- vim.print("cmdline with range", cmdline_with_range)
	-- 	-- vim.print("is ok", ok)
	-- end

	if result.range == nil or #result.range == 0 then
		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
	end

	if #result.range == 2 then
		selection_start_row = result.range[1]
		selection_start_col = 0

		selection_end_row = result.range[2]
		selection_end_col = 0
	elseif #result.range == 1 then
		selection_start_row = result.range[1]
		selection_start_col = 0

		selection_end_row = result.range[1]
		selection_end_col = selection_start_col
	else
		vim.notify(
			string.format("%s: unhandled vim.api.nvim_parse_cmd range %s.", ns, #result.range),
			vim.log.levels.ERROR
		)
		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
	end

	if selection_end_row < selection_start_row then
		local temp_selection_start_row = selection_start_row
		local temp_selection_start_col = selection_start_col

		selection_start_row = selection_end_row
		selection_start_col = selection_end_col
		selection_end_row = temp_selection_start_row
		selection_end_col = temp_selection_start_col
	end

	selection_start_row = selection_start_row - 1

	return selection_start_row, selection_start_col, selection_end_row, selection_end_col
end

---@param opts SetupOpts
function M.setup(opts)
	---@type SetupOpts
	M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	vim.api.nvim_create_autocmd({ "CmdlineChanged" }, {
		pattern = "*",
		callback = debounce(M.opts.debounce.wait, function(ev)
			local ok = pcall(function()
				if vim.api.nvim_buf_is_valid(ev.buf) then
					vim.api.nvim_buf_clear_namespace(ev.buf, ns_id, 0, -1)
				end
			end)

			if not ok then
				return
			end

			local cmdline = vim.fn.getcmdline()
			---@type integer|nil
			local selection_start_row = nil
			---@type integer
			local selection_start_col = 0

			---@type integer|nil
			local selection_end_row = nil
			---@type integer
			local selection_end_col = 0

			selection_start_row, selection_start_col, selection_end_row, selection_end_col =
				M.get_linewise_range(cmdline)

			if selection_start_row == nil or selection_end_row == nil then
				return
			end

			-- NOTE use this instead of vim.highlight.range, so we can highlight the background instead of text
			pcall(function()
				vim.api.nvim_buf_set_extmark(ev.buf, ns_id, selection_start_row, selection_start_col, {
					end_line = selection_end_row,
					end_col = selection_end_col,
					hl_eol = M.opts.highlight.to_eol,
					hl_group = M.opts.highlight.group,
					priority = M.opts.highlight.priority,
				})
				vim.cmd.redraw()
			end)
		end),
	})
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		pattern = "*",
		callback = function(ev)
			vim.api.nvim_buf_clear_namespace(ev.buf, ns_id, 0, -1)
		end,
	})
end

return M
