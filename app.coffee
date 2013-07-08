fs = require 'fs'

esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'

if !process.argv[2]
  console.error "Please specify an input file, e.g: coffee app.coffee input.js"
  process.exit()

source = fs.readFileSync(process.argv[2]).toString()

ast = esprima.parse source

collapseDotNotations = (node) ->
  if node.object
    collapseDotNotations(node.object) + "." + node.property.name
  else
    node.name

handle = (node) ->
  niceName = ""
  if node.type is 'FunctionExpression'
    niceName = if node.parent.id
      node.parent.id.name
    else if node.parent.left
      collapseDotNotations node.parent.left
    else if node.parent.key
      if node.parent.parent.parent.id?.name
        node.parent.parent.parent.id.name + "." + node.parent.key.name
      else
        node.parent.key.name

    niceName or= "<anonymous>"

    if node.parent.type in ['Property', 'AssignmentExpression', 'CallExpression', 'VariableDeclarator']
      return  {
        "type": "CallExpression",
        "callee": {
          "type": "Identifier",
          "name": "__profile"
        },
        "arguments": [
          {
            "type": "Literal",
            "value": niceName
          },
          node
        ]
      }

  else if node.type is 'FunctionDeclaration'
    # To cope with hoisting we hijack the fn at the top of its scope
    name = node.id.name
    profileNode = esprima.parse("#{name} = __profile('#{name}', #{name})").body[0]
    node.parent.body.unshift profileNode

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

map ast

profile = (name, fn) ->
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

output = escodegen.generate ast

fs.writeFileSync "./output.js", ("__callStack = [];\n__profile = " + profile.toString() + "\n\n" + output)
