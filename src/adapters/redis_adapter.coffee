redis = require('then-redis')

module.exports = class RedisAdapter
  constructor: (options) ->
    @client = redis.createClient(options)

  upload: (key, value) ->
    @client.set(key, value)

  updateManifest: (manifest, key) ->
    @client.lpush(manifest, key)

  cleanUpManifest: (manifest, manifestSize) ->
    @client.ltrim(manifest, 0, manifestSize - 1)

  listUploads: (manifest, limit) ->
    @client.lrange(manifest, 0, limit - 1)

  get: (key) ->
    @client.get(key)
