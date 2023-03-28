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
  decompiler = 'cfr', -- cfr, procyon, ferflower
}

M.setup = function(config)
  if config and config.decompiler then
    _config.decompiler = config.decompiler
  end
end

local get_cmd = function(decompiler, class_path, jar_path)
  local cmd
  -- print(string.format("%s, %s, %s", decompiler, class_path, jar_path))
  if decompiler == 'cfr' then
    if jar_path then
      cmd = { 'cfr', '--extraclasspath', jar_path, class_path }
    else
      cmd = { 'cfr', class_path }
    end
  elseif decompiler == 'procyon' then
    if jar_path then
      -- cmd = {
      --   "java",
      --   "-jar",
      --   "/Users/imarmole/Software/procyon-decompiler-0.6.0.jar",
      --   "--jar-file",
      --   jar_path,
      --   class_path
      -- }
      cmd = { 'cfr', '--extraclasspath', jar_path, class_path }
    else
      cmd = {
        "java",
        "-jar",
        "/Users/imarmole/Software/procyon-decompiler-0.6.0.jar",
        class_path
      }
    end
  elseif decompiler == 'fernflower' then
    -- Fernflower requires to put output in a directory
    if jar_path then
      print("Not yet implemented")
    else
      print("Not yet implemented")
    end
  end
  -- vim.inspect(cmd)
  return cmd
end


local jdgroup = vim.api.nvim_create_augroup("JavaDecompiler", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = '*.class',
  group = jdgroup,
  callback = function(evt)
    if not evt then
      print("Not a valid event")
      return
    end
    -- print(string.format("Start decompiling during event: '%s'", evt.event))
    local jar_path, class_path
    local cmd

    if string.find(evt.file, "zipfile") then
      print("Decompiling class inside jar file")
      local pattern = "(zipfile://)(.*)::(.*)"
      _, _, _, jar_path, class_path = string.find(evt.file, pattern)
      cmd = get_cmd(_config.decompiler, class_path, jar_path)
    else
      cmd = get_cmd(_config.decompiler, evt.file)
    end

    -- P(cmd)
    -- if cmd then
    --   vim.cmd("%delete")
    -- end

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
        vim.cmd([[
          syntax enable
          set syntax=java
          set nomodified
          set readonly
        ]])
      end
    })
  end
})

return M