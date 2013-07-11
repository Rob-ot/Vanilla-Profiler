var __callStack = [];
var __profile = function (_arg) {
    var checksum, date;
    date = _arg.date, checksum = _arg.checksum;
    return function(name, range, fn) {
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
    };
  }({"date":"2013-07-09T03:56:05.658Z","checksum":"a08f19eb1c855a73816fa9a6b6359cb4"});

named = __profile('named', '1,35', named);
function named() {
    return 1;
}
var assigned = __profile('assigned', '52,80', function () {
        return 1;
    });
var o = {
        objLiteralProp: __profile('o.objLiteralProp', '112,148', function () {
            return 1;
        }),
        some: { assignment: { deep: {} } }
    };
o.some.assignment.deep = __profile('o.some.assignment.deep', '217,245', function () {
    return 1;
});
;
__profile('<anonymous>', '249,277', function () {
    return 1;
})();
;
__profile('namedIife', '284,322', function namedIife() {
    return 1;
})();
document.addEventListener('click', __profile('<anonymous>', '362,390', function () {
    return 1;
}), false);