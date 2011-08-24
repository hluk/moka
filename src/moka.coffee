window.Moka = {}

# bind
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
#((logobj=window) and logfn=logobj.alert)
log = if logfn then logfn.bind(logobj) else () -> return

# debugging
dbg = log.bind(this, "DEBUG:")
#dbg = () -> return
#dbg = () -> alert("DEBUG: "+Array.prototype.join.call(arguments, " "))

# user agent
userAgents =
    unknown:0
    webkit:1
    opera:2

userAgent = () ->
    if navigator.userAgent.indexOf("WebKit") >= 0
        return userAgents.webkit
    if navigator.userAgent.indexOf("Opera") >= 0
        return userAgents.opera
    else
        return userAgents.unknown

# KEYBOARD
# TODO: add keynames for each web browser
keycodes = {}
keycodes[8] = "BACKSPACE"
keycodes[9] = "TAB"
keycodes[13] = "ENTER"
keycodes[27] = "ESCAPE"
keycodes[32] = "SPACE"
keycodes[37] = "LEFT"
keycodes[38] = "UP"
keycodes[39] = "RIGHT"
keycodes[40] = "DOWN"
keycodes[45] = "INSERT"
keycodes[46] = "DELETE"
keycodes[33] = "PAGEUP"
keycodes[34] = "PAGEDOWN"
keycodes[35] = "END"
keycodes[36] = "HOME"
#if userAgent() is userAgents.webkit
keycodes[96] =  "KP0"
keycodes[97] =  "KP1"
keycodes[98] =  "KP2"
keycodes[99] =  "KP3"
keycodes[100] = "KP4"
keycodes[101] = "KP5"
keycodes[102] = "KP6"
keycodes[103] = "KP7"
keycodes[104] = "KP8"
keycodes[105] = "KP9"
keycodes[106] = "*"
keycodes[107] = "+"
keycodes[109] = "MINUS"
keycodes[110] = "."
keycodes[111] = "/"
keycodes[112] = "F1"
keycodes[113] = "F2"
keycodes[114] = "F3"
keycodes[115] = "F4"
keycodes[116] = "F5"
keycodes[117] = "F6"
keycodes[118] = "F7"
keycodes[119] = "F8"
keycodes[120] = "F9"
keycodes[121] = "F10"
keycodes[122] = "F11"
keycodes[123] = "F12"
keycodes[191] = "?"

last_keyname = last_keyname_timestamp = null

# keyboard combination name is normalized
# format is "A-C-S-KEY" where A, C, S are optional modifiers (alt, control, shift)
normalizeKeyName = (keyname) ->
    modifiers = keyname.toUpperCase().split("-")
    key = modifiers.pop()

    modifiers = modifiers.map((x) -> x[0]).sort()
    k = if modifiers.length then modifiers.join("-")+"-"+key else key

    return k

getKeyName = (ev) ->
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

keyHintFocus = (keyname, root) ->
    if keyname.length is 1
        keyhint = keyname
    else
        # digit (1, KP1, S-1 ... not F1)
        n = keyname.replace(/^S-/,"").replace(/^KP/,"")
        if n >= "0" and n <= "9"
            keyhint = n

    e = null
    if keyhint?
        root.find(".moka-keyhint").each () ->
                $this = $(this)
                if $this.is(":visible") and keyhint is $this.text().toUpperCase()
                    parent = $this.parent()
                    if not parent.hasClass("moka-focus")
                        if parent.hasClass("moka-tab") or parent.hasClass("moka-input")
                            e = parent
                        else
                            e = parent.find(".moka-input:first")

                        if e.length
                            Moka.focus(e)
                            return false #break

    return e and e.length

Moka.createLabel = (text, e) ->
    e = $("<div>") if not e
    e.addClass("moka-label")

    # replace _x with underlined character and assign x key
    if text
        i=0
        while i < text.length
            c = text[i]
            if c is '_'
                break
            else if c is '\\'
                text = text.slice(0,i) + text.slice(i+1)
                ++i
            ++i

        if i+1 < text.length
            key = text[i+1]
            text = text.substr(0, i) +
                '<span class="moka-keyhint">'+key+'</span>' +
                text.substr(i+2)

        e.html(text)

    e.css("cursor","pointer")

    return e

Moka.findInput = (e, str) ->
    return null if not str

    # case-insensitive search
    query = str.toUpperCase()

    res = null
    find = () ->
        $this = $(this)
        if $this.text().toUpperCase().search(query) >= 0
            res = $this.closest(".moka-input")
            return false

    # search in labels inside each moka-input element
    e.find(".moka-input.moka-label:visible, .moka-input > .moka-label:visible").each(find)

    return res

initDraggable = (e, handle_e) ->
    if not handle_e
        handle_e = e
    return handle_e
      .css('cursor', "pointer")
      .mousedown (ev) ->
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

# dragScroll
Moka.scrolling = false
tt = 0
jQuery.extend( jQuery.easing,
    easeOutCubic: (x, t, b, c, d) ->
        # refresh preview every 30ms
        if ( t>tt )
            tt = t+30
        return (t=t/1000-1)*t*t + 1
)

dragScroll = (ev) ->
    # do not prevent focus
    Moka.focus( $(ev.target).parents(".moka-input:first") )

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
            Moka.focus( ev.target )
            return

        # TODO: better algorithm to determine scroll animation speed and amount
        t = ev.timeStamp
        dt = t-start
        if 0 < dt < 90 and (dx isnt 0 or dy isnt 0)
            accel = 200/dt
            vx = dx*accel
            vy = dy*accel

            tt = 100
            w.animate(
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

    $(window).one("mouseup", stopDragScroll)
             .one("mousemove", continueDragScroll)

    ev.preventDefault()

focused_widget = $()
focus_timestamp = 0

Moka.focus = (e) ->
    return if not e
    ee = if e.length then e[0] else e
    #window.setTimeout( (() -> ee.focus()), 0 )
    ee.focus()

Moka.blur = (e) ->
    return if not e
    ee = if e.length then e[0] else e
    ee.blur()

Moka.focusFirst = (e) ->
    if e.hasClass("moka-input")
        ee = e
    else
        ee = e.find(".moka-input:visible:first")
        # elements with "current" class first
        eee = ee.siblings(".moka-current")
        if eee.length
            ee = eee
    if ee.length and ee.is(":visible")
        Moka.focus(ee)
        return true
    else
        return false

isOnScreen = (w, how) ->
    return false if not w
    if not how
        return (isOnScreen(w, "right") or isOnScreen(w, "left")) and
               (isOnScreen(w, "top") or isOnScreen(w, "bottom"))

    e = if w.e then w.e else w

    pos = e.offset()
    return false if not pos
    pos.right = pos.left + e.width()
    pos.bottom = pos.top + e.height()

    wnd = $(window)
    if how is "right" or how is "left"
        min = wnd.scrollLeft()
        max = min + wnd.width()
    else
        min = wnd.scrollTop()
        max = min + wnd.height()

    x = pos[how]
    return (x+8) >= min and (x-8) <= max

ensureVisible = (widget, wnd) ->
    e = if widget.e then wideget.e else widget

    if not wnd
        wnd = widget.parent()
    return if not wnd.length

    #if wnd[0].scrollHeight > wnd[0].offsetHeight+4
    pos = wnd.offset() or {top:0, left:0}
    cpos = e.offset()
    cleft   = cpos.left - pos.left
    ctop    = cpos.top - pos.top
    cright  = cleft + e.width()
    cbottom = ctop + e.height()

    # FIXME: better visibility checking
    left  = wnd.scrollLeft()
    cleft += left
    cright += left
    right = left + wnd.width()
    if cleft > left and cright > right
        wnd.scrollLeft(if e.width() >= (w = wnd.width()) then cleft else cright - w)
    else if cright < right and cleft < left
        wnd.scrollLeft(if e.width() >= (w = wnd.width()) then cright-w else cleft)

    top = wnd.scrollTop()
    ctop += top
    cbottom += top
    bottom = top + wnd.height()
    if ctop > top and cbottom > bottom
        wnd.scrollTop(if e.height() >= (w = wnd.height()) then ctop else cbottom - w)
    else if cbottom < bottom and ctop < top
        wnd.scrollTop(if e.height() >= (w = wnd.height()) then cbottom-w else ctop)

    return ensureVisible(widget, wnd.parent())

doKey = (keyname, keys, default_keys, object) ->
    if (keys and fn = keys[keyname]) or
       (default_keys and fn = default_keys[keyname])
        if fn.apply(object) is false
            return false
        else
            return true
    return false

# widget focusing
Moka.lostFocus = (ev) ->
    e = $(ev.target)
    e.removeClass("moka-focus")
     .trigger("mokaBlurred")
    if e[0] is focused_widget[0]
        focused_widget = $()
        #dbg "blurred element",e

Moka.gainFocus = (ev) ->
    return if focus_timestamp is ev.timeStamp
    focus_timestamp = ev.timeStamp
    focused_widget = $(ev.target)
    focused_widget.addClass("moka-focus")
                  .trigger("mokaFocused")
    ensureVisible(focused_widget)
    #dbg "focused element",focused_widget

# GUI classes
# only one widget can can be focused at a time
class Moka.Widget
    constructor: (from_element) ->
        @e = if from_element and from_element.hasClass then from_element else $("<div>")

        @e.addClass("moka-widget")
          .bind( "mokaFocused",  () -> $(this).addClass("moka-focus") )
          .bind( "mokaBlurred",  () -> $(this).removeClass("moka-focus") )

    show: ->
        @e.show()
        @update()
        @e.trigger("mokaDone", [false])
        return this

    hide: () ->
        @e.hide()
        return this

    update: () ->
        return this

    isLoaded: () ->
        return true

    appendTo: (e) ->
        if e.e and e.append
            e.append(this)
        else
            @e.appendTo(e)
        return this

    remove: () ->
        #@e.remove()
        @e.trigger("mokaDestroyed")
        @e.detach()

    parent: () ->
        return @parentWidget

    addKey: (keyname, fn) ->
        @keys = {} if not @keys
        @keys[ normalizeKeyName(keyname) ] = fn
        return this

    connect: (event, fn) ->
        @e.bind(event, (ev) => if ev.target is @e[0] then fn())
        return this

    bind: (event, fn) ->
        @e.bind(event, fn)
        return this

    one: (event, fn) ->
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

    align: (alignment) ->
        @e.css("text-align", alignment)
        return this

    css: (prop, val) ->
        if val?
            @e.css(prop, val)
            return this
        else
            return @e.css(prop)

    do: (fn) ->
        fn.apply(this, [@e])
        return this

class Moka.Label extends Moka.Widget
    constructor: (@text) ->
        super Moka.createLabel(@text)

class Moka.Input extends Moka.Widget
    constructor: () ->
        super
        @e.addClass("moka-input")
          .attr("tabindex", 0)
          .css("cursor","pointer")

          .bind("focus.moka", Moka.gainFocus)
          .bind("blur.moka",   Moka.lostFocus)

          .bind( "focus.moka", (ev) => @focus?(ev) )
          .bind( "blur.moka", (ev) => @blur?(ev) )
          .bind( "click.moka", (ev) => @click?(ev) )
          .bind( "dblclick.moka", (ev) => @dblclick?(ev) )
          .bind( "mouseup.moka", (ev) => @mouseup?(ev) )
          .bind( "mousedown.moka", (ev) => @mousedown?(ev) )
          .bind( "keydown.moka", (ev) => @keydown?(ev) )
          .bind( "keyup.moka", (ev) => @keyup?(ev) )

    focus: () ->
        Moka.focus(@e)
        return this

    remove: () ->
        Moka.blur(@e)
        return super

class Moka.Container extends Moka.Widget
    constructor: (horizontal) ->
        super
        @e.addClass("moka-container")

        @widgets = []

        @vertical(if horizontal? then not horizontal else true)

    update: ->
        w = @widgets
        $.each( w, (i) -> w[i].update() )
        return this

    length: () ->
        return @widgets.length

    at: (index) ->
        return @widgets[index]

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
            e = widget.e

            # first & last
            if id is 0
                e.addClass("moka-first")
            else
                @widgets[id-1].e.removeClass("moka-last")

            e.addClass(@itemcls+" moka-last")
            e.appendTo(@e)
              .bind("mokaSizeChanged", @update.bind(this) )
              #.children().focus( @update.bind(this) )

        @update()

        return this

    remove: () ->
        for widget in @widgets
            widget.remove()
        return super

class Moka.WidgetList extends Moka.Container
    default_keys:
        LEFT:  -> if @e.hasClass("moka-horizontal") then @prev() else false
        RIGHT: -> if @e.hasClass("moka-horizontal") then @next() else false
        UP:    -> if not @e.hasClass("moka-horizontal") then @prev() else false
        DOWN:  -> if not @e.hasClass("moka-horizontal") then @next() else false
        TAB:   ->
            if @current+1 < @length()
                @next()
            else
                false
        'S-TAB': ->
            if @current > 0
                @prev()
            else
                false
                #@e.parent().trigger("mokaFocusUpRequest")

    constructor: (cls, itemcls) ->
        super
        @e.addClass(if cls? then cls else "moka-widgetlist")
          .bind( "keydown.moka", (ev) => @keydown(ev) )
          .bind( "mokaFocusUpRequest", () => @select(Math.max(0, @current)); return false )
          .bind( "mokaFocusNextRequest", () => @next(); return false )
          .bind( "mokaFocusPrevRequest", () => @prev(); return false )

        @itemcls = if itemcls? then itemcls else "moka-widgetlistitem"
        @current = 0

    append: (widgets) ->
        for widget in arguments
            id = @length()
            e = widget.e
            widget.parentWidget = this

            e.bind( "mokaFocused", () =>
                if @current >= 0
                    @widgets[@current]?.e.removeClass("moka-current")
                    e.trigger("mokaDeselected", [@current])
                @current = id
                e.addClass("moka-current")
                 .trigger("mokaSelected", [id])
                @update()
            )

            e.addClass("moka-current") if id is @current

        super

        return this

    select: (id) ->
        if id >= 0
            w = @widgets[id]
            Moka.focusFirst(w.e) if w

    next: ->
        @select(if @current >= 0 and @current < @length()-1 then @current+1 else 0)

    prev: ->
        l = @length()
        @select(if @current >= 1 && @current < l then @current-1 else l-1)

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # keyhints
        if keyHintFocus(keyname, @e)
            return false

class Moka.CheckBox extends Moka.Input
    default_keys:
        SPACE: -> @toggle()
        ENTER: -> @toggle()

    constructor: (text, checked) ->
        super Moka.createLabel(text).addClass("moka-checkbox")

        @checkbox = $('<input>', {tabindex:1, type:"checkbox", class:"moka-value"})
                   .prependTo(@e)

        @value(checked)

    click: (ev) ->
        return if ev.target.type is "checkbox"
        @toggle()
        return false

    toggle: () ->
        @value(not @value())
        return this

    value: (val) ->
        if val?
            @checkbox.attr("checked", val)
            return this
        else
            return @checkbox.is(":checked")

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)
        if doKey(keyname, @keys, @default_keys, this)
            return false

class Moka.LineEdit extends Moka.Input
    default_keys: {}

    constructor: (label_text, text) ->
        super
        @e.addClass("moka-lineedit")
        Moka.createLabel(label_text, @e) if label_text
        @edit = $("<input>")
               .appendTo(@e)
               .keyup( this.update.bind(this) )
               .focus (ev) =>
                    ev.target = @edit[0]
                    Moka.gainFocus(ev)
               .blur  (ev) =>
                    ev.target = @edit[0]
                    Moka.lostFocus(ev)
        @value(text) if text

    focus: () ->
        Moka.focus(@edit)
        return this

    remove: () ->
        Moka.blur(@edit)
        return super

    update: () ->
        @edit.attr( "size", @value().length+2 )

    value: (text) ->
        if text?
            @edit.attr("value", text)
            return this
        else
            return @edit.attr("value")

    keydown: (ev) ->
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        k = keyname.split('-')
        k = k[k.length-1]
        if k.length is 1 or ["LEFT", "RIGHT", "BACKSPACE", "DELETE", "MINUS", "SPACE"].indexOf(k) >= 0
            ev.stopPropagation()

class Moka.TextEdit extends Moka.Input
    default_keys:
        ENTER: -> Moka.focus(@editor.win)

    constructor: (label_text, text) ->
        super
        @e.addClass("moka-textedit")
          .attr("tabindex", 1)
        Moka.createLabel(label_text, @e)
        @text = text or ""
        @textarea = $("<textarea>").appendTo(@e)
            .focus(Moka.gainFocus)
            .blur(Moka.lostFocus)
            .keydown(@keydown)

    update: () ->
        return this

    hide: () ->
        @e.hide()
        return this

    value: (text) ->
        if text?
            @textarea.value(text)
            @text = text
            return this
        else
            return @text

    editorKeyDown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        k = keyname.replace(/^S-/,"").replace(/^KP/,"")
        if k is "TAB" or k.search(/^F[0-9]/) >= 0
            # emulate keydown event
            #ev2 = jQuery.Event("keydown")
            #ev2.which = ev.which
            @e.trigger(ev)
        else if k is "ESCAPE"
            # blur editor
            # FIXME: is there a better way?
            @hide()
            @show()

    focus: (ev) ->
        Moka.focus(@textarea)
        return this

    remove: () ->
        Moka.blur(@textarea)
        return super

    keydown: (ev) ->
        ev.stopPropagation()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

# TODO: add button icon
class Moka.Button extends Moka.Input
    constructor: (label_text, onclick, tooltip) ->
        super
        Moka.createLabel(label_text, @e)
        @e.addClass("moka-button")
        @click = onclick

        @e.attr("title", tooltip) if tooltip

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if keyname is "ENTER" or keyname is "SPACE"
            @e.click()
            return false

class Moka.ButtonBox extends Moka.WidgetList
    constructor: ->
        super
        @e
          .removeClass("moka-widgetlist")
          .addClass("moka-buttonbox moka-horizontal")

    append: (label_text, onclick, tooltip) ->
        widget = new Moka.Button(label_text, onclick, tooltip)
        super widget
        widget.e.removeClass("moka-widgetlistitem")
        @update()

        return this

class Moka.Tabs extends Moka.Widget
    default_keys:
        ENTER: -> Moka.focusFirst(@pages[@current].e)
        SPACE: -> @pages_e.toggle()

        LEFT: ->  if @vertical() then @focusUp() else @prev()
        RIGHT: -> if @vertical() then @focusDown() else @next()
        UP: -> if @vertical() then @prev() else @focusUp()
        DOWN: -> if @vertical() then @next() else @focusDown()

        PAGEUP: -> if @vertical() then @tabs.select(0)
        PAGEDOWN: -> if @vertical() then @tabs.select(@tabs.length()-1)
        HOME: -> if not @vertical() then @tabs.select(0)
        END: -> if not @vertical() then @tabs.select(@tabs.length()-1)

    default_tab_keys:
        TAB: -> if (page = @pages[@current]) then Moka.focusFirst(page.e.children()) else false

    constructor: ->
        super
        @e.addClass("moka-tabwidget")
          .bind( "keydown.moka", (ev) => @keydown(ev) )
          .bind( "mokaFocusUpRequest", () => @select(Math.max(0, @current)); return false )

        @tabs = new Moka.WidgetList("moka-tabs", "moka-tab")
        @tabs_e = @tabs.e
            .appendTo(@e)
            .bind "mokaSelected", (ev, id) =>
                return if @current is id
                if @current >= 0
                    @pages[@current].hide()
                    @tabs.at(@current).e.attr("tabindex", -1)
                @current = id
                @tabs.at(@current).e.attr("tabindex", 0)
                @pages[id].show()
        # override widgetlist keys
        @tabs.keydown = @tabsKeyDown.bind(this)
        @tabs.keys = @tab_keys = {}

        @pages_e = $("<div>", class:"moka-pages")
                   .appendTo(@e)

        @pages = []
        @current = 0

        @vertical(false)

    update: ->
        @tabs.update()
        # update active page
        if @current >= 0
            @pages[@current].show()
        return this

    focusUp: () ->
        if not @tabs_e.hasClass("moka-focus")
            @select(Math.max(0, @current))
        else
            @e.parent().trigger("mokaFocusUpRequest")
        return this

    focusDown: () ->
        Moka.focusFirst( @pages[@current].e )
        return this

    next: () ->
        @tabs.next()
        return this

    prev: () ->
        @tabs.prev()
        return this

    append: (tabname, widget) ->
        @pages.push(widget)

        tab = new Moka.Input().do( (e) -> e.attr("tabindex", -1) )
        tab.parentWidget = this
        Moka.createLabel(tabname, tab.e)
        @tabs.append(tab)

        # FIXME: handle showing/hidding elements already in DOM
        widget.hide()
        widget.parentWidget = this
        page = widget.e.addClass("moka-page")
        page.parentWidget = this
        if page.parent().length is 0
            page.appendTo(@pages_e)
        page.keydown(@keydown.bind(this))

        if @current < 0 or @current is @tabs.length()-1
            @select( Math.max(0, @current) )

        @update()

        return this

    select: (id) ->
        @tabs.select(id)
        return this

    vertical: (toggle) ->
        if toggle?
            @tabs.vertical(toggle)
            return this
        else
            return @tabs.vertical()

    tabsKeyDown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @tab_keys, @default_tab_keys, this)
            return false

        # keyhints
        page = @pages[@current]
        if (page? and keyHintFocus(keyname, page.e)) or keyHintFocus(keyname, @tabs_e)
            return false

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # keyhints
        if keyHintFocus(keyname, @tabs_e)
            return false

class Moka.Image extends Moka.Widget
    constructor: (@src, w, h, onload, onerror) ->
        super $("<img>", class:"moka-widget moka-image", width:w, height:h)
        @img = @e
        @e.one( "load",
            () =>
                @ok = true

                e = @e[0]
                @width = e.naturalWidth
                @height = e.naturalHeight
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

class Moka.Canvas extends Moka.Widget
    constructor: (@src, w, h, onload, onerror) ->
        super $("<canvas>", class:"moka-widget moka-canvas", width:w, height:h)
        @img = $("<img>", width:w, height:h)
        @img.one( "load",
            () =>
                @ok = true

                img = @img[0]
                e = @e[0]
                @width = e.width = img.naturalWidth
                @height = e.height = img.naturalHeight

                @ctx = e.getContext("2d")
                @ctx.clearRect(0,0,@width,@height)
                @ctx.drawImage(img,0,0,@width,@height)

                onload?()
        )
        @img.one( "error",
            () =>
                @ok = false
                @width = @height = 0
                onerror?()
        )
        @img.attr("src", @src)

    resize: (w,h) ->
        return this if not @ok
        e = @e[0]
        @ctx.clearRect(0,0,e.width,e.height)
        e.width = w if w>0
        e.height = h if h>0
        @ctx.drawImage(@img[0],0,0,e.width,e.height)
        return this

    sharpen: (strength) ->
        return this if not @ok
        if @t_sharpen
            window.clearTimeout(@t_sharpen)
        if strength < 0
            strength = 0
        else if strength > 1
            strength = 1

        e = @e[0]
        w = Math.ceil(e.width)
        h = Math.ceil(e.height)

        dataDesc = @ctx.getImageData(0, 0, w, h)
        data = dataDesc.data
        dataCopy = @ctx.getImageData(0, 0, w, h).data

        mul = 15
        mulOther = 1 + 3*strength
        weight = 1 / (mul - 4 * mulOther)

        mul *= weight
        mulOther *= weight

        w4 = w*4
        y = 1

        filter = (miny) ->
            offsetY = (y-1)*w4
            nextY = if y == h then y - 1 else y
            prevY = if y == 1 then 0 else y-2
            offsetYPrev = prevY*w4
            offsetYNext = nextY*w4

            while (y < miny)
                offsetY = (y-1)*w4

                nextY = if (y is h) then y - 1 else y
                prevY = if (y is 1) then 0 else y-2

                offsetYPrev = prevY*w4
                offsetYNext = nextY*w4

                x = w
                offset = offsetY - 4 + w*4
                offsetPrev = offsetYPrev + (w-2) * 4
                offsetNext = offsetYNext + (w-1) * 4
                while (x)
                    r = dataCopy[offset] * mul - mulOther * (
                        dataCopy[offsetPrev] +
                        dataCopy[offset-4] +
                        dataCopy[offset+4] +
                        dataCopy[offsetNext])

                    g = dataCopy[offset+1] * mul - mulOther * (
                        dataCopy[offsetPrev+1] +
                        dataCopy[offset-3] +
                        dataCopy[offset+5] +
                        dataCopy[offsetNext+1])

                    b = dataCopy[offset+2] * mul - mulOther * (
                        dataCopy[offsetPrev+2] +
                        dataCopy[offset-2] +
                        dataCopy[offset+6] +
                        dataCopy[offsetNext+2])

                    data[offset]   = Math.min( Math.max(r,0), 255 )
                    data[offset+1] = Math.min( Math.max(g,0), 255 )
                    data[offset+2] = Math.min( Math.max(b,0), 255 )

                    if x < w
                        offsetNext -= 4
                    --x
                    offset -= 4
                    if x > 2
                        offsetPrev -= 4

                ++y
                offsetY += w4
                if y != h
                    ++nextY
                    offsetYPrev += w4
                if y > 2
                    ++prevY
                    offsetYNext += w4
            @ctx.putImageData(dataDesc, 0, 0)
            @t_sharpen = if (y > h) then 0 else
                window.setTimeout(filter.bind(this, Math.min(y+50, h+1)), 0)

        @t_sharpen = window.setTimeout(filter.bind(this, 50), 0)

        return this

    isLoaded: () ->
        return @ok?

class Moka.ImageView extends Moka.Input
    default_keys: {}

    constructor: (src, @use_canvas, @sharpen) ->
        super
        @e.addClass("moka-imageview")
        @src = src

    show: () ->
        if @image
            if @t_remove
                window.clearTimeout(@t_remove)
                @t_remove = null
            @e.show()
            if @ok?
                @zoom(@z, @zhow)
                @e.trigger("mokaLoaded")
                @e.trigger("mokaDone", [not @ok])
        else
            onload = () =>
                @ok = true

                @zoom(@z, @zhow)

                @e.trigger("mokaLoaded")
                @e.trigger("mokaDone", [false])
            onerror = () =>
                @ok = false
                @e.trigger("mokaError")
                @e.trigger("mokaDone", [true])
            if @use_canvas
                @image = new Moka.Canvas(@src, "", "", onload, onerror)
            else
                @image = new Moka.Image(@src, "", "", onload, onerror)
            @zoom(@z, @zhow)
            @image.appendTo(@e)
            @e.show()
        return this

    hide: () ->
        @e.hide()
        if @image? and not @t_remove
            # delay resource removal
            @t_remove = window.setTimeout(
                () =>
                    dbg "removing image", @image.img.attr("src")
                    @ok = null
                    @image.img.attr("src", "")
                    @image.remove()
                    @image = null
                    @t_remove = null
            , 60000 )
        return this

    isLoaded: () ->
        return @ok?

    zoom: (how, how2) ->
        if how?
            need_update = @z isnt how or @zhow isnt how2
            @z = how
            @zhow = how2

            if @image?
                e = @image.e
                width = e.outerWidth() or e.width() or @image.width
                height = e.outerHeight() or e.height() or @image.height
                w = h = mw = mh = ""

                if how instanceof Array
                    mw = how[0]
                    mh = how[1]

                    d = mw/mh
                    d2 = width/height
                    if how2 is "fill"
                        if d > d2
                            w = mw
                            h = height*mw/width
                        else
                            h = mh
                            w = width*mh/height
                        mw = mh = ""
                    else
                        if d > d2
                            h = mh
                            w = width*mh/height
                        else
                            w = mw
                            h = height*mw/width
                        mw = mh = ""
                else
                    @z = parseFloat(how) or 1
                    mw = Math.floor(@z*@image.width)
                    mh = Math.floor(@z*@image.height)

                if how2 isnt "fit" and how2 isnt "fill"
                    if width/height < mw/mh
                        h = mh
                    else
                        w = mw

                e.css('max-width': mw, 'max-height': mh, width: w, height: h)
                log('max-width': mw, 'max-height': mh, width: w, height: h)

                if need_update
                    @image.resize(w or mw, h or mh)
                    if @image.sharpen and @sharpen
                        @image.sharpen(@sharpen)

            return this
        else
            return @z

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)
        if doKey(keyname, @keys, @default_keys, this)
            return false
        else if (keyname is "LEFT" or keyname is "RIGHT") and @image.e.width() > @e.width()
            ev.stopPropagation()
        else if (keyname is "UP" or keyname is "DOWN") and @image.e.height() > @e.height()
            ev.stopPropagation()

class Moka.Viewer extends Moka.Input
    default_keys:
        RIGHT: -> isOnScreen(focused_widget, "right") and @focusRight() or
            @e.scrollLeft( @e.scrollLeft()+30 )
        LEFT: -> isOnScreen(focused_widget, "left") and @focusLeft() or
            @e.scrollLeft( @e.scrollLeft()-30 )
        UP: -> isOnScreen(focused_widget, "top") and @focusUp() or
            @e.scrollTop( @e.scrollTop()-30 )
        DOWN: -> isOnScreen(focused_widget, "bottom") and @focusDown() or
            @e.scrollTop( @e.scrollTop()+30 )

        TAB: ->
            if @index + @current + 1 < @length() and @currentcell + 1 < @cellCount()
                @next()
            else
                return false
        'S-TAB': -> if @currentcell > 0 then @prev() else false

        KP6: -> @next()
        KP4: -> @prev()
        KP2: -> @nextRow()
        KP8: -> @prevRow()
        SPACE: -> if isOnScreen(focused_widget, "bottom") then @next() else
            @e.scrollTop( @e.scrollTop()+0.9*@e.parent().height() )
        'S-SPACE': -> if isOnScreen(focused_widget, "top") then @prev() else
            @e.scrollTop( @e.scrollTop()-0.9*@e.parent().height() )

        ENTER: -> @dblclick?()

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
        @e.addClass("moka-viewer")
          .resize( @update.bind(this) )
          .bind( "scroll.moka", @onScroll.bind(this) )
          .css("cursor", "move")
          .attr("tabindex", 1)
          .bind( "mokaFocusUpRequest", () => @select(@index + @current); return false )
        $(window).bind("resize.moka", @update.bind(this) )

        @table = $("<table>", class:"moka-table", border:0, cellSpacing:0, cellPadding:0)
                .appendTo(@e)

        @cells = []
        @items = []

        # index of first item on current page
        @index = 0
        # index of selected item on current page
        @current  = -1
        # index of selected cell in viewer (from left to right, top to bottom)
        @currentcell = -1

        # preload item if it is less than preload_offset pixels away
        @preload_offset = 200

        @layout([1,1])
        @orientation("lt")
        @zoom(1)

    show: () ->
        @e.show()
        @update()

    update: ->
        return if not @e.is(":visible")

        @view(@index)

        w = @items
        $.each( w, (i) -> if w[i].update then w[i].update?() )
        return this

    focus: (ev) ->
        cell = @cells[if @currentcell > 0 then @currentcell else 0]
        Moka.focusFirst( cell.children() ) or Moka.focus(cell)
        return this

    append: (widget) ->
        id = @items.length
        widget.parentWidget = this
        @items.push(widget)
        if @lay[0] <= 0 or @lay[1] <= 0
            @updateTable()

        @update()

        return this

    at: (index) ->
        return @items[index]

    currentItem: () ->
        if @current >= 0
            return @at(@index+@current)
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
        return this if id >= @length()
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
        return this if not @e.is(":visible")
        return this if id < 0 or id >= @length()

        dbg "selecting view", id

        cell = @cell(@current) or @cell(0)
        Moka.blur( cell.children() ) or Moka.blur(cell)

        count = @cellCount()
        @current = id%count

        if id < @index or id >= @index+count
            @view(id)

        cell = @cell(id%count)
        Moka.focusFirst( cell.children() ) or Moka.focus(cell)

        return this

    zoom: (how) ->
        if how?
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

                for s in [@table[0].cellSpacing, @table[0].cellPadding, @table[0].border]
                    if s
                        w += layout[0]*s
                        h += layout[0]*s

                @z = [w,h]
                @zhow = how
            else if how is "+" or how is "-"
                d = if how is "-" then 0.889 else 1.125

                if not @z
                    @z = 1

                if @z instanceof Array
                    @z[0] *= d
                    @z[1] *= d
                else
                    @z *= d
                @zhow = null
            else if how instanceof Array
                @z = how
                @zhow = null
            else
                factor = parseFloat(how) or 1
                @z = factor
                @zhow = null

            i = @index
            len =i+@cellCount()
            len = Math.min(len, @length())
            dbg "zooming views", i+".."+(len-1), "using method", @z, @zhow
            while i < len
                item = @at(i)
                item.zoom?(@z, @zhow)
                ++i
            if @current >= 0
                ensureVisible( @at(@index+@current).e )

            @updateVisible()

            @e.trigger("mokaZoomChanged")
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

        cell = new Moka.Input().e
        id = @cellCount()
        cell.data("moka-cell-id", id)
        cell.css("overflow":"hidden")
        cell.addClass("moka-view")
            .bind("mokaFocused",
                (ev) =>
                    return if @currentcell is id and @currentindex is @index+id
                    if ev.target is cell[0] and Moka.focusFirst(cell.children())
                        return

                    @cells[@currentcell]?.removeClass("moka-current")
                                         .trigger("mokaDeselected", [@index + @current])
                    @currentindex = @index+id
                    @currentcell = id
                    @current = cell.data("itemindex")

                    cell.addClass("moka-current")
                    @e.trigger("mokaSelected", [@index + @current])
            )
            .appendTo(td)

        @cells.push(cell)

        return cell

    cell: (index) ->
        return @cells[ @indexfn(index) ]

    updateTable: () ->
        cell.children().detach() for cell in @cells
        @table.empty().hide()
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

            @clear()

            @e.removeClass("moka-layout-"+@lay.join("x")) if @lay
            @lay = [x, y]
            @e.addClass("moka-layout-"+@lay.join("x"))

            dbg "setting layout", @lay

            id = @index+@currentcell
            @updateTable()
            @update()
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
            h = cell.outerHeight()
            w = cell.outerWidth()
            item.hide()
            cell.css(width:w, height:h)

    updateVisible: (now) ->
        if not now
            window.clearTimeout(@t_update) if @t_update
            @t_update = window.setTimeout( @updateVisible.bind(this, true), 100 )
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
                        #ensureVisible(current_item)
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
                item.e.one("mokaDone", loaded)
                item.show()
                return
            if not item or not cell
                if @current >= 0 and not Moka.scrolling
                    @select(@index + @current)
                dbg "updateItems finished for direction", direction
                if direction > 0
                    updateItems.call(this, @index+@current-direction, -direction)
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

            item.e.one("mokaDone", loaded)
            item.show()

        #cell.css(width:"", height:"") for cell in @cells
        if @current >= 0
            # TODO: load current item first
            #updateItems(@index, 1)
            # calling updateItems multiple times here breaks layout
            updateItems(@index+@current, 1)
            #updateItems(@index+@current, -1)
        else
            updateItems(@index, 1)

    onScroll: (ev) ->
        lay = @layout()
        if lay[0] isnt 1 or lay[1] isnt 1
            @updateVisible()

    mousedown: (ev) ->
        if ev.button is 0
            dragScroll(ev)
        if ev.button is 1
            if @zhow is "fit" then @zoom(1) else @zoom("fit")

    dblclick: () ->
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

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # keyhints
        if keyHintFocus(keyname, @e)
            return false

class Moka.Notification extends Moka.Widget
    constructor: (html, notification_class, delay, @animation_speed) ->
        super
        if not Moka.notificationLayer?
            Moka.notificationLayer =
                $("<div>", id:"moka-notification-layer")
                    .appendTo("body")
        delay = 8000 if not delay?
        @animation_speed = 1000 if not @animation_speed?

        @e.addClass("moka-notification "+notification_class)
          .hide()
          .html(html)
          .bind( "mouseenter.moka", () => window.clearTimeout(@t_notify) )
          .bind( "mouseleave.moka", () => @t_notify = window.setTimeout(@remove.bind(this), delay/2) )
          .appendTo(Moka.notificationLayer)
          .fadeIn(@animation_speed)

        @t_notify = window.setTimeout( @remove.bind(this), delay )

    remove: () ->
        window.clearTimeout(@t_notify)
        @e.hide( @animation_speed, (() => @e.remove()) )

Moka.clearNotifications = () ->
    Moka.notificationLayer?.empty()

class Moka.Window extends Moka.Input
    default_keys:
        ESCAPE: -> @close()
        F4: -> @close()
        F2: -> @title.do(Moka.focus)
        F3: ->
            last_focused = focused_widget

            wnd = new Moka.Window("Search")
            w = new Moka.LineEdit("Find string:")
            e = w.e
            edit = w.edit

            edit.blur   () -> wnd.close()
            wnd.addKey "ESCAPE", () ->
                Moka.focus(last_focused)
                wnd.close()
            wnd.addKey "ENTER", () =>
                tofocus = Moka.findInput( @e, edit.attr("value") )
                Moka.focus(if tofocus then tofocus else last_focused)
                wnd.close()

            pos = @position()
            wnd.append(w)
               .appendTo( @e.parent() )
               .position(pos.left, pos.top)
               .show()
               .focus()

    default_title_keys:
        LEFT: ->
            pos = @e.offset()
            pos.left -= 20
            @e.offset(pos)
        RIGHT: ->
            pos = @e.offset()
            pos.left += 20
            @e.offset(pos)
        UP: ->
            pos = @e.offset()
            pos.top -= 20
            @e.offset(pos)
        DOWN: ->
            pos = @e.offset()
            pos.top += 20
            @e.offset(pos)
        'S-LEFT': ->
            pos = @e.offset()
            pos.left = 0
            @e.offset(pos)
        'S-RIGHT': ->
            pos = @e.offset()
            pos.left = @e.parent().innerWidth() - @e.outerWidth(true)
            @e.offset(pos)
        'S-UP': ->
            pos = @e.offset()
            pos.top = 0
            @e.offset(pos)
        'S-DOWN': ->
            pos = @e.offset()
            pos.top = @e.parent().innerHeight() - @e.outerWidth(true)
            @e.offset(pos)
        'C-LEFT':  -> @nextWindow("left", -1)
        'C-RIGHT': -> @nextWindow("left", 1)
        'C-UP':    -> @nextWindow("top", -1)
        'C-DOWN':  -> @nextWindow("top", 1)
        SPACE: -> @body.toggle()
        ESCAPE: -> @close()
        TAB: -> @focus()

    constructor: (title) ->
        super
        self = this
        @e.addClass("moka-window")
          .attr("tabindex", 1)
          .hide()
          .bind( "mokaFocusUpRequest", () => @title.do(Moka.focus); return false )
          .bind "mokaFocused", () =>
              cls="moka-top_window"
              @e.parent().children("."+cls).removeClass(cls)
              @e.addClass("moka-top_window")

        e = @container = $("<div>").css(width:"100%", height:"100%").appendTo(@e)

        $(window).bind( "resize.moka", @update.bind(this) )

        # title
        @title = new Moka.Input()
        @title.keydown = @keyDownTitle.bind(this)
        @title.e.addClass("moka-title")
                .appendTo(e)

        # window title buttons
        $("<div>", {'class':"moka-window-button moka-close"})
            .css('cursor', "pointer")
            .click( @hide.bind(this) )
            .appendTo(@title.e)
        $("<div>", {'class':"moka-window-button moka-maximize"})
            .css('cursor', "pointer")
            .click( @maximize.bind(this) )
            .appendTo(@title.e)

        # title name
        Moka.createLabel(title).appendTo(@title.e)

        # body
        @body = body = $("<div>", {class:"moka-body"})
                      .bind( "scroll.moka", @update.bind(this) )
                      .appendTo(e)

        @title.dblclick = () -> body.toggle(); Moka.focusFirst(body); return false
        @title.mousedown = (ev) => @focus(); ev.preventDefault() # prevent selecting text when double-clicking

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
                .mousedown (ev) ->
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

        @widgets = []

        initDraggable(@e, @title.e)
        $(window).load( (() -> @update()).bind(this) )

    toggleShow: ->
        if @e.is(":visible") then @hide() else @show()
        return this

    show: ->
        @e.show()
        @update()
        return this

    update: ->
        w = @widgets
        $.each( w, (i) -> w[i].update?() )

        # vertical align
        #$(".moka-widget.valign").each(
            #() ->
                #$this = $(this)
                #ah = $this.height()
                #ph = $this.parent().height()
                #mh = (ph - ah) / 2
                #$this.css('margin-top', mh)
            #)
        return this

    hide: () ->
        @e.detach()
        return this

    append: (widgets) ->
        for widget in arguments
            widget.parentWidget = this
            widget.e.appendTo(@body)
            @widgets.push(widget)

        @update()

        return this

    center: () ->
        @e.offset({
            left:(@e.parent().width()-@e.width())/2,
            top:(@e.parent().height()-@e.height())/2
        })
        return this

    focus: () ->
        Moka.focus(@title)
        Moka.focusFirst(@body)
        return this

    position: (x,y) ->
        if x?
            pos = @e.parent().offset()
            @e.offset({left:pos.left+x, top:pos.top+y}) if pos
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
        wnds = @e.siblings(".moka-window")
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

    remove: () ->
        for widget in @widgets
            widget.remove()
        ee = @e.parent()
        v = super
        if focused_widget.length is 0
            # focus nearest widget in parent
            e = @e[0]
            while(ee.length)
                if Moka.focusFirst(ee) and focused_widget[0] isnt e
                    break
                ee = ee.parent()
        return v

    close: () ->
        @remove()

    keydown: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # keyhints
        if keyHintFocus(keyname, @body)
            return false

    keyDownTitle: (ev) ->
        return if ev.isPropagationStopped()
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_title_keys, this)
            return false

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
    $("body").find(".moka-window").each () ->
        $this = $(this)
        w = elementToWidget( $(this) )
        if w
            w.appendTo($this.parent()).show()
            $this.remove()

$(document).ready(mokaInit)

