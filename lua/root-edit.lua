local M = {}

M.config = {
  editor = "sudo",
  readonly = false,
}

local function separateString(input_string)
  local result = {}
  for value in input_string:gmatch("%S+") do
    table.insert(result, value)
  end
  return result
end

local function CheckIfExist(filename)
  local file = io.open(filename, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function deleteTmpFile(filename)
  local success, err = os.remove(filename)
  if not success then
    print("Error deleting file: " .. (err or "Unknown error"))
  end
end

local function createFileData()
  local bufnr = vim.api.nvim_get_current_buf()
  local old_name = vim.api.nvim_buf_get_name(bufnr)
  local chown = separateString(vim.fn.system("ls -l ".. old_name .." | awk '{print $3, $4}'"))

  local tmp_file = ""
  repeat
    tmp_file = "/tmp/tmp." .. tostring({}):sub(10)
  until not CheckIfExist(tmp_file)

  vim.cmd('silent write ' .. tmp_file)
  vim.api.nvim_buf_set_name(bufnr, old_name)

  return {
    tmp = tmp_file,
    old = old_name,
    chown = chown
  }
end

local function rootEditEnd(filename)
  if CheckIfExist(filename) then
    deleteTmpFile(filename)
  end
end

function M.sudoEdit()
  local password = vim.fn.inputsecret("Enter password: ")
  local FileData = createFileData()

  local cmd = string.format(
    "echo '%s' | sudo -S mv %s %s && sudo chown %s:%s %s >/dev/null 2>&1",
    password, FileData.tmp, FileData.old, FileData.chown[1], FileData.chown[2], FileData.old
  )

  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error executing command: " .. output)
  else
    print("File successfully edited and ownership changed.")
  end

  rootEditEnd(FileData.tmp)
end

function M.doasEdit()
  local FileData = createFileData()

  local cmd = string.format(
    "doas mv %s %s && doas chown %s:%s %s",
    FileData.tmp, FileData.old, FileData.chown[1], FileData.chown[2], FileData.old
  )

  vim.cmd('below split')
  vim.cmd('terminal '.. cmd)
  vim.defer_fn(function() rootEditEnd(FileData.old) end, 0)
end

local function disableReadOnly()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
      if vim.bo.readonly then
        vim.bo.readonly = false
      end
    end,
  })
end

M.setup = function (opts)
  M.config = vim.tbl_extend('force', M.config, opts)
  local editor = M.config.editor
  local create_cmd = function (fun)
    vim.api.nvim_create_user_command("RootEdit", fun, {})
  end

  if not M.config.readonly then
    disableReadOnly()
  end

  if editor == "sudo"   then
    create_cmd(M.sudoEdit)
  elseif editor == "doas" then
    create_cmd(M.doasEdit)
  else
    vim.api.nvim_err_write("editor not equal sudo/doas in root-edit setup\n")
  end
end

return M
