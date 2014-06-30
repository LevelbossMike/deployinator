expect      = require('expect.js')
redis       = require('then-redis')
timekeeper  = require('timekeeper')
Deploy      = require('../../../dist/deployinator.js')

REDIS_CONNECTION_OPTIONS = { host: 'localhost', port: 6379 }
DOCUMENT_TO_SAVE         = 'Hello'
MANIFEST                 = 'test-deploy-manifest'
MANIFEST_SIZE            = 10
TIMESTAMP                = 1403807574351
redisClient              = redis.createClient(REDIS_CONNECTION_OPTIONS)

options =
  storeConfig: REDIS_CONNECTION_OPTIONS
  manifest: MANIFEST
  manifestSize: MANIFEST_SIZE

deployWithTimestamp = (deploy, timestamp) ->
  time = new Date(timestamp)
  timekeeper.freeze(time)
  deploy.deploy(DOCUMENT_TO_SAVE)
  timekeeper.reset()

describe 'Deploy', ->

  deploy = new Deploy(options)

  describe '#deploy', ->

    beforeEach ->
      redisClient.del(MANIFEST)
      deployWithTimestamp(deploy, TIMESTAMP)

    it 'stores a passed value in Redis with the current unix-time as key', ->
      redisClient.get(TIMESTAMP)
        .then (value) ->
          expect(value).to.be(DOCUMENT_TO_SAVE)

    it 'updates a list of references of last deployments', ->
      redisClient.lrange(MANIFEST, 0, 10)
        .then (value) ->
          expect(value.length).to.be.greaterThan(0)

    it 'only keeps <manifestSize> revisions of deploys', ->
      moreThanManifestSize = MANIFEST_SIZE + 2
      for n in[1..moreThanManifestSize]
        deploy.deploy("i#{DOCUMENT_TO_SAVE}-#{n}")
      redisClient.lrange(MANIFEST, 0, moreThanManifestSize)
        .then (value) ->
          expect(value.length).to.be(MANIFEST_SIZE)

  describe '#listDeploys ', ->
    times = []

    beforeEach ->
      times = []
      redisClient.del(MANIFEST)
      for timestamp in [TIMESTAMP..(TIMESTAMP + MANIFEST_SIZE - 1)]
        times.push(timestamp)
        deployWithTimestamp(deploy, timestamp)

    it 'lists all the deploys stored in the deploy manifest', ->
      deploy.listDeploys()
        .then (values) ->
          expect(values).to.contain("#{timestamp}") for timestamp in times

    it 'lists the last n-deploys when passing a number n', ->
      deploy.listDeploys(5)
        .then (values) ->
          expect(values.length).to.be(5)
          expect(values[0]).to.be("#{times[times.length - 1]}")
