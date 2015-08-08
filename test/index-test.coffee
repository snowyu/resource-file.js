chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

fs              = require 'fs'
fs.cwd          = process.cwd
File            = require '../src'

setImmediate    = setImmediate || process.nextTick
File.setFileSystem fs

describe 'ResourceFile', ->
