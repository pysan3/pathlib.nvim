#!/usr/bin/env bash
#
# Run local tests for lua using luarocks and busted extension
# with neovim as the runtime environment.

set -ex

BUSTED_VERSION="2.2.0-1"
luarocks init
luarocks install --only-deps ./pathlib.nvim-scm-1.rockspec
luarocks install busted "$BUSTED_VERSION"
luarocks config --scope project lua_version 5.1
nvim -u NONE \
  -c "lua package.path='lua_modules/share/lua/5.1/?.lua;lua_modules/share/lua/5.1/?/init.lua;'..package.path;package.cpath='lua_modules/lib/lua/5.1/?.so;'..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('busted','$BUSTED_VERSION')" \
  -l "lua_modules/lib/luarocks/rocks-5.1/busted/$BUSTED_VERSION/bin/busted" "$@"
