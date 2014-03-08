// Generated by CoffeeScript 1.6.3
(function() {
  var ajaxLegacy, use, uu,
    __slice = [].slice;

  if (typeof isNodeJs === "undefined" || typeof runTest === "undefined") {
    (function() {
      var root;
      root = typeof window === "undefined" ? global : window;
      if (typeof isNodeJs === "undefined") {
        root.isNodeJs = typeof process !== "undefined";
      }
      if (typeof isWindow === "undefined") {
        root.isWindow = typeof window !== "undefined";
      }
      if (typeof isPhoneGap === "undefined") {
        root.isPhoneGap = typeof (typeof document !== "undefined" && document !== null ? document.ondeviceready : void 0) !== "undefined";
      }
      if (typeof runTest === "undefined") {
        return root.runTest = (isNodeJs ? process.argv[2] === "test" : location.hash.slice(1) === "test");
      }
    })();
  }

  use = isNodeJs ? (function(module) {
    return require(module);
  }) : (function(module) {
    return window[module];
  });

  uu = isNodeJs ? exports : {};

  if (isWindow) {
    window.uu = uu;
  }

  uu.nextTick = isNodeJs ? process.nextTick : function(fn) {
    return setTimeout(fn, 0);
  };

  uu.ajax = void 0;

  ajaxLegacy = false;

  if (isWindow) {
    (function() {
      var XHR;
      XHR = XMLHttpRequest;
      if (typeof (new XHR).withCredentials !== "boolean") {
        ajaxLegacy = true;
        XHR = XDomainRequest;
      }
      uu.ajax = function(url, data, cb) {
        var xhr;
        xhr = new XHR();
        xhr.onerror = function(err) {
          return typeof cb === "function" ? cb(err || true) : void 0;
        };
        xhr.onload = function() {
          return typeof cb === "function" ? cb(null, xhr.responseText) : void 0;
        };
        xhr.open((data ? "POST" : "GET"), url, !!cb);
        xhr.send(data);
        if (!cb) {
          return xhr.responseText;
        }
      };
      if (runTest) {
        return uu.nextTick(function() {
          uu.ajax("//cors-test.appspot.com/test", void 0, function(err, result) {
            return expect(result, '{"status":"ok"}', "async ajax");
          });
          return uu.ajax("//cors-test.appspot.com/test", "foo", function(err, result) {
            return expect(result, '{"status":"ok"}', "async ajax post");
          });
        });
      }
    })();
  }

  uu.sleep = function(t, f) {
    return setTimeout(f, t * 1000);
  };

  uu.extend = function() {
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

  uu.whenDone = function(done) {
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

  uu.throttleAsyncFn = function(fn, delay) {
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
