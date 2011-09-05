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
        if ev.button is 0
            Moka.dragScroll(ev)

    return e

# Moka.dragScroll
Moka.scrolling = false
Moka.tt = 0
jQuery.extend( jQuery.easing,
    easeOutCubic: (x, t, b, c, d) ->
        # refresh preview every 30ms
        Moka.tt = t+30 if ( t>Moka.tt )
        return (t=t/1000-1)*t*t + 1
)

Moka.dragScroll = (ev) ->
    wnd = ev.currentTarget
    w = $(wnd)

    start = t = ev.timeStamp
    dt = 0
    dx = 0
    dy = 0

    mouseX = ev.pageX
    mouseY = ev.pageY
    from_mouseX = w.scrollLeft() + mouseX
    from_mouseY = w.scrollTop() + mouseY

    stop = false
    Moka.scrolling = false

    continueDragScroll = (ev) ->
        return if stop
        Moka.scrolling = true

        mouseX = ev.pageX
        mouseY = ev.pageY

        x = w.scrollLeft()
        y = w.scrollTop()

        # scroll
        w.scrollLeft(from_mouseX-mouseX)
        w.scrollTop(from_mouseY-mouseY)

        start = t
        t = ev.timeStamp
        dx = w.scrollLeft()-x
        dy = w.scrollTop()-y

        $(window).one("mousemove", continueDragScroll)

        ev.preventDefault()

    stopDragScroll = (ev) ->
        stop = true

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

            Moka.tt = 100
            w.stop(true).animate(
                scrollLeft: w.scrollLeft()+vx+"px",
                scrollTop: w.scrollTop()+vy+"px",
                1000, "easeOutCubic",
                () -> Moka.scrolling = false)

        return false

    # stop animations
    w.stop(true)

    # Chromium bug: http://code.google.com/p/chromium/issues/detail?id=14204
    # - scrollbar does not trigger mouseup
    pos = w.offset()
    if mouseX+24 > pos.left + w.width() or mouseY+24 > pos.top + w.outerHeight()
        return

    $(window).one("mouseup.moka.dragscroll", stopDragScroll)
             .one("mousemove.moka.dragscroll", continueDragScroll)

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
        e.addClass("moka-focus").trigger("mokaFocused")
        return e
    return Moka.focused_e

Moka.unfocused = () ->
    e = Moka.focused_e
    if e
        #dbg "blurring element\n ", e[0]
        e.removeClass("moka-focus").trigger("mokaBlurred")
        Moka.focused_e = null

Moka.focus = (e, o) ->
    ee = Moka.focused_e
    eee = e[0]
    return if ee and ee[0] is eee
    Moka.toScreen(e, null, o)
    eee.focus()

Moka.blur = (e) -> e.blur()

Moka.focusFirstWidget = (w, only_children) ->
    if not only_children and w.focus
        w.focus()
        return true
    else if w.widgets
        for ww in w.widgets
            if Moka.focusFirstWidget(ww, false)
                return true
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

Moka.onScreen = (e, how) ->
    if not how
        return (Moka.onScreen(e, 'r') or Moka.onScreen(e, 'l')) and
               (Moka.onScreen(e, 't') or Moka.onScreen(e, 'b'))

    pos = e.offset()
    wnd = $(window)
    d = 8
    switch how[0]
        when 'b' then return -d < pos.top+e.height() < wnd.height()+d
        when 't' then return -d < pos.top < wnd.height()+d
        when 'r' then return -d < pos.left+e.width() < wnd.width()+d
        when 'l' then return -d < pos.left < wnd.width()+d

Moka.toScreen = (e, wnd, o) ->
    o = "lt" if not o

    if not wnd
        wnd = e.parent()
        ee = wnd[0]
        while ee and wnd.outerWidth() is ee.scrollWidth and wnd.outerHeight() is ee.scrollHeight
            return if wnd[0].tagName is "BODY"
            wnd = wnd.parent()
            ee = wnd[0]
    return if not wnd.length or wnd[0] is e[0]

    pos = wnd.offset()
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

    Moka.scroll(wnd, {left:left, top:top, animate:true})

Moka.scroll = (e, opts) ->
    l = opts.left
    t = opts.top

    a = {}
    if l
        a.scrollLeft = l + (if opts.relative then e.scrollLeft() else 0)
    if t
        a.scrollTop = t + (if opts.relative then e.scrollTop() else 0)

    if opts.animate
        l = l or 0
        t = t or 0
        duration = Math.min( 1500, Math.sqrt(l*l+t*t) * (opts.speed or 1) )
        e.stop(true).animate(a, duration, opts.easing, opts.complete)
    else
        e.stop(true, true)
        if l and t
            e.scrollLeft(a.scrollLeft).scrollTop(a.scrollTop)
        else if l
            e.scrollLeft(a.scrollLeft)
        else if t
            e.scrollTop(a.scrollTop)

Moka.ensureVisible = (e, wnd) ->
    toScreen(e, wnd)

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

        @bind "mokaFocused", @addClass.bind(this, "moka-focus")
        @bind "mokaBlurred", @removeClass.bind(this, "moka-focus")

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
        @e.trigger("mokaDone", [false])
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
        @e.trigger("mokaDestroyed")
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

    keyHintFocus: (hint, skip_parent, w_to_skip) ->
        if this instanceof Moka.Input and @keyHint() is hint and not @hasFocus()
            @focus()
            return true

        l = if @length then @length() else 0
        i = 0
        while i<l
            w = @at(i)
            if w isnt w_to_skip and w.isVisible() and w.keyHintFocus(hint, true)
                return true
            ++i

        p = @parent()
        if p and not skip_parent
            return true if p.keyHintFocus?(hint, false, this)

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
            .connect( "focus.moka", (ev) => @onFocus(ev); return false )
            .bind( "mokaFocusUpRequest", () => @focus(); return false )
            .bind( "mokaFocused", @onChildFocus.bind(this) )
            .bind( "mokaBlurred",  @onChildBlur.bind(this) )
            .bind( "keydown.moka", (ev) =>
                return @onKeyDown(ev) if !ev.isPropagationStopped()
            )
            .bind( "blur.moka", (ev) => @onBlur(ev); return false )
            .css("cursor","pointer")

        @e_focus = @e
        @tabindex(1)
        @focusableElement(@e)

    focusableElement: (e) ->
        # if widget is focused then element e will recieve focus
        if e?
            ee = @e_focus
            @other_focusable = @e[0] isnt e[0]
            e.attr("tabindex", -1) if @other_focusable
            @e_focus = e
            return this
        else
            return @e_focus

    addNotFocusableElement: (e) ->
        # steal focus from all non-focusable elements
        e.bind("mokaFocused.notfocusable", @focus.bind(this))
        @focus() if e.is(":focus")
        return this

    removeNotFocusableElement: (e) ->
        e.unbind("mokaFocused.notfocusable")
        return this

    onChildFocus: (ev) ->
        if not Moka.focused()
            @focus()
            return false
        #dbg "  focused element\n ",@e[0]

    onChildBlur: (ev) ->
        # TODO: add code for modality
        #dbg "  blurred element\n ",@e[0]

    tabindex: (index) ->
        if index?
            @e.attr("tabindex", index)
            return this
        else
            return @e.attr("tabindex", index)

    focus: () ->
        Moka.focus(@e) if Moka.focused()?[0] isnt @e[0]
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
                    Moka.focus(@e_focus)
            ).start()
            @e.one "blur.moka", () => @t.kill()
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
        return

    doKey: (keyname) ->
        if @keys? and (fns = @keys[keyname])
            for fn in fns
                return true if fn.apply(this) isnt false
        if (fn = @default_keys[keyname])
            return true if fn.apply(this) isnt false

        return false

    onKeyDown: (ev) ->
        keyname = Moka.getKeyName(ev)
        return false if @doKey(keyname)
        # keyhint focusing only once per event
        if ev.target is @e[0]
            hint = Moka.getKeyHint(keyname)
            if hint isnt null
                return false if @keyHintFocus(hint)

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

        @c = new Moka.Container(false)
            .mainClass("moka-widgetlist-container moka-container")
            .itemClass(@itemclass)
            .appendTo(@e)
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
        bindfocus = (widget, id) =>
            widget
                .bind "mokaFocused", () =>
                    if @current >= 0
                        @c.at(@current)
                            .removeClass("moka-current")
                            .trigger("mokaDeselected", [@current])
                    @current = id
                    widget.addClass("moka-current")
                    @trigger("mokaSelected", [id])
                    @update()
                .bind "mousedown.moka", () ->
                    Moka.focusFirstWidget(widget)
                    return

        for widget in arguments
            id = @length()
            e = widget.e
            @c.append(widget)
            widget.parentWidget = this
            bindfocus(widget, id)

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

class Moka.CheckBox extends Moka.Input
    mainclass: "moka-checkbox "+Moka.Input.prototype.mainclass

    default_keys:
        SPACE: -> @toggle()

    constructor: (text, checked) ->
        super text

        @checkbox = $('<input>', {type:"checkbox", class:"moka-value"})
            .bind("change.moka", () => @e.trigger("mokaValueChanged", [@value()]) )
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
                @e.trigger("mokaValueChanged", [v])
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
            .bind("change.moka", () => @e.trigger("mokaValueChanged", [@value()]) )
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
            .bind( "change.moka", () => @e.trigger("mokaValueChanged", [@value()]) )
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
            .bind( "change.moka", () => @e.trigger("mokaValueChanged", [@value()]) )
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

    resize: (w, h) ->
        @e.width(w) if w?
        @e.height(h) if h?
        return this

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
        super $("<canvas>", width:0, height:0)
        @ctx = @e[0].getContext("2d")

        @t_draw = new Moka.Timer( callback: @draw.bind(this) )

        @owidth = @oheight = 0
        @img = $("<img>", width:w, height:h)
        @img.one( "load",
            () =>
                @ok = true
                img = @img[0]
                @owidth  = img.naturalWidth
                @oheight = img.naturalHeight
                onload() if onload
        )
        @img.one( "error",
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

    resize: (w,h) ->
        return this if not @ok or w<=0 or h<=0
        e = @e[0]
        if e.width isnt w or e.height isnt h
            e.width = w
            e.height = h
            if @t_filter
                @t_filter.kill()
                @t_filter = null
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
        return this if not @ok

        e = @e[0]
        w = Math.ceil(e.width)
        h = Math.ceil(e.height)

        img = @img[0]
        @ctx.clearRect(0, 0, w, h)
        @ctx.drawImage(img, 0, 0, w, h)

        if @t_filter_first
            @t_filter.kill() if @t_filter
            @t_filter = @t_filter_first
                .data(
                    dataDesc: @ctx.getImageData(0, 0, w, h)
                    dataDescCopy: @ctx.getImageData(0, 0, w, h)
                ).start()

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

    show: () ->
        if @image
            if @t_remove
                @t_remove.kill()
                @t_remove = null
                @image.show()
            @e.show()
            if @ok?
                @zoom(@zhow)
                @e.trigger("mokaLoaded")
                @e.trigger("mokaDone", [not @ok])
        else
            onload = () =>
                @ok = true

                @zoom(@zhow)

                @e.trigger("mokaLoaded")
                @e.trigger("mokaDone", [false])
            onerror = () =>
                @ok = false
                @e.trigger("mokaError")
                @e.trigger("mokaDone", [true])
            if @use_canvas
                image = @image = new Moka.Canvas(@src, "", "", onload, onerror)
                for f in @filters
                    image.addFilter(f.filename, f.callback)
            else
                @image = new Moka.Image(@src, "", "", onload, onerror)
            @image.appendTo(@e)
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
            ).start()
        return super

    remove: ->
        @e.hide()
        if @image
            @image.remove()
            @t_remove.kill() if @t_remove
        return super

    isLoaded: () ->
        return @ok is true or @ok is false

    originalWidth: () ->
        return @image.originalWidth()

    originalHeight: () ->
        return @image.originalHeight()

    zoom: (how) ->
        if how?
            return this if @z is how
            @zhow = how
            zhow = if how instanceof Array then how[2] else null

            if @ok and @isVisible()
                width = @image.width()
                height = @image.height()
                w = h = mw = mh = ""

                if how instanceof Array
                    mw = Math.floor(how[0])
                    mh = Math.floor(how[1])

                    d = mw/mh
                    d2 = width/height
                    if zhow is "fill"
                        if d > d2
                            w = mw
                            h = Math.floor(mw/d2)
                        else
                            h = mh
                            w = Math.floor(mh*d2)
                        mw = mh = ""
                    else
                        if d > d2
                            h = mh
                            w = Math.floor(mh*d2)
                        else
                            w = mw
                            h = Math.floor(mw/d2)
                        mw = mh = ""
                else
                    z = parseFloat(how) or 1
                    mw = Math.floor(z*@image.originalWidth())
                    mh = Math.floor(z*@image.originalHeight())

                if zhow isnt "fit" and zhow isnt "fill"
                    if width/height < mw/mh
                        h = mh
                    else
                        w = mw

                @image.css('max-width':mw, 'max-height':mh, width:w, height:h)
                @e.css('max-width':mw, 'max-height':mh, width:w, height:h)

                @image.resize(w or mw, h or mh)
                @zhow = @z = how

            return this
        else
            return @z

    onKeyDown: (ev) ->
        return false if super is false
        k = Moka.getKeyName(ev)
        if ((k is "LEFT" or k is "RIGHT") and @image.width() > @width()) or
           ((k is "UP" or k is "DOWN") and @image.height() > @height())
            ev.stopPropagation()

class Moka.Viewer extends Moka.Input
    mainclass: "moka-viewer "+Moka.Input.prototype.mainclass

    default_keys:
        RIGHT: -> Moka.onScreen(Moka.focused(), 'r') and @focusRight() or
            Moka.scroll(@e, {left:30, relative:true})
        LEFT: -> Moka.onScreen(Moka.focused(), 'l') and @focusLeft() or
            Moka.scroll(@e, {left:-30, relative:true})
        UP: -> Moka.onScreen(Moka.focused(), 't') and @focusUp() or
            Moka.scroll(@e, {top:-30, relative:true})
        DOWN: -> Moka.onScreen(Moka.focused(), 'b') and @focusDown() or
            Moka.scroll(@e, {top:30, relative:true})
        KP6: -> if 'l' in @orientation() then @next() else @prev()
        KP4: -> if 'r' in @orientation() then @next() else @prev()
        KP8: -> if 't' in @orientation() then @next() else @prev()
        KP2: -> if 'b' in @orientation() then @next() else @prev()

        TAB: ->
            if @index + @current + 1 < @length() and @currentcell + 1 < @cellCount()
                @next()
            else
                return false
        'S-TAB': -> if @currentcell > 0 then @prev() else false

        SPACE: ->
            how = @orientation()[1]
            switch how
                when 't' then how = 'b'
                when 'l' then how = 'r'
                when 'r' then how = 'l'
                else how = 't'
            if Moka.onScreen(Moka.focused(), how)
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
            if Moka.onScreen(Moka.focused(), how)
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

        ENTER: -> @next()

        '*': -> @layout([1,1]); @zoom(1)
        '/': -> if @zhow is "fit" then @zoom(1) else @zoom("fit")
        '+': -> @zoom("+")
        '.': -> if @zhow is "fill" then @zoom(1) else @zoom("fill")
        MINUS: -> @zoom("-")

        KP7: -> @select(0)
        HOME: -> @select(0)
        KP1: -> @select(@length()-1)
        END: -> @select(@length()-1)
        PAGEUP: ->
            c=@cellCount()
            if @currentcell%c is 0
                @select(@index-c)
            else
                @select(@index)
        PAGEDOWN: ->
            c=@cellCount()
            if (@currentcell+1)%c is 0
                @select(@index+c)
            else
                @select(@index+c-1)

        H: -> @layout([@lay[0]+1, @lay[1]])
        V: -> @layout([@lay[0], @lay[1]+1])
        'S-H': -> @layout([@lay[0]-1, @lay[1]])
        'S-V': -> @layout([@lay[0], @lay[1]-1])

    constructor: () ->
        super
        this
            #.bind( "resize.moka", @update.bind(this) )
            #.bind( "scroll.moka", @onScroll.bind(this) )
            .css("cursor", "move")
            .tabindex(1)
            .bind( "mokaFocusUpRequest", () => @select(@index + @current); return false )
            .bind( "mousedown.moka", @onMouseDown.bind(this) )
            .bind( "dblclick.moka", @onDoubleClick.bind(this) )


        Moka.initDragScroll(@e)

        $(window).bind("resize.moka", @update.bind(this) )

        @table = $("<table>", class:"moka-table", border:0, cellSpacing:0, cellPadding:0)
                .appendTo(@e)

        @cells = []
        @items = []

        # index of first item on current page
        @index = -1
        # index of selected item on current page
        @current = -1
        # index of selected cell in viewer (from left to right, top to bottom)
        @currentcell = -1

        # preload item if it is less than preload_offset pixels away
        @preload_offset = 200

        @layout([1,1])
        @orientation("lt")
        @zoom(1)

    update: ->
        @focus() if @hasFocus()

        return this

    focus: (ev) ->
        cell = @cells[@currentcell] or @cells[0]
        Moka.focusFirst( cell.children(), @o ) or Moka.focus(cell, @o)
        return this

    appendFunction: (fn, length) ->
        last = @length()
        itemfn = (index) -> return fn(index-last)

        i = @items.length
        l = i+length
        while i<l
            @items.push(itemfn)
            ++i

        if @lay[0] <= 0 or @lay[1] <= 0
            @updateTable()

        @update()

        return this

    append: (widget) ->
        id = @length()
        widget.parentWidget = this
        @items.push(widget)
        if @lay[0] <= 0 or @lay[1] <= 0
            @updateTable()

        @update()

        return this

    at: (index) ->
        x = @items[index]
        if x instanceof Function
            x = @items[index] = x(index)
            x.parentWidget = this
        return x

    clean: () ->
        i = 0
        l = @length()
        while i < l
            x = @items[i]
            if x not instanceof Function
                x.remove()
            ++i
        @items = []
        return this

    remove: () ->
        for item in @items
            if x not instanceof Function
                item.remove()
        for cell in @cells
            cell.remove()
        return super

    currentIndex: () ->
        return if @current >= 0 then @index + @current else -1

    currentItem: () ->
        i = @currentIndex()
        if i >= 0
            return @at(i)
        else
            return null

    length: () ->
        return @items.length

    clear: () ->
        i = 0
        len = @cellCount()
        while i < len
            item = @at(@index+i)
            if item
                item.e.detach()
                item.hide()
            ++i

    view: (id) ->
        return this if id >= @length() or id < 0
        id = 0 if id < 0

        @table.hide()

        @clear()

        i = 0
        len = @cellCount()
        @index = Math.floor(id/len)*len
        dbg "displaying views", @index+".."+(@index+len-1)
        while i < len
            cell = @cell(i)

            item = @at(@index+i)

            cell.data("itemindex", i)
            if item
                cell.attr("tabindex", -1)
                item.hide()
                    .appendTo(cell)
            else
                # cell is empty
                cell.attr("tabindex", "")
            ++i

        @table.show()

        @zoom(@zhow)
        @updateVisible(true)

        return this

    select: (id) ->
        return this if id < 0 or id >= @length()

        dbg "selecting view", id

        cell = @cell(@current) or @cell(0)
        Moka.blur( cell.children() ) or Moka.blur(cell)

        count = @cellCount()
        @current = id%count

        if id < @index or id >= @index+count
            @view(id)

        cell = @cell(id%count)
        Moka.focusFirst( cell.children(), @o ) or Moka.focus(cell, @o)
        #@update()

        return this

    zoom: (how) ->
        if how?
            @zhow = null
            if how is "fit" or how is "fill"
                layout = @layout()

                wnd = @e.parent()

                offset = wnd.offset() or {top:0, left:0}
                pos = @e.offset()
                pos.top -= offset.top
                pos.left -= offset.left

                if wnd[0] is window.document.body
                    wnd = $(window)

                w = (wnd.width()-pos.left)/layout[0]
                h = (wnd.height()-pos.top)/layout[1]

                c = @cells[0]
                w -= c.outerWidth(true)-c.width()
                h -= c.outerHeight(true)-c.height()

                @z = [w, h, how]
                @zhow = how
            else if how is "+" or how is "-"
                if not @z
                    @z = 1

                if @z instanceof Array
                    d = if how is "-" then 0.889 else 1.125
                    @z[0] *= d
                    @z[1] *= d
                else
                    @z += if how is "-" then -0.125 else 0.125
            else if how instanceof Array
                @z = how
            else
                factor = parseFloat(how) or 1
                @z = factor

            return if @index < 0
            i = @index
            len =i+@cellCount()
            len = Math.min(len, @length())
            dbg "zooming views", i+".."+(len-1), "using method", @z
            while i < len
                item = @at(i)
                item.zoom?(@z)
                ++i
            if @current >= 0
                Moka.toScreen( @at(@index+@current).e, @e, @o )

            @updateVisible()

            @trigger("mokaZoomChanged")
            return this
        else
            return if @zhow then @zhow else @z

    cellCount: () ->
        return @cells.length

    next: () ->
        @select(@index + @current + 1)
        return this

    prev: () ->
        @select(@index + @current - 1)
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
        id = @currentcell - 1
        if (id+1) % h is 0
            cell = @cells[id+h]
            if cell and cell.width()-8 <= @e.width()
                id = cell.data("itemindex")
                how = -@cellCount()
                if "r" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.data("itemindex")
                @select(@index + id)
        return this

    focusRight: () ->
        h = @layout()[0]
        id = @currentcell + 1
        if id % h is 0
            cell = @cells[id-h]
            if cell and cell.width()-8 <= @e.width()
                id = cell.data("itemindex")
                how = @cellCount()
                if "r" in @o
                    how = -how
                @select( Math.min(@index + id + how, @length()-1) )
        else
            cell = @cells[id]
            if cell
                id = cell.data("itemindex")
                @select(@index + id)
        return this

    focusUp: () ->
        h = @layout()[0]
        id = @currentcell - h
        if id < 0
            len = @cellCount()
            cell = @cells[id+len]
            if cell and cell.height()-8 <= @e.height()
                id = cell.data("itemindex")
                how = -@cellCount()
                if "b" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.data("itemindex")
                @select(@index + id)
        return this

    focusDown: () ->
        h = @layout()[0]
        len = @cellCount()
        id = @currentcell + h
        if id >= len
            cell = @cells[id-len]
            if cell and cell.height()-8 <= @e.height()
                id = cell.data("itemindex")
                how = @cellCount()
                if "b" in @o
                    how = -how
                @select( Math.min(@index + id + how, @length()-1) )
        else
            cell = @cells[id]
            if cell
                id = cell.data("itemindex")
                @select(@index + id)
        return this

    appendRow: () ->
        return $("<tr>", class:"moka-row")
              .height(@e.height)
              .appendTo(@table)

    appendCell: (row) ->
        td = $("<td>").appendTo(row)

        cell = $("<div>")
        id = @cellCount()
        cell.data("moka-cell-id", id)
        cell.css("overflow":"hidden")
        cell.addClass("moka-view")
            .bind("mokaFocused",
                (ev) =>
                    return if @currentcell is id and @currentindex is @index+id
                    if ev.target is cell[0] and Moka.focusFirst(cell.children(), @o)
                        return

                    @cells[@currentcell]?.removeClass("moka-current")
                                         .trigger("mokaDeselected", [@index + @current])
                    @currentindex = @index+id
                    @currentcell = id
                    @current = cell.data("itemindex")

                    cell.addClass("moka-current")
                    @trigger("mokaSelected", [@index + @current])
            )
            .appendTo(td)

        @cells.push(cell)

        return cell

    cell: (index) ->
        return @cells[ @indexfn(index) ]

    updateTable: () ->
        @table.empty().hide()
        @clear()
        cell.remove() for cell in @cells
        @cells = []

        layout = @layout()
        ilen = layout[0]
        jlen = layout[1]

        j = 0
        while j < jlen
            row = @appendRow()
            i = 0
            @appendCell(row) while ++i <= ilen
            ++j

        @table.show()

    layout: (layout) ->
        if layout
            x = Math.max( 0, Number(layout[0]) )
            y = Math.max( 0, Number(layout[1]) )
            return this if not (x? and y?) or (@lay and x is @lay[0] and y is @lay[1])

            @e.removeClass("moka-layout-"+@lay.join("x")) if @lay
            @lay = [x, y]
            @e.addClass("moka-layout-"+@lay.join("x"))

            dbg "setting layout", @lay

            id = @index+@currentcell
            @updateTable()
            @view(@index)
            @select(id)

            return this
        else
            i = @lay[0]
            j = @lay[1]
            if i <= 0
                i = Math.ceil( @length()/j )
            else if j <= 0
                j = Math.ceil( @length()/i )
            return [i, j]

    orientation: (o) ->
        if o
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

            fns =
                lt:(id,x,y) -> id
                rt:(id,x,y) -> i=id%x; j=Math.floor(id/x);   x-1 - i + j*x
                lb:(id,x,y) -> i=id%x; j=Math.floor(id/x); x*y-x + i - j*x
                rb:(id,x,y) -> i=id%x; j=Math.floor(id/x); x*y-1 - i - j*x

                tl:(id,x,y) -> i=id%y; j=Math.floor(id/y);               i*x + j
                tr:(id,x,y) -> i=id%y; j=Math.floor(id/y); x*y-1 - (y-1-i)*x - j
                bl:(id,x,y) -> i=id%y; j=Math.floor(id/y);         (y-1-i)*x + j
                br:(id,x,y) -> i=id%y; j=Math.floor(id/y); x*y-1 -       i*x - j

            # index function: view index -> cell index
            @indexfn = (id) =>
                x = @lay[0]
                y = @lay[1]
                fns[@o].apply(this, [id,x,y])

            @view(@index)

            return this
        else
            return @o

    hideItem: (index) ->
        item = @at(index)
        cell = @cell( index % @cellCount() )
        if item.e.is(":visible")
            dbg "hiding item", index
            h = cell.height()+"px"
            w = cell.width()+"px"
            cell.css(width:w, height:h)
            item.hide()

    updateVisible: (now) ->
        if not now
            @t_update.kill() if @t_update
            @t_update = new Moka.Timer(
                delay:100
                callback:@updateVisible.bind(this, true)
            ).start()
            return

        p = @cell(0).parent()
        topreload = 2

        if @current >= 0
            current_item = @at(@index+@current).e

        updateItems = (index, direction) =>
            loaded = () =>
                # resize cells
                if cell
                    dbg "view", index, "loaded"
                    id = cell.data("moka-cell-id")

                    x = @layout()[0]
                    col = id%x
                    row = Math.floor(id/x)

                    # set row height
                    i = row*x
                    max = i+x
                    while i < max and c = @cells[i]
                        c.height("auto")
                        ++i

                    # set column width
                    i = col
                    while c = @cells[i]
                        c.width("auto")
                        i+=x
                else
                    dbg "view", index, "preloaded"
                    # remove preloaded item after timeout
                    item.hide()

                item.zoom?(@z, @zhow)

                # keep relative scroll offset after image is loaded
                #left = @e.scrollLeft()
                #top = @e.scrollTop()
                #if left or top
                    #ww = p.width()
                    #hh = p.height()
                    #if current_item
                        #Moka.toScreen(current_item, @e, @o)
                    #else
                        #pos = @e.offset()
                        #if pos.left < wndleft+@e.width()/2 and ww > w
                            #@e.scrollLeft( left + (ww-w)/2 )
                        #if pos.top < wndtop+@e.height()/2 and hh > h
                            #@e.scrollTop( top + (hh-h)/2 )

                next()

            next = updateItems.bind(this, index+direction, direction)

            cell = @cell(index-@index)
            item = @at(index)
            if not cell and item and topreload > 0
                --topreload
                dbg "preloading view", index
                item.unbind("mokaDone.preload")
                    .one("mokaDone.preload", loaded)
                    .show()
                return
            if not item or not cell
                #if @current >= 0 and not Moka.scrolling
                    #@select(@index + @current)
                dbg "updateItems finished for direction", direction
                if direction > 0
                    updateItems.call(this, @index+@current-direction, -direction)
                @update()
                return

            if item.e.is(":visible")
                return next()

            # is item on screen or should it be preloaded?
            w = p.width()
            h = p.height()
            pos = cell.parent().offset()
            d = @preload_offset

            # FIXME: check if item is visible
            wndleft   = pos.left
            wndtop    = pos.top
            wndright  = wndleft + @e.width()
            wndbottom = wndtop + @e.height()

            if pos.left + w + d < wndleft or
               pos.left - d > wndright or
               pos.top + h + d < wndtop or
               pos.top - d > wndbottom
                # TODO: remove resource if necessary
                item.hide()
                return next()

            dbg "loading view", index

            item.unbind("mokaDone.preload")
                .one("mokaDone.preload", loaded)
                .show()

        if @current >= 0
            # load current item first
            updateItems(@index+@current, 1)
            # calling updateItems multiple times here breaks layout
            #updateItems(@index+@current, -1)
        else
            updateItems(@index, 1)

    onScroll: (ev) ->
        lay = @layout()
        if lay[0] isnt 1 or lay[1] isnt 1
            @updateVisible()

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
        @oldzoom = @zhow

        if lay[0] is @oldlay[0] and lay[1] is @oldlay[1] and z is @oldzoom
            lay = [1,1]
            z = 1

        @zoom(z)
        @layout(lay)

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
        @e.hide( @animation_speed, super )

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
            .bind "mokaFocused", () =>
                cls="moka-top_window"
                @e.parent().children("."+cls).removeClass(cls)
                @e.addClass("moka-top_window")

        e = @container = new Moka.Container().appendTo(@e)

        $(window).bind( "resize.moka", @update.bind(this) )

        # title
        @title = new Moka.Input(title)
            .addClass("moka-title")
            .appendTo(e)

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

        @widgets = [@container]

        @title
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
            widget.parentWidget = this

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
            Moka.focus(@title)
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

    onFocus: (ev) ->
        @focus()

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
    inputs = $("body,input,textarea,select")
    inputs.live "focus.moka", (ev) ->
        Moka.focused( $(ev.target) )
        return false
    inputs.live "blur.moka", (ev) ->
        Moka.unfocused()
        return false

    $("body").find(".moka-window").each () ->
        $this = $(this)
        w = elementToWidget( $(this) )
        if w
            w.appendTo($this.parent()).show()
            $this.remove()

$(document).ready(mokaInit)

