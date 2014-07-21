local path = require('path')

local utils = require('./utils')
local Dependencies = require('./dependencies')
local DependencySatisfier = require('./dependency_satisfier')


-- prints issues with package.lua if any
-- returns true if still OK, false if fatal
function check_meta(meta)
  if not meta then
    print('No package.lua or package.lua is invalid')
    return false
  end
  if not meta.dependencies then
    print('Warning: no "dependencies" key in package.lua')
  end
  return true
end


local exports = {}

exports.install = function(...)
  local args = { ... }

  if 0 == #args then
    -- called with no arguments:
    -- Install the dependencies in the local modules folder.
    meta = utils.get_package_lua(path.join(process.cwd()))
    if not check_meta(meta) then
      return
    end
    local dependencies = Dependencies:new(meta, true)
    local dependencySatisfier = DependencySatisfier:new(true)
    dependencies:pipe(dependencySatisfier)
    return
  end
end

return exports
