require "busted.runner" ()

local assert = require "luassert"

describe ("c3 algorithm implementation", function ()

  it ("can be required", function()
    assert.has.no.errors (function ()
      require "c3"
    end)
  end)

  it ("can be instantiated", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      C3 {
        superclass = function (x) return x end,
      }
    end)
  end)

  it ("detects non-callable superclass", function ()
    assert.has.error (function ()
      local C3 = require "c3"
      C3 {
        superclass = true,
      }
    end)
  end)

  it ("linearizes correctly a hierarchy", function ()
    local C3 = require "c3"
    local c3 = C3 {
      superclass = function (x) return x end,
    }
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
    local C3 = require "c3"
    local c3 = C3 {
      superclass = function (x) return x end,
    }
    local a, b = {}, {}
    a [1] = b
    b [1] = a
    assert.are.same (c3 (a), { b, a, })
    assert.are.same (c3 (b), { a, b, })
  end)

  it ("reports an error when linearization is not possible", function ()
    local C3 = require "c3"
    local c3 = C3 {
      superclass = function (x) return x end,
    }
    local a, b = {}, {}
    a [1] = b
    b [1] = a
    local c = { a, b, }
    local ok, err = pcall (c3, c)
    assert.is_falsy  (ok)
    assert.is_truthy (type (err) == "table")
  end)

  it ("allows to clear the cache", function ()
    assert.has.no.error (function ()
      local C3 = require "c3"
      local c3 = C3 {
        superclass = function (x) return x end,
      }
      c3:clear ()
    end)
  end)

end)
