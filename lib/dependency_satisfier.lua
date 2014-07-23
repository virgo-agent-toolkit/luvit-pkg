local fs = require('fs')
local spawn = require('./spawn')
local path = require('path')
local resolve = require('resolve')
local template = require('template-stream')
local stream_fs = require('stream-fs')
local stream = require('stream')

local Dependencies = require('./dependencies')

local DependencySatisfier = stream.Writable:extend()
function DependencySatisfier:initialize(enable_dev)
  stream.Writable.initialize(self, {objectMode = true})
  self.enable_dev = enable_dev
end

function DependencySatisfier:_write(data, encoding, callback)
  local module = resolve.resolve_package(data.module_name, process.cwd())

  local childDependencies = function(callback)
    if module and module.package then
      -- recursively satisfy this modules' dependencies
      local dependencies = Dependencies:new(module.package, self.enable_dev)
      local dependencySatisfier = DependencySatisfier:new(self.enable_dev)
      dependencySatisfier:once('finish', callback)
      dependencies:pipe(dependencySatisfier)
    else
      -- no need to further deal with dependencies
      process.nextTick(callback)
    end
  end

  if module ~= nil then -- module already exists
    -- TODO: check version
    childDependencies(callback)
  else -- module doesn't not exist yet
    -- make sure modules dir is there
    local modules_dir = path.join(process.cwd(), 'modules')
    if not fs.existsSync(modules_dir) then
      local success, err_msg = pcall(fs.mkdirSync, modules_dir, '755')
      if not success then
        -- probably lack of permission
        print(tostring(err_msg))
        process.exit(1)
      end
    end

    if type(data.repo_url) ~= 'string' then
      print('Package ' .. data.module_name .. ' does not exist but no repo url is provided.')
      callback()
      return
    end
    print('Cloning ' .. data.module_name .. ' from ' .. tostring(data.repo_url))
    local repo_dir = path.join(process.cwd(), 'modules', data.module_name)
    clone_repo(data.repo_url, repo_dir, function(exit_code)
      if exit_code and exit_code ~= 0 then
        print('Warning: git clone exits with non-zero exit code: ' .. tostring(exit_code))
      end

      module = resolve.resolve_package(repo_dir, process.cwd())
      if module == nil then
        -- cloned repo not there; something's wrong
        callback() -- callback for Writable to continue to next one
        return
      end

      childDependencies(callback)
    end)
  end

end

function clone_repo(repo_url, repo_dir, callback)
  local tmpl = stream_fs.ReadStream:new(path.join(__dirname, 'tmpl', 'clone.tmpl'))
  local context = template({repo_url = repo_url, path = repo_dir})
  local stdio_writer = stream.Writable:new()
  local proc = spawn('bash', nil, nil)
  tmpl:pipe(context):pipe(proc.stdin)
  proc:on('exit', callback)
end

return DependencySatisfier
