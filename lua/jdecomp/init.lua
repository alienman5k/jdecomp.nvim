-- print("Plugin jdecomp loaded")
local M = {}

vim.filetype.add({
  class = 'class'
})

-- local decompilers = {
--   CFR = 'cfr',
--   PROCYON = 'procyon',
--   FERNFLOWER = 'fernflower',
-- }

local _config = {
  path = 'cfr'
}

function M.setup (config)
  if config and config.path then
    _config.path = vim.fn.expand(config.path)
  end
end

local function get_cmd (class_path, jar_path)
  local cmd
  print(string.format("%s, %s, %s", _config.path, class_path, jar_path))
  if string.match(_config.path, 'cfr') then
    if jar_path then
      cmd = {
        _config.path,
        '--extraclasspath',
        jar_path,
        class_path
      }
    else
      cmd = {
        _config.path,
        class_path
      }
    end
  elseif string.match(_config.path, 'procyon') then
    if jar_path then
      -- cmd = {
      --   "java",
      --   "-jar",
      --   "/Users/imarmole/Software/procyon-decompiler-0.6.0.jar",
      --   "--jar-file",
      --   jar_path,
      --   class_path
      -- }
      cmd = {
        "java",
        "-jar",
        _config.path,
        "--jar-file",
        jar_path,
        class_path
      }
    else
      cmd = {
        "java",
        "-jar",
        _config.path,
        class_path
      }
    end
  elseif string.match(_config.path, 'fernflower') then
    -- Fernflower requires to put output in a directory
    if jar_path then
      print("Not yet implemented")
    else
      print("Not yet implemented")
    end
  end
  vim.inspect(cmd)
  return cmd
end


local jdgroup = vim.api.nvim_create_augroup("JavaDecompiler", { clear = true })
vim.api.nvim_create_autocmd({"BufWinEnter"}, {
  pattern = '*.class',
  group = jdgroup,
  callback = function(evt)
    -- print(string.format("Start decompiling during event: '%s'", vim.inspect(evt)))
    if vim.api.nvim_buf_get_option(evt.buf, "syntax") and vim.api.nvim_buf_get_option(evt.buf, 'readonly') then
      print('Buffer already decompiled, nothing else to do')
      return
    end
    local jar_path, class_path
    local cmd

    if string.find(evt.file, "jdt://") then
      print("Class from jdt do not decompile")
      return
    end

    if string.find(evt.file, "zipfile://") then
      print("Decompiling class inside jar file")
      P(_config)
      local pattern = "(zipfile://)(.*)::(.*)"
      _, _, _, jar_path, class_path = string.find(evt.file, pattern)
      cmd = get_cmd(class_path, jar_path)
    else
      cmd = get_cmd(evt.file)
    end

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data then
          if _config.decompiler ~= 'fernflower' then
            vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
          else
            vim.api.nvim_buf_set_lines(0, -1, -1, false, { "FernFlower is not supported yet" })
          end
        end
      end,
      -- stderr_buffered = true,
      -- on_stderr = function(_, data)
      --   if data then
      --     P(data)
      --     -- vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
      --   end
      -- end,
      on_exit = function()
        vim.api.nvim_buf_set_option(evt.buf, 'syntax', 'enable')
        vim.api.nvim_buf_set_option(evt.buf, 'syntax', 'java')
        vim.api.nvim_buf_set_option(evt.buf, 'modified', false)
        vim.api.nvim_buf_set_option(evt.buf, 'readonly', true)
      end
    })
  end
})

return M
