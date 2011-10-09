window.Moka = {}

# bind
if not Function.prototype.bind
    Function.prototype.bind = (thisObj, var_args) ->
        self = this
        staticArgs = Array.prototype.splice.call(arguments, 1, arguments.length)

        return () ->
            args = staticArgs.concat()
            i = 0
            while i < arguments.length
              args.push(arguments[i++])
            return self.apply(thisObj, args)

# console logging
((logobj=window.console) and logfn=logobj.log) or
((logobj=window.opera) and logfn=logobj.postError)
log = if logfn then logfn.bind(logobj) else () -> return

# debugging
dbg = log.bind(this, "DEBUG:")
#dbg = () -> return

# performance
Moka.performance = [new Date().getTime()]
Moka.perfmsg = null
Moka.perfpad = "##"
perf_begin = () ->
    Moka.performance.push( new Date().getTime() )
    Moka.perfpad += "#"
perf_end = (msg) ->
    t = new Date().getTime() - Moka.performance.pop()
    perfpad = Moka.perfpad = Moka.perfpad.slice(1)
    newmsg = perfpad + " " + t + "ms: " + msg

    perfmsg = Moka.perfmsg
    Moka.perfmsg = if perfmsg then newmsg + "\n" + perfmsg else newmsg

    if not Moka.performance.length
        log Moka.perfmsg
        Moka.perfmsg = null
#perf = () -> return

# TODO: macros for log, dbg, perf_* (to remove from compiled js if not needed)

# KEYBOARD
# TODO: add keynames for each web browser
keycodes = {
    8: "BACKSPACE"
    9: "TAB"
    13: "ENTER"
    27: "ESCAPE"
    32: "SPACE"
    37: "LEFT"
    38: "UP"
    39: "RIGHT"
    40: "DOWN"
    45: "INSERT"
    46: "DELETE"
    33: "PAGEUP"
    34: "PAGEDOWN"
    35: "END"
    36: "HOME"
    96:  "KP0"
    97:  "KP1"
    98:  "KP2"
    99:  "KP3"
    100: "KP4"
    101: "KP5"
    102: "KP6"
    103: "KP7"
    104: "KP8"
    105: "KP9"
    106: "*"
    107: "+"
    109: "MINUS"
    110: "."
    111: "/"
    112: "F1"
    113: "F2"
    114: "F3"
    115: "F4"
    116: "F5"
    117: "F6"
    118: "F7"
    119: "F8"
    120: "F9"
    121: "F10"
    122: "F11"
    123: "F12"
    191: "?"
}

# keyboard combination name is normalized
# format is "A-C-S-KEY" where A, C, S are optional modifiers (alt, control, shift)
Moka.normalizeKeyName = (keyname) ->
    modifiers = keyname.toUpperCase().split("-")
    key = modifiers.pop()

    modifiers = modifiers.map((x) -> x[0]).sort()
    k = if modifiers.length then modifiers.join("-")+"-"+key else key

    return k

last_keyname = last_keyname_timestamp = null
Moka.getKeyName = (ev) ->
    if ev.timeStamp is last_keyname_timestamp
        return last_keyname

    keycode = ev.which
    keyname = keycodes[keycode]
    if not keyname?
        keyname = if keycode < 32 then "" else String.fromCharCode(keycode)

    keyname = (if ev.altKey then "A-" else "") +
              (if ev.ctrlKey or ev.metaKey then "C-" else "") +
              (if ev.shiftKey then "S-" else "") +
              keyname.toUpperCase()

    last_keyname = keyname
    last_keyname_timestamp = ev.timeStamp

    return keyname

Moka.getKeyHint = (keyname) ->
    if keyname.length is 1
        return keyname
    else
        # digit (1, KP1, S-1 ... not F1)
        n = keyname.replace(/^S-/,"").replace(/^KP/,"")
        if n >= "0" and n <= "9"
            return n
    return null

Moka.keyHintFocus = (w, hint, skip_parent, w_to_skip) ->
    if w instanceof Moka.Input and w.keyHint() is hint and not w.hasFocus()
        w.focus()
        return true

    l = if w.length then w.length() else 0
    i = 0
    while i<l
        ww = w.at(i)
        if ww isnt w_to_skip and ww.isVisible() and Moka.keyHintFocus(ww, hint, true)
            return true
        ++i

    if not skip_parent
        p = w.parent()
        if p and Moka.keyHintFocus(p, hint, false, w)
            return true

    return false

Moka.findInput = (w, opts) ->
    return null if not opts.text

    prev_found = false
    first = null
    last = null
    # case-insensitive search
    query = opts.text.toUpperCase()

    find = (w) ->
        return null if not w.isVisible()
        if w.length
            i = 0
            l = w.length()
            while i<l
                res = find( w.at(i++) )
                return res if res
        if w.focus and w not instanceof Moka.WidgetList and
           w.text().toUpperCase().search(query) >= 0
            if (opts.next and prev_found) or not (opts.next or opts.prev)
                return w
            if w.hasClass("moka-found")
                return last if opts.prev
                prev_found = true
            first = w if not first
            last = w
        return null

    return find(w) or (opts.prev and last) or first

Moka.initDraggable = (e, handle_e) ->
    if not handle_e
        handle_e = e
    return handle_e
      .css('cursor', "pointer")
      .bind "mousedown", (ev) ->
          if ev.button is 0
              stop = false
              $(document).one( "mouseup", () -> stop = true )

              ev.preventDefault()
              self = $(this)
              pos = e.offset()
              x = ev.pageX - pos.left
              y = ev.pageY - pos.top

              move = (ev) ->
                  if stop
                      $(document).unbind("mousemove.moka")
                  else
                      e.offset({left:ev.pageX-x, top:ev.pageY-y})
              $(document).bind( "mousemove.moka", move)
              move(ev)

Moka.initDragScroll = (e) ->
    e.bind "mousedown.moka.initdragscroll", (ev) ->
        if ev.which is 1
            Moka.dragScroll(ev)

    return e

# Moka.dragScroll
Moka.scrolling = false
jQuery.extend( jQuery.easing,
    easeOutCubic: (x, t, b, c, d) ->
        # refresh preview every 30ms
        return (t=t/1000-1)*t*t + 1
)

Moka.from_mouseX = 0
Moka.from_mouseY = 0
Moka.dragScroll = (ev) ->
    wnd = ev.currentTarget
    w = $(wnd)

    start = t = ev.timeStamp
    dt = 0
    dx = 0
    dy = 0

    mouseX = ev.pageX
    mouseY = ev.pageY
    Moka.from_mouseX = w.scrollLeft() + mouseX
    Moka.from_mouseY = w.scrollTop() + mouseY

    stop = false
    Moka.scrolling = false

    continueDragScroll = (ev) ->
        return if stop
        if not Moka.scrolling
            return if Math.abs(mouseX-ev.pageX) < 6 and Math.abs(mouseY-ev.pageY) < 6
            Moka.scrolling = true

        mouseX = ev.pageX
        mouseY = ev.pageY

        x = w.scrollLeft()
        y = w.scrollTop()

        # scroll
        w.scrollLeft(Moka.from_mouseX-mouseX)
        w.scrollTop(Moka.from_mouseY-mouseY)

        start = t
        t = ev.timeStamp
        dx = w.scrollLeft()-x
        dy = w.scrollTop()-y

        ev.preventDefault()

    stopDragScroll = (ev) ->
        stop = true

        $(window).unbind("mousemove.moka.dragscroll")

        # if not scrolled: try to focus target element
        if not Moka.scrolling
            Moka.focus( $(ev.target).parents(".moka-input:first") )
            return

        # TODO: better algorithm to determine scroll animation speed and amount
        t = ev.timeStamp
        dt = t-start
        if 0 < dt < 90 and (dx isnt 0 or dy isnt 0)
            accel = 200/dt
            vx = dx*accel
            vy = dy*accel

            w.stop(true).animate(
                scrollLeft: w.scrollLeft()+vx+"px",
                scrollTop: w.scrollTop()+vy+"px",
                1000, "easeOutCubic",
                () -> Moka.scrolling = false)
        else
            Moka.scrolling = false

        return false

    # stop animations
    w.stop(true)

    # Chromium bug: http://code.google.com/p/chromium/issues/detail?id=14204
    # - scrollbar does not trigger mouseup
    pos = w.offset()
    if mouseX+24 > pos.left + w.width() or mouseY+24 > pos.top + w.outerHeight()
        return

    $(window).one("mouseup.moka.dragscroll", stopDragScroll)
             .bind("mousemove.moka.dragscroll", continueDragScroll)

    ev.preventDefault()

Moka.focused_e = null
Moka.focused = (e) ->
    if e?
        ee = Moka.focused_e
        if ee
            # return if element is already focused
            return e if ee[0] is e[0]
            # unfocus previous element
            Moka.unfocused()
        #dbg "focusing element\n ", e[0]
        Moka.focused_e = e
        e.addClass("moka-focus")
        return e
    return Moka.focused_e

Moka.unfocused = () ->
    e = Moka.focused_e
    if e
        #dbg "blurring element\n ", e[0]
        Moka.focused_e = null
        e.removeClass("moka-focus")

Moka.focus = (e, o) ->
    return if not e.is(":visible")
    focused = Moka.focused()
    e0 = e[0]
    return if focused and focused[0] is e0
    e0.focus()
    Moka.toScreen(e, null, o) if o
    Moka.focused(e)

Moka.blur = (e) -> e.blur()

Moka.focusFirstWidget = (w, only_children, o) ->
    return false if not w.isVisible()
    perf_begin()
    if not only_children and w.focus
        w.focus(o)
        perf_end("focusFirstWidget (self)")
        return true
    else if w.widgets
        for ww in w.widgets
            if Moka.focusFirstWidget(ww, false, o)
                perf_end("focusFirstWidget (child)")
                return true
    perf_end("focusFirstWidget (failed)")
    return false

Moka.focusFirst = (e, o) ->
    if e.hasClass("moka-input")
        ee = e
    else
        ee = e.find(".moka-input:visible:first")
        # elements with "current" class first
        eee = ee.siblings(".moka-current")
        if eee.length
            ee = eee
    if ee.length
        Moka.focus(ee, o)
        return true
    else
        return false

Moka.onScreen = (e, wnd, how, error) ->
    pos = e.offset()
    if not wnd
        wnd = e.parent()
        ee = wnd[0]
        while ee and wnd.outerWidth() is ee.scrollWidth and wnd.outerHeight() is ee.scrollHeight
            if wnd[0].tagName is "BODY"
                wnd = $(window)
            wnd = wnd.parent()
            ee = wnd[0]
    d = error or 8
    h = if how? then how[0] else ''
    switch h
        when 'b' then return -d <= pos.top+e.height() <= wnd.height()+d
        when 't' then return -d <= pos.top <= wnd.height()+d
        when 'r' then return -d <= pos.left+e.width() <= wnd.width()+d
        when 'l' then return -d <= pos.left <= wnd.width()+d
        when 'B' then return pos.top+e.height() <= wnd.height()+d
        when 'T' then return -d <= pos.top
        when 'R' then return pos.left+e.width() <= wnd.width()+d
        when 'L' then return -d <= pos.left
        else return -e.width()-d <= pos.left <= wnd.width()+d and -e.height()-d <= pos.top <= wnd.height()+d

t_toscreen = null
Moka.toScreen = (e, wnd, o, now) ->
    if now
        t_toscreen.kill()
    else
        if not t_toscreen
            t_toscreen = new Moka.Timer( callback: (data) -> Moka.toScreen(data[0],data[1],data[2],true) )
        t_toscreen.data([e,wnd,o]).start()
        return

    perf_begin()
    o = "lt" if not o

    if not wnd
        wnd = e.parent()
        ee = wnd[0]
        while ee and wnd.outerWidth() is ee.scrollWidth and wnd.outerHeight() is ee.scrollHeight
            if wnd[0].tagName is "BODY"
                wnd = $(window)
                break
            wnd = wnd.parent()
            ee = wnd[0]

    pos = wnd.offset() or {left:0, top:0}
    w = wnd.width()
    h = wnd.height()
    left = wnd.scrollLeft()
    top = wnd.scrollTop()

    cpos = e.offset()
    cw = e.width()
    ch = e.height()
    cleft = cpos.left - pos.left
    ctop = cpos.top - pos.top

    a  = left
    b  = a + w
    ca = cleft + a
    cb = ca + cw
    if 'l' in o
        if ca < a
            left = ca
        else if cb > b
            if cw > w
                left = ca
            else
                left = cb-w
    else if 'r' in o
        if cb > b
            left = cb-w
        else if ca < a
            if cw > w
                left = cb-w
            else
                left = ca

    a  = top
    b  = a + h
    ca = ctop + a
    cb = ca + ch
    if 't' in o
        if ca < a
            top = ca
        else if cb > b
            if ch > h
                top = ca
            else
                top = cb-h
    else if 'b' in o
        if cb > b
            top = cb-h
        else if ca < a
            if ch > h
                top = cb-h
            else
                top = ca

    Moka.scroll(wnd, {left:left, top:top, animate:false})
    perf_end("toScreen ("+o+")")

Moka.scroll = (e, opts) ->
    l = opts.left
    t = opts.top

    a = {}
    if l?
        a.scrollLeft = l + (if opts.relative then e.scrollLeft() else 0)
    if t?
        a.scrollTop = t + (if opts.relative then e.scrollTop() else 0)

    if opts.animate
        l = l or 0
        t = t or 0
        duration = Math.min( 1500, Math.sqrt(l*l+t*t) * (opts.speed or 1) )
        e.stop(true).animate(a, duration, opts.easing, opts.complete)
    else
        e.stop(true, true)
        e.scrollLeft(a.scrollLeft) if l?
        e.scrollTop(a.scrollTop) if t?

class Moka.Timer
    constructor: (options) ->
        @fn = options.callback
        @d = options.data
        @delay = options.delay or 0
        @t = null

    data: (data) ->
        if data?
            @d = data
            return this
        return @d

    isRunning: ->
        return @t isnt null

    start: (delay) ->
        if @t is null
            @t = window.setTimeout(
                @run.bind(this),
                if delay? then delay else @delay
            )
        return this

    restart: (delay) ->
        @kill()
        return @start(delay)

    kill: ->
        if @t isnt null
            window.clearTimeout(@t)
            @t = null
        return this

    run: ->
        @kill()
        @fn(@d)
        return this

class Moka.Thread
    constructor: (options) ->
        # TODO: implement workers
        # filename for Worker
        @filename = options.filename
        # or callback function for Moka.Timer (with delay=0)
        @fn = options.callback
        # if browser doesn't support Workers callback is used

        # data argument is passed to callback and changes to return value
        # of callback every Timer iteration
        # - invoke Timer only while data is not false
        @d = options.data

        @ondata = options.ondata
        @ondone = options.ondone
        @onerror = options.onerror

        @W = window.Worker
        @paused = false

    isRunning: ->
        return not @paused and (@w or @t)

    isPaused: ->
        return @paused

    onDone: (fn) ->
        if fn?
            @ondone = fn
            return this
        return @ondone

    data: (data) ->
        if data?
            @d = data
            return this
        return @d

    kill: ->
        if @w
            @w.terminate()
            @w = null
            @onerror() if @onerror
        else if @t
            @t.kill()
            @t = null
            @onerror() if @onerror
        @paused = false
        return this

    start: ->
        return this if @t or @w
        @paused = false
        if @filename
            if @W
                try
                    w = @w = new @W(@filename)
                    w.onmessage = @_onWorkerMessage.bind(this)
                    w.onerror = @_onWorkerError.bind(this)
                    w.postMessage(@d)
                    return this
                catch error
                    @w = null
                    log "Moka.Thread failed to create Worker (\""+@filename+"\")!",error
            else if not @fn
                @onerror() if @onerror
                dbg "Browser doesn't support Web Workers."
                return this
        @_runInBackground() if @fn
        return this

    restart: ->
        @kill()
        return @start()

    pause: ->
        @paused = true
        if @w
            @w.postMessage("pause")
        else if @t
            @t.kill()
            @t = null
        return this

    resume: ->
        if @paused
            @paused = false
            if @w
                @w.postMessage("resume")
            else if @fn
                @_runInBackground()
        return this

    _onWorkerMessage: (ev) ->
        d = ev.data
        if d is false
            @ondone(@d) if @ondone
            @w.terminate()
            @w = null
        else
            @d = d
            @ondata(d) if @ondata

    _onWorkerError: (ev) ->
        dbg "Worker error: " + ev.message
        @kill()

    _alarm: ->
        d = @fn(@d)
        if d is false
            @ondone(@d) if @ondone
            @t = null
        else
            @d = d
            @ondata(d) if @ondata
            @t.start() if @t isnt null

    _runInBackground: ->
        if not @t
            @t = new Moka.Timer( callback: @_alarm.bind(this) )
        @t.start()

# GUI classes
# only one widget can can be focused at a time
class Moka.Widget
    mainclass: "moka-widget"

    constructor: (from_element) ->
        if from_element instanceof $
            @e = from_element
        else
            @e = $("<div>")
        @addClass(@mainclass)

    mainClass: (cls, replace_all) ->
        if cls?
            @removeClass(@mainclass)
            if replace_all
                @mainclass = cls
            else
                @mainclass = @mainclass.replace(/\s*[^ ]*/, cls)
            @addClass(@mainclass)
            return this
        else
            return @mainclass

    element: ->
        return @e

    show: ->
        @e.show()
        @update()
        @trigger("mokaDone", [false])
        return this

    hide: () ->
        @e.hide()
        return this

    toggle: () ->
        if @isVisible()
            @hide()
        else
            @show()
        return this

    isVisible: () ->
        return @e.is(":visible")

    update: () ->
        return this

    isLoaded: () ->
        return true

    appendTo: (w_or_e) ->
        # append this to widget/element
        if w_or_e instanceof Moka.Widget and w_or_e.append
            w_or_e.append(this)
        else
            @e.appendTo(w_or_e)
        return this

    remove: () ->
        @e.hide()
        @trigger("mokaDestroyed")
        @e.remove()

    parent: () ->
        return @parentWidget

    connect: (event, fn) ->
        @e.bind(event, (ev) => if ev.target is @e[0] then fn.apply(this,arguments))
        return this

    unbind: (event) ->
        @e.unbind(event)
        return this

    bind: (event, fn) ->
        @e.bind(event, fn)
        return this

    one: (event, fn) ->
        @e.one(event, fn)
        return this

    once: (event, fn) ->
        @unbind(event)
        @e.one(event, fn)
        return this

    width: (val) ->
        if val?
            @e.width(val)
            return this
        else
            return @e.width()

    height: (val) ->
        if val?
            @e.height(val)
            return this
        else
            return @e.height()

    resize: (w, h) ->
        @e.width(w) if w?
        @e.height(h) if h?
        return this

    offset: (x, y) ->
        if x?
            @e.offset(x, y)
            return this
        else
            return @e.offset()

    hasFocus: () ->
        return @e.hasClass("moka-focus")

    hasClass: (cls) ->
        return @e.hasClass(cls)

    addClass: (cls) ->
        @e.addClass(cls)
        return this

    removeClass: (cls) ->
        @e.removeClass(cls)
        return this

    trigger: (event, data) ->
        @e.trigger(event, data)
        return this

    outerWidth: (include_margin) ->
        return @e.outerWidth(include_margin)

    outerHeight: (include_margin) ->
        return @e.outerHeight(include_margin)

    align: (alignment) ->
        @e.css("text-align", alignment)
        return this

    tooltip: (tooltip_text) ->
        return @e.attr("title", tooltip_text)

    css: (prop, val) ->
        if val?
            @e.css(prop, val)
            return this
        else
            return @e.css(prop)

    text: (text) ->
        if text?
            @e.text(text)
            return this
        else
            return @e.text()

    html: (html) ->
        if html?
            @e.html(html)
            return this
        else
            return @e.html()

    data: (key, value) ->
        if value?
            @e.data(key, value)
            return this
        else
            return @e.data(key)

    do: (fn) ->
        fn.apply(this, [@e])
        return this

    onChildFocus: (ev) ->
        #log "FOCUS",@e,ev.target
        @addClass("moka-focus")
        p = @parent()
        p.onChildFocus(ev, this) if p
        return false

    onChildBlur: (ev) ->
        #log "BLUR ",@e,ev.target
        @removeClass("moka-focus")
        p = @parent()
        p.onChildBlur(ev, w) if p
        return false

class Moka.Label extends Moka.Widget
    mainclass: Moka.Widget.prototype.mainclass

    constructor: (text, from_element) ->
        if text instanceof $
            e = text
            text = from_element
        else
            e = from_element
        super e

        if text
            @label(text)

    label: (text) ->
        if text?
            if text.length
                # replace _x with underlined character and assign x key
                keyhint = ""
                html = text.replace /_[a-z]/i, (key) ->
                    '<span class="moka-keyhint"' +
                    # delegate click to parent
                    ' onclick="$(this.parentNode).click()">' +
                    (keyhint=key[1]) + '</span>'
                @html(html)
                    .addClass("moka-label")
                    .css("cursor","pointer")
                    .data("keyhint", keyhint.toUpperCase())
            else
                @html("")
                    .removeClass("moka-label")
                    .css("cursor","")
                    .data("keyhint", "")

            return this
        else
            return @e.text()

    keyHint: ->
        return @e.data("keyhint")


class Moka.Input extends Moka.Label
    mainclass: "moka-input "+Moka.Label.prototype.mainclass

    default_keys: {}

    constructor: (text, from_element) ->
        super
        this
            .bind( "focus.moka", (ev) => @onChildFocus(ev); @onFocus(ev); return false )
            .bind( "blur.moka",  (ev) => @onChildBlur(ev); @onBlur(ev);  return false )
            .bind( "mokaFocusUpRequest", () => @focus(); return false )
            .bind( "keydown.moka", (ev) =>
                return @onKeyDown(ev) if !ev.isPropagationStopped()
            )
            .css("cursor","pointer")

        @e_focus = @e
        @tabindex(1)
        @focusableElement(@e)

    focusableElement: (e) ->
        # if widget is focused then element e will recieve focus
        if e?
            ee = @e_focus
            other = @other_focusable = @e[0] isnt e[0]
            if other
                e
                    .attr("tabindex", -1)
                    .unbind(".moka.focusable .moka.notfocusable")
                    .bind( "focus.moka.focusable", (ev) =>
                        Moka.focused( $(ev.target) )
                        @onChildFocus(ev)
                        return false
                    )
                    .bind( "blur.moka.focusable", (ev) =>
                        Moka.unfocused()
                        @onChildBlur(ev)
                        return false
                    )
            @e_focus = e
            return this
        else
            return @e_focus

    addNotFocusableElement: (e) ->
        # steal focus from all non-focusable elements
        e
            .unbind(".moka.focusable .moka.notfocusable")
            .bind( "focus.moka.notfocusable", (ev) =>
                @focus()
                return false
            )
        @focus() if e.is(":focus")
        return this

    removeNotFocusableElement: (e) ->
        e.unbind(".notfocusable")
        return this

    tabindex: (index) ->
        if index?
            @e.attr("tabindex", index)
            return this
        else
            return @e.attr("tabindex", index)

    focus: (o) ->
        perf_begin()
        focused = Moka.focused()
        Moka.focus(@e, o) if not focused or focused[0] isnt @e[0]
        if @other_focusable
            swap_index = (a, b) ->
                a.attr("tabindex", b.attr("tabindex"))
                b.attr("tabindex", -1)
            # in firefox if DOWN key is pressed and <select> element is
            # focused and current <option> changes when DOWN key is released
            # - so focus to focusableElement (e.g. <select>) after
            # a small delay (can be 0)
            @t.kill() if @t
            @t = new Moka.Timer(
                delay: 200
                callback: () =>
                    swap_index.apply(null, [@e_focus, @e])
                    @e_focus.one("blur.moka", swap_index.bind(null, @e, @e_focus))
                    Moka.focus(@e_focus, o)
            ).start()
            @e.one "blur.moka", () => @t.kill()
        perf_end("Input::focus")
        return this

    blur: () ->
        Moka.unfocused()
        return this

    remove: () ->
        ee = @e.parent()
        v = super
        if @hasFocus()
            e = Moka.focused()
            Moka.blur(e) if e
            # focus nearest widget in parent
            while(ee.length)
                if Moka.focusFirst(ee)
                    break
                ee = ee.parent()
        return v

    change: (fn) ->
        return @e.bind("mokaValueChanged", fn)

    addKey: (keyname, fn) ->
        @keys = {} if not @keys
        k = Moka.normalizeKeyName(keyname)
        if @keys[k]
            @keys[k].shift(fn)
        else
            @keys[k] = [fn]
        return this

    onFocus: (ev) ->
        if @other_focusable
            @focus()
        else
            Moka.focused(@e_focus)

    onBlur: (ev) ->
        Moka.unfocused()

    doKey: (keyname) ->
        if @keys? and (fns = @keys[keyname])
            for fn in fns
                return true if fn.apply(this) isnt false
        if (fn = @default_keys[keyname])
            return true if fn.apply(this) isnt false

        return false

    onKeyDown: (ev) ->
        keyname = Moka.getKeyName(ev)
        if @doKey(keyname)
            return false
        # keyhint focusing only once per event
        if ev.target is @e[0]
            Moka.keyhintwidget = this

class Moka.Container extends Moka.Widget
    mainclass: "moka-container "+Moka.Widget.prototype.mainclass
    itemclass: "moka-container-item"

    constructor: (horizontal) ->
        super
        @vertical(if horizontal? then not horizontal else true)
        @widgets = []

    itemClass: (cls) ->
        if cls?
            w = @widgets
            oldcls = @itemclass
            $.each( w, (i) ->
                w[i].removeClass(oldcls)
                    .addClass(cls)
            )
            @itemclass = cls
            return this
        else
            return @itemclass

    update: ->
        w = @widgets
        $.each( w, (i) -> w[i].update() )
        return this

    remove: () ->
        @e.hide()
        w = @widgets
        $.each( w, (i) -> w[i].remove?() ) if w
        return super

    at: (index) ->
        return @widgets[index]

    length: ->
        return @widgets.length

    vertical: (toggle) ->
        if toggle?
            @e.addClass( if toggle then "moka-vertical" else "moka-horizontal" )
            @e.removeClass(if toggle then "moka-horizontal" else "moka-vertical")
            return this
        else
            return @e.hasClass("moka-vertical")

    append: (widgets) ->
        for widget in arguments
            id = @length()
            widget.parentWidget = this
            @widgets.push(widget)

            # first & last
            if id is 0
                widget.addClass("moka-first")
            else
                @at(id-1).removeClass("moka-last")
            widget.addClass(@itemclass+" moka-last")

            widget.appendTo(@e)
                .bind("mokaSizeChanged", @update.bind(this) )
                #.children().focus( @update.bind(this) )

        @update()

        return this

class Moka.WidgetList extends Moka.Input
    mainclass: "moka-widgetlist "+Moka.Input.prototype.mainclass
    itemclass: "moka-widgetlist-item"

    default_keys:
        LEFT:  -> if @vertical() then false else @prev()
        RIGHT: -> if @vertical() then false else @next()
        UP:    -> if @vertical() then @prev() else false
        DOWN:  -> if @vertical() then @next() else false

    constructor: () ->
        super
        this
            .tabindex(-1)
            .bind( "mokaFocusUpRequest", () => @select(Math.max(0, @current)); return false )
            .bind( "mokaFocusNextRequest", () => @next(); return false )
            .bind( "mokaFocusPrevRequest", () => @prev(); return false )

        c = @c = new Moka.Container(false)
            .mainClass("moka-widgetlist-container moka-container")
            .itemClass(@itemclass)
            .appendTo(@e)
        c.parentWidget = this
        @current = -1
        @widgets = [@c]

    mainClass: (cls) ->
        if cls?
            @c.mainClass(cls.split(" ")[0]+"-container")
        return super

    itemClass: (cls) ->
        if cls?
            @c.itemClass(cls)
            @itemclass = cls
            return this
        else
            return @itemclass

    length: () ->
        return @c.length()

    vertical: (toggle) ->
        if toggle?
            @c.vertical(toggle)
            return this
        else
            return @c.vertical()

    at: (index) ->
        return @c.at(index)

    append: (widgets) ->
        for widget in arguments
            id = @length()
            e = widget.e
            @c.append(widget)
            widget.parentWidget = this
            widget.data("widget-index", id)
                #.bind "mousedown.moka", () ->
                    #Moka.focusFirstWidget(widget)
                    #return


        @current = 0 if @current < 0

        return this

    select: (id) ->
        if id >= 0
            w = @at(id)
            Moka.focusFirstWidget(w) if w
        return this

    currentIndex: ->
        return @current

    next: ->
        @select(if @current >= 0 and @current < @length()-1 then @current+1 else 0)

    prev: ->
        l = @length()
        @select(if @current >= 1 && @current < l then @current-1 else l-1)

    focus: ->
        @select(@current)
        return this

    onFocus: ->
        @focus()

    onChildFocus: (ev, w) ->
        if w
            if @current >= 0
                @c.at(@current).removeClass("moka-current")
                @trigger("mokaDeselected", [@current])
            id = @current = w.data("widget-index")
            w.addClass("moka-current")
            @trigger("mokaSelected", [id])
            @update()
        return super

class Moka.CheckBox extends Moka.Input
    mainclass: "moka-checkbox "+Moka.Input.prototype.mainclass

    default_keys:
        SPACE: -> @toggle()

    constructor: (text, checked) ->
        super text

        @checkbox = $('<input>', {type:"checkbox", class:"moka-value"})
            .bind("change.moka", () => @trigger("mokaValueChanged", [@value()]) )
            .prependTo(@e)

        @connect "click.moka", @toggle.bind(this)

        @addNotFocusableElement(@checkbox)
        @value(checked)

    toggle: () ->
        @value(not @value())
        return this

    remove: () ->
        @checkbox.remove()
        return super

    value: (val) ->
        if val?
            v = not not val
            if v isnt @checkbox.is(":checked")
                @trigger("mokaValueChanged", [v])
            @checkbox.attr("checked", v)
            return this
        else
            return @checkbox.is(":checked")

class Moka.Combo extends Moka.Input
    mainclass: "moka-combo "+Moka.Input.prototype.mainclass

    default_keys:
        TAB: -> Moka.focus(@combo)
        SPACE: -> Moka.focus(@combo)

    constructor: (text) ->
        super

        @combo = $('<select>', {class:"moka-value"})
            .attr("tabindex", -1)
            .bind("change.moka", () => @trigger("mokaValueChanged", [@value()]) )
            .appendTo(@e)
        @focusableElement(@combo)

    append: (texts) ->
        for text in arguments
            $("<option>").text(text).attr("value", text).appendTo(@combo)
        return this

    value: (val) ->
        if val?
            @combo.val(val)
            return this
        else
            return @combo.val()

    remove: () ->
        @combo.remove()
        return super

    onKeyDown: (ev) ->
        if ev.target is @combo[0]
            keyname = Moka.getKeyName(ev)
            if ["LEFT", "RIGHT", "UP", "DOWN", "SPACE", "ENTER"]
               .indexOf(keyname) >= 0
                ev.stopPropagation()
        else
            super

class Moka.LineEdit extends Moka.Input
    mainclass: "moka-lineedit "+Moka.Input.prototype.mainclass

    default_keys: {}

    constructor: (label_text, text) ->
        super label_text
        @edit = $("<input>")
            .appendTo(@e)
            .bind( "change.moka", () => @trigger("mokaValueChanged", [@value()]) )
            .keyup( @update.bind(this) )
        @value(text) if text?
        @focusableElement(@edit)

    remove: () ->
        Moka.blur(@edit)
        @edit.remove()
        return super

    update: () ->
        @edit.attr( "size", @value().length+2 )

    value: (text) ->
        if text?
            @edit.attr("value", text)
            return this
        else
            return @edit.attr("value")

    onKeyDown: (ev) ->
        keyname = Moka.getKeyName(ev)

        return false if @doKey(keyname)

        k = keyname.split('-')
        k = k[k.length-1]
        if k.length is 1 or ["LEFT", "RIGHT", "BACKSPACE", "DELETE", "MINUS", "SPACE"].indexOf(k) >= 0
            ev.stopPropagation()

class Moka.TextEdit extends Moka.Input
    mainclass: "moka-textedit "+Moka.Input.prototype.mainclass

    default_keys:
        ENTER: -> Moka.focus(@editor.win)

    constructor: (label_text, text) ->
        super label_text
        @text = text or ""
        @textarea = $("<textarea>")
            .appendTo(@e)
            .bind( "change.moka", () => @trigger("mokaValueChanged", [@value()]) )
        @focusableElement(@textarea)

    remove: () ->
        Moka.blur(@textarea)
        @textarea.remove()
        return super

    value: (text) ->
        if text?
            @textarea.value(text)
            @text = text
            return this
        else
            return @text

    onKeyDown: (ev) ->
        ev.stopPropagation()
        return false if @doKey( Moka.getKeyName(ev) )

# TODO: add button icon
class Moka.Button extends Moka.Input
    mainclass: "moka-button "+Moka.Input.prototype.mainclass

    default_keys:
        ENTER: -> @press()
        SPACE: -> @press()

    constructor: (label_text, onclick, tooltip) ->
        super label_text
        @connect "click.moka", onclick
        @tooltip(tooltip) if tooltip

    press: ->
        @e.click()
        return this

class Moka.ButtonBox extends Moka.WidgetList
    mainclass: "moka-buttonbox "+Moka.WidgetList.prototype.mainclass
    itemclass: "moka-buttonbox-item"

    constructor: ->
        super
        @vertical(false)

    append: (label_text, onclick, tooltip) ->
        widget = new Moka.Button(label_text, onclick, tooltip)
        super widget
        @update()

        return this

class Moka.Tabs extends Moka.WidgetList
    mainclass: "moka-tabwidget "+Moka.WidgetList.prototype.mainclass
    itemclass: "moka-tabwidget-item"

    default_keys:
        SPACE: -> @pages.e.slideToggle()

        LEFT: ->  if @vertical() then @focusUp() else @prev()
        RIGHT: -> if @vertical() then @focusDown() else @next()
        UP: -> if @vertical() then @prev() else @focusUp()
        DOWN: -> if @vertical() then @next() else @focusDown()

        PAGEUP: -> if @vertical() then @tabs.select(0)
        PAGEDOWN: -> if @vertical() then @tabs.select(@tabs.length()-1)
        HOME: -> if not @vertical() then @tabs.select(0)
        END: -> if not @vertical() then @tabs.select(@tabs.length()-1)

        TAB: ->
            return false if @pageHasFocus()
            page = @currentPage()
            if page
                Moka.focusFirstWidget(page, true)
            else
                return false

    constructor: ->
        super

        @tabs = new Moka.WidgetList()
            .appendTo(this)
            .mainClass("moka-tabs")
            .itemClass("moka-tab")
            .connect "mokaSelected", (ev, id) =>
                i = @currentpage
                if i >= 0
                    @tab(i).tabindex(-1)
                    @page(i).hide()
                @tabs.at(id).tabindex(1)
                @pages.at(id).show()
                @currentpage = id

        @pages = new Moka.Container()
            .appendTo(this)
            .mainClass("moka-pages")
            .itemClass("moka-page")

        @currentpage = -1
        @vertical(false)

    vertical: (toggle) ->
        if toggle?
            @tabs.vertical(toggle)
            super not toggle
            return this
        return @tabs.vertical()

    tab: (i) ->
        return @tabs.at(i)

    page: (i) ->
        return @pages.at(i)

    currentPage: ->
        return @page(@currentpage)

    update: ->
        # update active page
        @currentPage()?.update()
        return this

    pageHasFocus: () ->
        return @currentPage()?.hasFocus()

    focusUp: () ->
        if @pageHasFocus()
            @select(Math.max(0, @current))
        else
            @parent()?.trigger("mokaFocusUpRequest")
        return this

    focusDown: () ->
        Moka.focusFirstWidget( @currentPage() )
        return this

    append: (tabname, widget) ->
        if tabname instanceof Moka.Widget
            tmp = tabname; tabname = widget; widget = tmp
        if not tabname
            super widget
            return this

        tab = new Moka.Input(tabname)
            .appendTo(@tabs)
            .tabindex(-1)

        # TODO: select tab if something was programatically focused on the page
        widget
            .hide()
            .appendTo(@pages)

        @update()

        return this

    next: ->
        @tabs.next()
        return this

    prev: ->
        @tabs.prev()
        return this

class Moka.Image extends Moka.Widget
    mainclass: "moka-image "+Moka.Widget.prototype.mainclass

    constructor: (@src, w, h, onload, onerror) ->
        super $("<img>", width:w, height:h)
        @img = @e
        @owidth = @oheight = 0
        @e.one( "load",
            () =>
                @ok = true

                img = @img[0]
                @owidth  = img.naturalWidth
                @oheight = img.naturalHeight
                onload?()
        )
        @e.one( "error",
            () =>
                @ok = false
                @width = @height = 0
                onerror?()
        )
        @e.attr("src", @src)

    isLoaded: () ->
        return @ok?

    originalWidth: () ->
        return @owidth

    originalHeight: () ->
        return @oheight

class Moka.Canvas extends Moka.Widget
    mainclass: "moka-canvas "+Moka.Widget.prototype.mainclass

    constructor: (@src, w, h, onload, onerror) ->
        # try to use WebGL
        e = null
        super $("<canvas>")
        @ctx = @e[0].getContext("2d")

        @t_draw = new Moka.Timer( callback: @draw.bind(this) )

        @owidth = @oheight = 0
        @img = $("<img>", width:w, height:h)
        @img.one( "load.moka",
            () =>
                @img.unbind("error.moka")
                @ok = true
                img = @img[0]
                @owidth  = img.naturalWidth
                @oheight = img.naturalHeight
                onload() if onload
        )
        @img.one( "error.moka",
            () =>
                @ok = false
                onerror() if onerror
        )
        @img.attr("src", @src)

    originalWidth: () ->
        return @owidth

    originalHeight: () ->
        return @oheight

    show: ->
        # resume filtering
        @t_filter.resume() if @t_filter and @t_filter.isPaused()
        return super

    hide: ->
        # pause filtering
        @t_filter.pause() if @t_filter
        return super

    resize: (w, h) ->
        w = parseInt(w)
        h = parseInt(h)
        return this if not @ok or w<=0 or h<=0
        e = @e[0]
        if e.width isnt w or e.height isnt h
            e.width = w
            e.height = h
            if @t_filter
                @t_filter.kill()
                @t_filter = null
            img = @img[0]
            @ctx.clearRect(0, 0, w, h)
            @ctx.drawImage(img, 0, 0, w, h)
            @t_draw.data(0).start()

        return this

    draw: (data) ->
        return this if not @ok

        if data
            @ctx.putImageData(data, 0, 0)
        else
            @filter()

        return this

    isLoaded: () ->
        return @ok?

    filter: () ->
        return this if not @ok or not @t_filter_first

        e = @e[0]
        w = e.width
        h = e.height

        @t_filter.kill() if @t_filter
        @t_filter = @t_filter_first
            .data(
                dataDesc: @ctx.getImageData(0, 0, w, h)
                dataDescCopy: @ctx.getImageData(0, 0, w, h)
            ).start()
        @t_filter.pause() if not @isVisible()

        return this

    addFilter: (filename, callback) ->
        t = new Moka.Thread(
            callback: callback
            filename: filename
            ondata: (data) =>
                @t_draw.data(data).start(50)
            ondone: (data) =>
                @t_draw.data(data).run()
                @t_filter = null
        )

        if @t_filter_first
            @t_filter_last.onDone (data) =>
                @t_draw.data(data).run()
                e = @e[0]
                w = Math.ceil(e.width)
                h = Math.ceil(e.height)
                @t_filter = t
                    .data(
                        dataDesc: data
                        dataDescCopy: @ctx.getImageData(0, 0, w, h)
                    ).start()
        else
            @t_filter_first = t
        @t_filter_last = t

        return this

class Moka.ImageView extends Moka.Input
    mainclass: "moka-imageview "+Moka.Input.prototype.mainclass

    default_keys: {}

    constructor: (@src, @use_canvas, @filters) ->
        super()

    show: (callback) ->
        if @image
            if @t_remove
                @t_remove.kill()
                @t_remove = null
                @image.show()
            @zoom(@zhow)
            @e.show()
            callback(this) if callback
        else
            onload = () =>
                @ok = true
                @zoom(@zhow)
                callback(this) if callback
            onerror = () =>
                @ok = false
                callback(this) if callback
            if @use_canvas
                image = @image = new Moka.Canvas(@src, "", "", onload, onerror)
                for f in @filters
                    image.addFilter(f.filename, f.callback)
            else
                image = @image = new Moka.Image(@src, "", "", onload, onerror)
            image.appendTo(@e)
                .css('max-width':"100%", 'max-height':"100%")
            @e.show()
        return this

    hide: () ->
        @e.hide()
        if @image? and not @t_remove
            @image.hide()
            # delay resource removal
            @t_remove = new Moka.Timer(
                delay: 60000
                callback: () =>
                    dbg "removing image", @image.img.attr("src")
                    @ok = null
                    @image.img.attr("src", "")
                    @image.remove()
                    @image = null
                    @t_remove = null
                    @z = null
            ).start()
        return super

    remove: ->
        @e.hide()
        if @image
            @image.img.attr("src", "")
            @image.remove()
            @t_remove.kill() if @t_remove
        return super

    isLoaded: () ->
        return @ok is true or @ok is false

    originalWidth: () ->
        return @image.originalWidth()

    originalHeight: () ->
        return @image.originalHeight()

    resize: (w, h) ->
        super
        @image.resize(w, h) if @image
        return this

    zoom: (how) ->
        if how?
            return this if @z is how
            @zhow = how
            zhow = if how instanceof Array then how[2] else null

            if @ok
                width = @image.originalWidth()
                height = @image.originalHeight()
                if how instanceof Array
                    w = how[0]
                    h = how[1]

                    d = w/h
                    d2 = width/height
                    if zhow is "fill"
                        if d > d2
                            h = Math.floor(w/d2)
                        else
                            w = Math.floor(h*d2)
                    else
                        if width > w or height > h
                            if d > d2
                                w = Math.floor(h*d2)
                            else
                                h = Math.floor(w/d2)
                        else
                            w = width
                            h = height
                else
                    z = parseFloat(how) or 1
                    w = Math.floor(z*@image.originalWidth())
                    h = Math.floor(z*@image.originalHeight())

                @resize(w, h)
                @zhow = @z = how
            else if zhow is "fit"
                @css(width:how[0], height:how[1])

            return this
        else
            return @z

class Moka.Viewer extends Moka.Input
    mainclass: "moka-viewer "+Moka.Input.prototype.mainclass

    default_keys:
        RIGHT: ->
            if @cell(@current).width()-8 <= @e.width() and
               (Moka.onScreen(Moka.focused(), @e, 'R') or not Moka.onScreen(Moka.focused(), @e, 'l'))
                @focusRight()
            else
                Moka.scroll(@e, {left:30, relative:true})
        LEFT: ->
            if @cell(@current).width()-8 <= @e.width() and
               (Moka.onScreen(Moka.focused(), @e, 'L') or not Moka.onScreen(Moka.focused(), @e, 'r'))
                @focusLeft()
            else
                Moka.scroll(@e, {left:-30, relative:true})
        UP: ->
            if @cell(@current).height()-8 <= @e.height() and
               (Moka.onScreen(Moka.focused(), @e, 'T') or not Moka.onScreen(Moka.focused(), @e, 'b'))
                @focusUp()
            else
                Moka.scroll(@e, {top:-30, relative:true})
        DOWN: ->
            if @cell(@current).height()-8 <= @e.height() and
               (Moka.onScreen(Moka.focused(), @e, 'B') or not Moka.onScreen(Moka.focused(), @e, 't'))
                @focusDown()
            else
                Moka.scroll(@e, {top:30, relative:true})
        KP6: -> if 'l' in @orientation() then @next() else @prev()
        KP4: -> if 'r' in @orientation() then @next() else @prev()
        KP2: -> if 't' in @orientation() then @next() else @prev()
        KP8: -> if 'b' in @orientation() then @next() else @prev()

        TAB: ->
            if @index + @current + 1 < @itemCount() and @current + 1 < @cellCount()
                @next()
            else
                return false
        'S-TAB': -> if @current > 0 then @prev() else false

        SPACE: ->
            how = @orientation()[1]
            switch how
                when 't' then how = 'b'
                when 'l' then how = 'r'
                when 'r' then how = 'l'
                else how = 't'
            if Moka.onScreen(Moka.focused(), @e, how)
                @next()
            else
                opts = {relative:true}
                val = if how is 'l' or how is 't' then -1 else 1
                if how is 'l' or how is 'r'
                    opts.left = val*0.9*@e.parent().width()
                else
                    opts.top = val*0.9*@e.parent().height()
                Moka.scroll(@e, opts)
        'S-SPACE': ->
            how = @orientation()[1]
            if Moka.onScreen(Moka.focused(), @e, how)
                @prev()
                switch how
                    when 't' then how = 'b'
                    when 'l' then how = 'r'
                    when 'r' then how = 'l'
                    else how = 't'
                Moka.toScreen(Moka.focused(), @e, how)
                Moka.scroll(@e, {animate:false})
            else
                opts = {relative:true}
                val = if how is 'l' or how is 't' then -1 else 1
                if how is 'l' or how is 'r'
                    opts.left = val*0.9*@e.parent().width()
                else
                    opts.top = val*0.9*@e.parent().height()
                Moka.scroll(@e, opts)

        ENTER: -> @onDoubleClick()

        '*': -> @layout([1,1]); @zoom(1)
        '/': -> if @zhow is "fit" then @zoom(1) else @zoom("fit")
        '+': -> @zoom("+")
        '.': -> if @zhow is "fill" then @zoom(1) else @zoom("fill")
        MINUS: -> @zoom("-")

        KP7: -> @select(0)
        HOME: -> @select(0)
        KP1: -> @select(@itemCount()-1)
        END: -> @select(@itemCount()-1)
        PAGEUP: ->
            len = @cellCount()
            if @current%len is 0
                @select(@index-len)
            else
                @select(@index)
        PAGEDOWN: ->
            len = @cellCount()
            if (@current+1)%len is 0
                @select(@index+len)
            else
                @select(@index+len-1)

        H: -> @layout([@lay[0]+1, @lay[1]])
        V: -> @layout([@lay[0], @lay[1]+1])
        'S-H': -> @layout([@lay[0]-1, @lay[1]])
        'S-V': -> @layout([@lay[0], @lay[1]-1])

    constructor: () ->
        super

        @t_update = new Moka.Timer(
            delay:100
            callback:@updateVisible.bind(this, true)
        )
        @preload_session = 0
        @cache = {}

        @w = 0
        @h = 0

        this
            #.bind( "resize.moka", @update.bind(this) )
            .bind( "scroll.moka", @onScroll.bind(this) )
            .css("cursor", "move")
            .tabindex(1)
            .bind( "mokaFocusUpRequest", () => @select(@index + @current); return false )
            .bind( "mousedown.moka", @onMouseDown.bind(this) )
            .bind( "dblclick.moka", @onDoubleClick.bind(this) )

        # FIXME: firefox: scroll is restored on page refresh
        #        - this misbehaves if items are not yet loaded
        $(window).bind( "unload.moka", () =>
            @e.unbind("scroll.moka")
            Moka.scroll(@e, {left:0, top:0})
            @e.hide()
        )

        Moka.initDragScroll(@e)

        $(window).bind("resize.moka", @update.bind(this) )

        @table = $("<table>", class:"moka-table", border:0, cellSpacing:0, cellPadding:0)
                .appendTo(@e)

        @cells = []
        @items = []

        # index of first item on current page
        @index = -1
        # index of selected cell in viewer (from left to right, top to bottom)
        @current = -1

        # preload item if it is less than preload_offset pixels away
        @preload_offset = 400

        @orientation("lt")
        @layout([1,1])
        @zoom(1)

    update: ->
        @focus() if @hasFocus()

        return this

    appendTo: (w_or_e) ->
        super
        @zoom(@zoom())
        return this

    focus: (ev) ->
        cell = @cell(@current) or @cell(0)
        Moka.focus(cell) if cell
        return this

    append: (widget_or_fn, length) ->
        if length
            fn = widget_or_fn
            last = @itemCount()
            itemfn = (index) -> return fn(index-last)

            i = last
            l = i+length
            while i<l
                @items.push(itemfn)
                ++i
        else
            widget = widget_or_fn
            id = @itemCount()
            widget.parentWidget = this
            @items.push(widget)

        lay = @layout()
        if not @cells.length or
           not lay[0] or not lay[1] or
           (@index > -1 and @index + @cellCount() > i)
            @updateTable()

        @update()

        return this

    item: (index) ->
        x = @items[index]
        if x instanceof Function
            x = @items[index] = x(index)
            x.parentWidget = this
        return x

    clean: () ->
        i = 0
        l = @itemCount()
        while i < l
            x = @items[i]
            if x not instanceof Function
                x.remove()
            ++i
        @items = []
        return this

    remove: () ->
        cache = @cache
        for it in cache
            it.remove()
        for cell in @cells
            cell.remove()
        return super

    currentIndex: () ->
        return if @current >= 0 then @index + @current else -1

    currentItem: () ->
        i = @currentIndex()
        if i >= 0
            return @item(i)
        else
            return null

    itemCount: () ->
        return @items.length

    clear: () ->
        # clear cells
        perf_begin()
        i = -1
        len = @cellCount()+1
        while i < len
            item = @items[@index+i]
            if item and item not instanceof Function
                item.hide()
                item.e.detach()
            ++i
        perf_end("Viewer::clear")

    view: (id) ->
        return this if id >= @itemCount() or id < 0

        perf_begin()

        #@table.hide()

        @clear()

        i = 0
        len = @cellCount()
        len1 = Math.min(len, @items.length)
        j = @index = Math.floor(id/len)*len
        dbg "displaying views", @index+".."+(@index+len-1)
        while i < len1
            @cell(i++)
                .data("itemindex", j++)
                .attr("tabindex", -1)
        # empty cells (no items left)
        while i < len
            @cell(i++).attr("tabindex", "")

        @zoom(@zoom())

        #@table.show()

        @updateVisible()

        perf_end("Viewer::view")

        return this

    select: (id) ->
        return this if id < 0 or id >= @itemCount()

        dbg "selecting view", id

        perf_begin()
        len = @cellCount()
        cell_id = id%len

        if @index is -1 or id < @index or id >= @index+len
            @view(id)
        else
            item = @items[id]
            if not (item instanceof Function or item.isVisible())
                @updateVisible()

        cell = @cell(cell_id)
        Moka.toScreen(cell, @e, @o, true)
        Moka.focus(cell)
        perf_end("Viewer::select")

        return this

    zoom: (how) ->
        if how?
            perf_begin()
            @zhow = null
            if how is "fit" or how is "fill"
                l = @layout()
                ww = @e.width()
                hh = @e.height()
                c = @cell(0)
                w = Math.max( 16, Math.floor( ww/l[0] ) - c.outerWidth(true) + c.width() )
                h = Math.max( 16, Math.floor( hh/l[1] ) - c.outerHeight(true) + c.height() )

                @z = [w, h, how]
                @zhow = how
            else if how is "+" or how is "-"
                if @z instanceof Array
                    d = if how is "-" then 0.889 else 1.125
                    w = Math.max( 16, Math.ceil(@z[0]*d) )
                    h = Math.max( 16, Math.ceil(@z[1]*d) )
                    @z = [w, h, @z[2]]
                else
                    if not @z
                        @z = 1
                    @z += if how is "-" then -0.125 else 0.125
            else if how instanceof Array
                @z = how
            else
                factor = parseFloat(how) or 1
                @z = factor

            if @index > -1
                dbg "zooming views using method", @z

                # zoom items in cache
                z = @z
                for i,item of @cache
                    item.zoom(z) if item.zoom

                Moka.toScreen( @cell(@current), @e, @o ) if @current >= 0
                @updateVisible()
            perf_end("Viewer::zoom")
            @trigger("mokaZoomChanged")

            return this
        else
            return if @zhow then @zhow else @z

    #length: () ->
        #return @cells.length

    cellCount: ->
        return @cells.length

    next: (skip) ->
        @select(@index + @current + (if skip then skip else 1))
        return this

    prev: (skip) ->
        @select(@index + @current - (if skip then skip else 1))
        return this

    nextRow: () ->
        @select(@index + @current + @layout()[0])
        return this

    prevRow: () ->
        @select(@index + @current - @layout()[0])
        return this

    nextPage: () ->
        @select(@index + @cellCount())
        return this

    prevPage: () ->
        @select(@index - @cellCount())
        return this

    focusLeft: () ->
        h = @layout()[0]
        id = @current - 1
        if (id+1) % h is 0
            cell = @cell(id+h)
            id = cell.data("itemindex")
            how = -@cellCount()
            if "r" in @o
                how = -how
            @select(id + how)
        else
            cell = @cell(id)
            if cell
                id = cell.data("itemindex")
                @select(id)
        return this

    focusRight: () ->
        h = @layout()[0]
        id = @current + 1
        if id % h is 0
            cell = @cell(id-h)
            id = cell.data("itemindex")
            how = @cellCount()
            if "r" in @o
                how = -how
            @select( Math.min(id + how, @itemCount()-1) )
        else
            cell = @cell(id)
            if cell
                id = cell.data("itemindex")
                @select(id)
        return this

    focusUp: () ->
        h = @layout()[0]
        id = @current - h
        if id < 0
            len = @cellCount()
            cell = @cell(id+len)
            id = cell.data("itemindex")
            how = -@cellCount()
            if "b" in @o
                how = -how
            @select(id + how)
        else
            cell = @cell(id)
            if cell
                id = cell.data("itemindex")
                @select(id)
        return this

    focusDown: () ->
        h = @layout()[0]
        len = @cellCount()
        id = @current + h
        if id >= len
            cell = @cell(id-len)
            id = cell.data("itemindex")
            how = @cellCount()
            if "b" in @o
                how = -how
            @select( Math.min(id + how, @itemCount()-1) )
        else
            cell = @cell(id)
            if cell
                id = cell.data("itemindex")
                @select(id)
        return this


    appendRow: (table) ->
        return $("<tr>", class:"moka-row").appendTo(table)

    appendCell: (row) ->
        cell = $("<div>")
        cell.addClass("moka-view")
            .css(
                width: @e.width()/2
                height: @e.height()/2
                overflow:"hidden"
            )
            .appendTo( $("<td align='center'>").appendTo(row) )
        cell[0].onfocus = @onChildFocus.bind(this)
        @cells.push(cell)

        return cell

    #at: (index) ->
        #return @items[@index+index]

    cell: (index) ->
        return @cells[ @indexfn(index) ]

    updateTable: () ->
        perf_begin()
        table = @table.hide()
        @clear()
        table.empty()
        @cells = []
        @index = -1

        layout = @layout()
        ilen = layout[0]
        jlen = layout[1]

        j = 0
        while j < jlen
            i = 0
            row = @appendRow(table)
            @appendCell(row) while ++i <= ilen
            ++j

        @table.show()
        perf_end("Viewer::updateTable")

    layout: (layout) ->
        if layout
            x = Math.max( 0, Number(layout[0]) or 0 )
            y = Math.max( 0, Number(layout[1]) or 0 )
            return this if (not x and not y) or (@lay and x is @lay[0] and y is @lay[1])

            perf_begin()
            @e.removeClass("moka-layout-"+@lay.join("x")) if @lay
            @lay = [x, y]
            @e.addClass("moka-layout-"+@lay.join("x"))

            dbg "setting layout", @lay

            focused = @hasFocus()
            id = if @current > -1 then @index+@current else @index
            @updateTable()
            cell = @cell(@current)
            cell.addClass("moka-current") if cell
            @current = @currentindex = 0
            @view(id)
            @select(id) if focused
            perf_end("Viewer::layout")

            @trigger("mokaLayoutChanged")

            return this
        else
            i = @lay[0]
            j = @lay[1]
            if i is 0
                i = Math.ceil( @itemCount()/j )
            else if j is 0
                j = Math.ceil( @itemCount()/i )
            return [i, j]

    orientation: (o) ->
        if o
            perf_begin()
            # TODO: correctly parse orientation string
            # (length is 2 and it contains items: (L or R) and (T or B))
            @o = ""
            x = o.toLowerCase().split(" ")
            if x.length < 2
                x = o.toLowerCase().split(///%20|-|_///)
            if x.length < 2
                a = x[0][0]
                b = x[0][1]
            else
                a = x[0][0]
                b = x[1][0]
            if a in "lr"
                @o += a
                if b in "tb"
                    @o += b
            else if a in "tb"
                @o += a
                if b in "lr"
                    @o += b
            if @o.length isnt 2
                dbg "cannot parse orientation ('#{o}'); resetting to 'left top'"
                @o = "lt"

            dbg "setting orientation", o

            switch @o
                when "rt" then fn = (id,x,y) -> i=id%x; j=Math.floor(id/x);   x-1 - i + j*x
                when "lb" then fn = (id,x,y) -> i=id%x; j=Math.floor(id/x); x*y-x + i - j*x
                when "rb" then fn = (id,x,y) -> i=id%x; j=Math.floor(id/x); x*y-1 - i - j*x

                when "tl" then fn = (id,x,y) -> i=id%y; j=Math.floor(id/y);               i*x + j
                when "tr" then fn = (id,x,y) -> i=id%y; j=Math.floor(id/y); x*y-1 - (y-1-i)*x - j
                when "bl" then fn = (id,x,y) -> i=id%y; j=Math.floor(id/y);         (y-1-i)*x + j
                when "br" then fn = (id,x,y) -> i=id%y; j=Math.floor(id/y); x*y-1 -       i*x - j

            # index function: view index -> cell index
            if fn
                @indexfn = (id) =>
                    l = @layout()
                    return fn(id, l[0], l[1])
            else
                @indexfn = (id) -> id

            @view(@index)
            perf_end("Viewer::orientation")

            return this
        else
            return @o

    _itemOnLoad: (item, cell, next, msg) ->
        if msg.cancel
            dbg " CANCELED"
            return

        item.css("opacity", 1)
        w = item.width()
        h = item.height()
        if w>0 and h>0
            cell.css(
                width: w
                height: h
            )
        else
            cell.css(
                width: "auto"
                height: "auto"
            )

        # focus
        focused = Moka.focused()
        if focused and focused[0] is cell[0]
            Moka.focusFirstWidget(item)

        # TODO: better scroll offset restoring
        if @preload_e
            pos1 = @preload_pos
            pos2 = @preload_e.offset()
            if pos2.left isnt pos1.left or pos2.top isnt pos1.top
                Moka.scroll(@e, {
                    left: pos2.left-pos1.left
                    top:  pos2.top-pos1.top
                    relative: true
                })
                @ignore_onscroll = true
                window.setTimeout(
                    (() =>
                        @ignore_onscroll = false
                        if Moka.scrolling
                            Moka.from_mouseX += pos2.left-pos1.left
                            Moka.from_mouseY += pos2.top-pos1.top
                        next()
                    ), 0
                )
            else
                next()
        else
            e = @preload_e = cell
            @preload_pos = e.offset()
            next()

    _preloadItems: (index, direction, cache, ondone, msg) ->
        if msg.cancel
            dbg " CANCELED"
            return

        item = @item(index)
        cell = @cell(index-@index)

        # done?
        if not item
            dbg " DONE (no more items avalable)"
        else if not (cell and cell.length)
            dbg "  preloading view", index
            item.zoom(@z) if item.zoom
            item.show()
            dbg " DONE (view", index, "is off table)"
        else
            next = @_preloadItems.bind(this, index+direction, direction, cache, ondone, msg)
            # is item on screen or should it be preloaded?
            if Moka.onScreen(cell, @e, null, @preload_offset)
                dbg "  loading view", index
                @notloaded = 0

                if index in cache
                    delete cache[index]
                else
                    item.zoom(@z) if item.zoom

                if @z[2] is "fit"
                    cell.css(
                        width: @z[0]
                        height: @z[1]
                    )
                else
                    cell.css(
                        width: cell.width()
                        height: cell.height()
                    )

                if not item.e.parent().length
                    item.css("opacity", 0).appendTo(cell)

                item.show( @_itemOnLoad.bind(this, item, cell, next, msg) )

                @cache[index] = item
                return
            else
                # hide offscreen items
                if item.isVisible() and not item.hasFocus()
                    dbg "  hiding view", index
                    # save cell size before hiding item
                    cell.css(
                        width: cell.width()
                        height: cell.height()
                    )
                    item.hide()

                if ++@notloaded > @maxnotloaded
                    dbg " DONE (rest views are off screen)"
                else
                    return next()

        # done
        ondone() if ondone

        return

    updateVisible: (now) ->
        return this if @index is -1

        if @loading
            @msg.cancel = true if @msg

        if not now
            @t_update.start()
        else
            perf_begin()
            @t_update.kill()
            @cancel = false
            @notloaded = 0
            lay = @layout()
            @maxnotloaded = if lay[1] > 1 then lay[0] else 1

            cache = @cache
            @cache = {}

            # preload items from first visible cell or current
            index = @current+@index
            item = @item(index)
            if not Moka.onScreen(item.e, @e, null, @preload_offset)
                i = 0
                while (cell = @cell(i++)) and not Moka.onScreen(cell, @e, null, @preload_offset) then
                index = cell.data("itemindex") if cell
                item = @item(index)

            dbg "loading views starting from "+index+" ..."+@e.scrollLeft()
            ondone2 = () =>
                # clear rest of the old cache
                for it in cache
                    it.hide()
                @loading = false
            ondone1 = () =>
                @_preloadItems(index-1, -1, cache, ondone2, msg)
            @loading = true
            msg = @msg = {}
            @preload_e = @preload_pos = null
            @_preloadItems(index, 1, cache, ondone1, msg)
            perf_end("Viewer::updateVisible")

        return this

    onFocus: ->
        @focus()

    onScroll: (ev) ->
        return if @ignore_onscroll
        lay = @layout()
        if lay[0] isnt 1 or lay[1] isnt 1
            return @updateVisible()

    onMouseDown: (ev) ->
        if ev.button is 1
            if @zhow is "fit" then @zoom(1) else @zoom("fit")

    onDoubleClick: () ->
        if @oldlay
            lay = @oldlay
            z = @oldzoom
        else
            lay = [1,1]
            z = 1

        @oldlay = @layout()
        @oldzoom = @zoom()

        if lay[0] is @oldlay[0] and lay[1] is @oldlay[1] and z is @oldzoom
            lay = [1,1]
            z = 1

        @layout(lay)
        @zoom(z)

    onChildFocus: (ev, w) ->
        cell = if w then w.e.parent() else $(ev.target)
        i = cell.data("itemindex")
        if i >= 0
            if not w
                item = @item(i)
                if item.isVisible() and Moka.focusFirstWidget(item)
                    return false
                else
                    Moka.focused(cell)

            id = i-@index
            current = @current

            oldcell = @cell(current)
            if oldcell
                oldcell.removeClass("moka-current")
                @trigger("mokaDeselected", [@index + @current])
            @currentindex = i
            @current = id

            cell.addClass("moka-current")
            @trigger("mokaSelected", [i])

        return super

class Moka.Notification extends Moka.Widget
    mainclass: "moka-notification "+Moka.Widget.prototype.mainclass

    constructor: (html, notification_class, delay, @animation_speed) ->
        super
        if not Moka.notificationLayer?
            Moka.notificationLayer =
                $("<div>", id:"moka-notification-layer")
                    .appendTo("body")
        delay = 8000 if not delay?
        @animation_speed = 1000 if not @animation_speed?

        @e.addClass(notification_class)
          .hide()
          .html(html)
          .bind( "mouseenter.moka", () => @t_notify.kill() )
          .bind( "mouseleave.moka", () => @t_notify.restart(delay/2) )
          .appendTo(Moka.notificationLayer)
          .fadeIn(@animation_speed)

        @t_notify = new Moka.Timer(
            delay:delay
            callback:@remove.bind(this)
        ).start()

    remove: () ->
        @t_notify.kill()
        @e.hide(@animation_speed, super)

Moka.clearNotifications = () ->
    Moka.notificationLayer?.empty()

class Moka.Window extends Moka.Input
    mainclass: "moka-window "+Moka.Input.prototype.mainclass

    default_keys:
        ESCAPE: -> @close()
        F4: -> @close()
        F2: -> @title.focus()
        F3: ->
            return @searchwnd.focus() if @searchwnd
            wnd = @searchwnd = new Moka.Window("Search")
            edit = new Moka.LineEdit("Find string:")
            tofocus = null
            val = ""
            w = this

            search = (next) ->
                oldtofocus = tofocus
                opts = {text:val, next:next is true, prev:next is false}
                tofocus = Moka.findInput(w.body, opts)
                oldtofocus.removeClass("moka-found") if oldtofocus
                tofocus.addClass("moka-found") if tofocus
            wnd.addKey "F3", () ->
                search(true)
            wnd.addKey "S-F3", () ->
                search(false)
            wnd.addKey "ESCAPE", () ->
                wnd.close()
            edit.bind "keyup.moka", (ev) =>
                v = edit.value()
                if v isnt val
                    val = v
                    search()
            wnd.addKey "ENTER", () =>
                tofocus.focus() if tofocus
                wnd.close()
            wnd.connect "mokaDestroyed", () =>
                tofocus.removeClass("moka-found") if tofocus
                @searchwnd = null
            w.connect "mokaDestroyed", () -> wnd.remove()

            pos = @position()
            wnd.append(edit)
               .appendTo( @e.parent() )
               .position(pos.left-50, pos.top-50)
               .show()
               .focus()
        LEFT: ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.left -= 20
            @e.offset(pos)
        RIGHT: ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.left += 20
            @e.offset(pos)
        UP: ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.top -= 20
            @e.offset(pos)
        DOWN: ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.top += 20
            @e.offset(pos)
        'S-LEFT': ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.left = 0
            @e.offset(pos)
        'S-RIGHT': ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.left = @e.parent().innerWidth() - @e.outerWidth(true)
            @e.offset(pos)
        'S-UP': ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.top = 0
            @e.offset(pos)
        'S-DOWN': ->
            return false if not @titleHasFocus()
            pos = @e.offset()
            pos.top = @e.parent().innerHeight() - @e.outerHeight(true)
            @e.offset(pos)
        'C-LEFT':  -> @nextWindow("left", -1)
        'C-RIGHT': -> @nextWindow("left", 1)
        'C-UP':    -> @nextWindow("top", -1)
        'C-DOWN':  -> @nextWindow("top", 1)
        SPACE: ->
            return false if not @titleHasFocus()
            @body.toggle()

    constructor: (title, from_element) ->
        if title instanceof $
            tmp = title; title = from_element; from_element = tmp
        super from_element
        self = this
        this
            .tabindex(-1)
            .hide()
            .bind "mokaFocusUpRequest", () =>
                @title.focus()
                return false

        e = @container = new Moka.Container().appendTo(@e)

        $(window).bind( "resize.moka", @update.bind(this) )

        # title
        titlebar = @title = new Moka.Input(title)
            .addClass("moka-title")
            .appendTo(e)
        titlebar.parentWidget = this

        # window title buttons
        @noclose = false
        @e_close = $("<div>", {'class':"moka-window-button moka-close"})
            .css('cursor', "pointer")
            .click( @close.bind(this) )
            .appendTo(@title.e)
        @nomax = true
        @e_max = $("<div>", {'class':"moka-window-button moka-maximize"})
            .css('cursor', "pointer")
            .click( @maximize.bind(this) )
            .hide()
            .appendTo(@title.e)

        # body
        body = @body = new Moka.Container()
            .addClass("moka-body").appendTo(e)
        body.parentWidget = this

        @widgets = [@container]

        titlebar
            .bind "dblclick.moka", () ->
                body.toggle()
                Moka.focusFirstWidget(body)
                return false
            .bind "mousedown.moka", (ev) =>
                # prevent selecting text when double-clicking
                @focus()
                ev.preventDefault()

        # window edges
        edges =
            'moka-n':        [1, 1, 0, 1, 0, 1, "n"]
            'moka-e':        [1, 1, 1, 0, 1, 0, "e"]
            'moka-s':        [0, 1, 1, 1, 0, 1, "s"]
            'moka-w':        [1, 0, 1, 1, 1, 0, "w"]
            'moka-n moka-e': [1, 1, 0, 0, 1, 1, "ne"]
            'moka-s moka-e': [0, 1, 1, 0, 1, 1, "se"]
            'moka-s moka-w': [0, 0, 1, 1, 1, 1, "sw"]
            'moka-n moka-w': [1, 0, 0, 1, 1, 1, "nw"]
        for edge, s of edges
            $("<div>", {class:"moka-edge " + edge})
                .css(
                    position:"absolute"
                    top: s[0] and "-2px" or ""
                    right: s[1] and "-2px" or ""
                    bottom: s[2] and "-2px" or ""
                    left: s[3] and "-2px" or ""
                    width: s[4] and "8px" or ""
                    height: s[5] and "8px" or ""
                    cursor:s[6]+"-resize"
                )
                .appendTo(e)
                .bind "mousedown.moka", (ev) ->
                    x = ev.pageX
                    y = ev.pageY
                    $this = $(this)
                    $(document).bind("mousemove.moka", (ev) ->
                        dx = ev.pageX-x
                        dy = ev.pageY-y
                        x += dx
                        y += dy
                        pos = self.position()
                        if $this.hasClass("moka-n")
                            body.height( body.height()-dy )
                            pos.top += dy
                        if $this.hasClass("moka-e")
                            body.width( body.width()+dx )
                        if $this.hasClass("moka-s")
                            body.height( body.height()+dy )
                        if $this.hasClass("moka-w")
                            body.width( body.width()-dx )
                            pos.left += dx
                        self.position(pos.left, pos.top)
                        self.update()
                    )
                    $(document).one("mouseup", () -> $(document).unbind("mousemove.moka"))
                    return false

        Moka.initDraggable(@e, @title.e)
        $(window).load( (() -> @update()).bind(this) )

    toggleShow: ->
        if @e.is(":visible") then @hide() else @show()
        return this

    disableClose: (noclose) ->
        if noclose
            @noclose = true
            @e_close.hide()
        else
            @noclose = false
            @e_close.show()
        return this

    disableMaximize: (nomax) ->
        if nomax
            @nomax = true
            @e_max.hide()
        else
            @nomax = false
            @e_max.show()
        return this

    length: ->
        return @body.length()+1

    at: (i) ->
        # last widget is always window title
        return if i is @body.length() then @title else @body.at(i)

    update: ->
        w = @widgets
        $.each( w, (i) -> w[i].update?() )
        return this

    append: (widgets) ->
        for widget in arguments
            @body.append(widget)

        @update()

        return this

    remove: ->
        w = @widgets
        $.each( w, (i) -> w[i].update?() )
        return super

    center: (once) ->
        @e.css("opacity",0)
        @e.offset({
            left:(@e.parent().width()-@e.width())/2,
            top:(@e.parent().height()-@e.height())/2
        })
        if once
            @e.css("opacity",1)
        if not once
            new Moka.Timer(callback:@center.bind(this, true)).start()
        return this

    focus: () ->
        if not Moka.focusFirstWidget(@body)
            @title.focus()
        return this

    titleHasFocus: () ->
        return @title.hasFocus()

    position: (x,y) ->
        if x?
            pos = @e.parent().offset()
            if pos
                @e.offset(
                    left: pos.left + Math.max(0,x),
                    top: pos.top + Math.max(0,y)
                )
            return this
        else
            return @e.offset()

    resize: (w, h) ->
        @body.width(w).height(h)
        @update()
        return this

    align: (alignment) ->
        @body.css("text-align", alignment)
        return this

    maximize: () ->
        # FIXME: maximum size is incorrect
        @position(0, 0)
        p = @e.parent()
        pos = @body.offset()
        pos2 = p.offset()
        pos.left += pos2.left
        pos.top += pos2.top
        @resize( p.width()-pos.left, p.height()-pos.top )

        return this

    nextWindow: (left_or_top, direction) ->
        wnds = @e.siblings( (" "+@mainclass).split(" ").join(" .") )
        x = @e.offset()[left_or_top]
        d = -1
        e = @e
        wnds.each () ->
            $this = $(this)
            dd = direction * ($this.offset()[left_or_top] - x)
            if (d < 0 and dd >= 0) or (dd > 0 and dd < d)
                e = $this
                d = dd
        Moka.focus( e.find(".moka-title:first") )

    close: () ->
        return this if @noclose
        @remove()

    onFocus: () ->
        @focus()

    onChildFocus: ->
        @e.parent().children(".moka-top_window")
            .removeClass("moka-top_window")
        @e.addClass("moka-top_window")
        return super

elementToWidget = (e) ->
    w = null
    if e.hasClass("moka-window")
        title = e.children(".moka-title").html() or "untitled"
        w = new Moka.Window(title)
        e.children().each () ->
            ww = elementToWidget( $(this) )
            w.append(ww) if ww
    else if e.hasClass("moka-button")
        onclick = e[0].onclick
        tooltip = e.attr("title")
        label = e.html() or ""
        w = new Moka.Button(label, onclick, tooltip)
    else if e.hasClass("moka-label")
        label = e.html() or ""
        w = new Moka.Label(label)
    else if e.hasClass("moka-image")
        src = e.text().trim() or ""
        m = e.attr("class").match(/\bmoka-size-([0-9]*)x([0-9]*)\b/)
        w = if m then m[1] else ""
        h = if m then m[2] else ""
        w = new Moka.Image(src, w, h)
    else if e.hasClass("moka-container")
        w = new Moka.Container().vertical( e.hasClass("moka-vertical") )
        e.children().each () ->
            ww = elementToWidget( $(this) )
            w.append(ww) if ww
    else if e.hasClass("moka-widgetlist")
        w = new Moka.WidgetList().vertical( e.hasClass("moka-vertical") )
        e.children().each () ->
            ww = elementToWidget( $(this) )
            w.append(ww) if ww
    else if e.hasClass("moka-buttonbox")
        w = new Moka.ButtonBox().vertical( e.hasClass("moka-vertical") )
        e.children().each () ->
            onclick = this.onclick
            tooltip = this.title
            label = $(this).html() or ""
            w.append(label, onclick, tooltip)
    #else if e.hasClass("moka-tabwidget")

    if w?
        # copy element attributes
        w.do (we) ->
            we.addClass(e.attr("class"))
            attr = e.attr("id")
            we.attr("id", attr) if attr
            attr = e.attr("style")
            we.attr("style", attr) if attr

        # parse moka-keys
        e.children(".moka-keys").each () ->
            $(this).children().each () ->
                key = $(this).text()
                fn = this.onclick
                w.addKey(key, fn)

    return w

mokaInit = () ->
    perf_end("page ready")
    perf_begin()

    $("body")
        .bind("keydown.moka", (ev) ->
            perf_begin()
            w = Moka.keyhintwidget
            if w
                Moka.keyhintwidget = null
                keyname = Moka.getKeyName(ev)
                hint = Moka.getKeyHint(keyname)
                if hint isnt null and Moka.keyHintFocus(w, hint)
                    perf_end("key hint focusing (success)")
                    return false
            perf_end("key hint focusing (failed)")
        )
        .find(".moka-window").each () ->
            $this = $(this)
            w = elementToWidget( $(this) )
            if w
                w.appendTo($this.parent()).show()
                $this.remove()
    perf_end("mokaInit")

$(document).ready(mokaInit)

