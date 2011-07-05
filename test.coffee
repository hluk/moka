wnd_count = 0
window.test = () -># {{{
    wnd = new Moka.Window("Widget Test - Window #{++wnd_count}")

    p0 = new Moka.WidgetList()

    p1 = new Moka.WidgetList()
        .append( new Moka.TextEdit("text _edit widget:", "type some text\nhere", true) )
        .append( new Moka.LineEdit("_line edit widget:", "type some text here") )
        .append( new Moka.Button("_Button", () -> alert "CLICKED") )
        .append( new Moka.CheckBox("_Checkbox") )
        .append( new Moka.CheckBox("C_heckbox", true) )

    p2 = new Moka.ButtonBox()
        .append("Button_1", () -> alert "1 CLICKED")
        .append("Button_2", () -> alert "2 CLICKED")
        .append("Button_3", () -> alert "3 CLICKED")
        .append("Button_4", () -> alert "4 CLICKED")

    e = new Moka.Input($("<input>"))
    p3_2_1 = new Moka.Tabs()
          .vertical(true)
          .append("page _U", e)
          .append("page _V", e)
          .append("page _W", e)
    p3_1 = new Moka.Tabs()
          .vertical(true)
          .append("page _1", e)
          .append("page _2", p3_2_1)
          .append("page _3", e)
    p3 = new Moka.Tabs()
       .vertical(true)
       .append("page _X", p3_1)
       .append("page _Y", e)
       .append("page _Z", e)

    p4_2_1 = new Moka.Tabs()
          .append("page _U", e)
          .append("page _V", e)
          .append("page _W", e)
    p4_1 = new Moka.Tabs()
          .append("page _1", e)
          .append("page _2", p4_2_1)
          .append("page _3", e)
    p4 = new Moka.Tabs()
       .append("page _X", p4_1)
       .append("page _Y", e)
       .append("page _Z", e)

    t = new Moka.Tabs()
       .vertical(true)
       .append("page _A", p1)
       .append("page _B", p2)
       .append("page _C", p3)
       .append("page _D", p4)
    w = new Moka.Container().append(t, new Moka.ButtonBox().append("_Close", () -> wnd.close()) )
    wnd.append(w)

    $(".value").css 'font-family': "monospace"
    $(".page").addClass("valign")

    $(".widgetlistitem").bind("mokaSelected", (e, id) -> console.log "ITEM #{id} SELECTED")
    $(".buttonbox .button").bind("mokaSelected", (e, id) -> console.log "BUTTON #{id} SELECTED")
    $(".tab").bind("mokaSelected", (e, id) -> console.log "TAB #{id} SELECTED")

    wnd.e.prependTo("body")
    wnd.show()
    wnd.focus()
# }}}

onLoad = () -># {{{
    onLoad = undefined

    if title?
        document.title = title

    # variables from URL
    map = {}
    location.search.replace( /[?&]+([^=&]+)=([^&]*)/gi,
        (m,key,value) -> map[key] = value )

    # Moka.Viewer {{{
    v = new Moka.Viewer()
        .layout(if map.layout? then map.layout.split("x") else [1,1])
       .orientation(if map.o then map.o else "lt")
       #.layout([2,1])
       #.layout([0,1])
    #v.append(
        #new Moka.ButtonBox().append("Button _1", () -> alert "click 1!")
                       #.append("Button _2", () -> alert "click 2!")
    #)
    #v.append( new Moka.ImageView(item) ) for item in items
    for item in ls
        if item instanceof Array
            itempath = item[0]
        else
            itempath = item
        console.log itempath
        v.append( new Moka.ImageView(itempath) )
    #v.append( new Moka.Image(item) ) for item in items
    #v.append( new Moka.Button(i, ((x) ->-> alert x)(i)) ) for i in [0..36]

    # Viwer in document
    v.e.appendTo("body")
    v.show()

    # notifications
    oldid = undefined
    notify = (id) ->
        if id?
            oldid = id
        else
            id = oldid
        img = v.at(id)
        if img.image
            item = ls[id]
            if item instanceof Array
                itempath = item[0]
                # TODO: get item properties from item[1]
            else
                itempath = item
            Moka.notificationLayer?.empty()
            new Moka.Notification(
                "<b>#{id+1}/#{ls.length}</b><br/>"+
                "URL: <i>#{itempath}</i><br/>"+
                (if img.width then "size: <i>#{img.width}x#{img.height}</i></br>" else "") +
                "zoom: <i>#{if img.width then Math.floor(100*img.image.e.width()/img.width)+"%" else img.zhow}</i>",
                "", 4000, 300
            )

    v.e.bind "mokaSelected mokaZoomChanged", (ev, id) ->
        return if ev.target isnt this or not (id? or oldid?)
        notify(id)

    # Viewer in window
    #wnd = new Window("Viewer")
         #.append(v)
         #.resize(500, 300)
         #.show()
    #wnd.e.appendTo("body")
    #wnd.focus()
    # }}}

    # Moka.Window # {{{
    wnd = new Moka.Window("HELP - <i>JavaScript generated window</i>")
    wnd.append(
        new Moka.Container(true).append(
            new Moka.Container().append(
                new Moka.Label("Moka is JavaScript GUI framework."),
                new Moka.ButtonBox()
                    .append("Add _New Window", test, "Create new window")
                    .append("_Close", (() -> wnd.close()), "Close this window")
            ),
            new Moka.Image("img/moka.png", 96, 96).show()
        )
    )
    wnd.addKey("shift-t", test)
    wnd.appendTo("body")
       .position(0, 150)
       #.show()
       #.focus()
    # }}}

    v.zoom(map.zoom)
# }}}

$(document).ready(onLoad)

