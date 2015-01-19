sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.ec2VolumesProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'ec2VolumesProvider', ->

		describe 'getResources', ->

			generateTestVolumes = (num) ->
				i = 0
				result = { Volumes: [] }

				while i < num 
					result.Volumes.push { VolumeId: i, Tags: [
							{ Key: "Key: #{i}", Value: "Value: #{i}"}
						] }
					i++
				result

			getResourcesTests = (num, done) ->

				resources = generateTestVolumes num

				AWS = 
					EC2: class
						describeVolumes: (options, callback) ->
							callback null, resources

				niteoVolumes = getTarget()

				niteoVolumes.getResources()
					.done (data) ->
							data.length.should.be.equal(num)
							i = 0
							while i < num
								resources.Volumes[i].VolumeId.should.equal(data[i].id)
								resources.Volumes[i].Tags[0].Key.should.equal(data[i].tags[0].key)
								resources.Volumes[i].Tags[0].Value.should.equal(data[i].tags[0].value)
								i++
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

			it 'should return 1 resources when there are 1 items.', (done) ->

				getResourcesTests 1, done

			it 'should return 10 resources when there are 10 items.', (done) ->

				getResourcesTests 10, done

			it 'should return 100 resources when there are 100 items.', (done) ->

				getResourcesTests 100, done