(function() {
  var onLoad, test, wnd_count;
  wnd_count = 0;
  test = function() {
    var e, p0, p1, p2, p3, p3_1, p3_2_1, p4, p4_1, p4_2_1, w, wnd;
    wnd = new Moka.Window("Widget Test - Window " + (++wnd_count));
    p0 = new Moka.WidgetList();
    p1 = new Moka.WidgetList().append(new Moka.TextEdit("text _edit widget:", "type some text\nhere", true)).append(new Moka.TextEdit("text _edit widget:", "type some text here")).append(new Moka.Button("_Button", function() {
      return alert("CLICKED");
    })).append(new Moka.CheckBox("_Checkbox")).append(new Moka.CheckBox("C_heckbox", true));
    p2 = new Moka.ButtonBox().append("Button_1", function() {
      return alert("1 CLICKED");
    }).append("Button_2", function() {
      return alert("2 CLICKED");
    }).append("Button_3", function() {
      return alert("3 CLICKED");
    }).append("Button_4", function() {
      return alert("4 CLICKED");
    });
    e = new Moka.Input($("<input>"));
    p3_2_1 = new Moka.Tabs().vertical(true).append("page _U", e).append("page _V", e).append("page _W", e);
    p3_1 = new Moka.Tabs().vertical(true).append("page _1", e).append("page _2", p3_2_1).append("page _3", e);
    p3 = new Moka.Tabs().vertical(true).append("page _X", p3_1).append("page _Y", e).append("page _Z", e);
    p4_2_1 = new Moka.Tabs().append("page _U", e).append("page _V", e).append("page _W", e);
    p4_1 = new Moka.Tabs().append("page _1", e).append("page _2", p4_2_1).append("page _3", e);
    p4 = new Moka.Tabs().append("page _X", p4_1).append("page _Y", e).append("page _Z", e);
    w = new Moka.Tabs().vertical(true).append("page _A", p1).append("page _B", p2).append("page _C", p3).append("page _D", p4);
    wnd.append(w);
    $(".value").css({
      'font-family': "monospace"
    });
    $(".page").addClass("valign");
    $(".widgetlistitem").bind("mokaSelected", function(e, id) {
      return console.log("ITEM " + id + " SELECTED");
    });
    $(".buttonbox .button").bind("mokaSelected", function(e, id) {
      return console.log("BUTTON " + id + " SELECTED");
    });
    $(".tab").bind("mokaSelected", function(e, id) {
      return console.log("TAB " + id + " SELECTED");
    });
    wnd.e.prependTo("body");
    wnd.show();
    return wnd.focus();
  };
  onLoad = function() {
    var item, items, map, notify, oldid, onLoad, v, wnd, _i, _len;
    onLoad = void 0;
    items = ["file:///home/lukas/Pictures/paintings/Andrew Gonzales/AlbedoSublimis.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/AeternaSaltatus.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/amore.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Magia of the Heart.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Aura Gloriae.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/In The Wake of the.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Sapientia.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Seraphim Awakening.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/SirensDream.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Soror Mystica.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Telluric Womb.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Angel of Nekyia.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Breath of Dakini.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Love of Souls.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Oracle of the Pearl.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Summoning of the Muse.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Visitation.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/UnioMystica.jpg"];
    map = {};
    location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m, key, value) {
      return map[key] = value;
    });
    v = new Moka.Viewer().layout(map.layout.split("x")).orientation(map.o ? map.o : "lt");
    for (_i = 0, _len = items.length; _i < _len; _i++) {
      item = items[_i];
      v.append(new Moka.ImageView(item));
    }
    v.e.appendTo("body");
    v.show();
    oldid = void 0;
    notify = function(id) {
      var _ref;
      if (id != null) {
        oldid = id;
      } else {
        id = oldid;
      }
      if ((_ref = Moka.notificationLayer) != null) {
        _ref.empty();
      }
      return new Moka.Notification(("<b>" + (id + 1) + "/" + items.length + "</b><br/>") + ("URL: <i>" + items[id] + "</i><br/>") + ("zoom: <i>" + (v.at(id).zhow) + "</i>"), "", 4000, 300);
    };
    v.e.bind("mokaSelected mokaZoomChanged", function(ev, id) {
      console.log(oldid, id);
      if (ev.target !== this || !((id != null) || (oldid != null))) {
        return;
      }
      return notify(id);
    });
    wnd = new Moka.Window("HELP");
    wnd.append(new Moka.Container(true).append(new Moka.Container().append(new Moka.Label("Moka is JavaScript GUI framework."), new Moka.ButtonBox().append("Add _New Window", test).append("_Close", function() {
      return wnd.close();
    })), new Moka.Image("img/moka.png", 96, 96).show()));
    wnd["do"](function(e) {
      return e.prependTo("body");
    }).show().focus();
    return v.zoom(map.zoom);
  };
  $(document).ready(onLoad);
}).call(this);
