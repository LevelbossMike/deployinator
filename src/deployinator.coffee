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
    new RSVP.Promise(@_uploadIfNotAlreadyInManifest(key, value).bind(@))

  listUploads: (limit = @manifestSize) ->
    @adapter.listUploads(@manifest, limit)

  setCurrent: (key) ->
    new RSVP.Promise(@_setCurrentIfKeyInManifest(key).bind(@))

  getCurrent: ->
    @adapter.get(@_currentKey())

  # Internal: Uploads the passed key/value pair to the store via the adapter.
  # This method returns a {Function} that will reject if the passed key is
  # already included in the manifest. If the key is not included in the
  # manifest it will upload the key/value pair, clean up the manifest according
  # to the manifest-config and resolve with a {Promise} that resolves when the
  # adapter tasks are finished.
  #
  # key - The key the passed value should be stored with via the adapter.
  # value - The value to be stored in the store via the adapter.
  #
  # Returns a {Function}.
  _uploadIfNotAlreadyInManifest: (key, value) ->
    (resolve, reject) ->
      @listUploads().then ((keys) ->
        if keys.indexOf(key) == -1
          promises =
            upload: @adapter.upload(key, value)
            update: @adapter.updateManifest(@manifest, key)
            cleanup: @adapter.cleanUpManifest(@manifest, @manifestSize)

          resolve(RSVP.hash(promises))
        else
          reject()
      ).bind(@)

  # Internal: Sets <manifest>:current via the adapter. This method returns
  # a {Function} that will reject when the passed key is not included in the
  # manifest. When the passed key is included in the manifest it will set the
  # passed key as current and resolve.
  #
  # key - The key that should be set as current on the manifest.
  #
  # Returns a {Function}.
  _setCurrentIfKeyInManifest: (key) ->
    (resolve, reject) ->
      @adapter.listUploads(@manifest, @manifestSize).then ((keys) ->
        if keys.indexOf(key) == -1
          reject()
        else
          @adapter.upload(@_currentKey(), key).then -> resolve()
      ).bind(@)

  # Internal: Gets the current git-sha and sets it as the key property on this
  # {Object}
  _getKey: ->
    @key = null
    cmd  = new git.Command('./', 'rev-parse', [], 'HEAD')

    cmd.exec(@_generateKey.bind(@), useSync = true)

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
  _generateKey: (_error, sha, _stderr) ->
    @key = "#{@manifest}:#{sha.slice(0,7)}"

  _currentKey: ->
    @currentKey = @currentKey ? "#{@manifest}:current"
