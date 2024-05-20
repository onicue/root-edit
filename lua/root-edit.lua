local M = {}

M.config = {
  editor = "sudo"
}

function M.Hello()
  print(M.config.editor)
end

M.setup = function (opts)
  M.config = vim.tbl_extend('force', M.config, opts)
  vim.api.nvim_create_user_command("Hello", M.Hello, {})
end


return M
