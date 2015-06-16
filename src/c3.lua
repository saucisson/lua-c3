-- C3 superclass linearization
-- ===========================

-- This module is an implementation in Lua of the
-- [C3 linearization algorithm](http://en.wikipedia.org/wiki/C3_linearization).
--
-- It extracts super classes with a user-defined function,
-- and handles cycles.
--
-- The `superclass` function takes as input a class, and returns its direct
-- superclasses, from the lowest to the highest priority.
-- The C3 function returns a linaerization of the classes, also from
-- the lowest to the highest priority.
-- These orders differ from the one used in the Wikipedia article,
-- but it allows an efficient implementation.

local C3    = {}
local Cache = {}
Cache.__mode      = "k"

-- Example
-- -------
--
-- First, require this module and create an instance of the algorithm
-- using your own `superclass` function.
--
-- Here, we simply use the identity function for `superclass`: the superclasses
-- are stored within the class, from `1` (the lowest priority) to `n` (the
-- highest priority).
--
--     > C3 = require "c3"
--     > c3 = C3.new {
--     >   superclass = function (x) return x end,
--     > }
--
-- Then, build the class hierarchy. Here, we follow the example given in
-- [Wikipedia](http://en.wikipedia.org/wiki/C3_linearization). We check that linearization works as expected:
--
--     > local o  = {}
--     > local a  = { o, }
--     > local b  = { o, }
--     > local c  = { o, }
--     > local d  = { o, }
--     > local e  = { o, }
--     > local k1 = { c, b, a, }
--     > local k2 = { e, b, d, }
--     > local k3 = { d, a, }
--     > local z  = { k3, k2, k1, }
--     > local assert = require "luassert"
--     > assert.are.same (c3 (o ), { o, })
--     > assert.are.same (c3 (a ), { o, a, })
--     > assert.are.same (c3 (b ), { o, b, })
--     > assert.are.same (c3 (c ), { o, c, })
--     > assert.are.same (c3 (d ), { o, d, })
--     > assert.are.same (c3 (e ), { o, e, })
--     > assert.are.same (c3 (k1), { o, c, b, a, k1, })
--     > assert.are.same (c3 (k2), { o, e, b, d, k2, })
--     > assert.are.same (c3 (k3), { o, a, d, k3, })
--     > assert.are.same (c3 (z ), { o, e, c, b, a, d, k3, k2, k1, z, })

-- Cycles
-- ------
--
-- Cycles can occur in a class hierarchy. They are handled as expected,
-- by cutting the `superclass` search when a class has already been encoutered.
--

--     > local a, b = {}, {}
--     > a [1] = b
--     > b [1] = a
--     > local assert = require "luassert"
--     > assert.are.same (c3 (a), { b, a, })
--     > assert.are.same (c3 (b), { a, b, })

-- Errors
-- ------
--
-- Linearization can fail sometimes, but it is quite difficult to get in such
-- cases. The example below creates an error, because we try to linearize
-- a class `c` with two superclasses with conflicting orders.

--     > local a, b = {}, {}
--     > a [1] = b
--     > b [1] = a
--     > local c = { a, b, }
--     > local assert = require "luassert"
--     > local ok, err = pcall (c3, c)
--     > assert.is_falsy  (ok)
--     > assert.is_truthy (err:match "linearization failed")

function C3.new (options)
  local superclass = options.superclass
  -- Check that superclass is callable:
  do
    local ok, err = pcall (superclass)
    if not ok and err:match "^attempt to call" then
      error "superclass is neither a function nor callable"
    end
  end
  local unpack = table.unpack or unpack
  -- Create cache:
  local cache = setmetatable ({}, Cache)
  -- Return the linearization function:
  return function (x)
    local seen = {}
    local function linearize (t)
      if options.cache then
        local cached = cache [t]
        if cached then
          return cached
        end
      end
      if seen [t] then
        return {}
      end
      seen [t] = true
      -- Prepare:
      local depends = superclass (t)
      local l, n = {}, {}
      if depends and #depends ~= 0 then
        depends = { unpack (depends) }
        for i = 1, #depends do
          depends [i] = depends [i]
        end
        l [#l+1] = depends
        n [#n+1] = #depends
        for i = 1, #depends do
          local linearized = linearize (depends [i], seen)
          if #linearized ~= 0 then
            local ll = {}
            for j = 1, #linearized do
              local z = linearized [j]
              if z ~= t then
                ll [#ll+1] = z
              end
            end
            l [#l+1] = ll
            n [#n+1] = # (l [#l])
          end
        end
      end
      l [#l+1] = { t }
      n [#n+1] = 1
      -- Compute tails:
      local tails = {}
      for i = 1, #l do
        local v = l [i]
        for j = 1, #v do
          local w   = v [j]
          tails [w] = (tails [w] or 0) + 1
        end
      end
      -- Compute linearization:
      local result = {}
      while #l ~= 0 do
        for i = #l, 1, -1 do
          local vl, vn   = l [i], n [i]
          local first    = vl [vn]
          local first_id = first
          tails [first_id] = tails [first_id] - 1
        end
        local head
        for i = #l, 1, -1 do
          local vl, vn   = l [i], n [i]
          local first    = vl [vn]
          local first_id = first
          if tails [first_id] == 0 then
            head = first
            break
          end
        end
        if head == nil then
          error "linearization failed"
        end
        result [#result + 1] = head
        for i = 1, #l do
          local vl, vn = l [i], n [i]
          local first  = vl [vn]
          if first == head then
            n [i] = n [i] - 1
          else
            local first_id = first
            tails [first_id] = tails [first_id] + 1
          end
        end
        local nl, nn = {}, {}
        for i = 1, #l do
          if n [i] ~= 0 then
            nl [#nl+1] = l [i]
            nn [#nn+1] = n [i]
          end
        end
        l, n = nl, nn
      end
      for i = 1, #result/2 do
        result [i], result [#result-i+1] = result [#result-i+1], result [i]
      end
      if options.cache then
        cache [t] = result
      end
      return result
    end
    return linearize (x)
  end
end

return C3