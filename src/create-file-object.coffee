isObject        = require 'util-ex/lib/is/type/object'
getPrototypeOf  = require 'inherits-ex/lib/getPrototypeOf'
setPrototypeOf  = require 'inherits-ex/lib/setPrototypeOf'

# create a file object from a plain object.
module.exports = (aParent, aFileObject)->
  result = aFileObject
  setPrototypeOf result, aParent if isObject result
  result
