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
window.uutil = window.uu = uu if isWindow
#{{{1 Shim
Object.keys ?= (obj) -> (key for key, _ of obj)
#{{{1 DOM
uu.domListen = (elem, events, fn) -> #{{{3
  return if !elem
  for event in events.split " "
    if elem.addEventListener
      elem.addEventListener event, fn, false
    else
      elem.attachEvent "on#{event}", fn
uu.onComplete = (fn) -> #{{{2
  if isWindow
    if document.readyState == "complete"
      fn()
    else
      setTimeout (-> uu.onComplete fn), 17

#{{{1 Objects
uu.extend = (target, sources...) -> #{{{2
  for source in sources
    for key, val of source
      target[key] = val
  target
uu.deepCopy = (obj) -> #{{{2
    if typeof obj == "object"
      if obj.constructor == Array
        result = []
        result.push uu.deepCopy(e) for e in obj
      else
        result = {}
        result[key] = uu.deepCopy(val) for key, val of obj
      return result
    else
      return obj
#{{{1 Array
uu.pick = (arr) -> arr[Math.random() * arr.length | 0]
#{{{1 Numbers
uu.prng = (n) -> (1664525 * n + 1013904223) |0 #{{{2
#{{{1 String
uu.urlString = (str) -> #{{{2
  mapping =
    "å": "aa"
    "Å": "Aa"
    "ø": "o"
    "Ø": "O"
    "æ": "ae"
    "Æ": "AE"
    ",": " "
    ".": " "

  str
    .trim()
    .toLocaleLowerCase()
    .replace(/[^a-zA-Z0-9]/g, (c) -> mapping[c] || " ")
    .replace(/\ +/g, "-")
uu.strHash = (s) -> #{{{2 hashing based on djb
  hash = 5381
  i = s.length
  while i
    hash = (hash*31 + s.charCodeAt(--i)) | 0
  hash
#{{{1 jsonml2html
uu.xmlEscape = (str) -> String(str).replace RegExp("[\x00-\x1f\x80-\uffff&<>\"']", "g"), (c) -> "&##{c.charCodeAt 0};" #{{{2
uu.obj2style = (obj) -> #{{{2
  (for key, val of obj
    csskey = key.replace /[A-Z]/g, (c) -> "-" + c.toLowerCase()
    val = "#{val}px" if typeof val == "number"
    if val && typeof val == "object" && val.constructor == Object
      "#{key}{#{uu.obj2style val}}"
    else
      "#{csskey}:#{val};"
  ).join ""

uu.jsonml2html = (arr) -> #{{{2
  return "#{uu.xmlEscape arr}" if !Array.isArray(arr)
  # raw html, useful for stuff which shouldn't be xmlescaped etc.
  return arr[1] if arr[0] == "rawhtml"
  # normalise jsonml, make sure it contains attributes
  arr = [arr[0], {}].concat arr.slice(1) if arr[1]?.constructor != Object
  attr = {}
  attr[key] = val for key, val of arr[1]
  # convert style objects to strings
  attr.style = uu.obj2style attr.style if attr.style?.constructor == Object
  # shorthand for classes and ids
  tag = arr[0].replace /#([^.#]*)/, ((_, id) -> attr.id = id; "")
  tag = tag.replace /\.([^.#]*)/g, (_, cls) ->
    attr["class"] = if attr["class"] == undefined then cls else "#{attr["class"]} #{cls}"
    ""
  # create actual tag string
  result = "<#{tag}#{(" #{key}=\"#{uu.xmlEscape val}\"" for key, val of attr).join ""}>"
  # add children and endtag, if there are children. `<foo></foo>` is done with `["foo", ""]`
  result += "#{arr.slice(2).map(uu.jsonml2html).join ""}</#{tag}>" if arr.length > 2
  return result

#{{{2 Test / examples
if false and runTest then process.nextTick ->
  assert = require "assert"
  jsonml = ["div.main",
      style:
        background: "red"
        textSize: 12
    ["h1#theHead.foo.bar", "Blåbærgrød"],
    ["img",
      src: "foo"
      alt: 'the "quoted"'],
    ["script", ["rawhtml", "console.log(foo<bar)"]]]

  assert.equal jsonml2html.toString(jsonml),
    """<div style="background:red;text-size:12px" class="main"><h1 id="theHead" class="foo bar">Bl&#229;b&#230;rgr&#248;d</h1><img src="foo" alt="the &#34;quoted&#34;"><script>console.log(foo<bar)</script></div>"""




#{{{1 Colors
uu.intToColor = (i) -> "#" + ((i & 0xffffff) + 0x1000000).toString(16).slice(1)
uu.hashColor = (str) ->  -> uu.intToColor uu.prng uu.strHash str
uu.hashColorLight = (str) -> uu.intToColor 0xe0e0e0 | ((uu.prng uu.strHash str) >> 3)
uu.hashColorDark = (str) -> uu.intToColor ((uu.prng uu.strHash str) >> 1) & 0x7f7f7f
#{{{1 Invoke fn
uu.whenDone = (done) -> #{{{2
  # Utility function for combining several callbacks into a single one. `fn = uu.whenDone(done)` returns a function `fn` where each call `done1 = fn(); done2 = fn(); ...` returns new callback functions, such that when all of `done1 done2 ...` has been called once, then done will be called.
  count = 0
  results = []
  ->
    idx = count
    ++count
    (args...) ->
      args.push idx
      results.push args
      done? results if results.length == count
uu.throttleAsyncFn = (fn, delay) -> #{{{2
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
uu.nextTick = if isNodeJs then process.nextTick else (fn) -> setTimeout fn, 0 #{{{2
uu.sleep = (t,f) -> setTimeout f, t*1000 #{{{2
# Reversing order of arguments an settin tim e in seconds, makes it both easier to write and read, ie. `uu.sleep 1, -> ...`
#{{{1 Network
ajaxLegacy = false
uu.ajax = undefined #{{{2
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
#{{{1 Logging
#{{{2 doc+initialisation
#
# We want to send logging and statistics to server, 
# but not drain battery nor exhaust the network,
# so the log is saved to memory, and then only send across the network 
# when more than `logBeforeSync` entries has been collected, 
# or the user leaves the page. It is also throttled, 
# so logging data are sent no more than once every `syncDelay` milliseconds.
#
# On legacy browsers we cannot send the log when the user leave the page,
# so there we just send update every `syncDelay` milliseconds.
#
do ->
  logData = []
  logId = Math.random()
  if isWindow && window.location?.protocol == "http:"
    logUrl = "http://ssl.solsort.com/api/log"
  else
    logUrl = "https://ssl.solsort.com/api/log"
  logSyncing = false
  logsBeforeSync = 200
  syncDelay = 400
  uu.syncLog = -> #{{{2
    if !logSyncing
      try
        logContent = JSON.stringify logData
      catch e
        logContent = "Error stringifying log"
      logSyncing = logData
      logData = []
      uu.ajax logUrl, logContent, (err, result) ->
        setTimeout (-> logSyncing = false), syncDelay
        if err
          log "logsync error", err
          logData = logSyncing.concat(logData)
        else
          logData.push [+(new Date()), "log sync'ed", logId, logData.length]
          uu.syncLog() if (ajaxLegacy || runTest) && logData.length > 1

  uu.log = (args...) -> #{{{2
    logData.push [+(new Date()), args...]
    uu.nextTick uu.syncLog if logData.length > logsBeforeSync || ajaxLegacy || runTest
    return args

  uu.onComplete -> #{{{2
    uu.domListen window, "error", (err) ->
      uu.log "window.onerror ", String(err)
    uu.domListen window, "beforeunload", ->
      uu.log "window.beforeunload"
      try
        uu.ajax logUrl, JSON.stringify logData # blocking POST request
      catch e
        undefined
      undefined
    uu.log "starting", logId, window.performance
    uu.log "userAgent", navigator.userAgent


