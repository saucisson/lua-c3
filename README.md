[![Build status](https://travis-ci.org/saucisson/lua-c3.svg?branch=master)](https://travis-ci.org/saucisson/lua-c3)
[![Coverage Status](https://coveralls.io/repos/saucisson/lua-c3/badge.svg?branch=master&service=github)](https://coveralls.io/github/saucisson/lua-c3?branch=master)
[![Chat](https://badges.gitter.im/saucisson/lua-c3.svg)](https://gitter.im/saucisson/lua-c3?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# C3 superclass linearization

This module is an implementation in Lua of the
[C3 linearization algorithm](http://en.wikipedia.org/wiki/C3_linearization).

It extracts super classes with a user-defined function,
and handles cycles.

The `superclass` function takes as input a class, and returns its direct
superclasses, from the lowest to the highest priority.
The C3 function returns a linearization of the classes, also from
the lowest to the highest priority. These orders differ from the one used in
the [Wikipedia](http://en.wikipedia.org/wiki/C3_linearization) article,
but they allow an efficient implementation.

## Install

This module is available in [luarocks](https://luarocks.org):
````sh
    luarocks install c3
````

## Example

First, require this module and create an instance of the algorithm
using your own `superclass` function.

Here, we simply use the identity function for `superclass`: the superclasses
are stored within the class, from `1` (the lowest priority) to `n` (the
highest priority).

````lua
    C3 = require "c3"
    c3 = C3.new {
      superclass = function (x) return x end,
    }
````

Then, build the class hierarchy. Here, we follow the example given in
[Wikipedia](http://en.wikipedia.org/wiki/C3_linearization). We check that
linearization works as expected:

````lua
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
    local assert = require "luassert"
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
````

## Cycles

Cycles can occur in a class hierarchy. They are handled as expected,
by cutting the `superclass` search when a class has already been encountered.

````lua
    local a, b = {}, {}
    a [1] = b
    b [1] = a
    local assert = require "luassert"
    assert.are.same (c3 (a), { b, a, })
    assert.are.same (c3 (b), { a, b, })
````

## Errors

Linearization can fail sometimes, but it is quite difficult to get in such
cases. The example below creates an error, because we try to linearize
a class `c` with two superclasses with conflicting orders.

````lua
    local a, b = {}, {}
    a [1] = b
    b [1] = a
    local c = { a, b, }
    local assert = require "luassert"
    local ok, err = pcall (c3, c)
    assert.is_falsy  (ok)
    assert.is_truthy (err:match "linearization failed")
````

## Caching

Linearization uses a cache, that is by default reused between calls.
It can be emptied using the `clear` method.

````lua
    c3:clear ()
````

# Test

Tests are written for [busted](http://olivinelabs.com/busted).
```bash
  busted src/
```
