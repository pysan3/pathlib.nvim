rockspec_format = "3.0"
package = "pathlib.nvim"
version = "scm-1"

dependencies = {
  "lua >= 5.1",
  "nvim-nio >= 1.2.0",
}

test_dependencies = {
  "lua >= 5.1",
  "nvim-nio >= 1.2.0",
}

source = {
  url = "git://github.com/pysan3/" .. package,
}

build = {
  type = "builtin",
}
