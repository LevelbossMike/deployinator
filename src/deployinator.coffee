RedisAdapter = require('./adapters/redis_adapter')

module.exports = class Deploy

  # Public: Constructor function for the Deploy class. Deploy needs an adapter
  # to `know` which document-store to deploy to. When not passing an adapter
  # explicitly this will assume you want to use the RedisAdapter.
  #
  # options - The options
  #           :storeConfig - Connection options for the store to deploy to.
  #           :manifest - The name of the manifest
  #           :manifestSize - {Number} of deploys to keep in manifest
  #
  # Examples
  #
  # options =
  #   storeConfig: { host: 'localhost', port: 6379 }
  #   manifest: 'runtastic'
  #   manifestSize: 10
  #
  # deploy = new Deploy(options)
  #
  # Returns an {Object}.
  constructor: (options) ->
    @adapter      = options.adapter ? new RedisAdapter(options.storeConfig)
    @manifest     = options.manifest
    @manifestSize = options.manifestSize

  deploy: (value) ->
    timestamp = @_getTimestamp()

    @adapter.deployBootstrapCode(timestamp, value)
    @adapter.updateManifest(@manifest, timestamp)
    @adapter.cleanUpManifest(@manifest, @manifestSize)

  listDeploys: (limit = @manifestSize) ->
    @adapter.listDeploys(@manifest, limit)

  # Internal: Gets the current time as a UnixTimestamp and sets it as the
  # timestamp property on this {Object}.
  _getTimestamp: ->
    new Date().getTime()
