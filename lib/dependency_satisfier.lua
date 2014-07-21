local fs = require('fs')
local childprocess = require('childprocess')
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
  print(data.module_name .. '    ' .. data.repo_url)
  local module = resolve.resolve_package(data.module_name, process.cwd())

  local childDependencies = function()
    if module and module.package then
      -- recursively satisfy this modules' dependencies
      local dependencies = Dependencies:new(module.package, self.enable_dev)
      local dependencySatisifer = DependencySatisfier:new(self.enable_dev)
      DependencySatisfier:once('finish', calllback)
      dependencies:pipe(dependencySatisfier)
    else
      -- no need to further deal with dependencies
      callback()
    end
  end

  if module ~= nil then -- module already exists
    -- TODO: check version
    childDependencies()
  else -- module doesn't not exist yet
    -- make sure tmp dir is there
    local tmp_dir = path.join(process.cwd(), '.pkg_tmp')
    if not fs.existsSync(tmp_dir) then
      fs.mkdirSync(tmp_dir, '755')
      -- TODO: mkdirSync crashes the process if there's no permission
    end

    local repo_tmp_dir = path.join(tmp_dir, data.module_name)
    if type(data.repo_url) ~= 'string' then
      -- not suporrted for now
      callback() -- callback for Writable to continue to next one
      return
    end
    clone_repo(data.repo_url, repo_tmp_dir, function(err)
      if err then
        print('Warning: git clone exits with non-zero exit code: ' .. tostring(err))
      end

      module = resolve.resolve_package(repo_tmp_dir, process.cwd())
      if module == nil then
        -- cloned repo not there; something's wrong
        callback() -- callback for Writable to continue to next one
        return
      end

      -- move/rename repo to the right place
      local repo_dir
      if module.package and type(module.package.name) == 'string' then
        repo_dir = path.join(process.cwd(), 'modules', module.package.name)
      else
        repo_dir = path.join(process.cwd(), 'modules', data.module_name)
      end
      fs.renameSync(repo_tmp_dir, repo_dir)
      childDependencies()
    end)
  end

end

function clone_repo(repo_url, repo_tmp_dir, callback)
  local tmpl = stream_fs.ReadStream:new(path.join(__dirname, 'tmpl', 'clone.tmpl'))
  local context = template({repo_url = repo_url, path = repo_path})
  local concat = stream.Concat:new()
  concat:string(function(data)
    childprocess.execFile('bash', {'-c', data}, nil, callback)
  end)
  tmpl:pipe(context):pipe(concat)
end

return DependencySatisfier
