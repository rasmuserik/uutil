# {{{1 Boilerplate
if typeof isNodeJs == "undefined" or typeof runTest == "undefined" then do ->
  root = if typeof window == "undefined" then global else window
  root.isNodeJs = (typeof process != "undefined") if typeof isNodeJs == "undefined"
  root.isWindow = (typeof window != "undefined") if typeof isWindow == "undefined"
  root.isPhoneGap = typeof document?.ondeviceready != "undefined" if typeof isPhoneGap == "undefined"
  root.runTest = (if isNodeJs then process.argv[2] == "test" else location.hash.slice(1) == "test") if typeof runTest == "undefined"
# use - require/window.global with non-require name to avoid being processed in firefox plugins
use = if isNodeJs then ((module) -> require module) else ((module) -> window[module])

# define module
uu = if isNodeJs then exports else {}
window.uu = uu if isWindow
#{{{1 General utility functions

#{{{2 nextTick
uu.nextTick = if isNodeJs then process.nextTick else (fn) -> setTimeout fn, 0
#{{{2 ajax
uu.ajax = undefined
ajaxLegacy = false
if isWindow then do ->
  XHR = XMLHttpRequest
  if typeof (new XHR).withCredentials != "boolean"
    ajaxLegacy = true
    XHR = XDomainRequest

  uu.ajax = (url, data, cb) ->
    xhr = new XHR()
    xhr.onerror = (err) -> cb? err || true
    xhr.onload = -> cb? null, xhr.responseText
    xhr.open (if data then "POST" else "GET"), url, !!cb
    xhr.send data
    return xhr.responseText if !cb

  if runTest then uu.nextTick ->
    uu.ajax "//cors-test.appspot.com/test", undefined, (err, result) -> expect result, '{"status":"ok"}', "async ajax"
    uu.ajax "//cors-test.appspot.com/test", "foo", (err, result) -> expect result, '{"status":"ok"}', "async ajax post"
#{{{2 sleep - nicer settimeout
#
# Reversing order of arguments an settin tim e in seconds, makes it both easier to write and read, ie. `uu.sleep 1, -> ...`
uu.sleep = (t,f) -> setTimeout f, t*1000
#{{{2 extend
uu.extend = (target, sources...) ->
  for source in sources
    for key, val of source
      target[key] = val
  target
#{{{2 whenDone - combining several callbacks into a single one
#
# Utility function for combining several callbacks into a single one. `fn = uu.whenDone(done)` returns a function `fn` where each call `done1 = fn(); done2 = fn(); ...` returns new callback functions, such that when all of `done1 done2 ...` has been called once, then done will be called.
#
uu.whenDone = (done) ->
  count = 0
  results = []
  ->
    idx = count
    ++count
    (args...) ->
      args.push idx
      results.push args
      done? results if results.length == count
#{{{2 throttleAsyncFn - throttle asynchronous function
uu.throttleAsyncFn = (fn, delay) ->
  delay ||= 1000
  running = []
  rerun = []
  scheduled = false
  lastTime = 0
  run = ->
    scheduled = false
    t = running; running = rerun; rerun = running
    lastTime = Date.now()
    fn (args...) ->
      for cb in running
        cb args...
      running.empty()
      schedule()
    
  schedule = ->
    if rerun.length > 0 && running.length == 0 && !scheduled
      scheduled = true
      setTimeout run, Math.max(0, lastTime - Date.now() - delay)
  
  (cb) ->
    rerun.push cb
    schedule()
