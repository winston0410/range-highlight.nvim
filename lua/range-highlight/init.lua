local ns = vim.api.nvim_create_namespace("range-highlight")
local M = {}

---@alias SetupOpts { highlight_group: string }
---@type SetupOpts
local default_opts = {
	highlight_group = "Visual",
}
---@param opts SetupOpts
function M.setup(opts)
	---@type SetupOpts
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	vim.api.nvim_create_autocmd({ "CmdlineChanged" }, {
		pattern = "*",
		callback = function()
			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

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
				selection_end_col = col + 1
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
				-- only early return, if it is digit range for both start and end
				if digit_start_range ~= nil and digit_end_range ~= nil then
					return
				else
					-- TODO handle swapped start and end
				end
			end

			-- normalize line number
			selection_start_row = selection_start_row - 1

			vim.highlight.range(
				0,
				ns,
				opts.highlight_group,
				{ selection_start_row, selection_start_col },
				{ selection_end_row, selection_end_col }
			)
		end,
	})
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		pattern = "*",
		callback = function()
			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
		end,
	})
end

return M
