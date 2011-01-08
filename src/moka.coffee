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
dbg = log.bind(this, "DEBUG:")
#dbg = () -> return
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
                            e[0]?.focus()
                        else
                            e = parent.find(".input").eq(0)
                            e[0]?.focus()

                        if e.length
                            return false #break
        )

    return e and e.length
# }}}
# }}}

createLabel = (text) -># {{{
    e = $("<div>", {'class':"widget label"})

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
                      $(document).unbind("mousemove.mokaDrag")
                  else
                      e.offset({left:ev.pageX-x, top:ev.pageY-y})
              $(document).bind( "mousemove.mokaDrag", move)
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
            ev.target.focus()
            return

        # TODO: better algorithm to determine scroll animation speed and amount
        t = ev.timeStamp
        dt = t-start
        if 0 < dt < 90 and (dx > 0 or dy > 0)
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
# }}}

# GUI classes# {{{
# only one widget can can be focused at a time
focused_widget = $()
focus_timestamp = 0

focus_first = (e) -># {{{
    ee = e.find(".input:visible")
    if ee.length
        ee[0].focus()
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

    wnd = $(window)
    if how is "right" or how is "left"
        min = wnd.scrollLeft()
        max = min + wnd.width()
    else
        min = wnd.scrollTop()
        max = min + wnd.height()

    pos = e.offset()
    pos.right = pos.left + e.width()
    pos.bottom = pos.top + e.height()

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

init_GUI = () -># {{{
    # init widgets
    $(".input")
        .live( "focus",
            (ev) ->
                return if focus_timestamp is ev.timeStamp
                focus_timestamp = ev.timeStamp
                focused_widget = $(ev.target)
                focused_widget.trigger("mokaFocused")
                ensure_visible(focused_widget)
        )
        .live( "blur",
            () ->
                focused_widget = $()
                $(this).trigger("mokaLostFocus")
        )
    $(".widget")
        .live( "focusin",  () -> $(this).addClass("focused") )
        .live( "focusout", () -> $(this).removeClass("focused") )

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

class Widget# {{{
    default_keys: {}

    constructor: () -># {{{
        @e = $("<div>", {'class':"widget"})
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

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        # keyhints
        if keyHintFocus(keyname, @body)
            return false
    # }}}
# }}}

class Selection extends Widget# {{{
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
        pos = e.offset()
        @e
            .width( e.outerWidth() )
            .height( e.outerHeight() )
            .offset({top:pos.top, left:pos.left})

        if @current then @current.removeClass("current")
        @current = e.addClass("current")

        ensure_position(this.e, e, true)
    # }}}
# }}}

class CheckBox extends Widget# {{{
    default_keys:# {{{
        SPACE: -> @value(not @value())
        ENTER: -> @value(not @value())
    # }}}

    constructor: (text, checked) -># {{{
        super
        label = createLabel(text)

        @e.css("cursor","pointer")
          .keydown( @keyPress.bind(this) )

        @checkbox = $('<input>', {type:"checkbox", 'class':"input value"})
                   .prependTo(label)
                   .click( (ev) -> ev.stopPropagation() )

        # clicking on option selects input text or toggles checkbox
        label.click(
            () ->
                if not checkbox.attr('disabled')
                    checkbox
                        .focus()
                        .attr( "checked", if checkbox.is(':checked') then 0 else 1 )
        ).appendTo(@e)

        @value(checked)
    # }}}

    value: (val) -># {{{
        if val?
            @checkbox.attr("checked", val)
            return this
        else
            return @checkbox.attr("checked")
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)
        if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}
# }}}

class TextEdit extends Widget# {{{
    default_keys:# {{{
        # movement
        LEFT:  -> @moveCursor(-1, 0)
        RIGHT: -> @moveCursor(1, 0)
        UP:    -> @moveCursor(0, -1)
        DOWN:  -> @moveCursor(0, 1)
        HOME: ->
            e = @getChars().eq(@pos).parent().children(".c").eq(0)
            @moveCursor(@index(e)-@pos, 0)
        END: ->
            e = @getChars().eq(@pos).parent().children(".c").eq(-1)
            @moveCursor(@index(e)-@pos, 0)
            # if cursor moves to other line it stays on the end
            @left = 999999

        # character deletion
        DELETE: ->
            if @sel1 is @sel2
                @removeChars(@sel1, @sel1+1)
            else
                @removeChars(@sel1, @sel2)
            @selection(@sel1, @sel1)
        BACKSPACE: ->
            if @sel1 is @sel2
                pos = @sel1-1
                @removeChars(pos, @sel1)
            else
                pos = @sel1
                @removeChars(@sel1, @sel2)
            @selection(pos, pos)

        # selection
        'S-LEFT':  -> @moveCursor(-1, 0, true)
        'S-RIGHT': -> @moveCursor(1, 0, true)
        'S-UP':    -> @moveCursor(0, -1, true)
        'S-DOWN':  -> @moveCursor(0, 1, true)
        'S-HOME': ->
            e = @getChars().eq(@pos).parent().children(".c").eq(0)
            @moveCursor(@index(e)-@pos, 0, true)
        'S-END': ->
            e = @getChars().eq(@pos).parent().children(".c").eq(-1)
            @moveCursor(@index(e)-@pos, 0, true)
        'C-A': -> @selection(0, @text.length)
    # }}}

    constructor: (label_text, text, @multiline) -># {{{
        super
        self = this

        @keys = {}
        if @multiline
            edit = @edit = $("<textarea>")
        else
            edit = @edit = $("<input>")
            @keys.UP = @keys.DOWN = @keys['S-UP'] = @keys['S-DOWN'] = () -> return

        edit.addClass("input value")
            .keydown( @keyPress.bind(this) )
            .blur( @blur.bind(this) )

        @e.addClass("textedit")

        if label_text
            # clicking on option selects input text or toggles checkbox
            label = createLabel(label_text)
                   .mousedown( (ev) -> edit[0]?.focus() if not edit.is(":focus"); ev.preventDefault() )
                   .appendTo(@e)

        editor = @editor = $("<div>")
        editor.addClass( (if @multiline then "multi" else "") + "lineedit" )
        editor.mousedown (ev) ->
            return if ev.button isnt 0

            edit[0]?.focus() if not edit.is(":focus")

            index = (e) ->
                if e.hasClass("l")
                    e = e.children(".c").eq(-1)
                else if e.hasClass("linenumber")
                    e = e.next()
                return self.index(e)

            from = index( $(ev.target) )
            return if from is -1
            self.select(from, from)

            editor.mousemove (ev) ->
                to = index( $(ev.target) )
                return if to is -1
                self.select(from, to)
            $(document).one( "mouseup",
                (ev) -> editor.unbind("mousemove") if ev.button is 0
            )
            ev.preventDefault()
        editor.dblclick (ev) ->
            e = $(ev.target)
            nbsp = String.fromCharCode(160)
            # double click on line -> select line
            if e.hasClass("l")
                chars = e.children(".c")
                from = self.index( chars.eq(0) )
                to = self.index( chars.eq(-1) )
            # double click on a char -> select word
            else
                chars = self.chars.children(".l").children(".c")
                if e.hasClass("linenumber")
                    chars = e.parent().children(".c")
                    from = self.index( chars.eq(0) )
                    to = self.index( chars.eq(-1) )
                else
                    e = chars.eq(self.sel1)
                    if e.text() != nbsp
                        ee = e
                        while ee.length and ee.text()[0] isnt nbsp
                            to = self.index(ee)
                            ee = ee.next()
                        ++to
                        ee = e
                        while ee.length and ee.text()[0] isnt nbsp
                            from = self.index(ee)
                            ee = ee.prev()
            self.select(from, to)

            ev.preventDefault()
        editor.appendTo(label)

        cursor = @cursor = $("<div>", {class:"cursor"}).css({position:"absolute"})
                .css({'cursor':"text"})
                .mousedown( (ev) -> ev.preventDefault() )
                .hide()
                .appendTo(editor)

        edit.css({opacity:0, position:"absolute", left:"-10000px", tabindex:100000})
            .focus( () -> cursor.show(); self.selection(); editor.addClass("focused") )
            .blur( () -> cursor.hide(); editor.removeClass("focused") )
            .appendTo(label)

        # characters in editor
        @chars = $("<div>", {class:"cs"})
                .appendTo(editor)

        @value(if text then text else "")
        @sel1 = @sel2 = 0
    # }}}

    dirty: () -># {{{
        @lines = @characters = null
    # }}}

    getLines: () -># {{{
        if not @lines
            @lines = @chars.children(".l")
        return @lines
    # }}}

    getChars: () -># {{{
        if not @characters
            @characters = @getLines().children(".c")
        return @characters
    # }}}

    index: (e) -># {{{
        # return character element index
        return @getChars().index(e)
    # }}}

    indexOnLine: (e) -># {{{
        # return character element index on line
        return e.parent().children(".c").index(e)
    # }}}

    appendLine: () -># {{{
        l = $("<div>", {class:"l"})
            .css("min-height", "1em")
            .hide()
        $("<span>", {class:"linenumber"}).appendTo(l)
        l.appendTo(@chars)

        @characters = null

        return l
    # }}}

    char: (c) -># {{{
        # return char element
        ce = $("<span>", {class:"c"})
            .css("cursor","text")

        if c is ' '
            ce.html("&nbsp;")
        else if c is '\n'
            ce.html("&nbsp;").addClass("eol")
        else if c is null
            ce.html("&nbsp;").addClass("eof")
        else if c is '\t'
            ce.html("&nbsp;&nbsp;&nbsp;&nbsp;")
        else
            ce.text(c)

        return ce
    # }}}

    appendChar: (c, line) -># {{{
        @characters = null
        return @char(c).appendTo(line)
    # }}}

    insertChars: (text, to) -># {{{
        target = @getChars().eq(to)
        i = 0
        len = text.length
        while i < len
            e = @char( text[i++] )
            e.insertBefore(target)
            if e.hasClass("eol")
                p = e.parent()
                newline = @appendLine().insertAfter(p)
                e.nextAll( p.children(".c") ).appendTo(newline)
        @dirty()
        if newline
            @updateLines()
    # }}}

    remove: (ce) -># {{{
        if ce.hasClass("eol")
            nextline = ce.parent().next()
            nextline.children(".c").insertAfter(ce)
            nextline.remove()
        ce.remove()
    # }}}

    replaceChars: (from, to, replacement) -># {{{
        return if from < 0 or to < 0 or from > to
        @text = @text.slice(0, from) + replacement + @text.slice(to)

        i = 0
        len = replacement.length
        self = this
        @getChars().slice(from, to).each () -> self.remove($(this))

        @insertChars(replacement, to)
    # }}}

    removeChars: (from, to) -># {{{
        @replaceChars(from, to, "")
    # }}}

    updateText: () -># {{{
        @chars.empty()

        i = 0
        len = @text.length
        l = null
        while i < len
            # line element
            l = @appendLine() if l is null

            c = @text[i]
            @appendChar(c, l)

            if c is '\n'
                l = null
            ++i
        # last empty line
        l = @appendLine() if l is null

        # end of input character
        @appendChar(null, l)

        @updateLines()

        @selection(0, 0)

        return true
    # }}}

    updateLines: () -># {{{
        lines = @getLines()
        ln = lines.children(":first-child")
        len = ln.length
        i = 0
        j = 1
        padding = new Array( Math.floor(Math.log(len)/2.3)+1 ).join("&nbsp;")

        while i < len
            num = String(i+1)
            if j < num.length
                padding = padding.slice(6)
                ++j
            num = padding+num
            e = ln[i]
            e.innerHTML = num if e.innerHTML isnt num
            ++i
        lines.show()
    # }}}

    moveCursor: (dx, dy, anchored) -># {{{
        pos = @pos
        if dx
            chars = @getChars().eq(pos).parent().children(".c")
            a = @index( chars.eq(0) )
            b = @index( chars.eq(-1) )
            pos += dx
            if pos > b
                pos = b
            else if pos < a
                pos = a
            @left = @getChars().eq(pos).offset().left
        if dy
            char = @getChars().eq(pos)
            ln = char.parent()
            if dy > 0
                line = ln while ( ln = ln.next() ) and (--dy) >= 0
            else
                line = ln while ( ln = ln.prev() ) and (++dy) <= 0

            left = char.offset().left
            if not @left or left > @left
                @left = left
            else
                left = @left

            ch = line.children(".c").eq(0)
            while ch.length and left >= ch.offset().left
                char = ch
                ch = ch.next()
            pos = @index(char)

        if pos >= 0
            if anchored
                if @pos is @sel1
                    @selection(@sel2, pos)
                else
                    @selection(@sel1, pos)
            else
                @selection(pos, pos)
    # }}}

    selection: (from, to) -># {{{
        return if from < 0 or to < 0 or not @cursor.is(":visible")
        from = @sel1 if from is undefined
        to = @sel2 if to is undefined

        # cursor position
        #@pos = if to is @sel2 then from else to
        @pos = to

        # selection
        chars = @getChars()
        chars.eq(@sel1).parent().removeClass("current")
        chars.eq(@sel2).parent().removeClass("current")
        chars.slice(@sel1, @sel2)
             .each( () -> $(this).removeClass("selected") )
        if from <= to
            @sel1 = from
            @sel2 = to
        else
            @sel1 = to
            @sel2 = from
        chars.slice(@sel1, @sel2).each( () -> $(this).addClass("selected") )

        c = chars.eq(@pos)
        c.parent().addClass("current")

        # scroll to current char
        c_pos = c.offset()
        pos = @chars.offset()

        c_s = c.height()+16
        s = @chars.innerHeight()
        d = c_pos.top - pos.top
        scroll = @chars.scrollTop()
        if d-c_s < 0
            @chars.scrollTop(scroll + d-c_s)
        else if d+2*c_s > s
            @chars.scrollTop(scroll + d + 2*c_s - s)

        c_s = c.width()+16
        s = @chars.innerWidth()
        d = c_pos.left - pos.left
        scroll = @chars.scrollLeft()
        if d-c_s < 0
            @chars.scrollLeft(scroll + d-c_s)
        else if d+2*c_s > s
            @chars.scrollLeft(scroll + d + 2*c_s - s)

        ensure_position(@cursor, c, true)

        window.clearTimeout(@size_t) if @size_t?
        @size_t = window.setTimeout( ( () ->
            @size_t = null
            w = @e.width()
            h = @e.height()
            if @w isnt w or @h isnt h
                @w = w
                @h = h
                @e.trigger("mokaSizeChanged")
        ).bind(this), 200)
    # }}}

    update: () -># {{{
        @selection()
        return this
    # }}}

    blur: () -># {{{
        @e.removeClass('focused')
        @edit.removeClass('focused')
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_keys, this)
            return false

        k = keyname.split('-')
        k = k[k.length-1]
        # stop propagation only if
        if k.length is 1 or # a character typed
           k is "MINUS" or k is "SPACE" or # textedit keys
           ( @multiline and keyname is "ENTER" ) or # multilineedit keys
           ( keyname is "C-V" or keyname is "C-C" or keyname is "C-X" or
             keyname is "S-INSERT" or keyname is "S-DELETE" ) # clipboard access keys
            @edit.trigger("keyup")

            # set textarea text before default textarea action
            if @sel1 isnt @sel2
                @edit.attr("value", @text.slice(@sel1, @sel2)).select()
            else
                @edit.attr("value", "")

            # update text on keyup
            @edit.one("keyup", ( () ->
                text = @edit.attr("value")
                e = @edit[0]
                if (@sel1 is @sel2 and text) or
                   (text.slice(e.selectionStart, e.selectionEnd) isnt @text.slice(@sel1, @sel2))
                    len = text.length
                    @replaceChars(@sel1, @sel2, text)
                    pos = @sel1+len
                    @selection(pos, pos)
            ).bind(this) )

            ev.stopPropagation()
    # }}}

    value: (val) -># {{{
        if val?
            @text = val
            @updateText()
            return this
        else
            return @text
    # }}}
# }}}

# TODO: add button icon
class Button extends Widget # {{{
    constructor: (label_text, onclick) -># {{{
        super
        @e = createLabel(label_text) # $("<div>")
             .addClass("widget input button").attr("tabindex", 0)
             .click(onclick)
             .keydown( @keyPress.bind(this) )
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        if keyname is "ENTER" or keyname is "SPACE"
            @e.click()
            return false
    # }}}
# }}}

class WidgetList extends Widget # {{{
    constructor: -># {{{
        super
        @e.addClass("widgetlist")
          .keydown( @keyPress.bind(this) )
        @widgets = []
        @items = []
        @selection = sel = new Selection(@e)
        @.current = -1
    # }}}

    update: -># {{{
        w = @widgets
        $.each( w, (i) -> w[i].update?() )
        @updateSelection()
        return this
    # }}}

    next: -># {{{
        @select(if @current >= 0 and @current < @items.length-1 then @current+1 else 0)
    # }}}

    prev: -># {{{
        l = @items.length
        @select(if @current >= 1 && @current < l then @current-1 else l-1)
    # }}}

    select: (id, no_focus) -># {{{
        old_id = @current
        if old_id != id
            @current = id
            item = @items[id]
            if not no_focus
                e = item.filter(".input")
                if not e.length
                    e = item.find(".input")
                e[0]?.focus()

            @updateSelection()

            item.trigger("mokaSelected", [id])
    # }}}

    append: (widget) -># {{{
        if widget.e?
            ee = widget.e
            @widgets.push(widget)
        else
            ee = widget

        id = @items.length

        # first & last
        if id == 0
            ee.addClass("first")
        else
            @items[id-1].removeClass("last")
        @items.push(ee)

        ee.addClass("widget widgetlistitem last")
        ee.filter(".input").focus( @select.bind(this, id, false) )
        ee.find(".input").focus( @select.bind(this, id, false) )

        ee.appendTo(@e)
          .bind("mokaSizeChanged", @updateSelection.bind(this) )
          .children().focus( @updateSelection.bind(this) )

        return this
    # }}}

    updateSelection: -># {{{
        if @current >= 0
            @selection.select( @items[@current] )
    # }}}

    keyPress: (ev) -># {{{
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

class ButtonBox extends WidgetList # {{{
    constructor: -># {{{
        super
        @e
          .removeClass("widgetlist")
          .addClass("buttonbox horizontal")
    # }}}

    updateSelection: -># {{{
    # }}}

    append: (label_text, onclick) -># {{{
        widget = new Button(label_text, onclick)
        super widget
        widget.e.removeClass("widgetlistitem")

        return this
    # }}}
# }}}

class Tabs extends Widget # {{{
    constructor: -># {{{
        super
        @e.addClass("tabs_widget")
          .keydown( @keyPress.bind(this) )

        self = this
        @tabs_e = $("<div>", {class:"tabs input", tabindex:0})
                 .appendTo(@e)
        @tabs_e.focus(
            () ->
                id = self.current
                if id >= 0
                    self.tabs_e.children(".tab")
                        .eq(id)
                        .addClass("focused")
        )
        @tabs_e.blur(
            () ->
                id = self.current
                if id >= 0
                    self.tabs_e.children(".tab")
                        .eq(id)
                        .removeClass("focused")
        )
        @pages_e = $("<div>", class:"pages")
                   .appendTo(@e)

        @pages = []
        @current = -1
        @selection = new Selection(@tabs_e)

        @setVertical(false)
    # }}}

    update: -># {{{
        # update active page and tab selection cursor
        if @current >= 0
            @pages[@current].update?()
        @updateSelection()
        return this
    # }}}

    next: -># {{{
        if (@current >= 0 && @current < @pages.length-1)
            @select(@current+1)
        else
            @select(0)
    # }}}

    prev: -># {{{
        l = @pages.length
        if (@current >= 1 && @current < l)
            @select(@current-1)
        else
            @select(l-1)
    # }}}

    select: (id) -># {{{
        @tabs_e[0]?.focus()
        old_id = @current

        if old_id != id
            if old_id >= 0
                @pages[old_id].hide()
                @tabs_e.children(".tab").eq(old_id).removeClass("focused")

            page = @pages[id]
            page.show()

            tab = @tabs_e.children(".tab").eq(id)
                 .trigger("mokaSelected", [id])
            @current = id

        @updateSelection()

        return this
    # }}}

    updateSelection: -># {{{
        if not @e.is(":visible")
            return

        if @current >= 0
            tab = @tabs_e.children(".tab").eq(@current)
            @selection.select(tab)
    # }}}

    append: (tabname, widget) -># {{{
        @pages.push(widget)
        page = if widget.e then widget.e else widget

        tab = createLabel(tabname)
        tab.addClass("tab")
        tab.appendTo(@tabs_e)

        widget.hide()
        page.addClass("widget page")
        page.appendTo(@pages_e)

        id = @pages.length-1
        tab.click( @select.bind(this, id) )

        if id is 0
            @select(0)

        return this
    # }}}

    setVertical: (toggle) -># {{{
        @tabs_e.addClass( if toggle is false then "horizontal" else "vertical" )
        @tabs_e.removeClass(if toggle is false then "vertical" else "horizontal")
        return this
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        # focus next/previous tab
        go_next = go_prev = go_focus_up = go_focus_down = false
        if @tabs_e.hasClass("vertical")
            if keyname is "UP"
                go_prev = true
            else if keyname is "DOWN"
                go_next = true
            else if keyname is "LEFT"
                go_focus_up = true
            else if keyname is "RIGHT"
                go_focus_down = true
        else
            if keyname is "LEFT"
                go_prev = true
            else if keyname is "RIGHT"
                go_next = true
            else if keyname is "UP"
                go_focus_up = true
            else if keyname is "DOWN"
                go_focus_down = true

        if go_next or go_prev or go_focus_up or go_focus_down
            @tabs_e[0]?.focus()
            if go_next
                @next()
            else if go_prev
                @prev()
            else if go_focus_up
                @e.parents().children(".input").eq(-1)[0]?.focus()
            else
                page = @pages[@current]
                page = page.e if page.e?
                page.find(".input")[0]?.focus()

            return false

        # send key press event to active page
        if @current >= 0
            page = @pages[@current]
            if page.keyPress
                if page.keyPress(ev) is false
                    return false
                else if ev.isPropagationStopped()
                    return

        # keyhints
        if keyHintFocus(keyname, @e)
            return false
    # }}}
# }}}

class ImageView extends Widget# {{{
    default_keys = {}# {{{
    # }}}

    constructor: (src) -># {{{
        super
        @e.addClass("imageview")
          .keydown( @keyPress.bind(this) )
        @view = $("<img>", {class:"input", tabindex:0, src:""})
               .appendTo(@e)
        @src = src
    # }}}

    show: () -># {{{
        if @ok?
            @e.trigger("mokaLoaded")
            @e.trigger("mokaDone", [not @ok])
            @zoom(@z, @zhow)
        else
            @view.one( "load",
                () =>
                    e = @view[0]
                    @width = if e.width then e.width else e.naturalWidth
                    @height = if e.height then e.height else e.naturalHeight

                    @ok = true
                    @e.trigger("mokaLoaded")
                    @e.trigger("mokaDone", [not @ok] )

                    @zoom(@z, @zhow)
            )
            @view.one( "error",
                () =>
                    @width = @height = 0
                    @ok = false
                    @e.trigger("mokaError")
                    @e.trigger("mokaDone", [not @ok] )
            )
            @view.attr("src", @src)
        @e.show()
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
                w = h = mw = mh = ""
                if how instanceof Array
                    mw = how[0]
                    mh = how[1]
                else
                    @z = parseFloat(how) or 1
                    mw = Math.floor(@z*@width)
                    mh = Math.floor(@z*@height)

                if how2 isnt "fit"
                    if @width/@height < mw/mh
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

class Viewer extends Widget# {{{
    default_keys:# {{{
        RIGHT: -> is_on_screen(focused_widget, "right") and @next()
        LEFT: -> is_on_screen(focused_widget, "left") and @prev()
        UP: -> is_on_screen(focused_widget, "top") and @prevRow()
        DOWN: -> is_on_screen(focused_widget, "bottom") and @nextRow()
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
        'MINUS': -> @zoom("-")
        HOME: -> @select(0)
        END: -> @select(@length()-1)
        PAGEUP: ->
            c=@visibleItems()
            if @current%c is 0
                @select(@index-c)
            else
                @select(@index)
        PAGEDOWN: ->
            c=@visibleItems()
            if (@current+1)%c is 0
                @select(@index+c)
            else
                @select(@index+c-1)
    # }}}

    constructor: () -># {{{
        super
        @e.addClass("viewer")
          .keydown( @keyPress.bind(this) )
          .resize( @update.bind(this) )
          .one( "scroll.mokaViewerScroll", @onScroll.bind(this) )
          .mousedown( (ev) -> if ev.button is 0 then dragScroll(ev) )
          .css("cursor", "move")

        @table = $("<table>", class:"table", cellSpacing:0, cellPadding:0).appendTo(@e)
                .bind("mokaFocused",
                    (ev) =>
                        e = $(ev.target).parents(".view:last")
                        return if not e.length
                        @current = e.data("index")
                        e.addClass("current")
                         .attr('tabindex', -1)
                )
                .bind("mokaLostFocus",
                    (ev) =>
                        e = $(ev.target).parents(".view:last")
                        return if @current isnt e.data("index")
                        @current = -1
                        e.removeClass("current")
                         .attr('tabindex', -1)
                )

        @cells = []
        @items = []
        @index = 0
        @current = -1
        @preload_count = 2
        #@preload_count = 0

        @layout([1,1])
        @zoom(1)
    # }}}

    show: () -># {{{
        @e.show()
        @update()
    # }}}

    update: -># {{{
        return if not @e.is(":visible")

        if @current >= 0
            id = @index + @current

        if @lastlay isnt @lay
            @lastlay = @lay
            @updateTable()

        @view(@index)

        if @zhow is "fit"
            @zoom(@zhow)

        @onScroll()

        @select(id) if id?

        w = @items
        $.each( w, (i) -> if w[i].update then w[i].update?() )
        return this
    # }}}

    append: (widget) -># {{{
        id = @items.length
        @items.push(widget)
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

        flood = (from, to, i, dir) ->
            if i >= to or i < 0
                @preload( [i...i+@preload_count] )
                return

            cell = @cell(i)
            item = @at(from+i)

            cell.empty()
            if item
                cell.attr("tabindex", 0)
                e = if item.e then item.e else item
                container = $("<div>", {class:"container"})
                           .css(width: @e.width(), height: @e.height())
                           .appendTo(cell)
                e.appendTo(container)

                nextflood = (ev, error) =>
                    if error
                        item.hide()
                    else
                        item.zoom(@z, @zhow) if item.zoom
                    flood.apply(this, [from, to, i+dir, dir])

                if @lay[0] > 0 and @lay[1] > 0
                    if item.isLoaded()
                        item.show()
                        nextflood()
                    else
                        item.e.one("mokaDone", nextflood)
                        item.show()
                else
                    item.e.hide()
                    nextflood()
            else
                cell.attr("tabindex", -1)

        len = @cells.length
        return if not len

        # hide previous (removes resources from memory)
        #olditems = @items.slice(@index, @index+len)
        #for item in olditems
            #item.hide().e.remove()

        # show next
        @index = Math.floor(id/len)*len

        i = id%len
        dbg "displaying views",@index+".."+(@index+len-1)
        flood.apply(this, [@index, len, i, 1])
        flood.apply(this, [@index, len, i-1, -1])

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
        dbg "selecting view",id
        return this if not @e.is(":visible")
        return this if id < 0 or id >= @length()
        count = @visibleItems()
        if id < @index or id >= @index+count
            @view(id)

        @e.unbind("scroll.mokaViewerScroll")

        # item should be visible before gaining focus
        cell = @cell(id % count)
        focus_first(cell) or cell[0]?.focus()

        @onScroll()

        return this
    # }}}

    indexOnPage: () -># {{{
        return @current
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
                    @z = 1 * d
                else if @z instanceof Array
                    @z[0] *= d
                    @z[1] *= d
            else if not how instanceof Array
                factor = parseFloat(how) or 1
                @z = factor

            i = @index
            len =i+@visibleItems()
            len = Math.min(len, @length())
            dbg "zooming views ",i+".."+(len-1)," using method ",@zhow,@z
            while i < len
                item = @at(i)
                item.zoom(@z, @zhow) if item.zoom
                ++i

            @onScroll()

            return this
        else
            return @z
    # }}}

    visibleItems: () -># {{{
        # number of visible items
        layout = @layout()
        return layout[0]*layout[1]
    # }}}

    next: () -># {{{
        @select(@index+@current+1)
        return this
    # }}}

    prev: () -># {{{
        @select(@index+@current-1)
        return this
    # }}}

    nextRow: () -># {{{
        @select(@index + @indexOnPage() + @layout()[0])
        return this
    # }}}

    prevRow: () -># {{{
        @select(@index + @indexOnPage() - @layout()[0])
        return this
    # }}}

    nextPage: () -># {{{
        @select(@index + @visibleItems())
        return this
    # }}}

    prevPage: () -># {{{
        @select(@index - @visibleItems())
        return this
    # }}}

    appendRow: () -># {{{
        return $("<tr>", class:"row")
               .hide()
               .appendTo(@table)
    # }}}

    appendCell: (row) -># {{{
        cell = $("<td>", {class:"widget input view"})
              .data("index", @cells.length)
              .hide()
              .focus( () -> focus_first(cell) )
              .appendTo(row)
        @cells.push(cell)
        return cell
    # }}}

    cell: (index) -># {{{
        return @cells[index]
    # }}}

    updateTable: () -># {{{
        @table.empty()
        @cells = []

        layout = @layout()
        ilen = layout[0]
        jlen = layout[1]

        j = 0
        while j < jlen
            row = @appendRow()
            i = 0
            while ++i <= ilen
                cell = @appendCell(row)
                cell.show()
            row.show()
            ++j
    # }}}

    layout: (layout) -># {{{
        if not layout
            i = @lay[0]
            j = @lay[1]
            if i <= 0
                i = @length()
                j = 1
            else if j <= 0
                i = 1
                j = @length()
            return [i, j]

        dbg "setting layout",layout
        @lay = layout
        @update()

        return this
    # }}}

    showItem: (index) -># {{{
        if @lay[0] <= 0
            sz2 = "height"
            scroll2 = "scrollTop"
        else if @lay[1] <= 0
            sz2 = "width"
            scroll2 = "scrollLeft"
        else
            return

        cell = @cells[index]
        item = @at(index)

        p = @table
        h = p[sz2]()
        # scrolling relative to middle
        scrolld = h/2 - @e[scroll2]()

        updateSize = () =>
            dbg "item",index,"loaded in continuous layout"
            if scrolld
                h2 = p[sz2]()
                if h < h2
                    # keep the biggest size for table (all cells can be smaller)
                    p[sz2](h2)
                    # keep scroll offset after image is loaded
                    @e[scroll2]( h2/2 - scrolld )

            h = cell.outerHeight()
            w = cell.outerWidth()

            item.e.parent().css(width:"", height:"")

            @onScroll()

        if item.isLoaded()
            item.show()
            updateSize()
        else
            item.e.parent().css(width:"", height:"")
            item.e.one( "mokaDone", updateSize )
            item.show()
    # }}}

    hideItem: (index) -># {{{
        item = @at(index)
        cell = @cells[index % @visibleItems()]
        if item.e.is(":visible")
            dbg "hiding item",index,"in continuos view"
            h = cell.outerHeight()
            w = cell.outerWidth()
            item.hide()
            item.e.parent().css(width:w, height:h)
    # }}}

    onScroll: () -># {{{
        @e.unbind("scroll.mokaViewerScroll")

        if @lay[0] <= 0
            dir = "left"
            sz = "width"
            scroll = "scrollLeft"
        else if @lay[1] <= 0
            dir = "top"
            sz = "height"
            scroll = "scrollTop"
        else
            @e.one( "scroll", @onScroll.bind(this) )
            return

        min = @e.offset()[dir]
        i = 0
        while (cell = @cells[i]) and (pos = cell.offset()[dir] + cell[sz]()) < min
            if pos < min - @e.width()
                @hideItem(@index+i)
            ++i

        max = min+@e[sz]()
        preloaded = 0
        while (cell = @cells[i]) and (((pos = cell.offset()[dir]) < max) or ++preloaded <= @preload_count)
            item = @at(@index + i)
            break if not item.e.is(":visible")
            ++i

        if cell and not item.e.is(":visible")
            @showItem(i)
            return
        else
            while cell = @cells[i]
                @hideItem(@index+i)
                ++i
            @e.one( "scroll", @onScroll.bind(this) )
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        # keyhints
        if keyHintFocus(keyname, @e)
            return false
        else if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}
# }}}

class Window extends Widget# {{{
    default_keys: {}# {{{
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
          .keydown( @keyPress.bind(this) )
          .hide()

        e = @container = $("<div>").css(width:"100%", height:"100%").appendTo(@e)

        $(window).resize( @update.bind(this) )

        # title
        @title = $("<div>", {'class':"title", 'html':title, tabindex:0})
                .css('cursor', "pointer")
                .keydown( @keyPressTitle.bind(this) )
                .appendTo(e)

        # window title buttons
        $("<div>", {'class':"window_control close"})
            .css('cursor', "pointer")
            .click( @hide.bind(this) )
            .appendTo(@title)
        $("<div>", {'class':"window_control maximize"})
            .css('cursor', "pointer")
            .click( @maximize.bind(this) )
            .appendTo(@title)

        # body
        @body = body = $("<div>", {class:"body"})
                      .appendTo(e)

        @title.dblclick( () -> body.toggle(); focus_first(body); return false )
              .click( () -> this.focus() )
              .mousedown( (ev) -> ev.preventDefault() ) # prevent selecting text when double-clicking

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
                    $(document).bind("mousemove.mokaResize", (ev) ->
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
                    $(document).one("mouseup", () -> $(document).unbind("mousemove.mokaResize"))
                    return false

        @widgets = []

        initDraggable(@e, @title)
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
        @e.remove()
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
        @title[0].focus()
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
        e.children(".title")[0]?.focus()
    # }}}

    close: () -># {{{
        @e.remove()
    # }}}

    keyPress: (ev) -># {{{
        keyname = getKeyName(ev)

        # keyhints
        if keyHintFocus(keyname, @body)
            return false

        if doKey(keyname, @keys, @default_keys, this)
            return false
    # }}}

    keyPressTitle: (ev) -># {{{
        keyname = getKeyName(ev)

        if doKey(keyname, @keys, @default_title_keys, this)
            return false
    # }}}
# }}}
# }}}

$(document).ready(init_GUI)

