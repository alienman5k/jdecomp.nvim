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

-- Decompress a file from a jar file and stored in a tmp file
local function decompress_file(class, jar, tmp_dir)
  -- print(class, jar)
  if not class or not jar then
    vim.notify('class or jar not provided to decompress from jar')
    return
  end

  local cmd = string.format('!unzip %s %s -d %s', jar, class, tmp_dir)
  -- print("command", vim.inspect(cmd))
  vim.cmd(cmd)
end

local function get_cmd (class_path, jar_path)
  local cmd = {}
  local tmp_file
  -- print(string.format("%s, %s, %s", _config.decompiler, class_path, jar_path))
  if string.match(_config.decompiler, 'cfr') then
    if _config.provider.cfr.bin then
      table.insert(cmd, _config.provider.cfr.bin)
    else
      table.insert(cmd, 'java')
      table.insert(cmd, '-jar')
      table.insert(cmd, _config.provider.cfr.jar)
    end
    if jar_path then
      table.insert(cmd, '--extraclasspath')
      table.insert(cmd, jar_path)
    end
    table.insert(cmd, class_path)
  elseif string.match(_config.decompiler, 'procyon') then
    table.insert(cmd, 'java')
    table.insert(cmd, '-jar')
    table.insert(cmd, _config.provider.procyon.jar)
    if jar_path then
      -- If the class is inside a jar, then we need to decompress it to tmp_dir and update class_path to that of the decompressed file
      local tmp_dir = vim.fs.dirname(vim.fn.tempname()) .. "/jdecomp"
      -- print("tmp_dir", tmp_dir)
      vim.fn.mkdir(tmp_dir, "p")
      decompress_file(class_path, jar_path, tmp_dir)
      class_path = tmp_dir .. '/' .. class_path
    end
    table.insert(cmd, class_path)
  elseif string.match(_config.decompiler, 'fernflower') then
    -- Fernflower requires to put output in a directory, we will use a temp directory
    -- java -jar ~/Software/fernflower.jar -dgs=1 -hes=1 -hdc=1 <source> <destination>
    table.insert(cmd, "java")
    table.insert(cmd, "-jar")
    table.insert(cmd, _config.provider.fernflower.jar)
    table.insert(cmd, "-dgs=1")
    table.insert(cmd, "-hes=1")
    table.insert(cmd, "-hdc=1")

    local tmp_dir = vim.fs.dirname(vim.fn.tempname()) .. "/jdecomp"
    -- print("tmp_dir", tmp_dir)
    vim.fn.mkdir(tmp_dir, "p")

    if jar_path then
      decompress_file(class_path, jar_path, tmp_dir)
      table.insert(cmd, tmp_dir .. '/' .. class_path)
    else
      table.insert(cmd, class_path)
    end
    table.insert(cmd, tmp_dir)
    -- tmp_file = string.gsub(tmp_dir, '.class', '.java')
    tmp_file = string.format("%s/%s", tmp_dir, string.gsub(vim.fn.fnamemodify(class_path, ":t"), '.class', '.java'))
  end
  -- print(vim.inspect(cmd))
  -- print("tmp_file",  tmp_file)
  return cmd, tmp_file
end


local jdgroup = vim.api.nvim_create_augroup("JavaDecompiler", { clear = true })
vim.api.nvim_create_autocmd({"BufWinEnter"}, {
  pattern = '*.class',
  group = jdgroup,
  callback = function(evt)
    -- print(string.format("Start decompiling during event: '%s'", vim.inspect(evt)))
    if vim.api.nvim_buf_get_option(evt.buf, "syntax") and vim.api.nvim_buf_get_option(evt.buf, 'readonly') then
      vim.notify('Buffer already decompiled, nothing else to do', vim.log.levels.DEBUG)
      return
    end
    local jar_path, class_path
    local cmd, tmp_file

    if string.find(evt.file, "jdt://") then
      vim.notify("Class from jdt do not decompile", vim.log.levels.DEBUG)
      return
    end

    if string.find(evt.file, "zipfile://") then
      local pattern = "(zipfile://)(.*)::(.*)"
      _, _, _, jar_path, class_path = string.find(evt.file, pattern)
      cmd, tmp_file = get_cmd(class_path, jar_path)
    else
      cmd, tmp_file = get_cmd(evt.file)
    end

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data then
          if _config.decompiler ~= 'fernflower' then
            vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
          else
            -- vim.api.nvim_buf_set_lines(0, -1, -1, false, { "FernFlower is not supported yet" })
          end
        end
      end,
      on_exit = function()
        if _config.decompiler == 'fernflower' then
          -- tmp_file = tmp_dir .. jdecomp .. class_path  (replace .class with .java)
          -- vim.api.nvim_buf_set_option(evt.buf, 'filetype', 'off')
          vim.api.nvim_buf_set_lines(evt.buf, 0, -1, true, {})
          vim.api.nvim_buf_set_lines(evt.buf, 0, 0, true, {'// decompiled with fernflower'})
          vim.cmd('1read ' .. tmp_file)
        end
        vim.api.nvim_buf_set_option(evt.buf, 'syntax', 'enable')
        vim.api.nvim_buf_set_option(evt.buf, 'syntax', 'java')
        vim.api.nvim_buf_set_option(evt.buf, 'modified', false)
        vim.api.nvim_buf_set_option(evt.buf, 'readonly', true)
      end
    })
  end
})

return M
