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
  -- path = 'cfr',
  decompiler = 'cfr',
  provider = {
    cfr = {
      bin = 'cfr', -- If binary is not available in $PATH then provide full path of cfr binary (as some distributions provide a binary script around cfr jar) 
      --jar = '/home/user/.local/cfr/cfr.jar' -- full path of cfr jar
    },
    procyon = {
      jar =  os.getenv('HOME') .. '/Software/procyon-decompiler-0.6.0.jar'
    },
    fernflower = {
      jar = os.getenv('HOME') .. '~/Software/fernflower-decompiler.jar'
    }
  }

}

function M.setup (config)
  if config and config.decompiler then
    local decomp = config.decompiler
    _config.decompiler = decomp
    _config.provider[decomp] = config.provider[decomp]
  end
end

local function get_cmd (class_path, jar_path)
  local cmd = {}
  print(string.format("%s, %s, %s", _config.decompiler, class_path, jar_path))
  if string.match(_config.decompiler, 'cfr') then
    if _config.provider.cfr.bin then
      table.insert(cmd, _config.provider.cfr.bin)
    else
      table.insert(cmd, 'java')
      table.insert(cmd, '-jar')
      table.insert(cmd, _config.provider.cfr.jar)
    end
    if jar_path then
      table.insert(cmd, jar_path)
    end
    table.insert(cmd, class_path)
  elseif string.match(_config.decompiler, 'procyon') then
    table.insert(cmd, 'java')
    table.insert(cmd, '-jar')
    table.insert(cmd, _config.provider.procyon.jar)
    --[[ TODO: Extract the file to a tmp folder and then decompile it and put in the buffer  --]]
    if jar_path then
      table.insert(cmd, '--jar-file')
      table.insert(cmd, jar_path)
    end
    table.insert(cmd, class_path)
  elseif string.match(_config.decompiler, 'fernflower') then
    -- Fernflower requires to put output in a directory, we will use a temp directory
    if jar_path then
      print("Not yet implemented")
      print(_config.provider.fernflower.jar)
    else
      print("Not yet implemented")
      print(_config.provider.fernflower.jar)
    end
  end
  print(vim.inspect(cmd))
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
