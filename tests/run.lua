-- Lightweight test runner to execute Lua tests without external dependencies.
local M = {}

-- Ensure the plugin's Lua modules are discoverable.
local sep = package.config:sub(1, 1)
local repo_root = debug.getinfo(1, "S").source:sub(2):match(("^.*%s"):format(sep)) or ""
local plugin_path = repo_root .. ".." .. sep .. "lua"
package.path = table.concat({ package.path, plugin_path .. sep .. "?.lua", plugin_path .. sep .. "?/init.lua" }, ";")

local function iter_tests()
  local tests = {}
  local handle = vim.loop.fs_scandir(repo_root)
  while handle do
    local name = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if name:match("_test%.lua$") then
      local module_name = name:gsub("%.lua$", "")
      table.insert(tests, module_name)
    end
  end
  table.sort(tests)
  return tests
end

local function run_test(module_name)
  local ok, test_module = pcall(require, "tests." .. module_name)
  if not ok then
    error(("failed loading %s: %s"):format(module_name, test_module))
  end

  local results = {}
  for name, fn in pairs(test_module) do
    if type(fn) == "function" and name:match("^test_") then
      local success, err = pcall(fn)
      if success then
        table.insert(results, { name = name, status = "ok" })
      else
        table.insert(results, { name = name, status = "failed", error = err })
      end
    end
  end
  return results
end

function M.run()
  local failures = 0
  for _, module_name in ipairs(iter_tests()) do
    for _, result in ipairs(run_test(module_name)) do
      if result.status == "ok" then
        print(("ok    %s.%s"):format(module_name, result.name))
      else
        failures = failures + 1
        print(("not ok %s.%s"):format(module_name, result.name))
        print(result.error)
      end
    end
  end
  if failures > 0 then
    error(("%d test(s) failed"):format(failures))
  end
  print("All tests passed")
end

return M
