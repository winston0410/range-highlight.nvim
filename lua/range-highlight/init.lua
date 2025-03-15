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
			local cmdline = vim.fn.getcmdline()

			local range_pattern = "^([%d']*),?([%d']*)(%a+)"
			local selection_start, selection_end, _ = cmdline:match(range_pattern)

			selection_start = tonumber(selection_start)
			selection_end = tonumber(selection_end)

			if selection_start == nil and selection_end == nil then
				return
			end

			if selection_end == nil and selection_start ~= nil then
				selection_end = selection_start
			end

			-- handle incompleted range, for example 10,2
			if selection_end < selection_start then
				return
			end

			-- normalize line number
			selection_start = selection_start - 1

			vim.highlight.range(0, ns, opts.highlight_group, { selection_start, 0 }, { selection_end, 0 })
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
