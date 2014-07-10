redis = require('then-redis')

module.exports = class RedisAdapter
  constructor: (options) ->
    @client = redis.createClient(options)

  uploadBootstrapCode: (timestampKey, bootstrapFile) ->
    @client.set(timestampKey, bootstrapFile)

  updateManifest: (manifest, timestampKey) ->
    @client.lpush(manifest, timestampKey)

  cleanUpManifest: (manifest, manifestSize) ->
    @client.ltrim(manifest, 0, manifestSize - 1)

  listUploads: (manifest, limit) ->
    @client.lrange(manifest, 0, limit - 1)
