pcall(require, "luacov")


print("------------------------------------")
print("Lua version: " .. (jit and jit.version or _VERSION))
print("------------------------------------")
print("")

local HAS_RUNNER = not not lunit
local lunit = require "lunit"
local TEST_CASE = lunit.TEST_CASE

local LUA_VER = _VERSION
local unpack, pow, bit32 = unpack, math.pow, bit32

local _ENV = TEST_CASE"test_travis_running_lua"

function test_1()
  assert_false(false)
end

if not HAS_RUNNER then lunit.run() end
