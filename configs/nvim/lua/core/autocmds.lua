local api = vim.api

local augroup = api.nvim_create_augroup("userConfig", {})

api.nvim_create_autocmd("InsertLeave", {
  group = augroup,
  pattern = "*",
  command  = "set nopaste",
})

-- From SalarAlo/neovim_configuration's lua/salar/tools/include_formatter.lua,
-- used as-is — already language-agnostic, no C++-specific logic in it despite
-- living in a C++-focused config.
api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = { "*.h", "*.c" },
  callback = function(args)
    require("tools.include_formatter").format(args.buf)
  end,
})

