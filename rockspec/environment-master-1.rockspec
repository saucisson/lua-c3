package = "environment"
version = "master-1"

source = {
  url    = "git+https://github.com/saucisson/lua-c3.git",
  branch = "master",
}

description = {
  summary     = "Development environment for c3",
  detailed    = [[]],
  license     = "MIT/X11",
  homepage    = "https://github.com/saucisson/lua-c3",
  maintainer  = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua >= 5.1",
  "busted",
  "cluacov",
  "luacheck",
  "luacov",
  "luacov-coveralls",
}

build = {
  type    = "builtin",
  modules = {},
}
