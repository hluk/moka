wnd_count = 0
window.test = () ->
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

onLoad = () ->
    $("body").css(width:"100%", height:"100%")
        .bind("mokaValueChanged", (ev, value) ->
            console.log("New value ("+value+") for", ev.target) )

    wnd = new Moka.Window("HELP - <i>JavaScript generated window</i>")
    wnd.append(
        new Moka.WidgetList().append(
            new Moka.CheckBox("test _1:"),
            new Moka.TextEdit("test _2:", "test"),
            new Moka.Combo("test _3:").append("a", "b", "c", "d"),
            new Moka.LineEdit("test _4:")
        ),
        new Moka.Container().append(
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
       .center()
       .disableClose()
       .show()
       .focus()

$(document).ready(onLoad)

