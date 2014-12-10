return {
  name = "pkg",
  version = "0.1.0",
  description = "a package manager for luvit",
  repository = {
    url = "https://github.com/virgo-agent-toolkit/luvit-pkg.git",
  },
  author = {
    name = "Song Gao",
    email = "song@gao.io",
    url = "https://song.gao.io",
  },
  contributors = {
    {
      name = "Robert Chiniquy",
      email = "robert.chiniquy@rackspace.com",
      url = "https://robert-chiniquy.github.io/",
    },
    {
      name = "Ryan Phillips",
      email = "ryan.phillips@rackspace.com",
      url = "http://trolocsis.com/",
    },
    {
      name = "Rob Emanuele",
      email = "rje@ieee.org",
      url = "http://rob.emanuele.us/",
    },
  },
  licenses = {"Apache-2.0"},
  dependencies = {
    ["stream"] = "https://github.com/virgo-agent-toolkit/luvit-stream",
    ["stream-fs"] = "https://github.com/virgo-agent-toolkit/luvit-stream-fs",
    ["template-stream"] = "https://github.com/virgo-agent-toolkit/luvit-template-stream",
    ["resolve"] = "https://github.com/virgo-agent-toolkit/luvit-resolve",
  },
  devDependencies = {
    ["tape"] = "https://github.com/virgo-agent-toolkit/luvit-tape",
  },
  main = 'init.lua',
}
