#!/usr/bin/env coffee
require("platformenv").define global if typeof isNodeJs != "boolean"
if isNodeJs
  exports.about =
    title: "µutil"
    description: "micro library with various utility functions"
    npmjs: true
    webjs: true

#{{{1 General utility functions
#{{{2 sleep - nicer settimeout
#
# Reversing order of arguments an settin tim e in seconds, makes it both easier to write and read, ie. `uu.sleep 1, -> ...`
exports.sleep = (t,f) -> setTimeout f, t*1000
#{{{2 extend
exports.extend = (target, sources...) ->
  for source in sources
    for key, val of source
      target[key] = val
  target
#{{{2 whenDone - combining several callbacks into a single one
#
# Utility function for combining several callbacks into a single one. `fn = uu.whenDone(done)` returns a function `fn` where each call `done1 = fn(); done2 = fn(); ...` returns new callback functions, such that when all of `done1 done2 ...` has been called once, then done will be called.
#
exports.whenDone = (done) ->
  count = 0
  results = []
  ->
    idx = count
    ++count
    (args...) ->
      args.push idx
      results.push args
      done? results if results.length == count
#{{{2 nextTick
exports.nextTick = if isNodeJs then process.nextTick else (fn) -> setTimeout fn, 0
#{{{2 throttleAsyncFn - throttle asynchronous function
exports.throttleAsyncFn = (fn, delay) ->
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
