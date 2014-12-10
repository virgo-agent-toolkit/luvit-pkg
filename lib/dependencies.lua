local stream = require('stream')
local table = require('table')

local Dependencies = stream.Readable:extend()
-- Dependencies is a Readable stream that emits the dependencies
-- of a package
-- meta is the meta object in package.lua of the package (module)
function Dependencies:initialize(meta, enable_dev)
  stream.Readable.initialize(self, {objectMode = true})

  self.deps = {}
  self.enable_dev = enable_dev or false

  local addDeps = function(deps_table)
    if type(deps_table) == 'table' then
      for k,v in pairs(meta.dependencies) do
        if type(k) == 'number' then
          table.insert(self.deps, {module_name = v, repo_url = nil})
        elseif type(k) == 'string' then
          table.insert(self.deps, {module_name = k, repo_url = v})
        end
      end
    end
  end
  addDeps(meta.dependencies)
  if self.enable_dev then
    addDeps(meta.devDependencies)
  end

  self.p = 1
end

function Dependencies:_read(n)
  for i = 1,n do
    if self.deps and self.p <= #self.deps then
      self:push(self.deps[i])
      self.p = self.p + 1
    else
      self:push(nil)
    end
  end
end

return Dependencies
