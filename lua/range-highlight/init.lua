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

			local mark_range_pattern = "^'(.),?'(.)(%a+)"
			---@type string|nil, string|nil, string|nil
			local mark_start_range, mark_end_range, _ = cmdline:match(mark_range_pattern)

			if mark_start_range ~= nil then
				local line, col = unpack(vim.api.nvim_buf_get_mark(0, mark_start_range))
				selection_start_row = line
				selection_start_col = col
			end

			if mark_end_range ~= nil then
				local line, col = unpack(vim.api.nvim_buf_get_mark(0, mark_end_range))
				selection_end_row = line - 1
				selection_end_col = col
			end

			local digit_range_pattern = "^(%d*),?(%d*)(%a+)"
			---@type string|nil, string|nil, string|nil
			local digit_start_range, digit_end_range, _ = cmdline:match(digit_range_pattern)
			if digit_start_range ~= nil then
				selection_start_row = tonumber(digit_start_range)
				selection_start_col = 0
			end

			if digit_end_range ~= nil then
				selection_end_row = tonumber(digit_end_range)
				selection_end_col = 0
			end

			if selection_start_row == nil and selection_end_row == nil then
				return
			end

			if selection_end_row == nil and selection_start_row ~= nil then
				selection_end_row = selection_start_row
			end

			-- handle incompleted range, for example 10,2
			if selection_end_row < selection_start_row then
				vim.notify(
					string.format(
						"%s reversed range encountered %s",
						ns,
						vim.inspect({
							start_row = selection_start_row,
							start_col = selection_start_col,
							end_row = selection_end_row,
							end_col = selection_end_col,
						})
					),
					vim.log.levels.DEBUG
				)
				return
			end

			-- NOTE not sure if we have missed anything, keep them here for now
			-- if selection_end_row < selection_start_row then
			-- 	local temp_selection_start_row = selection_start_row
			-- 	local temp_selection_start_col = selection_start_col
			--
			-- 	selection_start_row = selection_end_row
			-- 	selection_start_col = selection_end_col
			-- 	selection_end_row = temp_selection_start_row
			-- 	selection_end_col = temp_selection_start_col
			-- 	return
			-- end

			selection_start_row = selection_start_row - 1
			vim.notify(
				string.format(
					"%s final highlight range is %s",
					ns,
					vim.inspect({
						start_row = selection_start_row,
						start_col = selection_start_col,
						end_row = selection_end_row,
						end_col = selection_end_col,
					})
				),
				vim.log.levels.DEBUG
			)

			vim.highlight.range(
				ev.buf,
				ns_id,
				opts.highlight.group,
				{ selection_start_row, selection_start_col },
				{ selection_end_row, selection_end_col },
				{ inclusive = mark_end_range ~= nil, priority = opts.highlight.priority, regtype = "v" }
			)
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
