local path = require('path')

local utils = require('./utils')
local deps = require('./deps')


-- prints issues with package.lua if any
-- returns true if still OK, false if fatal
function check_meta(meta)
  if not meta then
    print('No package.lua or package.lua is invalid')
    return false
  end
  if not meta.dependencis then
    print('Warning: no "dependencies" key in package.lua')
  end
  return true
end


local exports = {}

exports.install = function(...)
  meta = utils.get_package_lua(path.join(process.cwd()))
  if not check_meta(meta) then
    return
  end

  local args = { ... }

  if 0 == #args then
    -- called with no arguments:
    -- Install the dependencies in the local modules folder.
    deps.ensure_deps(meta, true) -- TODO: allow disabling devDependencies through flags
    return
  end


end
