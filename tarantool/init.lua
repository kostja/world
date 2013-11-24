--
-- Blacklists
--
dofile('db.lua')
dofile('feeds.lua')

local function merge(t1, t2, fieldno)
    for k,v in pairs(t2) do
        t1[v[fieldno]] = true
    end
end

local function minus(t1, t2)
    if t2 == nil then
        return t1
    end
    local res = {}
    for k,v in pairs(t1) do 
        if t2[k] == nil then
            res[k] = v
        end
    end
    return res 
end

all_feeds = {}
merge(all_feeds, { box.space['feeds']:select(0) }, 0)

all_tasks = {}

for v in box.space['workload'].index[0]:iterator(box.index.ALL) do
    table.insert(all_tasks, {v:slice(1, 7)})
end

local bl = box.space['blacklists']
local caps = box.space['caps']
local limit1 = box.space['limit1']
local limit24 = box.space['limit24']

has_caps = {}
merge(has_caps, { caps:select_range(0, caps:len()) }, 0)

has_limit1 = {}
merge(has_limit1, { limit1:select_range(0, limit24:len()) }, 0)

has_limit24 = {}
merge(has_limit24, { limit24:select_range(0, limit24:len()) }, 0)

local function check_caps(feeds, caps)
    local res = {}
    local caps_out = {}
    for feed, v in pairs(feeds) do
        local cap = caps:select(0, feed)
        if cap ~= nil then
            if cap[1] > cap[2] then
                res[feed] = true 
            end
        end
    end
    for feed, v in pairs(res) do
        feeds[feed] = nil
    end
end

local function update_caps(feeds)
    for feed, v in pairs(feeds) do
        if has_caps[feed] then
            caps:update(feed, "+p", 1, 1)
        end
        if has_limit1[feed] then
            limit1:update(feed, "+p", 1, 1)
        end
        if has_limit24[feed] then
            limit24:update(feed, "+p", 1, 1)
        end
    end
end

function rtb(city, keyword, country, region, referer, useragent)
    local feeds = {}
    merge(feeds, { bl:select(0, 'city', city) }, 2)
    merge(feeds, { bl:select(0, 'keyword', keyword) }, 2)
    merge(feeds, { bl:select(0, 'country', country) }, 2)
    merge(feeds, { bl:select(0, 'region', region) }, 2)
    merge(feeds, { bl:select(0, 'referer', referer) }, 2)
    merge(feeds, { bl:select(0, 'useragent', useragent) }, 2)
    feeds = minus(all_feeds, feeds)
    check_caps(feeds, caps)
    check_caps(feeds, limit1)
    check_caps(feeds, limit24)
    update_caps(feeds)
    return feeds
end

function reset_caps(space, period)
    print("Starting background cap purger for space '"..space.name..
          "' period "..period)
    box.fiber.name(space.name.." purger")
    local time2 = box.time()
    local all_caps = {}
    merge(all_caps, { space:select_range(0, space:len()) }, 0)
    while true do
        local time1 = time2
        for k,v in pairs(all_caps) do
            space:update(k, "=p", 1, 0)
        end
        print("Purged "..space.name)
        time2 = box.time()
        local totaltime = time2 - time1
        if totaltime < period then
            box.fiber.sleep(period - totaltime)
            time2 = time2 + period - totaltime 
        end
    end
end

local function bgstop1(name)
    if _G[name] ~= nil then
        box.fiber.cancel(_G[name])
        _G[name] = nil
    end
end

local function bgstart1(name, space, period)
    bgstop1(name)
    _G[name] = box.fiber.wrap(reset_caps, space, period)
end

function bgstart()
    bgstart1('caps_purger', caps, 1)
    bgstart1('limit1_purger', limit1, 3600)
    bgstart1('limit24_purger', limit24, 86400)
end

function bgstop()
    bgstop1('caps_purger')
    bgstop1('limit1_purger')
    bgstop1('limit24_purger')
end

requests = 0

local function bench1(wl, id)
    box.fiber.name("bench "..id)
    local len = 0
    for k, v in pairs(wl) do
        rtb(unpack(v))
        box.fiber.sleep(0)
        requests = requests + 1
    end
end

local function measure()
    box.fiber.name("RPS measure")
    while true do
        local old_requests = requests
        box.fiber.sleep(1)
        print("RPS: "..requests - old_requests)
    end
end

function bench(fibers)
    for i = 1,fibers do
        box.fiber.wrap(bench1, all_tasks, i)
    end
    box.fiber.wrap(measure)
end
