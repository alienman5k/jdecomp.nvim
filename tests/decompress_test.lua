local M = {}
local helper = require("jdecomp.helper")

local function with_stubbed_cmd(fn)
  local original_cmd = vim.cmd
  local captured
  vim.cmd = function(command)
    captured = command
  end

  local ok, err = pcall(fn, function()
    return captured
  end)

  vim.cmd = original_cmd

  if not ok then
    error(err)
  end
end

function M.test_decompress_file_quotes_paths_with_spaces()
  with_stubbed_cmd(function(get_command)
    local jar = "/tmp/path with spaces/archive.jar"
    local class = "com/example/My Class.class"
    local tmp_dir = "/tmp/jdecomp dir"

    helper.decompress_file(class, jar, tmp_dir)

    local expected = string.format("!unzip %s %s -d %s",
      vim.fn.shellescape(jar),
      vim.fn.shellescape(class),
      vim.fn.shellescape(tmp_dir))

    local actual = get_command()
    if actual ~= expected then
      error(string.format("expected '%s' but received '%s'", expected, tostring(actual)))
    end
  end)
end

return M
