require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- nvim-treesitter stores queries under runtime/queries/ but needs that path in rtp
vim.opt.rtp:prepend(vim.fn.stdpath "data" .. "/lazy/nvim-treesitter/runtime")
