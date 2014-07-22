local childprocess = require('childprocess')
local core = require('core')
local stream = require('stream')

local Process = core.Emitter:extend()
function Process:initialize()
  self._uv_process = nil
  self.stdin = stream.Writable:new()
  self.stdout = stream.Readable:new()
  self.stderr = stream.Readable:new()
end

function wrap_readable(uv_readable, readable)
  readable:wrap(uv_readable)
end

function wrap_writable(uv_writable, writable)
  writable._write = function(self, data, encoding, callback)
    uv_writable:write(data, callback)
  end
  writable:once('finish', function()
    uv_writable:close()
  end)
end

function relay_events(proc, events)
  for k,v in pairs(events) do
    proc._uv_process:on(v, function(...)
      proc:emit(v, ...)
    end)
  end
end

return function(command, args, options)
  local proc = Process:new()

  proc._uv_process = childprocess.spawn(command, args, options)

  wrap_writable(proc._uv_process.stdin, proc.stdin)
  wrap_readable(proc._uv_process.stdout, proc.stdout)
  wrap_readable(proc._uv_process.stderr, proc.stderr)
  relay_events(proc, {'exit'})

  return proc
end
