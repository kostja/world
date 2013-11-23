
function field(t1, fieldno)
    local res = {}
    if t1 ~= nil then
        for k,v in pairs(t1) do
            res[v] = true
        end
    end
end

function field(t1, fieldno)
    local res = {}
    if t1 ~= nil then
        for k, v in pairs(t1) do
            res[v[fieldno]] = true
        end
    end
    return res
end

function merge(t1, t2)
    if t1 ~= nil then
        for k,v in pairs(t1) do
            t2[k] = v
        end
    end
end

function minus(t1, t2)
    if t2 == nil then
        return t1
    end
    local res = {}
    for k,v in pairs(t1) do 
        if not t2[k]  then
            res[k] = v 
        end
    end
    return res 
end

all_feeds = field({ box.space['feeds']:select(0) }, 0)

caps = box.space['caps']
limit1 = box.space['limit1']
limit24 = box.space['limit24']

function check_caps(feeds)
    res = {}
    for feed, v in pairs(feeds) do
        cap = caps:select(0, feed)
        if cap[2] > cap[3] then
            res[feed] = true
        end
    end
    return res
end

function update_caps(feeds)
-- update time
    for k, v in pairs(feeds) do
        caps:update(k, "=p+p", 1, box.time(), 2, 1)
        limit1:update(k, "=p+p", 1, box.time(), 2, 1)
        limit24:update(k, "=p+p", 1, box.time(), 2, 1)
    end
end

function rtb(city, keyword, country, region, referer, useragent)
    local bl = box.space['blacklists']
    local feeds = field({ bl:select(0, 'city', city) }, 0)
    merge(feeds, field({ bl:select(0, 'keyword', keyword) }, 0))
    merge(feeds, field({ bl:select(0, 'country', country) }, 0))
    merge(feeds, field({ bl:select(0, 'region', region) }, 0))
    merge(feeds, field({ bl:select(0, 'referer', referer) }, 0))
    merge(feeds, field({ bl:select(0, 'useragent', useragent) }, 0))
    feeds = minus(all_feeds, feeds)
    feeds = minus(feeds, check_caps(feeds))
    return update_caps(feeds)
end

function bench(wl)
    for k, v in pairs(wl) do
        feeds(v:unpack())
    end
end
