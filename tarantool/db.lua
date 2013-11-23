--
-- Feeds
--
box.schema.create_space('blacklists')
feeds = box.space['blacklists']
feeds:create_index('primary', 'tree', { parts = { 0, 'str', 1, 'str', 2, 'str' } })

