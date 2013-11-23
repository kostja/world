
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

function feeds(city, keyword, country, region, referer, useragent)
    local bl = box.space['blacklists']
    local feeds = field({ bl:select(1, 'city', city) }, 0)
    merge(feeds, field({ bl:select(1, 'keyword', keyword) }, 0))
    merge(feeds, field({ bl:select(1, 'country', country) }, 0))
    merge(feeds, field({ bl:select(1, 'region', region) }, 0))
    merge(feeds, field({ bl:select(1, 'referer', referer) }, 0))
    merge(feeds, field({ bl:select(1, 'useragent', useragent) }, 0))
    return minus(all_feeds, feeds)
end

function bench(wl)
    for k, v in pairs(wl) do
        feeds(v:unpack())
    end
end
