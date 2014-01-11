(function() {
  var __slice = [].slice;

  if (typeof isNodeJs !== "boolean") {
    require("platformenv").define(global);
  }

  if (isNodeJs) {
    exports.about = {
      title: "µutil",
      description: "micro library with various utility functions",
      npmjs: true,
      webjs: true
    };
  }

  exports.sleep = function(t, f) {
    return setTimeout(f, t * 1000);
  };

  exports.extend = function() {
    var key, source, sources, target, val, _i, _len;
    target = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      for (key in source) {
        val = source[key];
        target[key] = val;
      }
    }
    return target;
  };

  exports.whenDone = function(done) {
    var count, results;
    count = 0;
    results = [];
    return function() {
      var idx;
      idx = count;
      ++count;
      return function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        args.push(idx);
        results.push(args);
        if (results.length === count) {
          return typeof done === "function" ? done(results) : void 0;
        }
      };
    };
  };

  exports.nextTick = isNodeJs ? process.nextTick : function(fn) {
    return setTimeout(fn, 0);
  };

  exports.throttleAsyncFn = function(fn, delay) {
    var lastTime, rerun, run, running, schedule, scheduled;
    delay || (delay = 1000);
    running = [];
    rerun = [];
    scheduled = false;
    lastTime = 0;
    run = function() {
      var t;
      scheduled = false;
      t = running;
      running = rerun;
      rerun = running;
      lastTime = Date.now();
      return fn(function() {
        var args, cb, _i, _len;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        for (_i = 0, _len = running.length; _i < _len; _i++) {
          cb = running[_i];
          cb.apply(null, args);
        }
        running.empty();
        return schedule();
      });
    };
    schedule = function() {
      if (rerun.length > 0 && running.length === 0 && !scheduled) {
        scheduled = true;
        return setTimeout(run, Math.max(0, lastTime - Date.now() - delay));
      }
    };
    return function(cb) {
      rerun.push(cb);
      return schedule();
    };
  };

}).call(this);

