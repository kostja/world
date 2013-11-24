--
-- Blacklists
--
if box.space['blacklists'] == nil then 
    box.schema.create_space('blacklists')
    feeds = box.space['blacklists']
    feeds:create_index('primary', 'tree', { parts = { 0, 'str', 1, 'str', 2, 'str' } })
end

if box.space['caps'] == nil then
    box.schema.create_space('caps')
    caps = box.space['caps']
    caps:create_index('primary', 'hash', { parts = { 0, 'str' } })
end

if box.space['limit1'] == nil then
    box.schema.create_space('limit1')
    limit1 = box.space['limit1']
    limit1:create_index('primary', 'hash', { parts = { 0, 'str' } })
end

if box.space['limit24'] == nil then
    box.schema.create_space('limit24')
    limit24 = box.space['limit24']
    limit24:create_index('primary', 'hash', { parts = { 0, 'str' } })
end

if box.space['workload'] == nil then
    box.schema.create_space('workload')
    wl = box.space['workload']
    wl:create_index('primary', 'tree', { parts = { 0, 'num' } })
end
