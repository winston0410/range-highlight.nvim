local ns = "range-highlight"
local ns_id = vim.api.nvim_create_namespace(ns)
local M = {}

---@alias SetupOpts { highlight: { group: string, priority: number} }
---@type SetupOpts
local default_opts = {
	highlight = {
		group = "Visual",
		priority = 10,
	},
}

---@param cmdline string
---@return number|nil, number|nil, number|nil, number|nil
function M.get_charwise_range(cmdline)
	local mark_pattern = "^'(.)[,;]?'(.)(%a+)"

	-- if start_range ~= nil then
	-- 	local line, col = unpack(vim.api.nvim_buf_get_mark(0, start_range))
	-- 	selection_start_row = line
	-- 	selection_start_col = col
	-- 	selection_start_kind = "mark"
	-- end
	--
	-- if end_range ~= nil then
	-- 	local line, col = unpack(vim.api.nvim_buf_get_mark(0, end_range))
	-- 	selection_end_row = line - 1
	-- 	selection_end_col = col
	-- 	selection_end_kind = "mark"
	-- end
end

---@param cmdline string
---@return number|nil, number|nil, number|nil, number|nil
function M.get_linewise_range(cmdline)
	local DEFAULT_COMMAND_WITH_RANGE = "print"
	local ok, result = pcall(function()
		return vim.api.nvim_parse_cmd(cmdline, {})
	end)

	if not ok then
		local dummy_cmdline = cmdline
		if result.cmd == nil then
			dummy_cmdline = cmdline .. DEFAULT_COMMAND_WITH_RANGE
		else
			-- NOTE parse again, with a command with range, as nvim_parse_cmd would not show range for command that does not support range
			local cmd_idx = cmdline:find(result.cmd)
			if cmd_idx == nil then
				return nil, nil, nil, nil
			end

			dummy_cmdline = cmdline:sub(1, cmd_idx) .. DEFAULT_COMMAND_WITH_RANGE
		end
		ok, result = pcall(function()
			return vim.api.nvim_parse_cmd(dummy_cmdline, {})
		end)
		if not ok then
			return nil, nil, nil, nil
		end
	end

	---@type number|nil
	local selection_start_row = nil
	---@type number|nil
	local selection_start_col = nil

	---@type number|nil
	local selection_end_row = nil
	---@type number|nil
	local selection_end_col = nil

	if result.range == nil or #result.range == 0 then
		return nil, nil, nil, nil
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
		return nil, nil, nil, nil
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
			---@type number|nil
			local selection_start_row = nil
			---@type number|nil
			local selection_start_col = nil

			---@type number|nil
			local selection_end_row = nil
			---@type number|nil
			local selection_end_col = nil

			selection_start_row, selection_start_col, selection_end_row, selection_end_col =
				M.get_linewise_range(cmdline)

			if selection_start_row == nil or selection_end_row == nil then
				return
			end

			vim.highlight.range(
				ev.buf,
				ns_id,
				opts.highlight.group,
				{ selection_start_row, selection_start_col },
				{ selection_end_row, selection_end_col },
				-- TODO detect mark and make this true, when the matching is not linewise but charwise
				{ inclusive = false, priority = opts.highlight.priority, regtype = "v" }
			)
			vim.cmd.redraw()
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
