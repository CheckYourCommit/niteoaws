sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.iamSSLCertificateProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'iamSSLCertificateProvider', ->

		describe 'getResources', ->

			generateTestCertificates = (num) ->
				i = 0
				result = { ServerCertificateMetadataList: [] }

				while i < num 
					result.ServerCertificateMetadataList.push { ServerCertificateId: i, Tags: [] }
					i++
				result

			getResourcesTests = (num, done) ->

				resources = generateTestCertificates num

				AWS = 
					IAM: class
						listServerCertificates: (options, callback) ->
							callback null, resources

				niteoCertificates = getTarget()

				niteoCertificates.getResources()
					.done (data) ->
							data.length.should.be.equal(num)
							i = 0
							while i < num
								resources.ServerCertificateMetadataList[i].ServerCertificateId.should.equal(data[i].id)
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
			
			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					IAM: class
						constructor: ->
							throw 'Some Random Error'

				getTarget().getResources()
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()