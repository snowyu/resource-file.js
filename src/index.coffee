CustomFile        = require 'custom-file'
File              = require 'custom-file/lib/advance'
inherits          = require 'inherits-ex/lib/inherits'
getPrototypeOf    = require 'inherits-ex/lib/getPrototypeOf'
matter            = require 'gray-matter'
loadCfgFile       = require 'load-config-file'
loadCfgFolder     = require 'load-config-folder'
extend            = require 'util-ex/lib/_extend'
isObject          = require 'util-ex/lib/is/type/object'
defineProperty    = require 'util-ex/lib/defineProperty'
Promise           = require 'bluebird'
createFileObject  = require './create-file-object'
setImmediate  = setImmediate || process.nextTick
Promise.promisifyAll File, filter:(name,fn)->name in ['load']

module.exports = class Resource
  inherits Resource, File
  @setFileSystem: CustomFile.setFileSystem

  # filled by _updateFS:
  fs = null
  path = null

  constructor: (aPath, aOptions, done)->
    return new Resource(aPath, aOptions, done) unless @ instanceof Resource
    super

  @defineProperties: File.defineProperties

  File.defineProperties Resource, extend
    isDir:
      type: 'Boolean'
  , File::$attributes

  defineProperty @::, 'parent', undefined,
    get: ->
      result = getPrototypeOf @
      result = null if result is Object::
      result

  createFileObject: (aOptions)->
    aOptions.cwd = @cwd # for ReadDirStream
    aOptions.base = @base
    result = createFileObject @, aOptions

  _assign: (aOptions, aExclude)->
    vAttrs = @getProperties()
    for k,v of aOptions
      continue if vAttrs[k]? or k in aExclude
      @[k] = v # assign the user's customized attributes

  _updateFS: (aFS)->
    super aFS
    fs = @fs unless fs
    path = fs.path if fs and !path
    return
  isDirectory: ->
    if @hasOwnProperty 'isDir'
      result = @isDir
    else
      result = super()
    result

  # return {data:{title:1}, skipSize: 17, content}
  frontMatter: (aText, aOptions)->
    # return {org:'---\ntitle: 1\n---\nbody', data:{title:1}, content:'body'}
    result = matter(aText, aOptions)
    result.skipSize = aText.length - result.content.length
    result

  loadConfig: (aOptions, aContents, done)->
    that = @
    processCfg = (err, aConfig)->
      return done(err) if err
      if aConfig
        that.assign aConfig
        aContents = aConfig.contents if aConfig.contents
        aContents = aContents.filter (f)->f.isDirectoy()
        if aOptions.recursive and that.isDirectoy()
          Promise.map aContents, (f)->
            f.load aOptions
          .nodeify (err, result)->
            done(err, aConfig)
        else
          done(err, aConfig)
      else
        done(err, aConfig)
    if !aOptions.stat.isDirectory()
      vFrontConf = @frontMatter(aContents.toString(), aOptions)
      loadCfgFile aOptions.path, aOptions, (err, result)->
        return done(err) if err
        if vFrontConf and vFrontConf.skipSize
          result = extend result, vFrontConf.data
          #aOptions.skipSize = vFrontConf.skipSize
          if result.contents
            # do not enable the skipSize, but remember the position.
            result.skipSize = -vFrontConf.skipSize
          else
            #result.contents = vFrontConf.content
            result.skipSize = vFrontConf.skipSize
        processCfg(err, result)
    else
      loadCfgFolder aOptions.path, aOptions, processCfg

  loadConfigSync: (aOptions, aContents)->
    if !aOptions.stat.isDirectory()
      vFrontConf = @frontMatter(aContents.toString(), aOptions)
      result = loadCfgFile aOptions.path, aOptions
      result = {} unless isObject result
      if vFrontConf and vFrontConf.skipSize
        result = extend result, vFrontConf.data
        if result.contents
          result.skipSize = -vFrontConf.skipSize
        else
          #result.contents = vFrontConf.content
          result.skipSize = vFrontConf.skipSize
    else
      result = loadCfgFolder aOptions.path, aOptions
    if result
      @assign result
      aContents = result.contents if result.contents
      if aOptions.recursive and @isDirectoy()
        for vFile in aContents
          vFile.loadSync aOptions if vFile.isDirectoy()
    result

  _getBufferSync: (aFile)->
    result = super(aFile)
    conf = @loadConfigSync aFile, result
    if conf
      result = conf.contents unless conf.contents
    result

  _getBuffer: (aFile, done)->
    that = @
    super aFile, (err, result)->
      return done(err) if err
      @loadConfig aFile, result, (err, conf)->
        return done(err) if err
        if conf
          #extend that, conf
          result = conf.contents unless conf.contents
        done(err, result)
