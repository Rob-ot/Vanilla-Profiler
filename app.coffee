fs = require 'fs'
crypto = require 'crypto'

esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'


collapseDotNotations = (node) ->
  if node.object
    collapseDotNotations(node.object) + "." + node.property.name
  else
    node.name

handle = (node) ->
  niceName = ""
  if node.type is 'FunctionExpression'
    niceName = if node.id?.name
      node.id.name
    else if node.parent.id
      node.parent.id.name
    else if node.parent.left
      collapseDotNotations node.parent.left
    else if node.parent.key
      if node.parent.parent.parent.id?.name
        node.parent.parent.parent.id.name + "." + node.parent.key.name
      else
        node.parent.key.name
    else
      "<anonymous>"

    if node.parent.type in ['Property', 'AssignmentExpression', 'CallExpression', 'VariableDeclarator']
      return  {
        "type": "CallExpression",
        "callee": {
          "type": "Identifier",
          "name": "__profile"
        },
        "arguments": [
          {"type": "Literal", "value": niceName},
          {"type": "Literal", "value": node.range.join(",")},
          node
        ]
      }

  else if node.type is 'FunctionDeclaration'
    # To cope with hoisting we hijack the fn at the top of its scope
    name = node.id.name
    node.parent.body.unshift {
      "type": "ExpressionStatement",
      "expression": {
        "type": "AssignmentExpression",
        "operator": "=",
        "left": {
          "type": "Identifier",
          "name": name
        },
        "right": {
          "type": "CallExpression",
          "callee": {
            "type": "Identifier",
            "name": "__profile"
          },
          "arguments": [
            {"type": "Literal", "value": name},
            {"type": "Literal", "value": node.range.join(",")},
            {"type": "Identifier", "name": name}
          ]
        }
      }
    }

  return undefined


map = (node, parent=null) ->
  # it's important to add the parent on the way down so node.parent.parent exists
  node.parent = parent
  for property, value of node
    continue if property is "parent" # prevent infinite recursion
    if Array.isArray value
      # clone the array in case mutations are made mid-way through the loop
      for subNode, i in _.clone value
        ret = map subNode, node
        # we can't just replace the node at i because they can mutate the array, find where it currently exists and replace that
        if ret != undefined
          index = value.indexOf subNode
          if index == -1
            console.warn "Tried to replace node that no longer belongs to its parent: ", subNode, value
          else
            value[index] = ret

    else if value?.type
      ret = map value, node
      if ret != undefined
        node[property] = ret

  return handle node

profile = ({date, checksum}) ->
  (name, range, fn) ->
    # TODO: awesome stuff
    newFn = ->
      start = Date.now()
      __callStack.push name
      ret = fn.apply this, arguments
      console.log Date.now() - start, __callStack.join(" > ")
      __callStack.pop()
      return ret

    newFn.length = fn.length
    newFn.name = fn.name
    return newFn


transform = (source) ->
  opts =
    date: new Date()

  hash = crypto.createHash 'md5'
  hash.update source
  opts.checksum = hash.digest 'hex'

  ast = esprima.parse source, range: true
  # console.log JSON.stringify(ast)
  map ast

  output = escodegen.generate ast
  return """
    var __callStack = [];
    var __profile = #{profile.toString()}(#{JSON.stringify(opts)});

    #{output}
  """


if !process.argv[2]
  console.error "Please specify an input file, e.g: coffee app.coffee input.js"
  process.exit()

fs.writeFileSync "./output.js", transform fs.readFileSync(process.argv[2]).toString()
