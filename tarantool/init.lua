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

local bl = box.space['blacklists']
local caps = box.space['caps']
local limit1 = box.space['limit1']
local limit24 = box.space['limit24']

local function check_caps(feeds, caps)
    local res = {}
    for feed, v in pairs(feeds) do
        local cap = caps:select(0, feed)
        if cap ~= nil then
            if cap[1] < cap[2] then
                res[feed] = true 
            end
        end
    end
    for feed, v in pairs(res) do
        feeds[feed] = nil
    end
end

local function update_caps(feeds)
-- update time
    for k, v in pairs(feeds) do
        caps:update(k, "+p", 1, 1)
        limit1:update(k, "+p", 1, 1)
        limit24:update(k, "+p", 1, 1)
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
    local time1 = box.time()
    while true do
        local time1 = box.time()
        for k,v in pairs(all_feeds) do
            space:update(k, "=p", 1, 0)
        end
        print("Purged "..space.name)
        local time2 = box.time()
        local totaltime = time2 - time1
        time = time2
        if totaltime < period then
            box.fiber.sleep(period - totaltime)
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

function bench(wl)
    for k, v in pairs(wl) do
        feeds(v:unpack())
    end
end
