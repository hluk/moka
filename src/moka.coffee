window.Moka = {}

# bind# {{{
Function.prototype.bind = (thisObj, var_args) ->
  self = this
  staticArgs = Array.prototype.splice.call(arguments, 1, arguments.length)

  return () ->
    args = staticArgs.concat()
    i = 0
    while i < arguments.length
      args.push(arguments[i++])
    return self.apply(thisObj, args)
# }}}

# console logging# {{{
((logobj=window.console) and logfn=logobj.log) or
((logobj=window.opera) and logfn=logobj.postError)
#((logobj=window) and logfn=logobj.alert)
log = if logfn then logfn.bind(logobj) else () -> return
# }}}

# debugging {{{
#dbg = log.bind(this, "DEBUG:")
dbg = () -> return
#dbg = () -> alert("DEBUG: "+Array.prototype.join.call(arguments, " "))
# }}}

# user agent # {{{
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
# }}}

# KEYBOARD# {{{
keycodes = {}# {{{
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
if userAgent() is userAgents.webkit
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
# }}}

last_keyname = last_keyname_timestamp = null
getKeyName = (ev) -># {{{
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
# }}}

keyHintFocus = (keyname, root) -># {{{
    if keyname.length is 1
        keyhint = keyname
    else
        # digit (1, KP1, S-1, ...)
        n = keyname[keyname.length-1]
        if n >= "0" and n <= "9"
            keyhint = n

    e = null
    if keyhint?
        root.find(".keyhint").each(
            () ->
                $this = $(this)
                if $this.is(":visible") and keyhint is $this.text().toUpperCase()
                    parent = $this.parent()
                    if not parent.hasClass("focused")
                        if parent.hasClass("tab")
                            e = parent
                            e.trigger("click")
                        else if parent.hasClass("input")
                            e = parent
                            Moka.focus(e)
                        else
                            e = parent.find(".input").eq(0)
                            Moka.focus(e)

                        if e.length
                            return false #break
        )

    return e and e.length
# }}}
# }}}

Moka.createLabel = (text, e) -># {{{
    if not e
        e = $("<div>")
    e.addClass("label")

    # replace _x with underlined character and assign x key
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
            '<span class="keyhint">'+key+'</span>' +
            text.substr(i+2)

    e.html(text)
    e.css("cursor","pointer")

    return e
# }}}

initDraggable = (e, handle_e) -># {{{
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
# }}}

# dragScroll {{{
tt = 0
jQuery.extend( jQuery.easing,
    easeOutCubic: (x, t, b, c, d) ->
        # refresh preview every 30ms
        if ( t>tt )
            tt = t+30
        return (t=t/1000-1)*t*t + 1
)

dragScroll = (ev) ->
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
    scrolling = false

    continueDragScroll = (ev) ->
        return if stop
        scrolling = true

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
        if not scrolling
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
                1000, "easeOutCubic")

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
# }}}

# GUI classes# {{{
# only one widget can can be focused at a time
focused_widget = $()
focus_timestamp = 0

Moka.focus = (e) -># {{{
    return if not e
    ee = if e.length then e[0] else e
    #window.setTimeout( (() -> ee.focus()), 0 )
    ee.focus()
# }}}

Moka.focus_first = (e) -># {{{
    if e.hasClass("input")
        ee = e
    else
        ee = e.find(".input:first")
    if ee.length
        Moka.focus(ee)
        return true
    else
        return false
# }}}

ensure_position = (ee, e, size) -># {{{
    ee.show()

    pos = e.offset()
    ee.offset(pos)
    if size
        w = e.outerWidth()
        h = e.outerHeight()
        ee.width(w).height(h)
    newpos = ee.offset()

    #t = ee.data("ensure_position_t")
    #window.clearTimeout(t) if t?

    #if Math.abs(pos.left-newpos.left)>2 or Math.abs(pos.top-newpos.top)>2
        #t = window.setTimeout(
              #ensure_position.bind(this, ee, e, left, top, size), 20)
        #ee.data("ensure_position_t", t)
    #else
        #ee.data("ensure_position_t", null)
# }}}

is_on_screen = (w, how) -># {{{
    return false if not w
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
    return x >= min and x <= max
# }}}

ensure_visible = (w, wnd) -># {{{
    e = if w.e then w.e else w

    if not wnd
        wnd = w.parent()
    return if not wnd.length

    if wnd[0].scrollHeight > wnd[0].offsetHeight+4
        pos = wnd.offset()
        cpos = e.offset()
        cleft   = cpos.left - pos.left
        ctop    = cpos.top - pos.top
        cright  = cleft + e.width()
        cbottom = ctop + e.height()

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

    return ensure_visible(w, wnd.parent())
# }}}

doKey = (keyname, keys, default_keys, object) -># {{{
    if (keys and fn = keys[keyname]) or
       (default_keys and fn = default_keys[keyname])
        if fn.apply(object) is false
            return false
        else
            return true
    return false
# }}}

# widget focusing # {{{
Moka.lostFocus = (ev) ->
    focused_widget.removeClass("focused")
                  .trigger("mokaBlurred")
    focused_widget = $()
    #dbg "blurred element",focused_widget

Moka.gainFocus = (ev) ->
    return if focus_timestamp is ev.timeStamp
    focus_timestamp = ev.timeStamp
    focused_widget = $(ev.target)
    focused_widget.addClass("focused")
                  .trigger("mokaFocused")
    ensure_visible(focused_widget)
    #dbg "focused element",focused_widget
# }}}

Moka.init = () -># {{{
    # wait before document loaded
    ensure_fns = []

    ensure_position_tmp = ensure_position
    ensure_position = (ee, e, size) ->
        ee.hide()
        ensure_fns.push ensure_position_tmp.bind(this, ee, e, size)

    $(window).load () ->
        ensure_position = ensure_position_tmp
        fn() for fn in ensure_fns
# }}}

class Moka.Widget# {{{
    constructor: () -># {{{
        @e = $("<div>", {'class':"widget"})
            .bind( "mokaFocused",  () -> $(this).addClass("focused") )
            .bind( "mokaBlurred",  () -> $(this).removeClass("focused") )
    # }}}

    show: -># {{{
        @e.show()
        @update()
        return this
    # }}}

    hide: () -># {{{
        @e.hide()
        return this
    # }}}

    update: () -># {{{
        return this
    # }}}

    isLoaded: () -># {{{
        return true
    # }}}
# }}}

class Moka.Input extends Moka.Widget # {{{
    constructor: () -># {{{
        super
        @e.addClass("input")
          .attr("tabindex", 0)
          .css("cursor","pointer")

          .bind("focus.moka", Moka.gainFocus)
          .bind("blur.moka",   Moka.lostFocus)
          .click( () -> Moka.focus(this) )

          .focus( (ev) => @focus?(ev) )
          .blur( (ev) => @blur?(ev) )
          .click( (ev) => @click?(ev) )
          .dblclick( (ev) => @dblclick?(ev) )
          .mouseup( (ev) => @mouseup?(ev) )
          .mousedown( (ev) => @mousedown?(ev) )
          .keydown( (ev) => @keydown?(ev) )
          .keyup( (ev) => @keyup?(ev) )
    # }}}
# }}}

class Moka.Selection extends Moka.Widget # {{{
    constructor: (@parent) -># {{{
        super
        @e.css({position:"absolute", 'z-index':-2})
          .addClass("selection")
          .appendTo(@parent)
        @current = null
    # }}}

    update: -># {{{
        @current ? @select(@current)
        return this
    # }}}

    select: (e) -># {{{
        @current.removeClass("current") if @current

        if e?
            pos = e.offset()
            @e.show()
              .width( e.outerWidth() )
              .height( e.outerHeight() )
              .offset({top:pos.top, left:pos.left})
            @current = e.addClass("current")
            ensure_position(this.e, e, true)
        else
            @e.hide()
    # }}}
# }}}

class Moka.Container extends Moka.Input# {{{
    constructor: () -># {{{
        super
        @e.addClass("container")

        @widgets = []
        @current = -1
        @selection = new Moka.Selection(@e)
    # }}}

    update: -># {{{
        w = @widgets
        $.each( w, (i) -> w[i].update() )
        @updateSelection()
        return this
    # }}}

    updateSelection: -># {{{
        @selection.select( if @current >= 0 then @widgets[@current].e else null )
    # }}}

    focus: () -># {{{
        @select(if @current >= 0 then @current else 0)
        return this
    # }}}

    length: () -># {{{
        return @widgets.length
    # }}}

    at: (index) -># {{{
        return @widgets[index]
    # }}}

    itemClass: (cls) -># {{{
        if cls
            @itemcls = cls
            return this
        else
            return @itemcls
    # }}}

    append: (widget) -># {{{
        id = @length()
        @widgets.push(widget)
        e = widget.e

        # first & last
        if id is 0
            e.addClass("first")
        else
            @widgets[id-1].e.removeClass("last")

        e.addClass(@itemcls+" last")
        e.bind( "mokaFocused", () =>
            if @current >= 0
                e.trigger("mokaDeselected", [@current])
            @current = id
            e.trigger("mokaSelected", [id])
            @updateSelection()
        )

        e.appendTo(@e)
          .bind("mokaSizeChanged", @update.bind(this) )
          #.children().focus( @update.bind(this) )

        return this
    # }}}

    next: -># {{{
        @select(if @current >= 0 and @current < @length()-1 then @current+1 else 0)
    # }}}

    prev: -># {{{
        l = @length()
        @select(if @current >= 1 && @current < l then @current-1 else l-1)
    # }}}

    select: (id) -># {{{
        if id >= 0
            @current = id
            w = @widgets[id]
            Moka.focus_first(w.e)
        else
            @current = -1

        @updateSelection()
    # }}}
# }}}

class Moka.CheckBox extends Moka.Input # {{{
    default_keys:# {{{
        SPACE: -> @toggle()
        ENTER: -> @toggle()
    # }}}

    constructor: (text, checked) -># {{{
        super
        @e.addClass("checkbox")
        Moka.createLabel(text, @e)

        @checkbox = $('<input>', {type:"checkbox", class:"value"})
                   .prependTo(@e)

        @value(checked)
    # }}}

    click: (ev) -># {{{
        return if ev.target.type is "checkbox"
        @toggle()
        return false
    # }}}

    toggle: () -># {{{
        @value(not @value())
        return this
    # }}}

    value: (val) -># {{{
        if val?
            @checkbox.attr("checked", val)
            return this
        else
            return @checkbox.is(":checked")
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)
        if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}
# }}}

class Moka.TextEdit extends Moka.Input# {{{
    default_keys: # {{{
        ENTER: ->
    # }}}

    constructor: (label_text, text) -># {{{
        super
        @e.addClass("textedit")
        Moka.createLabel(label_text, @e)
        @create = true
    # }}}

    update: () -># {{{
        if @create and @e.is(":visible")
            @create = false

            editor = new CodeMirror( @e[0],
                height: "dynamic"
                parserfile: "parsedummy.js"
                #stylesheet: "deps/codemirror/css/jscolors.css"
                path: "deps/codemirror/js/"
                onCursorActivity: () =>
                    window.clearTimeout(@t_sizeupdate) if @t_sizeupdate
                    @t_sizeupdate = window.setTimeout( @e.trigger.bind(@e, "mokaSizeChanged"), 300 )
            )

            $(editor.win.document)
                .keyup( @editorKeyUp.bind(this) )
                .keydown( () => @oldpos = @editor.cursorPosition() )

            win = $(editor.win)
            win.focus (ev) => ev.target = editor.wrapping; Moka.gainFocus(ev)
            win.blur  (ev) => ev.target = editor.wrapping; Moka.lostFocus(ev)

            @e.focus( () => @oldpos = line:null, character:null; editor.win.focus() )

            @editor = editor
            @oldpos = editor.cursorPosition()
    # }}}

    editorKeyUp: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        pos = @editor.cursorPosition()
        if @oldpos.line is pos.line and @oldpos.character is pos.character
            # emulate keydown event
            ev2 = jQuery.Event("keydown")
            ev2.which = ev.which
            @e.trigger(ev2)
        else
            @oldpos = pos
            ev.stopPropagation()
    # }}}

# }}}

# TODO: add button icon
class Moka.Button extends Moka.Input # {{{
    constructor: (label_text, onclick) -># {{{
        super
        Moka.createLabel(label_text, @e)
        @e.addClass("button")
        @click = onclick
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)

        if keyname is "ENTER" or keyname is "SPACE"
            @e.click()
            return false
    # }}}
# }}}

class Moka.WidgetList extends Moka.Container # {{{
    constructor: -># {{{
        super
        @e.addClass("widgetlist")

        @itemClass("widgetlistitem")
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)

        if @e.hasClass("horizontal")
            if keyname is "LEFT"
                @prev()
            else if keyname is "RIGHT"
                @next()
            else if not keyHintFocus(keyname, @e)
                return
        else
            if keyname is "UP"
                @prev()
            else if keyname is "DOWN"
                @next()
            else if not keyHintFocus(keyname, @e)
                return

        return false
    # }}}
# }}}

class Moka.ButtonBox extends Moka.WidgetList # {{{
    constructor: -># {{{
        super
        @e
          .removeClass("widgetlist")
          .addClass("buttonbox horizontal")
    # }}}

    append: (label_text, onclick) -># {{{
        widget = new Moka.Button(label_text, onclick)
        super widget
        widget.e.removeClass("widgetlistitem")

        return this
    # }}}
# }}}

class Moka.Tabs extends Moka.Input # {{{
    default_keys: # {{{
        ENTER: -> Moka.focus_first(@pages[@current].e)
        SPACE: -> @pages_e.toggle()

        TAB: -> if (page = @pages[@current]) then Moka.focus_first(page.e)
        LEFT: ->  if @vertical() then @focusUp() else @prev()
        RIGHT: -> if @vertical() then @focusDown() else @next()
        UP: -> if @vertical() then @prev() else @focusUp()
        DOWN: -> if @vertical() then @next() else @focusDown()

        PAGEUP: -> if @vertical() then @tabs.select(0)
        PAGEDOWN: -> if @vertical() then @tabs.select(@tabs.length()-1)
        HOME: -> if not @vertical() then @tabs.select(0)
        END: -> if not @vertical() then @tabs.select(@tabs.length()-1)
    # }}}

    constructor: -># {{{
        super
        @e.addClass("tabs_widget")

        @tabs = new Moka.Container()
               .itemClass("tab")
        @tabs_e = @tabs.e
            .addClass("tabs")
            .appendTo(@e)
            .bind "mokaSelected", (ev, id) =>
                @pages[@current].hide() if @current >= 0
                @current = id
                @pages[id].show()

        @pages_e = $("<div>", class:"pages")
                   .appendTo(@e)

        @pages = []
        @current = 0

        @vertical(false)
    # }}}

    update: -># {{{
        @tabs.update()
        # update active page and tab selection cursor
        if @current >= 0
            @pages[@current].show()
        return this
    # }}}

    focus: () -># {{{
        Moka.focus(@tabs.e)
        return this
    # }}}

    focusUp: () -># {{{
        Moka.focus( @e.parents(".input").eq(0) )
        return this
    # }}}

    focusDown: () -># {{{
        Moka.focus_first( @pages[@current].e )
        return this
    # }}}

    next: () -># {{{
        @tabs.next()
        return this
    # }}}

    prev: () -># {{{
        @tabs.prev()
        return this
    # }}}

    append: (tabname, widget) -># {{{
        @pages.push(widget)
        page = if widget.e then widget.e else widget

        tab = new Moka.Input()
        Moka.createLabel(tabname, tab.e)
        @tabs.append(tab)

        widget.hide()
        page.addClass("widget page")
        page.appendTo(@pages_e)

        if @current is @tabs.length()-1
            @select(@current)

        return this
    # }}}

    select: (id) -># {{{
        @tabs.select(id)
        return this
    # }}}

    vertical: (toggle) -># {{{
        if toggle?
            @tabs_e.addClass( if toggle is false then "horizontal" else "vertical" )
            @tabs_e.removeClass(if toggle is false then "vertical" else "horizontal")
            return this
        else
            return @tabs_e.hasClass("vertical")
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # send key press event to active page
        if page = @pages[@current]
            if page.keydown
                if page.keydown(ev) is false
                    return false
                else if ev.isPropagationStopped()
                    return

        # keyhints
        if keyHintFocus(keyname, @e)
            return false
    # }}}
# }}}

class Moka.ImageView extends Moka.Input# {{{
    default_keys: {}# {{{
    # }}}

    constructor: (src) -># {{{
        super
        @e.addClass("imageview")
          .keydown( @keyPress.bind(this) )
        @view = $("<img>", {class:"input", src:""})
               .appendTo(@e)
        @src = src
    # }}}

    show: () -># {{{
        if @ok?
            @e.show()
            @zoom(@z, @zhow)
            @e.trigger("mokaLoaded")
            @e.trigger("mokaDone", [not @ok])
        else
            @view.one( "load",
                () =>
                    @ok = true

                    e = @view[0]
                    @width = if e.width then e.width else e.naturalWidth
                    @height = if e.height then e.height else e.naturalHeight
                    @zoom(@z, @zhow)

                    @e.trigger("mokaLoaded")
                    @e.trigger("mokaDone", [not @ok] )
            )
            @view.one( "error",
                () =>
                    @ok = false
                    @width = @height = 0
                    @e.trigger("mokaError")
                    @e.trigger("mokaDone", [not @ok] )
            )
            @e.show()
            @view.attr("src", @src)
        return this
    # }}}

    hide: () -># {{{
        @e.hide()
        @ok = null
        @view.attr("src", "")
        return this
    # }}}

    isLoaded: () -># {{{
        return @ok?
    # }}}

    zoom: (how, how2) -># {{{
        if how?
            @z = how
            @zhow = how2

            if @ok?
                width = @view.outerWidth()
                height = @view.outerHeight()
                w = h = mw = mh = ""

                if how instanceof Array
                    # fit element to how[0] x how[1] rectangle
                    #if width/height < mw/mh
                        #mh = how[1] - height + @e.height()
                    #else
                        #mw = how[0] - width + @e.width()
                    mw = how[0] - width + @view.width()
                    mh = how[1] - height + @view.height()
                else
                    @z = parseFloat(how) or 1
                    mw = Math.floor(@z*@width)
                    mh = Math.floor(@z*@height)

                if how2 isnt "fit"
                    if width/height < mw/mh
                        h = mh
                    else
                        w = mw

                @view.css('max-width': mw, 'max-height':mh, width: w, height: h)

            return this
        else
            return @z
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)
        if doKey(keyname, @keys, @default_keys, this)
            return false
        else if (keyname is "LEFT" or keyname is "RIGHT") and @view.width() > @e.width()
            ev.stopPropagation()
        else if (keyname is "UP" or keyname is "DOWN") and @view.height() > @e.height()
            ev.stopPropagation()
    # }}}
# }}}

class Moka.Viewer extends Moka.Input # {{{
    default_keys: # {{{
        RIGHT: -> is_on_screen(focused_widget, "right") and @focusRight()
        LEFT: -> is_on_screen(focused_widget, "left") and @focusLeft()
        UP: -> is_on_screen(focused_widget, "top") and @focusUp()
        DOWN: -> is_on_screen(focused_widget, "bottom") and @focusDown()
        'KP6': -> @next()
        'KP4': -> @prev()
        'KP2': -> @nextRow()
        'KP8': -> @prevRow()
        SPACE: -> @nextPage()
        'S-SPACE': -> @prevPage()

        ENTER: ->
            if @oldlay
                lay = @oldlay
                z = @oldzoom
            else
                lay = [1,1]
                z = 1
            @oldlay = @layout()
            @oldzoom = @zoom()
            @zoom(z)
            @layout(lay)

        '*': -> @layout([1,1]); @zoom(1)
        '/': -> if @zoom() is "fit" then @zoom(1) else @zoom("fit")
        '+': -> @zoom("+")
        MINUS: -> @zoom("-")

        HOME: -> @select(0)
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
    # }}}

    constructor: () -># {{{
        super
        @e.addClass("viewer")
          .resize( @update.bind(this) )
          .bind( "scroll.moka", @onScroll.bind(this) )
          .css("cursor", "move")
        $(window).bind("resize.moka", @update.bind(this) )

        @table = $("<table>", class:"table", border:0, cellSpacing:0, cellPadding:0)
                .appendTo(@e)
                .bind("mokaFocused",
                    (ev) =>
                        e = $(ev.target)
                        return if not e.hasClass("view")
                        @currentcell = e.data("index")
                        @current = e.children().eq(0).data("index")
                        e.addClass("current")
                        e.trigger("mokaSelected", [@current])
                )
                .bind("mokaBlurred",
                    (ev) =>
                        e = $(ev.target)
                        return if not e.hasClass("view")
                        e.removeClass("current")
                        e.trigger("mokaDeselected", [@current])
                )

        @cells = []
        @items = []

        # index of first item on current page
        @index = 0
        # index of selected item on current page
        @current  = -1
        # index of selected cell in viewer (from left to right, top to bottom)
        @currentcell = -1

        # TODO: preload views
        @preload_count = 2
        #@preload_count = 0

        @orientation("lt")
        @layout([1,1])
        @zoom(1)
    # }}}

    show: () -># {{{
        @e.show()
        @update()
    # }}}

    update: -># {{{
        return if not @e.is(":visible")

        @view(@index)

        w = @items
        $.each( w, (i) -> if w[i].update then w[i].update?() )
        return this
    # }}}

    focus: (ev) -># {{{
        @currentcell = 0 if @currentcell < 0
        Moka.focus( @cells[@index + @currentcell] )
        return this
    # }}}

    append: (widget) -># {{{
        id = @items.length
        @items.push(widget)
        if @lay[0] <= 0 or @lay[1] <= 0
            @updateTable()
        @update()

        return this
    # }}}

    at: (index) -># {{{
        return @items[index]
    # }}}

    currentItem: () -># {{{
        if @current >= 0
            return @at(@index+@current)
        else
            return null
    # }}}

    length: () -># {{{
        return @items.length
    # }}}

    view: (id) -># {{{
        return this if id >= @length()
        id = 0 if id < 0

        # TODO: hide previous (removes resources from memory)
        #olditems = @items.slice(@index, @index+len)
        #for item in olditems
            #item.hide().e.remove()

        i = 0
        len = @cellCount()
        @index = Math.floor(id/len)*len

        dbg "displaying views",@index+".."+(@index+len-1)

        while i < len
            cell = @cell(i)
            item = @at(@index+i)

            cell.children().detach()
            if item
                cell.attr("tabindex", 1)
                    .css(width: @e.width(), height: @e.height())
                item.e.hide()
                      .data("index", i)
                      .appendTo(cell)
            else
                # cell is empty
                cell.attr("tabindex", "")
            ++i

        @zoom(@zhow)
        @updateVisible(true)

        return this
    # }}}

    preload: (indexes) -># {{{
        preloader = (indexes) ->
            return if indexes.length is 0

            i = indexes[0]
            next = preloader.bind(this, indexes.slice(1))
            if 0 < i < @length()
                item = @items[i]
                if item.isLoaded()
                    item.show()
                    next()
                else
                    item.e.one( "mokaDone", next )
                item.show()
            else
                return next()

        (preloader.bind(this, indexes))()
        return this
    # }}}

    select: (id) -># {{{
        return this if not @e.is(":visible")
        return this if id < 0 or id >= @length()

        dbg "selecting view",id

        count = @cellCount()
        @current = id%count

        if id < @index or id >= @index+count
            @view(id)

        cell = @cell(id%count)
        if cell
            ensure_visible( cell.children() )
            Moka.focus(cell)

        return this
    # }}}

    zoom: (how) -># {{{
        if how?
            @zhow = how

            if how is "fit"
                layout = @layout()
                if @lay[0] <= 0
                    layout[0] = 1
                else if @lay[1] <= 0
                    layout[1] = 1

                wnd = @e.parent()

                offset = wnd.offset()
                pos = @e.offset()
                pos.top -= offset.top
                pos.left -= offset.left

                w = (wnd.width()-pos.left)/layout[0]
                h = (wnd.height()-pos.top)/layout[1]

                for s in [@table.cellSpacing, @table.cellPadding, @table.border]
                    if s
                        w += layout[0]*s
                        h += layout[0]*s

                @z = [w,h]
            else if how is "+" or how is "-"
                d = 1.125
                d = 1/d if how is "-"

                if not @z
                    @z = 1

                if @z instanceof Array
                    @z[0] *= d
                    @z[1] *= d
                else
                    @z *= d
            else if not (how instanceof Array)
                factor = parseFloat(how) or 1
                @z = factor

            i = @index
            len =i+@cellCount()
            len = Math.min(len, @length())
            dbg "zooming views",i+".."+(len-1),"using method",@z,@zhow
            while i < len
                item = @at(i)
                item.zoom(@z, @zhow) if item.zoom
                ++i
            if @current >= 0
                ensure_visible( @at(@index+@current).e )

            @updateVisible()

            return this
        else
            return @z
    # }}}

    cellCount: () -># {{{
        return @cells.length
    # }}}

    next: () -># {{{
        @select(@index + @current + 1)
        return this
    # }}}

    prev: () -># {{{
        @select(@index + @current - 1)
        return this
    # }}}

    nextRow: () -># {{{
        @select(@index + @current + @layout()[0])
        return this
    # }}}

    prevRow: () -># {{{
        @select(@index + @current - @layout()[0])
        return this
    # }}}

    nextPage: () -># {{{
        @select(@index + @cellCount())
        return this
    # }}}

    prevPage: () -># {{{
        @select(@index - @cellCount())
        return this
    # }}}

    focusLeft: () -># {{{
        id = @currentcell - 1
        h = @layout()[0]
        if (id+1) % h is 0
            cell = @cells[id+h]
            if cell
                id = cell.children().eq(0).data("index")
                how = -@cellCount()
                if "r" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.children().eq(0).data("index")
                @select(@index + id)
        return this
    # }}}

    focusRight: () -># {{{
        id = @currentcell + 1
        h = @layout()[0]
        if id % h is 0
            cell = @cells[id-h]
            if cell
                id = cell.children().eq(0).data("index")
                how = @cellCount()
                if "r" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.children().eq(0).data("index")
                @select(@index + id)
        return this
    # }}}

    focusUp: () -># {{{
        id = @currentcell
        layout = @layout()
        h = layout[0]
        id -= h
        if id < 0
            len = @cellCount()
            cell = @cells[id+len]
            if cell
                id = cell.children().eq(0).data("index")
                how = -@cellCount()
                if "b" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.children().eq(0).data("index")
                @select(@index + id)
        return this
    # }}}

    focusDown: () -># {{{
        id = @currentcell
        layout = @layout()
        h = layout[0]
        id += h
        len = @cellCount()
        if id >= len
            cell = @cells[id-len]
            if cell
                id = cell.children().eq(0)?.data("index")
                how = @cellCount()
                if "b" in @o
                    how = -how
                @select(@index + id + how)
        else
            cell = @cells[id]
            if cell
                id = cell.children().eq(0)?.data("index")
                @select(@index + id)
        return this
    # }}}

    appendRow: () -># {{{
        return $("<tr>", class:"row")
              .hide()
              .appendTo(@table)
    # }}}

    appendCell: (row) -># {{{
        td = $("<td>")
            .appendTo(row)

        cell = new Moka.Input().e
        cell.addClass("view")
            .data("index", @cellCount())
            .focus( (ev) => Moka.focus_first(cell.children()) )
            .appendTo(td)

        @cells.push(cell)

        return cell
    # }}}

    cell: (index) -># {{{
        return @cells[ @indexfn(index) ]
    # }}}

    updateTable: () -># {{{
        cell.children().detach() for cell in @cells
        @table.empty()
        @cells = []

        layout = @layout()
        ilen = layout[0]
        jlen = layout[1]

        j = 0
        while j < jlen
            row = @appendRow()
            i = 0
            @appendCell(row) while ++i <= ilen
            row.show()
            ++j

        # reset orientation
        @orientation(@o)
    # }}}

    layout: (layout) -># {{{
        if layout
            x = Math.max( 0, Number(layout[0]) )
            y = Math.max( 0, Number(layout[1]) )
            return this if @lay and x is @lay[0] and y is @lay[1]

            @e.removeClass("layout_"+@lay.join("x")) if @lay
            @lay = [x, y]
            @e.addClass("layout_"+@lay.join("x"))

            dbg "setting layout",@lay

            id = @index+@currentcell
            @updateTable()
            @update()
            @select(id)

            return this
        else
            i = @lay[0]
            j = @lay[1]
            if i <= 0
                i = @length()
            else if j <= 0
                j = @length()
            return [i, j]
    # }}}

    orientation: (o) -># {{{
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
            log x,a,b
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
            log @o

            len = @cells.length
            return this if not len

            dbg "setting orientation",o

            x = @lay[0]
            y = @lay[1]

            fns =
                lt:(id) -> id
                rt:(id) -> i=id%x; j=Math.floor(id/x);   x-1 - i + j*x
                lb:(id) -> i=id%x; j=Math.floor(id/x); len-x + i - j*x
                rb:(id) -> i=id%x; j=Math.floor(id/x); len-1 - i - j*x

                tl:(id) -> i=id%y; j=Math.floor(id/y);               i*x + j
                tr:(id) -> i=id%y; j=Math.floor(id/y); len-1 - (y-1-i)*x - j
                bl:(id) -> i=id%y; j=Math.floor(id/y);         (y-1-i)*x + j
                br:(id) -> i=id%y; j=Math.floor(id/y); len-1 -       i*x - j

            # index function: view index -> cell index
            @indexfn = fns[@o]

            return this
        else
            return @o
    # }}}

    hideItem: (index) -># {{{
        item = @at(index)
        cell = @cell( index % @cellCount() )
        if item.e.is(":visible")
            dbg "hiding item",index
            h = cell.outerHeight()
            w = cell.outerWidth()
            item.hide()
            cell.css(width:w, height:h)
    # }}}

    updateSizes: () -># {{{
        i = 0
        len = @cellCount()
        while i < len
            item = @at(@index+i)
            if not item or item.isLoaded()
                ++i
                continue

            cell = @cell(i)
            if cell.width() <= 1
                cell.width( @e.width() )
            if cell.height() <= 1
                cell.height( @e.height() )
            ++i
    # }}}

    updateVisible: (now) -># {{{
        if not now
            window.clearTimeout(@t_update) if @t_update
            @t_update = window.setTimeout( @updateVisible.bind(this, true), 100 )
            return

        pos = @e.offset()
        wndleft   = pos.left
        wndtop    = pos.top
        wndright  = wndleft + @e.width()
        wndbottom = wndtop + @e.height()

        if @current >= 0
            current_item = @at(@index+@current).e

        updateItems = (index, direction) =># {{{
            next = updateItems.bind(this, index+direction, direction)

            cell = @cell(index-@index)
            item = @at(index)
            if not item or not cell
                # finished
                @updateSizes()
                return

            if item.e.is(":visible")
                return next()

            p = cell.parent()
            w = p.width()
            h = p.height()
            pos = cell.parent().offset()
            if pos.left + w < wndleft or
               pos.left > wndright or
               pos.top + h < wndtop or
               pos.top > wndbottom
                # TODO: remove resource if necessary
                return next()

            loaded = () =>
                dbg "view",index,"loaded"
                cell.css(width:"", height:"")

                # keep relative scroll offset after image is loaded
                left = @e.scrollLeft()
                top = @e.scrollTop()
                if left or top
                    ww = p.width()

                    hh = p.height()
                    if current_item
                        ensure_visible(current_item)
                    else
                        if pos.left < wndleft+@e.width()/2 and ww > w
                            @e.scrollLeft( left + (ww-w)/2 )
                        if pos.top < wndtop+@e.height()/2 and hh > h
                            @e.scrollTop( top + (hh-h)/2 )

                @updateVisible(true)
                #window.setTimeout(next, 20)
                #next()

            dbg "loading view",index

            if item.isLoaded()
                item.show()
                next()
            else
                item.e.one("mokaDone", loaded)
                item.show()
        # }}}

        cell.css(width:"", height:"") for cell in @cells
        if @current >= 0
            updateItems(@index+@current, 1)
            updateItems(@index+@current, -1)
        else
            updateItems(@index, 1)
    # }}}

    onScroll: (ev) -># {{{
        @updateVisible()
    # }}}

    mousedown: (ev) -># {{{
          if ev.button is 0
              dragScroll(ev)
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)

        # keyhints
        if keyHintFocus(keyname, @e)
            return false
        else if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}
# }}}

class Moka.Window extends Moka.Input# {{{
    default_keys: # {{{
        F4: -> @close()
    # }}}

    default_title_keys: # {{{
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
    # }}}

    constructor: (title) -># {{{
        super
        self = this
        @e.addClass("window")
          .attr("tabindex", -1)
          .hide()

        e = @container = $("<div>").css(width:"100%", height:"100%").appendTo(@e)

        $(window).bind("resize.moka", @update.bind(this) )

        # title
        @title = new Moka.Input()
        @title.keydown = @keyDownTitle.bind(this)
        @title.e.addClass("title")
                .html(title)
                .appendTo(e)

        # window title buttons
        $("<div>", {'class':"window_control close"})
            .css('cursor', "pointer")
            .click( @hide.bind(this) )
            .appendTo(@title.e)
        $("<div>", {'class':"window_control maximize"})
            .css('cursor', "pointer")
            .click( @maximize.bind(this) )
            .appendTo(@title.e)

        # body
        @body = body = $("<div>", {class:"body"})
                      .appendTo(e)

        @title.dblclick = () -> body.toggle(); Moka.focus_first(body); return false
        @title.mousedown = (ev) => @focus(); ev.preventDefault() # prevent selecting text when double-clicking

        # window edges
        edges =
            n:  [1, 1, 0, 1, 0, 1, "n"]
            e:  [1, 1, 1, 0, 1, 0, "e"]
            s:  [0, 1, 1, 1, 0, 1, "s"]
            w:  [1, 0, 1, 1, 1, 0, "w"]
            ne: [1, 1, 0, 0, 1, 1, "ne"]
            se: [0, 1, 1, 0, 1, 1, "se"]
            sw: [0, 0, 1, 1, 1, 1, "sw"]
            nw: [1, 0, 0, 1, 1, 1, "nw"]
        for edge, s of edges
            $("<div>", {class:"edge " + edge.split("").join(" ")})
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
                        if $this.hasClass("n")
                            body.height( body.height()-dy )
                            pos.top += dy
                        if $this.hasClass("e")
                            body.width( body.width()+dx )
                        if $this.hasClass("s")
                            body.height( body.height()+dy )
                        if $this.hasClass("w")
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
    # }}}

    toggleShow: -> # {{{
        if @e.is(":visible") then @hide() else @show()
        return this
    # }}}

    show: -># {{{
        @e.show()
        @update()
        return this
    # }}}

    update: -># {{{
        w = @widgets
        $.each( w, (i) -> w[i].update?() )

        # vertical align
        #$(".widget.valign").each(
            #() ->
                #$this = $(this)
                #ah = $this.height()
                #ph = $this.parent().height()
                #mh = (ph - ah) / 2
                #$this.css('margin-top', mh)
            #)
        return this
    # }}}

    hide: -># {{{
        @e.detach()
        return this
    # }}}

    append: (widget) -># {{{
        if widget.e and widget.e.hasClass("widget")
            @widgets.push(widget)
            widget.e.appendTo(@body)
        else
            widget.appendTo(@body)

        return this
    # }}}

    focus: () -># {{{
        Moka.focus_first(@body)
        return this
    # }}}

    position: (x,y) -># {{{
        if x?
            pos = @e.parent().offset()
            @e.offset({left:pos.left+x, top:pos.top+y})
            return this
        else
            return @e.offset()
    # }}}

    resize: (w, h) -># {{{
        @body.width(w).height(h)
        @update()
        return this
    # }}}

    maximize: () -># {{{
        # FIXME: maximum size is incorrect
        @position(0, 0)
        p = @e.parent()
        pos = @body.offset()
        pos2 = p.offset()
        pos.left += pos2.left
        pos.top += pos2.top
        @resize( p.width()-pos.left, p.height()-pos.top )

        return this
    # }}}

    nextWindow: (left_or_top, direction) -># {{{
        wnds = @e.siblings(".window")
        x = @e.offset()[left_or_top]
        d = -1
        e = @e
        wnds.each () ->
            $this = $(this)
            dd = direction * ($this.offset()[left_or_top] - x)
            if (d < 0 and dd >= 0) or (dd > 0 and dd < d)
                e = $this
                d = dd
        Moka.focus( e.find(".title:first") )
    # }}}

    close: () -># {{{
        @e.remove()
    # }}}

    keydown: (ev) -># {{{
        keyname = getKeyName(ev)

        # keyhints
        if keyHintFocus(keyname, @body)
            return false

        if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}

    keyDownTitle: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_title_keys, this)
            return false
    # }}}
# }}}
# }}}

$(document).ready(Moka.init)

