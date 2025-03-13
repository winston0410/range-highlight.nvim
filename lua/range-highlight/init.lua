local ns = vim.api.nvim_create_namespace("range-highlight")
local M = {}

function M.setup() end
vim.api.nvim_create_autocmd("CmdlineChanged", {
	callback = function()
		local cmdline = vim.fn.getcmdline()
		local parsed_cmdline = vim.api.nvim_parse_cmd(cmdline, {})
		local selection_start, selection_end = unpack(parsed_cmdline.range)
		vim.print("selection area", selection_start, selection_end)
	end,
})
vim.api.nvim_create_autocmd("CmdlineLeave", {
	callback = function()
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end,
})

return M
