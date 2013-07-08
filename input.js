
function named () {
    return 1
}

var assigned = function () {
    return 1
}

var o = {
    objLiteralProp: function () {
        return 1
    },
    some: { assignment: { deep: {} } }
}

o.some.assignment.deep = function () {
    return 1
}

;(function () {
    return 1
}())

;(function namedIife () {
    return 1
}())

document.addEventListener("click", function () {
    return 1
}, false)
