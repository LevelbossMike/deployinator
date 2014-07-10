RedisAdapter = require('./adapters/redis_adapter')
git          = require('gitty')

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
    key = @_getKey()

    @adapter.deployBootstrapCode(key, value)
    @adapter.updateManifest(@manifest, key)
    @adapter.cleanUpManifest(@manifest, @manifestSize)

  listDeploys: (limit = @manifestSize) ->
    @adapter.listDeploys(@manifest, limit)

  # Internal: Gets the current time as a UnixTimestamp and sets it as the
  # timestamp property on this {Object}.
  _getKey: ->
    @key = null
    cmd  = new git.Command('./', 'rev-parse', [], 'HEAD')

    cmd.exec(@_sliceGitSHA.bind(@))

    @key

  # Internal: Callback function that gets called when git commands execs. Git
  # command gets executed with the 'Gitty' node-module. See
  # https://github.com/gordonwritescode/gitty for details.
  #
  # _error - Error that gets passed when gitty call fails
  # sha - stdout message that gets passed when git-rev-Command succeeds
  # _stderr - stderr message that gets passen when git-rev command fails
  #
  # Returns a String.
  _sliceGitSHA: (_error, sha, _stderr) ->
    @key = sha.slice(0,6)
