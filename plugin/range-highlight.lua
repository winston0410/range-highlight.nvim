vim.api.nvim_create_autocmd("CmdlineEnter", {
    once = true,
    callback = function()
        require("range-highlight").setup({})
    end,
})
