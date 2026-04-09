local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "gofmt" },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  format_on_save = function(bufnr)
    if vim.g.format_on_save then
      return { timeout_ms = 500, lsp_fallback = true }
    end
  end,
}

return options
