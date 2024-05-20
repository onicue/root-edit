local M = {}

M.config = {
  editor = "sudo"
}

M.separate_string = function(input_string)
    local result = {}
    for value in input_string:gmatch("%S+") do
        table.insert(result, value)
    end
    return result
end

M.rootEdit = function ()
  local new = "/tmp/tmp." .. tostring({}):sub(10)
  local bufnr = vim.api.nvim_get_current_buf()
  local old = vim.api.nvim_buf_get_name(bufnr)

  local chown = M.separate_string(vim.fn.system("ls -l "..old.." | awk '{print $3, $4}'"))

  vim.cmd('write ' .. new)
  vim.api.nvim_buf_set_name(bufnr, old)

  vim.cmd('below split')
  vim.cmd('terminal ' .. M.config.editor .. ' mv ' .. new .. ' ' .. old
          .. ' && '.. M.config.editor ..' chown '..chown[1]..':'..chown[2]..'  ' .. ' ' .. old)
end

M.setup = function (opts)
  M.config = vim.tbl_extend('force', M.config, opts)
  local editor = M.config.editor
  if editor == "sudo" or editor == "doas"   then
    vim.api.nvim_create_user_command("RootEdit", M.rootEdit, {})
  else
    vim.api.nvim_err_write("editor not equal sudo/doas in root-edit setup\n")
  end
end

return M
