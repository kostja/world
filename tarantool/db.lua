--
-- Blacklists
--
box.schema.create_space('blacklists')
feeds = box.space['blacklists']
feeds:create_index('primary', 'tree', { parts = { 0, 'str', 1, 'str', 2, 'str' } })

box.schema.create_space('caps')
caps = box.space['caps']
caps:create_index('primary', 'hash', { parts = { 0, 'str' } })

box.schema.create_space('limit1')
limit1 = box.space['limit1']
limit1:create_index('primary', 'hash', { parts = { 0, 'str' } })

box.schema.create_space('limit24')
limit24 = box.space['limit24']
limit24:create_index('primary', 'hash', { parts = { 0, 'str' } })
