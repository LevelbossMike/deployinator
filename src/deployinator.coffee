RedisAdapter = require('./adapters/redis_adapter')
git          = require('gitty')
RSVP         = require('rsvp')

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

  upload: (value) ->
    key = @_getKey()

    @adapter.upload(key, value)
    @adapter.updateManifest(@manifest, key)
    @adapter.cleanUpManifest(@manifest, @manifestSize)

  listUploads: (limit = @manifestSize) ->
    @adapter.listUploads(@manifest, limit)

  setCurrent: (key) ->
    adapter      = @adapter
    manifest     = @manifest
    manifestSize = @manifestSize
    currentKey   = @_currentKey()

    new RSVP.Promise (resolve, reject) ->
      adapter.listUploads(manifest, manifestSize).then (keys) ->
        if keys.indexOf(key) == -1
          reject()
        else
          adapter.upload(currentKey, key).then -> resolve()

  getCurrent: ->
    @adapter.get(@_currentKey())

  # Internal: Gets the current git-sha and sets it as the key property on this
  # {Object}
  _getKey: ->
    @key = null
    cmd  = new git.Command('./', 'rev-parse', [], 'HEAD')

    cmd.exec(@_sliceGitSHA.bind(@), useSync = true)

    @key

  # Internal: Callback function that gets called when git commands execs. Git
  # command gets executed with the 'Gitty' node-module. See
  # https://github.com/gordonwritescode/gitty for details.
  #
  # _error - Error that gets passed when gitty call fails
  # sha - stdout message that gets passed when git-rev-Command succeeds
  # _stderr - stderr message that gets passen when git-rev command fails
  #
  # Returns a {String}.
  _sliceGitSHA: (_error, sha, _stderr) ->
    @key = sha.slice(0,7)

  _currentKey: ->
    @currentKey = @currentKey ? "#{@manifest}:current"
