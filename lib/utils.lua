local path = require('path')
local fs = require('fs')

local exports = {}

-- get package information from package.lua in abs_path
exports.get_package_lua = function(abs_path)
  local package_path = path.join(abs_path, 'package.lua')
  if not fs.existsSync(package_path) then
    return nil
  end
  local meta_loader = loadstring(fs.readFileSync(package_path))
  if not meta_loader then
    return nil
  end
  local success, meta = pcall(meta_loader)
  if not success then
    return nil
  end
  return meta
end

return exports
