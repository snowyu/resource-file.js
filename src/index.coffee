CustomFile        = require 'custom-file'
File              = require 'custom-file/lib/advance'
inherits          = require 'inherits-ex/lib/inherits'
getPrototypeOf    = require 'inherits-ex/lib/getPrototypeOf'
setPrototypeOf    = require 'inherits-ex/lib/setPrototypeOf'
matter            = require 'front-matter-markdown/lib/'
loadCfgFile       = require 'load-config-file'
loadCfgFolder     = require 'load-config-folder'
extend            = require 'util-ex/lib/_extend'
isObject          = require 'util-ex/lib/is/type/object'
isString          = require 'util-ex/lib/is/type/string'
isArray           = require 'util-ex/lib/is/type/array'
defineProperty    = require 'util-ex/lib/defineProperty'
Promise           = require 'bluebird'
createFileObject  = require './create-file-object'
setImmediate  = setImmediate || process.nextTick
Promise.promisifyAll File, filter:(name,fn)->name in ['load']

markdownExts = [
  '.txt'
  '.md', '.mdown', '.markdown', '.mkd','.mkdn'
  '.mdwn', '.mdtext','.mdtxt'
  '.text'
]

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

  matter.setOptionAlias 'toc', ['isDir', 'isDirectory']
  matter.setOptionAlias 'heading', ['dirHeading', 'dirHeadings']
  matter.setOptionAlias 'headingsAsToc', 'headingsAsToc'
  File.defineProperties Resource, extend
    isDir:
      type: 'Boolean'
      alias: ['isDirectory']
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

  # TODO: howto validate a virtual file?
  # fake a stat object.
  # currently has only virtual folder object. (no virtual file yet)
  #_validate: (file)-> file.hasOwnProperty('contents') and file.contents?
  inspect: ->
    name = 'File'
    if @loaded()
      name = 'Folder' if @isDirectory()
    else
      name += '?'
    '<'+ name + ' ' + @_inspect() + '>'

  isDirectory: ->
    if @hasOwnProperty('isDir') and @isDir isnt undefined
      result = @isDir
    else
      result = super()
    result

  toObject: (options, aExclude)->
    if isString aExclude
      aExclude = [aExclude]
    else if !isArray aExclude
      aExclude = []
    aExclude.push 'contents' unless @hasOwnProperty('contents')
    aExclude.push 'stat' unless @hasOwnProperty('stat')
    @exportTo(options, aExclude)

  getContentSync: (aOptions)->
    aOptions = {} unless isObject aOptions
    aOptions.overwrite = true unless aOptions.overwrite? or @loaded()
    super aOptions

  getContent: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
    aOptions = {} unless isObject aOptions
    aOptions.overwrite = true unless aOptions.overwrite? or @loaded()
    super aOptions, done

  # frontMatter('---\ntitle: 1\n---\nbody')
  # return {title:1, skipSize: 17, content: 'body', $compiled:[...]}
  frontMatter: (aText, aOptions)->
    if @extname in markdownExts
      result = matter(aText.toString(), aOptions)
      # TODO:whether export the non-enumerable $compiled attribute?
    result

  convertVirtualFolder: (aContents)->
    for k in aContents
      if k.path?
        k.base = @path
        setPrototypeOf k, @
    aContents

  loadConfig: (aOptions, aContents, done)->
    that = @
    processCfg = (err, aConfig)->
      return done(err) if err
      if aConfig
        that.assign aConfig, 'contents'
        if that.isDirectory()
          if aConfig.contents #virtual folder
            that.convertVirtualFolder(aConfig.contents)
            aContents = aConfig.contents
          if aOptions.recursive
            aContents.forEach (f)->
              f.loadSync aOptions if (f instanceof Resource) and f.isDirectory()
            #aContents = aContents.filter (f)->(f instanceof Resource) and f.isDirectory()
            # can not work!!:
            # Promise.map aContents, (f)->
            #   f.load aOptions
            # .nodeify (err, result)->
            #   done(err, aConfig)
            # return
      done(err, aConfig)
      return

    if !aOptions.stat.isDirectory()
      vFrontConf = @frontMatter(aContents, aOptions)
      vOptions = exclude: aOptions.path #avoid load twice.
      vOptions.configurators = aOptions.configurators if aOptions.configurators
      loadCfgFile aOptions.path, vOptions, (err, result)->
        return done(err) if err
        if vFrontConf and vFrontConf.skipSize
          result = {} unless isObject result
          result = extend result, vFrontConf
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
      vOptions = exclude: aOptions.path #avoid load twice.
      vOptions.configurators = aOptions.configurators if aOptions.configurators
      result = loadCfgFile aOptions.path, vOptions
      result = {} unless isObject result
      if vFrontConf and vFrontConf.skipSize
        result = extend result, vFrontConf
        if result.contents
          result.skipSize = -vFrontConf.skipSize
        else
          #result.contents = vFrontConf.content
          result.skipSize = vFrontConf.skipSize
    else
      result = loadCfgFolder aOptions.path, aOptions
    if result
      @assign result, 'contents'
      @$cfgPath = result.$cfgPath if result.$cfgPath
      if @isDirectory()
        if result.contents #virtual folder
          @convertVirtualFolder(result.contents)
          aContents = result.contents
        if aOptions.recursive
          # TODO: it must be loaded first if the file treat as virtual folder.
          aContents.forEach (f)->
            if (f instanceof Resource) and f.isDirectory()
              f.loadSync aOptions if result
    result

  _getBufferSync: (aFile)->
    result = super(aFile)
    conf = @loadConfigSync aFile, result
    if conf
      result = conf.contents if conf.contents
      if conf.$cfgPath
        if @isDirectory()
          result = result.filter (f)->f.path isnt conf.$cfgPath
        else if (vDir = @parent)
          vDir.contents = vDir.contents.filter (f)->f.path isnt conf.$cfgPath
    result

  _getBuffer: (aFile, done)->
    that = @
    super aFile, (err, result)->
      return done(err) if err
      that.loadConfig aFile, result, (err, conf)->
        return done(err) if err
        if conf
          #extend that, conf
          result = conf.contents if conf.contents
          if conf.$cfgPath
            if that.isDirectory()
              result = result.filter (f)->f.path isnt conf.$cfgPath
            else if (vDir = that.parent)
              vDir.contents = vDir.contents.filter (f)->f.path isnt conf.$cfgPath
        done(err, result)
