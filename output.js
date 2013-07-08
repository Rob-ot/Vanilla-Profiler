__callStack = [];
__profile = function (name, fn) {
    var newFn;
    newFn = function() {
      var ret, start;
      start = Date.now();
      __callStack.push(name);
      ret = fn.apply(this, arguments);
      console.log(Date.now() - start, __callStack.join(" > "));
      __callStack.pop();
      return ret;
    };
    newFn.length = fn.length;
    newFn.name = fn.name;
    return newFn;
  }

named = __profile('named', named);
function named() {
    return 1;
}
var assigned = __profile('assigned', function () {
        return 1;
    });
var o = {
        objLiteralProp: __profile('o.objLiteralProp', function () {
            return 1;
        }),
        some: { assignment: { deep: {} } }
    };
o.some.assignment.deep = __profile('o.some.assignment.deep', function () {
    return 1;
});
;
__profile('<anonymous>', function () {
    return 1;
})();
;
__profile('<anonymous>', function namedIife() {
    return 1;
})();
document.addEventListener('click', __profile('<anonymous>', function namd() {
    return 1;
}), false);