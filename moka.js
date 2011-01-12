(function() {
  var dbg, doKey, dragScroll, ensure_position, ensure_visible, focus_timestamp, focused_widget, getKeyName, initDraggable, is_on_screen, keyHintFocus, keycodes, last_keyname, last_keyname_timestamp, log, logfn, logobj, tt, userAgent, userAgents;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  window.Moka = {};
  Function.prototype.bind = function(thisObj, var_args) {
    var self, staticArgs;
    self = this;
    staticArgs = Array.prototype.splice.call(arguments, 1, arguments.length);
    return function() {
      var args, i;
      args = staticArgs.concat();
      i = 0;
      while (i < arguments.length) {
        args.push(arguments[i++]);
      }
      return self.apply(thisObj, args);
    };
  };
  ((logobj = window.console) && (logfn = logobj.log)) || ((logobj = window.opera) && (logfn = logobj.postError));
  log = logfn ? logfn.bind(logobj) : function() {
    return;
  };
  dbg = function() {
    return;
  };
  userAgents = {
    unknown: 0,
    webkit: 1,
    opera: 2
  };
  userAgent = function() {
    if (navigator.userAgent.indexOf("WebKit") >= 0) {
      return userAgents.webkit;
    }
    if (navigator.userAgent.indexOf("Opera") >= 0) {
      return userAgents.opera;
    } else {
      return userAgents.unknown;
    }
  };
  keycodes = {};
  keycodes[8] = "BACKSPACE";
  keycodes[9] = "TAB";
  keycodes[13] = "ENTER";
  keycodes[27] = "ESCAPE";
  keycodes[32] = "SPACE";
  keycodes[37] = "LEFT";
  keycodes[38] = "UP";
  keycodes[39] = "RIGHT";
  keycodes[40] = "DOWN";
  keycodes[45] = "INSERT";
  keycodes[46] = "DELETE";
  keycodes[33] = "PAGEUP";
  keycodes[34] = "PAGEDOWN";
  keycodes[35] = "END";
  keycodes[36] = "HOME";
  if (userAgent() === userAgents.webkit) {
    keycodes[96] = "KP0";
    keycodes[97] = "KP1";
    keycodes[98] = "KP2";
    keycodes[99] = "KP3";
    keycodes[100] = "KP4";
    keycodes[101] = "KP5";
    keycodes[102] = "KP6";
    keycodes[103] = "KP7";
    keycodes[104] = "KP8";
    keycodes[105] = "KP9";
    keycodes[106] = "*";
    keycodes[107] = "+";
    keycodes[109] = "MINUS";
    keycodes[110] = ".";
    keycodes[111] = "/";
    keycodes[112] = "F1";
    keycodes[113] = "F2";
    keycodes[114] = "F3";
    keycodes[115] = "F4";
    keycodes[116] = "F5";
    keycodes[117] = "F6";
    keycodes[118] = "F7";
    keycodes[119] = "F8";
    keycodes[120] = "F9";
    keycodes[121] = "F10";
    keycodes[122] = "F11";
    keycodes[123] = "F12";
    keycodes[191] = "?";
  }
  last_keyname = last_keyname_timestamp = null;
  getKeyName = function(ev) {
    var keycode, keyname;
    if (ev.timeStamp === last_keyname_timestamp) {
      return last_keyname;
    }
    keycode = ev.which;
    keyname = keycodes[keycode];
    if (!(keyname != null)) {
      keyname = keycode < 32 ? "" : String.fromCharCode(keycode);
    }
    keyname = (ev.altKey ? "A-" : "") + (ev.ctrlKey || ev.metaKey ? "C-" : "") + (ev.shiftKey ? "S-" : "") + keyname.toUpperCase();
    last_keyname = keyname;
    last_keyname_timestamp = ev.timeStamp;
    return keyname;
  };
  keyHintFocus = function(keyname, root) {
    var e, keyhint, n;
    if (keyname.length === 1) {
      keyhint = keyname;
    } else {
      n = keyname[keyname.length - 1];
      if (n >= "0" && n <= "9") {
        keyhint = n;
      }
    }
    e = null;
    if (keyhint != null) {
      root.find(".keyhint").each(function() {
        var $this, parent;
        $this = $(this);
        if ($this.is(":visible") && keyhint === $this.text().toUpperCase()) {
          parent = $this.parent();
          if (!parent.hasClass("focused")) {
            if (parent.hasClass("tab")) {
              e = parent;
              e.trigger("click");
            } else if (parent.hasClass("input")) {
              e = parent;
              Moka.focus(e);
            } else {
              e = parent.find(".input").eq(0);
              Moka.focus(e);
            }
            if (e.length) {
              return false;
            }
          }
        }
      });
    }
    return e && e.length;
  };
  Moka.createLabel = function(text, e) {
    var c, i, key;
    if (!e) {
      e = $("<div>");
    }
    e.addClass("label");
    i = 0;
    while (i < text.length) {
      c = text[i];
      if (c === '_') {
        break;
      } else if (c === '\\') {
        text = text.slice(0, i) + text.slice(i + 1);
        ++i;
      }
      ++i;
    }
    if (i + 1 < text.length) {
      key = text[i + 1];
      text = text.substr(0, i) + '<span class="keyhint">' + key + '</span>' + text.substr(i + 2);
    }
    e.html(text);
    e.css("cursor", "pointer");
    return e;
  };
  initDraggable = function(e, handle_e) {
    if (!handle_e) {
      handle_e = e;
    }
    return handle_e.css('cursor', "pointer").mousedown(function(ev) {
      var move, pos, self, stop, x, y;
      if (ev.button === 0) {
        stop = false;
        $(document).one("mouseup", function() {
          return stop = true;
        });
        ev.preventDefault();
        self = $(this);
        pos = e.offset();
        x = ev.pageX - pos.left;
        y = ev.pageY - pos.top;
        move = function(ev) {
          if (stop) {
            return $(document).unbind("mousemove.moka");
          } else {
            return e.offset({
              left: ev.pageX - x,
              top: ev.pageY - y
            });
          }
        };
        $(document).bind("mousemove.moka", move);
        return move(ev);
      }
    });
  };
  tt = 0;
  jQuery.extend(jQuery.easing, {
    easeOutCubic: function(x, t, b, c, d) {
      if (t > tt) {
        tt = t + 30;
      }
      return (t = t / 1000 - 1) * t * t + 1;
    }
  });
  dragScroll = function(ev) {
    var continueDragScroll, dt, dx, dy, from_mouseX, from_mouseY, mouseX, mouseY, pos, scrolling, start, stop, stopDragScroll, t, w, wnd;
    wnd = ev.currentTarget;
    w = $(wnd);
    start = t = ev.timeStamp;
    dt = 0;
    dx = 0;
    dy = 0;
    mouseX = ev.pageX;
    mouseY = ev.pageY;
    from_mouseX = w.scrollLeft() + mouseX;
    from_mouseY = w.scrollTop() + mouseY;
    stop = false;
    scrolling = false;
    continueDragScroll = function(ev) {
      var x, y;
      if (stop) {
        return;
      }
      scrolling = true;
      mouseX = ev.pageX;
      mouseY = ev.pageY;
      x = w.scrollLeft();
      y = w.scrollTop();
      w.scrollLeft(from_mouseX - mouseX);
      w.scrollTop(from_mouseY - mouseY);
      start = t;
      t = ev.timeStamp;
      dx = w.scrollLeft() - x;
      dy = w.scrollTop() - y;
      $(window).one("mousemove", continueDragScroll);
      return ev.preventDefault();
    };
    stopDragScroll = function(ev) {
      var accel, vx, vy;
      stop = true;
      if (!scrolling) {
        Moka.focus(ev.target);
        return;
      }
      t = ev.timeStamp;
      dt = t - start;
      if ((0 < dt && dt < 90) && (dx !== 0 || dy !== 0)) {
        accel = 200 / dt;
        vx = dx * accel;
        vy = dy * accel;
        tt = 100;
        w.animate({
          scrollLeft: w.scrollLeft() + vx + "px",
          scrollTop: w.scrollTop() + vy + "px"
        }, 1000, "easeOutCubic");
      }
      return false;
    };
    w.stop(true);
    pos = w.offset();
    if (mouseX + 24 > pos.left + w.width() || mouseY + 24 > pos.top + w.outerHeight()) {
      return;
    }
    $(window).one("mouseup", stopDragScroll).one("mousemove", continueDragScroll);
    return ev.preventDefault();
  };
  focused_widget = $();
  focus_timestamp = 0;
  Moka.focus = function(e) {
    var ee;
    if (!e) {
      return;
    }
    ee = e.length ? e[0] : e;
    return ee.focus();
  };
  Moka.focus_first = function(e) {
    var ee;
    if (e.hasClass("input")) {
      ee = e;
    } else {
      ee = e.find(".input:first");
    }
    if (ee.length) {
      Moka.focus(ee);
      return true;
    } else {
      return false;
    }
  };
  ensure_position = function(ee, e, size) {
    var h, newpos, pos, w;
    ee.show();
    pos = e.offset();
    ee.offset(pos);
    if (size) {
      w = e.outerWidth();
      h = e.outerHeight();
      ee.width(w).height(h);
    }
    return newpos = ee.offset();
  };
  is_on_screen = function(w, how) {
    var e, max, min, pos, wnd, x;
    if (!w) {
      return false;
    }
    e = w.e ? w.e : w;
    pos = e.offset();
    if (!pos) {
      return false;
    }
    pos.right = pos.left + e.width();
    pos.bottom = pos.top + e.height();
    wnd = $(window);
    if (how === "right" || how === "left") {
      min = wnd.scrollLeft();
      max = min + wnd.width();
    } else {
      min = wnd.scrollTop();
      max = min + wnd.height();
    }
    x = pos[how];
    return x >= min && x <= max;
  };
  ensure_visible = function(w, wnd) {
    var bottom, cbottom, cleft, cpos, cright, ctop, e, left, pos, right, top;
    e = w.e ? w.e : w;
    if (!wnd) {
      wnd = w.parent();
    }
    if (!wnd.length) {
      return;
    }
    if (wnd[0].scrollHeight > wnd[0].offsetHeight + 4) {
      pos = wnd.offset();
      cpos = e.offset();
      cleft = cpos.left - pos.left;
      ctop = cpos.top - pos.top;
      cright = cleft + e.width();
      cbottom = ctop + e.height();
      left = wnd.scrollLeft();
      cleft += left;
      cright += left;
      right = left + wnd.width();
      if (cleft > left && cright > right) {
        wnd.scrollLeft(e.width() >= (w = wnd.width()) ? cleft : cright - w);
      } else if (cright < right && cleft < left) {
        wnd.scrollLeft(e.width() >= (w = wnd.width()) ? cright - w : cleft);
      }
      top = wnd.scrollTop();
      ctop += top;
      cbottom += top;
      bottom = top + wnd.height();
      if (ctop > top && cbottom > bottom) {
        wnd.scrollTop(e.height() >= (w = wnd.height()) ? ctop : cbottom - w);
      } else if (cbottom < bottom && ctop < top) {
        wnd.scrollTop(e.height() >= (w = wnd.height()) ? cbottom - w : ctop);
      }
    }
    return ensure_visible(w, wnd.parent());
  };
  doKey = function(keyname, keys, default_keys, object) {
    var fn;
    if ((keys && (fn = keys[keyname])) || (default_keys && (fn = default_keys[keyname]))) {
      if (fn.apply(object) === false) {
        return false;
      } else {
        return true;
      }
    }
    return false;
  };
  Moka.lostFocus = function(ev) {
    focused_widget.removeClass("focused").trigger("mokaBlurred");
    return focused_widget = $();
  };
  Moka.gainFocus = function(ev) {
    if (focus_timestamp === ev.timeStamp) {
      return;
    }
    focus_timestamp = ev.timeStamp;
    focused_widget = $(ev.target);
    focused_widget.addClass("focused").trigger("mokaFocused");
    return ensure_visible(focused_widget);
  };
  Moka.init = function() {
    var ensure_fns, ensure_position_tmp;
    ensure_fns = [];
    ensure_position_tmp = ensure_position;
    ensure_position = function(ee, e, size) {
      ee.hide();
      return ensure_fns.push(ensure_position_tmp.bind(this, ee, e, size));
    };
    return $(window).load(function() {
      var fn, _i, _len, _results;
      ensure_position = ensure_position_tmp;
      _results = [];
      for (_i = 0, _len = ensure_fns.length; _i < _len; _i++) {
        fn = ensure_fns[_i];
        _results.push(fn());
      }
      return _results;
    });
  };
  Moka.Widget = (function() {
    function Widget() {
      this.e = $("<div>", {
        'class': "widget"
      }).bind("mokaFocused", function() {
        return $(this).addClass("focused");
      }).bind("mokaBlurred", function() {
        return $(this).removeClass("focused");
      });
    }
    Widget.prototype.show = function() {
      this.e.show();
      this.update();
      return this;
    };
    Widget.prototype.hide = function() {
      this.e.hide();
      return this;
    };
    Widget.prototype.update = function() {
      return this;
    };
    Widget.prototype.isLoaded = function() {
      return true;
    };
    return Widget;
  })();
  Moka.Input = (function() {
    __extends(Input, Moka.Widget);
    function Input() {
      Input.__super__.constructor.apply(this, arguments);
      this.e.addClass("input").attr("tabindex", 0).css("cursor", "pointer").bind("focus.moka", Moka.gainFocus).bind("blur.moka", Moka.lostFocus).click(function() {
        return Moka.focus(this);
      }).focus(__bind(function(ev) {
        return typeof this.focus === "function" ? this.focus(ev) : void 0;
      }, this)).blur(__bind(function(ev) {
        return typeof this.blur === "function" ? this.blur(ev) : void 0;
      }, this)).click(__bind(function(ev) {
        return typeof this.click === "function" ? this.click(ev) : void 0;
      }, this)).dblclick(__bind(function(ev) {
        return typeof this.dblclick === "function" ? this.dblclick(ev) : void 0;
      }, this)).mouseup(__bind(function(ev) {
        return typeof this.mouseup === "function" ? this.mouseup(ev) : void 0;
      }, this)).mousedown(__bind(function(ev) {
        return typeof this.mousedown === "function" ? this.mousedown(ev) : void 0;
      }, this)).keydown(__bind(function(ev) {
        return typeof this.keydown === "function" ? this.keydown(ev) : void 0;
      }, this)).keyup(__bind(function(ev) {
        return typeof this.keyup === "function" ? this.keyup(ev) : void 0;
      }, this));
    }
    return Input;
  })();
  Moka.Selection = (function() {
    __extends(Selection, Moka.Widget);
    function Selection(parent) {
      this.parent = parent;
      Selection.__super__.constructor.apply(this, arguments);
      this.e.css({
        position: "absolute",
        'z-index': -2
      }).addClass("selection").appendTo(this.parent);
      this.current = null;
    }
    Selection.prototype.update = function() {
      var _ref;
      (_ref = this.current) != null ? _ref : this.select(this.current);
      return this;
    };
    Selection.prototype.select = function(e) {
      var pos;
      if (this.current) {
        this.current.removeClass("current");
      }
      if (e != null) {
        pos = e.offset();
        this.e.show().width(e.outerWidth()).height(e.outerHeight()).offset({
          top: pos.top,
          left: pos.left
        });
        this.current = e.addClass("current");
        return ensure_position(this.e, e, true);
      } else {
        return this.e.hide();
      }
    };
    return Selection;
  })();
  Moka.Container = (function() {
    __extends(Container, Moka.Input);
    function Container() {
      Container.__super__.constructor.apply(this, arguments);
      this.e.addClass("container");
      this.widgets = [];
      this.current = -1;
      this.selection = new Moka.Selection(this.e);
    }
    Container.prototype.update = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        return w[i].update();
      });
      this.updateSelection();
      return this;
    };
    Container.prototype.updateSelection = function() {
      return this.selection.select(this.current >= 0 ? this.widgets[this.current].e : null);
    };
    Container.prototype.focus = function() {
      this.select(this.current >= 0 ? this.current : 0);
      return this;
    };
    Container.prototype.length = function() {
      return this.widgets.length;
    };
    Container.prototype.at = function(index) {
      return this.widgets[index];
    };
    Container.prototype.itemClass = function(cls) {
      if (cls) {
        this.itemcls = cls;
        return this;
      } else {
        return this.itemcls;
      }
    };
    Container.prototype.append = function(widget) {
      var e, id;
      id = this.length();
      this.widgets.push(widget);
      e = widget.e;
      if (id === 0) {
        e.addClass("first");
      } else {
        this.widgets[id - 1].e.removeClass("last");
      }
      e.addClass(this.itemcls + " last");
      e.bind("mokaFocused", __bind(function() {
        if (this.current >= 0) {
          e.trigger("mokaDeselected", [this.current]);
        }
        this.current = id;
        e.trigger("mokaSelected", [id]);
        return this.updateSelection();
      }, this));
      e.appendTo(this.e).bind("mokaSizeChanged", this.update.bind(this));
      return this;
    };
    Container.prototype.next = function() {
      return this.select(this.current >= 0 && this.current < this.length() - 1 ? this.current + 1 : 0);
    };
    Container.prototype.prev = function() {
      var l;
      l = this.length();
      return this.select(this.current >= 1 && this.current < l ? this.current - 1 : l - 1);
    };
    Container.prototype.select = function(id) {
      var w;
      if (id >= 0) {
        this.current = id;
        w = this.widgets[id];
        Moka.focus_first(w.e);
      } else {
        this.current = -1;
      }
      return this.updateSelection();
    };
    return Container;
  })();
  Moka.CheckBox = (function() {
    __extends(CheckBox, Moka.Input);
    CheckBox.prototype.default_keys = {
      SPACE: function() {
        return this.toggle();
      },
      ENTER: function() {
        return this.toggle();
      }
    };
    function CheckBox(text, checked) {
      CheckBox.__super__.constructor.apply(this, arguments);
      this.e.addClass("checkbox");
      Moka.createLabel(text, this.e);
      this.checkbox = $('<input>', {
        type: "checkbox",
        "class": "value"
      }).prependTo(this.e);
      this.value(checked);
    }
    CheckBox.prototype.click = function(ev) {
      if (ev.target.type === "checkbox") {
        return;
      }
      this.toggle();
      return false;
    };
    CheckBox.prototype.toggle = function() {
      this.value(!this.value());
      return this;
    };
    CheckBox.prototype.value = function(val) {
      if (val != null) {
        this.checkbox.attr("checked", val);
        return this;
      } else {
        return this.checkbox.is(":checked");
      }
    };
    CheckBox.prototype.keydown = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return CheckBox;
  })();
  Moka.TextEdit = (function() {
    __extends(TextEdit, Moka.Input);
    TextEdit.prototype.default_keys = {
      ENTER: function() {}
    };
    function TextEdit(label_text, text) {
      TextEdit.__super__.constructor.apply(this, arguments);
      this.e.addClass("textedit");
      Moka.createLabel(label_text, this.e);
      this.create = true;
    }
    TextEdit.prototype.update = function() {
      var editor, win;
      if (this.create && this.e.is(":visible")) {
        this.create = false;
        editor = new CodeMirror(this.e[0], {
          height: "dynamic",
          parserfile: "parsedummy.js",
          path: "deps/codemirror/js/",
          onCursorActivity: __bind(function() {
            if (this.t_sizeupdate) {
              window.clearTimeout(this.t_sizeupdate);
            }
            return this.t_sizeupdate = window.setTimeout(this.e.trigger.bind(this.e, "mokaSizeChanged"), 300);
          }, this)
        });
        $(editor.win.document).keyup(this.editorKeyUp.bind(this)).keydown(__bind(function() {
          return this.oldpos = this.editor.cursorPosition();
        }, this));
        win = $(editor.win);
        win.focus(__bind(function(ev) {
          ev.target = editor.wrapping;
          return Moka.gainFocus(ev);
        }, this));
        win.blur(__bind(function(ev) {
          ev.target = editor.wrapping;
          return Moka.lostFocus(ev);
        }, this));
        this.e.focus(__bind(function() {
          this.oldpos = {
            line: null,
            character: null
          };
          return editor.win.focus();
        }, this));
        this.editor = editor;
        return this.oldpos = editor.cursorPosition();
      }
    };
    TextEdit.prototype.editorKeyUp = function(ev) {
      var ev2, keyname, pos;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      pos = this.editor.cursorPosition();
      if (this.oldpos.line === pos.line && this.oldpos.character === pos.character) {
        ev2 = jQuery.Event("keydown");
        ev2.which = ev.which;
        return this.e.trigger(ev2);
      } else {
        this.oldpos = pos;
        return ev.stopPropagation();
      }
    };
    return TextEdit;
  })();
  Moka.Button = (function() {
    __extends(Button, Moka.Input);
    function Button(label_text, onclick) {
      Button.__super__.constructor.apply(this, arguments);
      Moka.createLabel(label_text, this.e);
      this.e.addClass("button");
      this.click = onclick;
    }
    Button.prototype.keydown = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (keyname === "ENTER" || keyname === "SPACE") {
        this.e.click();
        return false;
      }
    };
    return Button;
  })();
  Moka.WidgetList = (function() {
    __extends(WidgetList, Moka.Container);
    function WidgetList() {
      WidgetList.__super__.constructor.apply(this, arguments);
      this.e.addClass("widgetlist");
      this.itemClass("widgetlistitem");
    }
    WidgetList.prototype.keydown = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (this.e.hasClass("horizontal")) {
        if (keyname === "LEFT") {
          this.prev();
        } else if (keyname === "RIGHT") {
          this.next();
        } else if (!keyHintFocus(keyname, this.e)) {
          return;
        }
      } else {
        if (keyname === "UP") {
          this.prev();
        } else if (keyname === "DOWN") {
          this.next();
        } else if (!keyHintFocus(keyname, this.e)) {
          return;
        }
      }
      return false;
    };
    return WidgetList;
  })();
  Moka.ButtonBox = (function() {
    __extends(ButtonBox, Moka.WidgetList);
    function ButtonBox() {
      ButtonBox.__super__.constructor.apply(this, arguments);
      this.e.removeClass("widgetlist").addClass("buttonbox horizontal");
    }
    ButtonBox.prototype.append = function(label_text, onclick) {
      var widget;
      widget = new Moka.Button(label_text, onclick);
      ButtonBox.__super__.append.call(this, widget);
      widget.e.removeClass("widgetlistitem");
      return this;
    };
    return ButtonBox;
  })();
  Moka.Tabs = (function() {
    __extends(Tabs, Moka.Input);
    Tabs.prototype.default_keys = {
      ENTER: function() {
        return Moka.focus_first(this.pages[this.current].e);
      },
      SPACE: function() {
        return this.pages_e.toggle();
      },
      TAB: function() {
        var page;
        if ((page = this.pages[this.current])) {
          return Moka.focus_first(page.e);
        }
      },
      LEFT: function() {
        if (this.vertical()) {
          return this.focusUp();
        } else {
          return this.prev();
        }
      },
      RIGHT: function() {
        if (this.vertical()) {
          return this.focusDown();
        } else {
          return this.next();
        }
      },
      UP: function() {
        if (this.vertical()) {
          return this.prev();
        } else {
          return this.focusUp();
        }
      },
      DOWN: function() {
        if (this.vertical()) {
          return this.next();
        } else {
          return this.focusDown();
        }
      },
      PAGEUP: function() {
        if (this.vertical()) {
          return this.tabs.select(0);
        }
      },
      PAGEDOWN: function() {
        if (this.vertical()) {
          return this.tabs.select(this.tabs.length() - 1);
        }
      },
      HOME: function() {
        if (!this.vertical()) {
          return this.tabs.select(0);
        }
      },
      END: function() {
        if (!this.vertical()) {
          return this.tabs.select(this.tabs.length() - 1);
        }
      }
    };
    function Tabs() {
      Tabs.__super__.constructor.apply(this, arguments);
      this.e.addClass("tabs_widget");
      this.tabs = new Moka.Container().itemClass("tab");
      this.tabs_e = this.tabs.e.addClass("tabs").appendTo(this.e).bind("mokaSelected", __bind(function(ev, id) {
        if (this.current >= 0) {
          this.pages[this.current].hide();
        }
        this.current = id;
        return this.pages[id].show();
      }, this));
      this.pages_e = $("<div>", {
        "class": "pages"
      }).appendTo(this.e);
      this.pages = [];
      this.current = 0;
      this.vertical(false);
    }
    Tabs.prototype.update = function() {
      this.tabs.update();
      if (this.current >= 0) {
        this.pages[this.current].show();
      }
      return this;
    };
    Tabs.prototype.focus = function() {
      Moka.focus(this.tabs.e);
      return this;
    };
    Tabs.prototype.focusUp = function() {
      Moka.focus(this.e.parents(".input").eq(0));
      return this;
    };
    Tabs.prototype.focusDown = function() {
      Moka.focus_first(this.pages[this.current].e);
      return this;
    };
    Tabs.prototype.next = function() {
      this.tabs.next();
      return this;
    };
    Tabs.prototype.prev = function() {
      this.tabs.prev();
      return this;
    };
    Tabs.prototype.append = function(tabname, widget) {
      var page, tab;
      this.pages.push(widget);
      page = widget.e ? widget.e : widget;
      tab = new Moka.Input();
      Moka.createLabel(tabname, tab.e);
      this.tabs.append(tab);
      widget.hide();
      page.addClass("widget page");
      page.appendTo(this.pages_e);
      if (this.current === this.tabs.length() - 1) {
        this.select(this.current);
      }
      return this;
    };
    Tabs.prototype.select = function(id) {
      this.tabs.select(id);
      return this;
    };
    Tabs.prototype.vertical = function(toggle) {
      if (toggle != null) {
        this.tabs_e.addClass(toggle === false ? "horizontal" : "vertical");
        this.tabs_e.removeClass(toggle === false ? "vertical" : "horizontal");
        return this;
      } else {
        return this.tabs_e.hasClass("vertical");
      }
    };
    Tabs.prototype.keydown = function(ev) {
      var keyname, page;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (page = this.pages[this.current]) {
        if (page.keydown) {
          if (page.keydown(ev) === false) {
            return false;
          } else if (ev.isPropagationStopped()) {
            return;
          }
        }
      }
      if (keyHintFocus(keyname, this.e)) {
        return false;
      }
    };
    return Tabs;
  })();
  Moka.ImageView = (function() {
    __extends(ImageView, Moka.Input);
    ImageView.prototype.default_keys = {};
    function ImageView(src) {
      ImageView.__super__.constructor.apply(this, arguments);
      this.e.addClass("imageview").keydown(this.keyPress.bind(this));
      this.view = $("<img>", {
        "class": "input",
        src: ""
      }).appendTo(this.e);
      this.src = src;
    }
    ImageView.prototype.show = function() {
      if (this.ok != null) {
        this.e.show();
        this.zoom(this.z, this.zhow);
        this.e.trigger("mokaLoaded");
        this.e.trigger("mokaDone", [!this.ok]);
      } else {
        this.view.one("load", __bind(function() {
          var e;
          this.ok = true;
          e = this.view[0];
          this.width = e.width ? e.width : e.naturalWidth;
          this.height = e.height ? e.height : e.naturalHeight;
          this.zoom(this.z, this.zhow);
          this.e.trigger("mokaLoaded");
          return this.e.trigger("mokaDone", [!this.ok]);
        }, this));
        this.view.one("error", __bind(function() {
          this.ok = false;
          this.width = this.height = 0;
          this.e.trigger("mokaError");
          return this.e.trigger("mokaDone", [!this.ok]);
        }, this));
        this.e.show();
        this.view.attr("src", this.src);
      }
      return this;
    };
    ImageView.prototype.hide = function() {
      this.e.hide();
      this.ok = null;
      this.view.attr("src", "");
      return this;
    };
    ImageView.prototype.isLoaded = function() {
      return this.ok != null;
    };
    ImageView.prototype.zoom = function(how, how2) {
      var h, height, mh, mw, w, width;
      if (how != null) {
        this.z = how;
        this.zhow = how2;
        if (this.ok != null) {
          width = this.view.outerWidth();
          height = this.view.outerHeight();
          w = h = mw = mh = "";
          if (how instanceof Array) {
            mw = how[0] - width + this.view.width();
            mh = how[1] - height + this.view.height();
          } else {
            this.z = parseFloat(how) || 1;
            mw = Math.floor(this.z * this.width);
            mh = Math.floor(this.z * this.height);
          }
          if (how2 !== "fit") {
            if (width / height < mw / mh) {
              h = mh;
            } else {
              w = mw;
            }
          }
          this.view.css({
            'max-width': mw,
            'max-height': mh,
            width: w,
            height: h
          });
        }
        return this;
      } else {
        return this.z;
      }
    };
    ImageView.prototype.keyPress = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      } else if ((keyname === "LEFT" || keyname === "RIGHT") && this.view.width() > this.e.width()) {
        return ev.stopPropagation();
      } else if ((keyname === "UP" || keyname === "DOWN") && this.view.height() > this.e.height()) {
        return ev.stopPropagation();
      }
    };
    return ImageView;
  })();
  Moka.Viewer = (function() {
    __extends(Viewer, Moka.Input);
    Viewer.prototype.default_keys = {
      RIGHT: function() {
        return is_on_screen(focused_widget, "right") && this.focusRight();
      },
      LEFT: function() {
        return is_on_screen(focused_widget, "left") && this.focusLeft();
      },
      UP: function() {
        return is_on_screen(focused_widget, "top") && this.focusUp();
      },
      DOWN: function() {
        return is_on_screen(focused_widget, "bottom") && this.focusDown();
      },
      'KP6': function() {
        return this.next();
      },
      'KP4': function() {
        return this.prev();
      },
      'KP2': function() {
        return this.nextRow();
      },
      'KP8': function() {
        return this.prevRow();
      },
      SPACE: function() {
        return this.nextPage();
      },
      'S-SPACE': function() {
        return this.prevPage();
      },
      ENTER: function() {
        var lay, z;
        if (this.oldlay) {
          lay = this.oldlay;
          z = this.oldzoom;
        } else {
          lay = [1, 1];
          z = 1;
        }
        this.oldlay = this.layout();
        this.oldzoom = this.zoom();
        this.zoom(z);
        return this.layout(lay);
      },
      '*': function() {
        this.layout([1, 1]);
        return this.zoom(1);
      },
      '/': function() {
        if (this.zoom() === "fit") {
          return this.zoom(1);
        } else {
          return this.zoom("fit");
        }
      },
      '+': function() {
        return this.zoom("+");
      },
      MINUS: function() {
        return this.zoom("-");
      },
      HOME: function() {
        return this.select(0);
      },
      END: function() {
        return this.select(this.length() - 1);
      },
      PAGEUP: function() {
        var c;
        c = this.cellCount();
        if (this.currentcell % c === 0) {
          return this.select(this.index - c);
        } else {
          return this.select(this.index);
        }
      },
      PAGEDOWN: function() {
        var c;
        c = this.cellCount();
        if ((this.currentcell + 1) % c === 0) {
          return this.select(this.index + c);
        } else {
          return this.select(this.index + c - 1);
        }
      },
      H: function() {
        return this.layout([this.lay[0] + 1, this.lay[1]]);
      },
      V: function() {
        return this.layout([this.lay[0], this.lay[1] + 1]);
      },
      'S-H': function() {
        return this.layout([this.lay[0] - 1, this.lay[1]]);
      },
      'S-V': function() {
        return this.layout([this.lay[0], this.lay[1] - 1]);
      }
    };
    function Viewer() {
      Viewer.__super__.constructor.apply(this, arguments);
      this.e.addClass("viewer").resize(this.update.bind(this)).bind("scroll.moka", this.onScroll.bind(this)).css("cursor", "move");
      $(window).bind("resize.moka", this.update.bind(this));
      this.table = $("<table>", {
        "class": "table",
        border: 0,
        cellSpacing: 0,
        cellPadding: 0
      }).appendTo(this.e).bind("mokaFocused", __bind(function(ev) {
        var e;
        e = $(ev.target);
        if (!e.hasClass("view")) {
          return;
        }
        this.currentcell = e.data("index");
        this.current = e.children().eq(0).data("index");
        e.addClass("current");
        return e.trigger("mokaSelected", [this.current]);
      }, this)).bind("mokaBlurred", __bind(function(ev) {
        var e;
        e = $(ev.target);
        if (!e.hasClass("view")) {
          return;
        }
        e.removeClass("current");
        return e.trigger("mokaDeselected", [this.current]);
      }, this));
      this.cells = [];
      this.items = [];
      this.index = 0;
      this.current = -1;
      this.currentcell = -1;
      this.preload_count = 2;
      this.orientation("lt");
      this.layout([1, 1]);
      this.zoom(1);
    }
    Viewer.prototype.show = function() {
      this.e.show();
      return this.update();
    };
    Viewer.prototype.update = function() {
      var w;
      if (!this.e.is(":visible")) {
        return;
      }
      this.view(this.index);
      w = this.items;
      $.each(w, function(i) {
        var _base;
        if (w[i].update) {
          return typeof (_base = w[i]).update === "function" ? _base.update() : void 0;
        }
      });
      return this;
    };
    Viewer.prototype.focus = function(ev) {
      if (this.currentcell < 0) {
        this.currentcell = 0;
      }
      Moka.focus(this.cells[this.index + this.currentcell]);
      return this;
    };
    Viewer.prototype.append = function(widget) {
      var id;
      id = this.items.length;
      this.items.push(widget);
      if (this.lay[0] <= 0 || this.lay[1] <= 0) {
        this.updateTable();
      }
      this.update();
      return this;
    };
    Viewer.prototype.at = function(index) {
      return this.items[index];
    };
    Viewer.prototype.currentItem = function() {
      if (this.current >= 0) {
        return this.at(this.index + this.current);
      } else {
        return null;
      }
    };
    Viewer.prototype.length = function() {
      return this.items.length;
    };
    Viewer.prototype.view = function(id) {
      var cell, i, item, len;
      if (id >= this.length()) {
        return this;
      }
      if (id < 0) {
        id = 0;
      }
      i = 0;
      len = this.cellCount();
      this.index = Math.floor(id / len) * len;
      dbg("displaying views", this.index + ".." + (this.index + len - 1));
      while (i < len) {
        cell = this.cell(i);
        item = this.at(this.index + i);
        cell.children().detach();
        if (item) {
          cell.attr("tabindex", 1).css({
            width: this.e.width(),
            height: this.e.height()
          });
          item.e.hide().data("index", i).appendTo(cell);
        } else {
          cell.attr("tabindex", "");
        }
        ++i;
      }
      this.zoom(this.zhow);
      this.updateVisible(true);
      return this;
    };
    Viewer.prototype.preload = function(indexes) {
      var preloader;
      preloader = function(indexes) {
        var i, item, next;
        if (indexes.length === 0) {
          return;
        }
        i = indexes[0];
        next = preloader.bind(this, indexes.slice(1));
        if ((0 < i && i < this.length())) {
          item = this.items[i];
          if (item.isLoaded()) {
            item.show();
            next();
          } else {
            item.e.one("mokaDone", next);
          }
          return item.show();
        } else {
          return next();
        }
      };
      (preloader.bind(this, indexes))();
      return this;
    };
    Viewer.prototype.select = function(id) {
      var cell, count;
      if (!this.e.is(":visible")) {
        return this;
      }
      if (id < 0 || id >= this.length()) {
        return this;
      }
      dbg("selecting view", id);
      count = this.cellCount();
      this.current = id % count;
      if (id < this.index || id >= this.index + count) {
        this.view(id);
      }
      cell = this.cell(id % count);
      if (cell) {
        ensure_visible(cell.children());
        Moka.focus(cell);
      }
      return this;
    };
    Viewer.prototype.zoom = function(how) {
      var d, factor, h, i, item, layout, len, offset, pos, s, w, wnd, _i, _len, _ref;
      if (how != null) {
        this.zhow = how;
        if (how === "fit") {
          layout = this.layout();
          if (this.lay[0] <= 0) {
            layout[0] = 1;
          } else if (this.lay[1] <= 0) {
            layout[1] = 1;
          }
          wnd = this.e.parent();
          offset = wnd.offset();
          pos = this.e.offset();
          pos.top -= offset.top;
          pos.left -= offset.left;
          w = (wnd.width() - pos.left) / layout[0];
          h = (wnd.height() - pos.top) / layout[1];
          _ref = [this.table.cellSpacing, this.table.cellPadding, this.table.border];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            s = _ref[_i];
            if (s) {
              w += layout[0] * s;
              h += layout[0] * s;
            }
          }
          this.z = [w, h];
        } else if (how === "+" || how === "-") {
          d = 1.125;
          if (how === "-") {
            d = 1 / d;
          }
          if (!this.z) {
            this.z = 1;
          }
          if (this.z instanceof Array) {
            this.z[0] *= d;
            this.z[1] *= d;
          } else {
            this.z *= d;
          }
        } else if (!(how instanceof Array)) {
          factor = parseFloat(how) || 1;
          this.z = factor;
        }
        i = this.index;
        len = i + this.cellCount();
        len = Math.min(len, this.length());
        dbg("zooming views", i + ".." + (len - 1), "using method", this.z, this.zhow);
        while (i < len) {
          item = this.at(i);
          if (item.zoom) {
            item.zoom(this.z, this.zhow);
          }
          ++i;
        }
        if (this.current >= 0) {
          ensure_visible(this.at(this.index + this.current).e);
        }
        this.updateVisible();
        return this;
      } else {
        return this.z;
      }
    };
    Viewer.prototype.cellCount = function() {
      return this.cells.length;
    };
    Viewer.prototype.next = function() {
      this.select(this.index + this.current + 1);
      return this;
    };
    Viewer.prototype.prev = function() {
      this.select(this.index + this.current - 1);
      return this;
    };
    Viewer.prototype.nextRow = function() {
      this.select(this.index + this.current + this.layout()[0]);
      return this;
    };
    Viewer.prototype.prevRow = function() {
      this.select(this.index + this.current - this.layout()[0]);
      return this;
    };
    Viewer.prototype.nextPage = function() {
      this.select(this.index + this.cellCount());
      return this;
    };
    Viewer.prototype.prevPage = function() {
      this.select(this.index - this.cellCount());
      return this;
    };
    Viewer.prototype.focusLeft = function() {
      var cell, h, how, id;
      id = this.currentcell - 1;
      h = this.layout()[0];
      if ((id + 1) % h === 0) {
        cell = this.cells[id + h];
        if (cell) {
          id = cell.children().eq(0).data("index");
          how = -this.cellCount();
          if (__indexOf.call(this.o, "r") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.children().eq(0).data("index");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusRight = function() {
      var cell, h, how, id;
      id = this.currentcell + 1;
      h = this.layout()[0];
      if (id % h === 0) {
        cell = this.cells[id - h];
        if (cell) {
          id = cell.children().eq(0).data("index");
          how = this.cellCount();
          if (__indexOf.call(this.o, "r") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.children().eq(0).data("index");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusUp = function() {
      var cell, h, how, id, layout, len;
      id = this.currentcell;
      layout = this.layout();
      h = layout[0];
      id -= h;
      if (id < 0) {
        len = this.cellCount();
        cell = this.cells[id + len];
        if (cell) {
          id = cell.children().eq(0).data("index");
          how = -this.cellCount();
          if (__indexOf.call(this.o, "b") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.children().eq(0).data("index");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusDown = function() {
      var cell, h, how, id, layout, len, _ref, _ref2;
      id = this.currentcell;
      layout = this.layout();
      h = layout[0];
      id += h;
      len = this.cellCount();
      if (id >= len) {
        cell = this.cells[id - len];
        if (cell) {
          id = (_ref = cell.children().eq(0)) != null ? _ref.data("index") : void 0;
          how = this.cellCount();
          if (__indexOf.call(this.o, "b") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = (_ref2 = cell.children().eq(0)) != null ? _ref2.data("index") : void 0;
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.appendRow = function() {
      return $("<tr>", {
        "class": "row"
      }).hide().appendTo(this.table);
    };
    Viewer.prototype.appendCell = function(row) {
      var cell, td;
      td = $("<td>").appendTo(row);
      cell = new Moka.Input().e;
      cell.addClass("view").data("index", this.cellCount()).focus(__bind(function(ev) {
        return Moka.focus_first(cell.children());
      }, this)).appendTo(td);
      this.cells.push(cell);
      return cell;
    };
    Viewer.prototype.cell = function(index) {
      return this.cells[this.indexfn(index)];
    };
    Viewer.prototype.updateTable = function() {
      var cell, i, ilen, j, jlen, layout, row, _i, _len, _ref;
      _ref = this.cells;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        cell.children().detach();
      }
      this.table.empty();
      this.cells = [];
      layout = this.layout();
      ilen = layout[0];
      jlen = layout[1];
      j = 0;
      while (j < jlen) {
        row = this.appendRow();
        i = 0;
        while (++i <= ilen) {
          this.appendCell(row);
        }
        row.show();
        ++j;
      }
      return this.orientation(this.o);
    };
    Viewer.prototype.layout = function(layout) {
      var i, id, j, x, y;
      if (layout) {
        x = Math.max(0, Number(layout[0]));
        y = Math.max(0, Number(layout[1]));
        if (this.lay && x === this.lay[0] && y === this.lay[1]) {
          return this;
        }
        if (this.lay) {
          this.e.removeClass("layout_" + this.lay.join("x"));
        }
        this.lay = [x, y];
        this.e.addClass("layout_" + this.lay.join("x"));
        dbg("setting layout", this.lay);
        id = this.index + this.currentcell;
        this.updateTable();
        this.update();
        this.select(id);
        return this;
      } else {
        i = this.lay[0];
        j = this.lay[1];
        if (i <= 0) {
          i = this.length();
        } else if (j <= 0) {
          j = this.length();
        }
        return [i, j];
      }
    };
    Viewer.prototype.orientation = function(o) {
      var a, b, fns, len, x, y;
      if (o) {
        this.o = "";
        x = o.toLowerCase().split(" ");
        if (x.length < 2) {
          x = o.toLowerCase().split(/%20|-|_/);
        }
        if (x.length < 2) {
          a = x[0][0];
          b = x[0][1];
        } else {
          a = x[0][0];
          b = x[1][0];
        }
        log(x, a, b);
        if (__indexOf.call("lr", a) >= 0) {
          this.o += a;
          if (__indexOf.call("tb", b) >= 0) {
            this.o += b;
          }
        } else if (__indexOf.call("tb", a) >= 0) {
          this.o += a;
          if (__indexOf.call("lr", b) >= 0) {
            this.o += b;
          }
        }
        if (this.o.length !== 2) {
          dbg("cannot parse orientation ('" + o + "'); resetting to 'left top'");
          this.o = "lt";
        }
        log(this.o);
        len = this.cells.length;
        if (!len) {
          return this;
        }
        dbg("setting orientation", o);
        x = this.lay[0];
        y = this.lay[1];
        fns = {
          lt: function(id) {
            return id;
          },
          rt: function(id) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return x - 1 - i + j * x;
          },
          lb: function(id) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return len - x + i - j * x;
          },
          rb: function(id) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return len - 1 - i - j * x;
          },
          tl: function(id) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return i * x + j;
          },
          tr: function(id) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return len - 1 - (y - 1 - i) * x - j;
          },
          bl: function(id) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return (y - 1 - i) * x + j;
          },
          br: function(id) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return len - 1 - i * x - j;
          }
        };
        this.indexfn = fns[this.o];
        return this;
      } else {
        return this.o;
      }
    };
    Viewer.prototype.hideItem = function(index) {
      var cell, h, item, w;
      item = this.at(index);
      cell = this.cell(index % this.cellCount());
      if (item.e.is(":visible")) {
        dbg("hiding item", index);
        h = cell.outerHeight();
        w = cell.outerWidth();
        item.hide();
        return cell.css({
          width: w,
          height: h
        });
      }
    };
    Viewer.prototype.updateSizes = function() {
      var cell, i, item, len, _results;
      i = 0;
      len = this.cellCount();
      _results = [];
      while (i < len) {
        item = this.at(this.index + i);
        if (!item || item.isLoaded()) {
          ++i;
          continue;
        }
        cell = this.cell(i);
        if (cell.width() <= 1) {
          cell.width(this.e.width());
        }
        if (cell.height() <= 1) {
          cell.height(this.e.height());
        }
        _results.push(++i);
      }
      return _results;
    };
    Viewer.prototype.updateVisible = function(now) {
      var cell, current_item, pos, updateItems, wndbottom, wndleft, wndright, wndtop, _i, _len, _ref;
      if (!now) {
        if (this.t_update) {
          window.clearTimeout(this.t_update);
        }
        this.t_update = window.setTimeout(this.updateVisible.bind(this, true), 100);
        return;
      }
      pos = this.e.offset();
      wndleft = pos.left;
      wndtop = pos.top;
      wndright = wndleft + this.e.width();
      wndbottom = wndtop + this.e.height();
      if (this.current >= 0) {
        current_item = this.at(this.index + this.current).e;
      }
      updateItems = __bind(function(index, direction) {
        var cell, h, item, loaded, next, p, w;
        next = updateItems.bind(this, index + direction, direction);
        cell = this.cell(index - this.index);
        item = this.at(index);
        if (!item || !cell) {
          this.updateSizes();
          return;
        }
        if (item.e.is(":visible")) {
          return next();
        }
        p = cell.parent();
        w = p.width();
        h = p.height();
        pos = cell.parent().offset();
        if (pos.left + w < wndleft || pos.left > wndright || pos.top + h < wndtop || pos.top > wndbottom) {
          return next();
        }
        loaded = __bind(function() {
          var hh, left, top, ww;
          dbg("view", index, "loaded");
          cell.css({
            width: "",
            height: ""
          });
          left = this.e.scrollLeft();
          top = this.e.scrollTop();
          if (left || top) {
            ww = p.width();
            hh = p.height();
            if (current_item) {
              ensure_visible(current_item);
            } else {
              if (pos.left < wndleft + this.e.width() / 2 && ww > w) {
                this.e.scrollLeft(left + (ww - w) / 2);
              }
              if (pos.top < wndtop + this.e.height() / 2 && hh > h) {
                this.e.scrollTop(top + (hh - h) / 2);
              }
            }
          }
          return this.updateVisible(true);
        }, this);
        dbg("loading view", index);
        if (item.isLoaded()) {
          item.show();
          return next();
        } else {
          item.e.one("mokaDone", loaded);
          return item.show();
        }
      }, this);
      _ref = this.cells;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        cell.css({
          width: "",
          height: ""
        });
      }
      if (this.current >= 0) {
        updateItems(this.index + this.current, 1);
        return updateItems(this.index + this.current, -1);
      } else {
        return updateItems(this.index, 1);
      }
    };
    Viewer.prototype.onScroll = function(ev) {
      return this.updateVisible();
    };
    Viewer.prototype.mousedown = function(ev) {
      if (ev.button === 0) {
        return dragScroll(ev);
      }
    };
    Viewer.prototype.keydown = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (keyHintFocus(keyname, this.e)) {
        return false;
      } else if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return Viewer;
  })();
  Moka.Window = (function() {
    __extends(Window, Moka.Input);
    Window.prototype.default_keys = {
      F4: function() {
        return this.close();
      }
    };
    Window.prototype.default_title_keys = {
      LEFT: function() {
        var pos;
        pos = this.e.offset();
        pos.left -= 20;
        return this.e.offset(pos);
      },
      RIGHT: function() {
        var pos;
        pos = this.e.offset();
        pos.left += 20;
        return this.e.offset(pos);
      },
      UP: function() {
        var pos;
        pos = this.e.offset();
        pos.top -= 20;
        return this.e.offset(pos);
      },
      DOWN: function() {
        var pos;
        pos = this.e.offset();
        pos.top += 20;
        return this.e.offset(pos);
      },
      'S-LEFT': function() {
        var pos;
        pos = this.e.offset();
        pos.left = 0;
        return this.e.offset(pos);
      },
      'S-RIGHT': function() {
        var pos;
        pos = this.e.offset();
        pos.left = this.e.parent().innerWidth() - this.e.outerWidth(true);
        return this.e.offset(pos);
      },
      'S-UP': function() {
        var pos;
        pos = this.e.offset();
        pos.top = 0;
        return this.e.offset(pos);
      },
      'S-DOWN': function() {
        var pos;
        pos = this.e.offset();
        pos.top = this.e.parent().innerHeight() - this.e.outerWidth(true);
        return this.e.offset(pos);
      },
      'C-LEFT': function() {
        return this.nextWindow("left", -1);
      },
      'C-RIGHT': function() {
        return this.nextWindow("left", 1);
      },
      'C-UP': function() {
        return this.nextWindow("top", -1);
      },
      'C-DOWN': function() {
        return this.nextWindow("top", 1);
      },
      SPACE: function() {
        return this.body.toggle();
      },
      ESCAPE: function() {
        return this.close();
      }
    };
    function Window(title) {
      var body, e, edge, edges, s, self;
      Window.__super__.constructor.apply(this, arguments);
      self = this;
      this.e.addClass("window").attr("tabindex", -1).hide();
      e = this.container = $("<div>").css({
        width: "100%",
        height: "100%"
      }).appendTo(this.e);
      $(window).bind("resize.moka", this.update.bind(this));
      this.title = new Moka.Input();
      this.title.keydown = this.keyDownTitle.bind(this);
      this.title.e.addClass("title").html(title).appendTo(e);
      $("<div>", {
        'class': "window_control close"
      }).css('cursor', "pointer").click(this.hide.bind(this)).appendTo(this.title.e);
      $("<div>", {
        'class': "window_control maximize"
      }).css('cursor', "pointer").click(this.maximize.bind(this)).appendTo(this.title.e);
      this.body = body = $("<div>", {
        "class": "body"
      }).appendTo(e);
      this.title.dblclick = function() {
        body.toggle();
        Moka.focus_first(body);
        return false;
      };
      this.title.mousedown = __bind(function(ev) {
        this.focus();
        return ev.preventDefault();
      }, this);
      edges = {
        n: [1, 1, 0, 1, 0, 1, "n"],
        e: [1, 1, 1, 0, 1, 0, "e"],
        s: [0, 1, 1, 1, 0, 1, "s"],
        w: [1, 0, 1, 1, 1, 0, "w"],
        ne: [1, 1, 0, 0, 1, 1, "ne"],
        se: [0, 1, 1, 0, 1, 1, "se"],
        sw: [0, 0, 1, 1, 1, 1, "sw"],
        nw: [1, 0, 0, 1, 1, 1, "nw"]
      };
      for (edge in edges) {
        s = edges[edge];
        $("<div>", {
          "class": "edge " + edge.split("").join(" ")
        }).css({
          position: "absolute",
          top: s[0] && "-2px" || "",
          right: s[1] && "-2px" || "",
          bottom: s[2] && "-2px" || "",
          left: s[3] && "-2px" || "",
          width: s[4] && "8px" || "",
          height: s[5] && "8px" || "",
          cursor: s[6] + "-resize"
        }).appendTo(e).mousedown(function(ev) {
          var $this, x, y;
          x = ev.pageX;
          y = ev.pageY;
          $this = $(this);
          $(document).bind("mousemove.moka", function(ev) {
            var dx, dy, pos;
            dx = ev.pageX - x;
            dy = ev.pageY - y;
            x += dx;
            y += dy;
            pos = self.position();
            if ($this.hasClass("n")) {
              body.height(body.height() - dy);
              pos.top += dy;
            }
            if ($this.hasClass("e")) {
              body.width(body.width() + dx);
            }
            if ($this.hasClass("s")) {
              body.height(body.height() + dy);
            }
            if ($this.hasClass("w")) {
              body.width(body.width() - dx);
              pos.left += dx;
            }
            self.position(pos.left, pos.top);
            return self.update();
          });
          $(document).one("mouseup", function() {
            return $(document).unbind("mousemove.moka");
          });
          return false;
        });
      }
      this.widgets = [];
      initDraggable(this.e, this.title.e);
      $(window).load((function() {
        return this.update();
      }).bind(this));
    }
    Window.prototype.toggleShow = function() {
      if (this.e.is(":visible")) {
        this.hide();
      } else {
        this.show();
      }
      return this;
    };
    Window.prototype.show = function() {
      this.e.show();
      this.update();
      return this;
    };
    Window.prototype.update = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        var _base;
        return typeof (_base = w[i]).update === "function" ? _base.update() : void 0;
      });
      return this;
    };
    Window.prototype.hide = function() {
      this.e.detach();
      return this;
    };
    Window.prototype.append = function(widget) {
      if (widget.e && widget.e.hasClass("widget")) {
        this.widgets.push(widget);
        widget.e.appendTo(this.body);
      } else {
        widget.appendTo(this.body);
      }
      return this;
    };
    Window.prototype.focus = function() {
      Moka.focus_first(this.body);
      return this;
    };
    Window.prototype.position = function(x, y) {
      var pos;
      if (x != null) {
        pos = this.e.parent().offset();
        this.e.offset({
          left: pos.left + x,
          top: pos.top + y
        });
        return this;
      } else {
        return this.e.offset();
      }
    };
    Window.prototype.resize = function(w, h) {
      this.body.width(w).height(h);
      this.update();
      return this;
    };
    Window.prototype.maximize = function() {
      var p, pos, pos2;
      this.position(0, 0);
      p = this.e.parent();
      pos = this.body.offset();
      pos2 = p.offset();
      pos.left += pos2.left;
      pos.top += pos2.top;
      this.resize(p.width() - pos.left, p.height() - pos.top);
      return this;
    };
    Window.prototype.nextWindow = function(left_or_top, direction) {
      var d, e, wnds, x;
      wnds = this.e.siblings(".window");
      x = this.e.offset()[left_or_top];
      d = -1;
      e = this.e;
      wnds.each(function() {
        var $this, dd;
        $this = $(this);
        dd = direction * ($this.offset()[left_or_top] - x);
        if ((d < 0 && dd >= 0) || (dd > 0 && dd < d)) {
          e = $this;
          return d = dd;
        }
      });
      return Moka.focus(e.find(".title:first"));
    };
    Window.prototype.close = function() {
      return this.e.remove();
    };
    Window.prototype.keydown = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (keyHintFocus(keyname, this.body)) {
        return false;
      }
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    Window.prototype.keyDownTitle = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_title_keys, this)) {
        return false;
      }
    };
    return Window;
  })();
  $(document).ready(Moka.init);
}).call(this);
