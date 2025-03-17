local ns = "range-highlight"
local ns_id = vim.api.nvim_create_namespace(ns)
local M = {}

---@alias SetupOpts { highlight: { group: string, priority: integer, to_eol: boolean}, excluded: { cmd: string[]}}
---@type SetupOpts
local default_opts = {
	highlight = {
		group = "Visual",
		priority = 10,
		to_eol = false,
	},
	-- NOTE the command here does not accept shorthand
	excluded = { cmd = { "substitute" } },
}

-- NOTE charwise operation is not supported by commandline right now, but keeping the implementation here
-- ---@param buf_id integer
-- ---@param cmdline string
-- ---@return integer|nil, integer, integer|nil, integer
-- function M.get_charwise_range(buf_id, cmdline)
-- 	---@type integer|nil
-- 	local selection_start_row = nil
-- 	---@type integer
-- 	local selection_start_col = 0
--
-- 	---@type integer|nil
-- 	local selection_end_row = nil
-- 	---@type integer
-- 	local selection_end_col = 0
-- 	local mark_pattern = "^'(.)[,;]?'(.)"
--
-- 	local ok, result = pcall(function()
-- 		return vim.api.nvim_parse_cmd(cmdline, {})
-- 	end)
-- 	if not ok then
-- 		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
-- 	end
--
-- 	local cmd_idx = cmdline:find(result.cmd)
-- 	if cmd_idx == nil then
-- 		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
-- 	end
--
-- 	cmdline = cmdline:sub(1, cmd_idx - 1)
--
-- 	local start_range, end_range = cmdline:match(mark_pattern)
-- 	if start_range ~= nil then
-- 		local line, col = unpack(vim.api.nvim_buf_get_mark(buf_id, start_range))
-- 		selection_start_row = line
-- 		selection_start_col = col
-- 	end
--
-- 	if end_range ~= nil then
-- 		local line, col = unpack(vim.api.nvim_buf_get_mark(buf_id, end_range))
-- 		selection_end_row = line - 1
-- 		selection_end_col = col
-- 	end
-- 	return selection_start_row, selection_start_col, selection_end_row, selection_end_col
-- end

---@param opts  SetupOpts
---@param cmdline string
---@return integer|nil, integer, integer|nil, integer
function M.get_linewise_range(cmdline, opts)
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

	if vim.list_contains(opts.excluded.cmd, result.cmd) then
		return selection_start_row, selection_start_col, selection_end_row, selection_end_col
	end

	if not ok then
		local dummy_cmdline = cmdline
		if result.cmd == nil then
			dummy_cmdline = cmdline .. DEFAULT_COMMAND_WITH_RANGE
		else
			-- NOTE parse again, with a command with range, as nvim_parse_cmd would not show range for command that does not support range
			local cmd_idx = cmdline:find(result.cmd)
			if cmd_idx == nil then
				return selection_start_row, selection_start_col, selection_end_row, selection_end_col
			end

			dummy_cmdline = cmdline:sub(1, cmd_idx - 1) .. DEFAULT_COMMAND_WITH_RANGE
		end
		ok, result = pcall(function()
			return vim.api.nvim_parse_cmd(dummy_cmdline, {})
		end)
		if not ok then
			return selection_start_row, selection_start_col, selection_end_row, selection_end_col
		end
	end

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
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	vim.api.nvim_create_autocmd({ "CmdlineChanged" }, {
		pattern = "*",
		callback = function(ev)
			vim.api.nvim_buf_clear_namespace(ev.buf, ns_id, 0, -1)

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
				M.get_linewise_range(cmdline, opts)

			if selection_start_row == nil or selection_end_row == nil then
				return
			end

			-- NOTE use this instead of vim.highlight.range, so we can highlight the background instead of text
			pcall(function()
				vim.api.nvim_buf_set_extmark(ev.buf, ns_id, selection_start_row, selection_start_col, {
					end_line = selection_end_row,
					end_col = selection_end_col,
					hl_eol = opts.highlight.to_eol,
					hl_group = opts.highlight.group,
					priority = opts.highlight.priority,
				})
				vim.cmd.redraw()
			end)
		end,
	})
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		pattern = "*",
		callback = function(ev)
			vim.api.nvim_buf_clear_namespace(ev.buf, ns_id, 0, -1)
		end,
	})
end

return M
