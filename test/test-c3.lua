require "busted.runner" ()

local assert = require "luassert"

describe ("the c3 module", function ()

  it ("can be required", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
    end)
  end)

  it ("can be instantiated", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      c3 = C3.new {
        superclass = function (x) return x end,
      }
    end)
  end)

  it ("runs on the Wikipedia example", function ()
    local o  = {}
    local a  = { o, }
    local b  = { o, }
    local c  = { o, }
    local d  = { o, }
    local e  = { o, }
    local k1 = { c, b, a, }
    local k2 = { e, b, d, }
    local k3 = { d, a, }
    local z  = { k3, k2, k1, }
    local C3 = require "c3"
    c3 = C3.new {
      superclass = function (x) return x end,
    }
    assert.are.same (c3 (o ), { o, })
    assert.are.same (c3 (a ), { o, a, })
    assert.are.same (c3 (b ), { o, b, })
    assert.are.same (c3 (c ), { o, c, })
    assert.are.same (c3 (d ), { o, d, })
    assert.are.same (c3 (e ), { o, e, })
    assert.are.same (c3 (k1), { o, c, b, a, k1, })
    assert.are.same (c3 (k2), { o, e, b, d, k2, })
    assert.are.same (c3 (k3), { o, a, d, k3, })
    assert.are.same (c3 (z ), { o, e, c, b, a, d, k3, k2, k1, z, })
  end)

  it ("handles cycles", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      c3 = C3.new {
        superclass = function (x) return x end,
      }
      local a, b = {}, {}
      a [1] = b
      b [1] = a
      assert.are.same (c3 (a), { b, a, })
      assert.are.same (c3 (b), { a, b, })
    end)
  end)

  it ("reports an error in case of conflicting orders", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      c3 = C3.new {
        superclass = function (x) return x end,
      }
      local a, b = {}, {}
      a [1] = b
      b [1] = a
      local c = { a, b, }
      local assert = require "luassert"
      local ok, err = pcall (c3, c)
      assert.is_falsy  (ok)
      assert.is_truthy (err:match "linearization failed")
    end)
  end)

  it ("allows to clear the cache", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      c3 = C3.new {
        superclass = function (x) return x end,
      }
      c3:clear ()
    end)
  end)

end)
