--
-- Feeds
--
--
box.schema.create_space('feeds')
feeds = box.space['feeds']
feeds:create_index('primary', 'tree', { parts = { 0, 'num' } })

-- 
-- List types - whitelists/blacklists
--
box.schema.create_space('lists', { if_not_exists = true })

lists = box.space['lists']

lists:create_index('primary', 'hash', { parts = { 0, 'str' } })

lists:insert(1, 'city')
lists:insert(2, 'country')
lists:insert(3, 'useragent')
lists:insert(4, 'keyword')
lists:insert(5, 'referer')
lists:insert(6, 'subaccount')
lists:insert(7, 'publisher')

-- 
-- All whitelists
--

box.schema.create_space('global_whitelists')

-- feed id, list id
global_whitelists:create_index('primary', 'hash', { parts = { 0, 'num', 1, 'num' } })

-- 
-- All blacklists
-- 
box.schema.create_space('global_blacklists')

blobal_blacklists = box.space['global_blacklists']

global_blacklists:create_index('primary', 'hash',
                               { parts = { 0, 'num', 1, 'num' } })

-- 
-- Global limits
--
box.schema.create_space('daily_limits')

daily_limits = box.schema['daily_limits']

-- feed_id/publisher_id, date
daily_limits:create_index('primary', 'hash',
                               { parts = { 0, 'num', 1, 'num' } })

