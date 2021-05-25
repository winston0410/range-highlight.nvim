local function mark_to_number(start_mark)
    return vim.api.nvim_buf_get_mark(0, string.sub(start_mark, 2, -1))[1]
end

local function search_to_number(config)
    return function(pattern)
        local pattern_text, search_options = string.sub(pattern, 2, -2), "n"
        if not config.forward then search_options = "bn" end
        local line_number = vim.api.nvim_call_function("searchpos", {
            pattern_text, search_options
        })[1]
        return line_number
    end
end

return {
    mark_to_number = mark_to_number,
    forward_search_to_number = search_to_number {forward = true},
    backward_search_to_number = search_to_number {forward = false}
}
