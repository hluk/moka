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

draggable = (e, handle_e) -># {{{
    if not handle_e
        handle_e = e
    return handle_e
      .css('cursor', "pointer")
      .mouseup( () -> $(document).unbind("mousemove") )
      .mousedown (ev) ->
          if ev.button is 0
              ev.preventDefault()
              self = $(this)
              pos = e.offset()
              x = ev.pageX - pos.left
              y = ev.pageY - pos.top
              $(document).mousemove( (ev) -> e.offset({left:ev.pageX-x, top:ev.pageY-y}) )
# }}}

# GUI classes# {{{
# only one widget can can be focused at a time
focused_widget = $()

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

    container =
        left:   wnd.scrollLeft()
        top:    wnd.scrollTop()
        width:  wnd.width()
        height: wnd.height()

    pos = e.offset()
    if (right = pos.left + e.width()) > container.left + container.width
        wnd.scrollLeft(right - container.width + 16)
    if pos.left < container.left
        wnd.scrollLeft(pos.left - 16)
    if (bottom = pos.top + e.height()) > container.top + container.height
        wnd.scrollTop(bottom - container.height + 16)
    if pos.top < container.top
        wnd.scrollTop(pos.top - 16)
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
                return if focused_widget is ev.target
                focused_widget = $(ev.target)
                                .trigger("mokaFocused")
                ensure_visible( focused_widget, $(window) )
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

    hide: -># {{{
        @e.hide()
        return this
    # }}}

    update: () -># {{{
        return this
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
        @view = $("<img>", {class:"input", tabindex:0})
               .appendTo(@e)
        @src = src
    # }}}

    show: () -># {{{
        if not @view.attr("src")
            @view.one("load", @e.trigger.bind(@e, "mokaLoaded") )
                 .one("error", @e.trigger.bind(@e, "mokaError") )
                 .attr("src", @src)
        else
            @view.trigger("mokaLoaded")
        @e.show()
        return this
    # }}}

    hide: () -># {{{
        @e.hide()
        @view.attr("src", "")
        return this
    # }}}

    zoom: (how) -># {{{
        if how?
            @z = how
            if how is "fit"
                @view.css( "max-height", @e.parent().css("max-height") )
            else
                @view.css("max-height", "none")
                @z = ""
        else
            return @z

        return this
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

# TODO:
#    * append a widget
#    * layouts: horizontal, vertical, 1x1, 2x2, 2x3, ...
#    * preload next widgets
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
                z = ""
            @oldlay = @layout()
            @oldzoom = @zoom()
            @zoom(z)
            @layout(lay)
        '*': -> @layout([1,1]); @zoom("")
        '/': -> if @zoom() is "fit" then @zoom("") else @zoom("fit")
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
        @table = $("<table>").appendTo(@e)
        @cells = []
        @items = []
        @index = 0
        @current = -1
        @preload = 2

        @layout([1,1])
        $(window).resize( @update.bind(this) )
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

    append: (widget) -># {{{
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
                @preloadNext()
                return

            cell = @cells[i]
            item = @items[from+i]

            cell.empty()
            if item
                cell.attr("tabindex", 0)
                e = if item.e then item.e else item
                e.appendTo(cell)
                self = this
                nextflood = flood.bind(this, from, to, i+dir, dir)
                item.e.one("mokaLoaded",
                    (ev) =>
                        $(ev.target).unbind()
                        @zoom(@z, from+i)
                        nextflood()
                )
                item.e.one("mokaError",
                    (ev) =>
                        $(ev.target).unbind()
                        item.hide()
                        nextflood()
                )
                item.show()
            else
                cell.attr("tabindex", -1)

        len = @cells.length

        # hide previous (removes resources from memory)
        olditems = @items.slice(@index, @index+len)
        for item in olditems
            item.hide().e.remove()

        # show next
        @index = Math.floor(id/len)*len
        flood.apply(this, [@index, len, id % len, 1])
        flood.apply(this, [@index, len, id % len-1, -1])

        return this
    # }}}

    preloadNext: () -># {{{
        i = @index + @visibleItems()
        len = Math.min(@length(), i+@preload)
        while i < len
            item = @items[i]
            item.show() if item.show
            ++i
    # }}}

    select: (id) -># {{{
        return this if id < 0 or id >= @length()
        count = @visibleItems()
        if id < @index or id >= @index+count
            @view(id)
        cell = @cells[id % count]
        focus_first(cell) or cell[0]?.focus()

        return this
    # }}}

    indexOnPage: () -># {{{
        return @current
    # }}}

    zoom: (how, index) -># {{{
        if how?
            @z = how
            if how is "fit"
                wnd = $(window)
                pos = @table.offset()
                w = (wnd.width()-pos.left)/@lay[0]-8+"px"
                h = (wnd.height()-pos.top)/@lay[1]-8+"px"

                row_css = {'max-height':h, 'height':h}
                cell_css = {'max-width':w, 'width':w, 'max-height':h, 'height':h}
            else
                @z = ""
                row_css = cell_css =
                    'max-width':"none"
                    width:"auto"
                    'max-height':"none"
                    height:"auto"
        else
            return @z

        @table.find(".row").css(row_css)
        @table.find(".view").css(cell_css)

        if index
            i = index
            len = index+1
        else
            i = @index
            len =i+@visibleItems()
        len = Math.min( len, @length() )

        while i < len
            item = @items[i]
            item.zoom(how) if item.zoom
            ++i

        @z = how

        return this
    # }}}

    visibleItems: () -># {{{
        # number of visible items
        return @lay[0]*@lay[1]
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
        @select(@index + @indexOnPage() + @lay[0])
        return this
    # }}}

    prevRow: () -># {{{
        @select(@index + @indexOnPage() - @lay[0])
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

    updateTable: () -># {{{
        @table.empty()
        @cells = []
        ilen = @lay[0]
        jlen = @lay[1]
        n = 0
        j = 0
        while j < jlen
            row = $("<tr>", class:"widget row")
            i = 0
            while i < ilen
                cell = $("<td>", {class:"widget input view"})
                      .focus( () -> focus_first($(this)) )
                      .appendTo(row)
                cell.bind("mokaFocused", ((e, n) ->
                    @current = n
                    e.addClass("current")
                     .attr('tabindex', -1)
                ).bind(this, cell, n) )
                cell.bind("mokaLostFocus", ((e) ->
                    @current = -1
                    e.removeClass("current")
                     .attr('tabindex', -1)
                ).bind(this, cell) )
                @cells.push(cell)
                ++i
                ++n
            row.appendTo(@table)
            ++j
        if @current >= 0
            id = @index + @current
        @update()
        @select(id) if id?
    # }}}

    layout: (layout) -># {{{
        if not layout
            return @lay
        @lay = layout
        @updateTable()

        return this
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
    default_keys: # {{{
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
        @e.addClass("window")
          .keydown( @keyPress.bind(this) )
          .hide()

        $(window).resize( @update.bind(this) )

        # title
        @title = $("<div>", {'class':"title", 'html':title, tabindex:0})
                .css('cursor', "pointer")
                .appendTo(@e)
                .keydown( @keyPress.bind(this) )

        # close button
        $("<div>", {'class':"close", 'html':
            #"&#8855"
            "&#8854"
            #"&#8856"
            #"&#8864"
            #"&#8863"
            #"&#8709"
        })
            .css('cursor', "pointer")
            .click( @hide.bind(this) )
            .appendTo(@title)

        # body
        @body = body = $("<div>", {class:"body"})
                      .appendTo(@e)

        @title.dblclick( () -> body.toggle(); focus_first(body); return false )
              .click( () -> focus_first(body); return false )
              .mousedown( (ev) -> ev.preventDefault() ) # prevent selecting text when double-clicking

        @widgets = []

        draggable(@e, @title)
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

        # all key-presses are local to the current window
        #ev.stopPropagation()
    # }}}
# }}}
# }}}

$(document).ready(init_GUI)

