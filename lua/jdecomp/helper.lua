local M = {}

function M.decompress_file(class, jar, tmp_dir)
  if not class or not jar then
    error('class or jar not provided to decompress from jar', 1)
  end

  local cmd = string.format('!unzip %s %s -d %s', vim.fn.shellescape(jar), vim.fn.shellescape(class), vim.fn.shellescape(tmp_dir))
  vim.cmd(cmd)
end

return M
