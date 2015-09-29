local C3 = {}

C3.__index = C3

function C3.new (options)
  assert (type (options) == "table")
  assert (options.superclass)
  -- Check that superclass is callable:
  do
    local ok, err = pcall (options.superclass)
    if not ok and err:match "^attempt to call" then
      error "superclass is neither a function nor a callable table"
    end
  end
  return setmetatable ({
    options = options,
    cache   = setmetatable ({}, { __mode = "k" })
  }, C3)
end

function C3.clear (c3)
  assert (getmetatable (c3) == C3)
  c3.cache = setmetatable ({}, { __mode = "k" })
  return c3
end

function C3.__call (c3, x)
  assert (getmetatable (c3) == C3)
  local unpack     = table.unpack or unpack
  local superclass = c3.options.superclass
  local seen       = {}
  local function linearize (t)
    local cached = c3.cache [t]
    if cached then
      return cached
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
    c3.cache [t] = result
    return result
  end
  return linearize (x)
end

return C3
