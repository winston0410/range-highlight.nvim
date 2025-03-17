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

---@alias RangeKind "mark" | "digit" | "special" |  nil
---@param cmd string
---@return RangeKind, number|nil, number|nil, RangeKind, number|nil, number|nil
local function get_range(cmd)
	---@type number|nil
	local selection_start_row = nil
	---@type number|nil
	local selection_start_col = nil
	---@type RangeKind
	local selection_start_kind = nil
	---@type number|nil
	local selection_end_row = nil
	---@type number|nil
	local selection_end_col = nil
	---@type RangeKind
	local selection_end_kind = nil

	local patterns = {
		{ kind = "mark", pattern = "^'(.)[,;]?'(.)(%a+)" },
		{ kind = "digit", pattern = "^(%d*)[,;]?(%d*)(%a+)" },
		{ kind = "special", pattern = "^([%.%$%%])[,;]?([%.%$%%])(%a+)" },
	}

	for _, item in ipairs(patterns) do
		if selection_start_row ~= nil and selection_end_row ~= nil then
			break
		end
		local start_range, end_range, _ = cmd:match(item.pattern)

		if item.kind == "mark" then
			if start_range ~= nil then
				local line, col = unpack(vim.api.nvim_buf_get_mark(0, start_range))
				selection_start_row = line
				selection_start_col = col
				selection_start_kind = "mark"
			end

			if end_range ~= nil then
				local line, col = unpack(vim.api.nvim_buf_get_mark(0, end_range))
				selection_end_row = line - 1
				selection_end_col = col
				selection_end_kind = "mark"
			end
		elseif item.kind == "digit" then
			if start_range ~= nil then
				selection_start_row = tonumber(start_range)
				selection_start_col = 0
				selection_start_kind = "digit"
			end

			if end_range ~= nil then
				selection_end_row = tonumber(end_range)
				selection_end_col = 0
				selection_end_kind = "digit"
			end
		elseif item.kind == "special" then
			-- handle range like :,15, and :15,.
			-- local line, _ = unpack(vim.api.nvim_win_get_cursor(0))
			-- selection_start_row = line
			-- selection_start_col = 0
			-- vim.print("hit special", start_range, end_range)
		end
	end

	-- TODO make this conditional and only for digit
	if selection_start_row ~= nil and selection_end_row == nil then
		selection_end_kind = selection_start_kind
		selection_end_row = selection_start_row
	end

	if selection_start_row ~= nil then
		selection_start_row = selection_start_row - 1
	end

	return selection_start_kind,
		selection_start_row,
		selection_start_col,
		selection_end_kind,
		selection_end_row,
		selection_end_col
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

			-- handle range like :15

			-- -- handle incompleted range, for example 10,2
			-- if selection_end_row < selection_start_row then
			-- 	vim.notify(
			-- 		string.format(
			-- 			"%s reversed range encountered %s",
			-- 			ns,
			-- 			vim.inspect({
			-- 				start_row = selection_start_row,
			-- 				start_col = selection_start_col,
			-- 				end_row = selection_end_row,
			-- 				end_col = selection_end_col,
			-- 			})
			-- 		),
			-- 		vim.log.levels.DEBUG
			-- 	)
			-- 	return
			-- end
			--
			--
			-- vim.notify(
			-- 	string.format(
			-- 		"%s final highlight range is %s",
			-- 		ns,
			-- 		vim.inspect({
			-- 			start_row = selection_start_row,
			-- 			start_col = selection_start_col,
			-- 			end_row = selection_end_row,
			-- 			end_col = selection_end_col,
			-- 		})
			-- 	),
			-- 	vim.log.levels.DEBUG
			-- )

			local _, selection_start_row, selection_start_col, selection_end_kind, selection_end_row, selection_end_col =
				get_range(cmdline)

			if selection_start_row == nil or selection_end_row == nil then
				return
			end

			vim.highlight.range(
				ev.buf,
				ns_id,
				opts.highlight.group,
				{ selection_start_row, selection_start_col },
				{ selection_end_row, selection_end_col },
				{ inclusive = selection_end_kind == "mark", priority = opts.highlight.priority, regtype = "v" }
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
