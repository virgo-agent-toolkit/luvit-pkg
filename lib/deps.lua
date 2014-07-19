local fs = require('fs')
local path = require('path')
local resolve = require('resolve')
local template = require('template-stream')
local stream_fs = require('stream-fs')

local utils = require('./utils')


function clone_repo(repo_url, repo_path)
  local tmpl = fs.ReadStream(path.join(__dirname, 'tmpl', 'clone.tmpl'))
  local context = template({repo_url = repo_url, path = repo_path})
  -- TODO clone the repo: we probably need a wrapper to childprocess.spawn that
  -- exposes stream interface?
end

-- returns true if module exists or is successfully installed
-- also makes sure dpes of the module is satisfied
function ensure_dep(module_name, repo_url)
  local module = resolve.resolve_package(module_name, process.cwd())
  if module ~= nil then
    -- module already exists
    -- TODO: check version
  else
    local tmp_dir = path.join(process.cwd(), '.pkg_tmp')
    if not fs.existsSync(tmp_dir) then
      fs.mkdirSync(tmp_dir)
      -- TODO: mkdirSync crashes the process if there's no permission
    end

    local repo_tmp_dir = path.join(tmp_dir, module_name)
    if type(repo_url) ~= 'string' then
      -- not suporrted for now
      return false
    end
    clone_repo(repo_url, repo_tmp_dir)

    local module = resolve.resolve_package(repo_tmp_dir, process.cwd())
    if module == nil then
      -- cloned repo not there; something's wrong
      return false
    end

    -- move/rename repo to the right place
    local repo_dir
    if module.meta and type(module.meta.name) == 'string' then
      repo_dir = path.join(process.cwd(), 'modules', module.meta.name)
    else
      repo_dir = path.join(process.cwd(), 'modules', module_name)
    end
    fs.renameSync(repo_tmp_dir, repo_dir)
  end

  -- recursively satisfy dep's deps
  local meta = utils.get_package_lua(path.join(repo_dir))
  if meta then
    return ensure_deps(meta, enable_dev)
  else
    return true
  end
end

function ensure_deps(meta, enable_dev)
  if meta.dependencies then
    for k,v in pairs(meta.dependencis) do
    end
  end

  if enable_dev and meta.devDependencies then
  end
end

local exports = {}
exports.ensure_deps = ensure_deps
return exports
