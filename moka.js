(function() {
  var dbg, doKey, dragScroll, elementToWidget, ensureVisible, focus_timestamp, focused_widget, getKeyName, initDraggable, isOnScreen, keyHintFocus, keycodes, last_keyname, last_keyname_timestamp, log, logfn, logobj, mokaInit, normalizeKeyName, tt, userAgent, userAgents;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __indexOf = Array.prototype.indexOf || function(item) {
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
  log = logfn ? logfn.bind(logobj) : function() {};
  dbg = log.bind(this, "DEBUG:");
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
  last_keyname = last_keyname_timestamp = null;
  normalizeKeyName = function(keyname) {
    var k, key, modifiers;
    modifiers = keyname.toUpperCase().split("-");
    key = modifiers.pop();
    modifiers = modifiers.map(function(x) {
      return x[0];
    }).sort();
    k = modifiers.length ? modifiers.join("-") + "-" + key : key;
    return k;
  };
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
      n = keyname.replace(/^S-/, "").replace(/^KP/, "");
      if (n >= "0" && n <= "9") {
        keyhint = n;
      }
    }
    e = null;
    if (keyhint != null) {
      root.find(".moka-keyhint").each(function() {
        var $this, parent;
        $this = $(this);
        if ($this.is(":visible") && keyhint === $this.text().toUpperCase()) {
          parent = $this.parent();
          if (!parent.hasClass("moka-focus")) {
            if (parent.hasClass("moka-tab") || parent.hasClass("moka-input")) {
              e = parent;
            } else {
              e = parent.find(".moka-input:first");
            }
            if (e.length) {
              Moka.focus(e);
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
    e.addClass("moka-label");
    if (text) {
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
        text = text.substr(0, i) + '<span class="moka-keyhint">' + key + '</span>' + text.substr(i + 2);
      }
      e.html(text);
    }
    e.css("cursor", "pointer");
    return e;
  };
  Moka.findInput = function(e, str) {
    var find, query, res;
    if (!str) {
      return null;
    }
    query = str.toUpperCase();
    res = null;
    find = function() {
      var $this;
      $this = $(this);
      if ($this.text().toUpperCase().search(query) >= 0) {
        res = $this.closest(".moka-input");
        return false;
      }
    };
    e.find(".moka-input.moka-label:visible, .moka-input > .moka-label:visible").each(find);
    return res;
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
  Moka.scrolling = false;
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
    var continueDragScroll, dt, dx, dy, from_mouseX, from_mouseY, mouseX, mouseY, pos, start, stop, stopDragScroll, t, w, wnd;
    Moka.focus($(ev.target).parents(".moka-input:first"));
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
    Moka.scrolling = false;
    continueDragScroll = function(ev) {
      var x, y;
      if (stop) {
        return;
      }
      Moka.scrolling = true;
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
      if (!Moka.scrolling) {
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
        }, 1000, "easeOutCubic", function() {
          return Moka.scrolling = false;
        });
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
  Moka.blur = function(e) {
    var ee;
    if (!e) {
      return;
    }
    ee = e.length ? e[0] : e;
    return ee.blur();
  };
  Moka.focusFirstWidget = function(w, only_children) {
    var ww, _i, _len, _ref;
    if (!only_children && w.focus) {
      w.focus();
      return true;
    } else if (w.widgets) {
      _ref = w.widgets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        ww = _ref[_i];
        if (Moka.focusFirstWidget(ww, false)) {
          return true;
        }
      }
    }
    return false;
  };
  Moka.focusFirst = function(e) {
    var ee, eee;
    if (e.hasClass("moka-input")) {
      ee = e;
    } else {
      ee = e.find(".moka-input:visible:first");
      eee = ee.siblings(".moka-current");
      if (eee.length) {
        ee = eee;
      }
    }
    if (ee.length) {
      Moka.focus(ee);
      return true;
    } else {
      return false;
    }
  };
  isOnScreen = function(w, how) {
    var e, max, min, pos, wnd, x;
    if (!w) {
      return false;
    }
    if (!how) {
      return (isOnScreen(w, "right") || isOnScreen(w, "left")) && (isOnScreen(w, "top") || isOnScreen(w, "bottom"));
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
    return (x + 8) >= min && (x - 8) <= max;
  };
  ensureVisible = function(widget, wnd) {
    var bottom, cbottom, cleft, cpos, cright, ctop, e, left, pos, right, top, w;
    e = widget.e ? wideget.e : widget;
    if (!wnd) {
      wnd = widget.parent();
    }
    if (!wnd.length) {
      return;
    }
    pos = wnd.offset() || {
      top: 0,
      left: 0
    };
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
    return ensureVisible(widget, wnd.parent());
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
    var e;
    e = $(ev.target);
    e.removeClass("moka-focus").trigger("mokaBlurred");
    if (e[0] === focused_widget[0]) {
      return focused_widget = $();
    }
  };
  Moka.gainFocus = function(ev) {
    if (focus_timestamp === ev.timeStamp) {
      return;
    }
    focus_timestamp = ev.timeStamp;
    focused_widget = $(ev.target);
    focused_widget.addClass("moka-focus").trigger("mokaFocused");
    return ensureVisible(focused_widget);
  };
  Moka.Widget = (function() {
    function Widget(from_element) {
      this.e = from_element && from_element.hasClass ? from_element : $("<div>");
      this.e.addClass("moka-widget").bind("mokaFocused", function() {
        return $(this).addClass("moka-focus");
      }).bind("mokaBlurred", function() {
        return $(this).removeClass("moka-focus");
      });
    }
    Widget.prototype.element = function() {
      return this.e;
    };
    Widget.prototype.show = function() {
      this.e.show();
      this.update();
      this.e.trigger("mokaDone", [false]);
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
    Widget.prototype.appendTo = function(e) {
      if (e.e && e.append) {
        e.append(this);
      } else {
        this.e.appendTo(e);
      }
      return this;
    };
    Widget.prototype.remove = function() {
      var w, widget, _i, _len, _ref;
      this.e.hide();
      w = this.widgets;
      if (w) {
        _ref = this.widgets;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          widget = _ref[_i];
          widget.remove();
        }
      }
      this.e.trigger("mokaDestroyed");
      return this.e.detach();
    };
    Widget.prototype.parent = function() {
      return this.parentWidget;
    };
    Widget.prototype.addKey = function(keyname, fn) {
      if (!this.keys) {
        this.keys = {};
      }
      this.keys[normalizeKeyName(keyname)] = fn;
      return this;
    };
    Widget.prototype.connect = function(event, fn) {
      this.e.bind(event, __bind(function(ev) {
        if (ev.target === this.e[0]) {
          return fn();
        }
      }, this));
      return this;
    };
    Widget.prototype.bind = function(event, fn) {
      this.e.bind(event, fn);
      return this;
    };
    Widget.prototype.one = function(event, fn) {
      this.e.one(event, fn);
      return this;
    };
    Widget.prototype.width = function(val) {
      if (val != null) {
        this.e.width(val);
        return this;
      } else {
        return this.e.width();
      }
    };
    Widget.prototype.height = function(val) {
      if (val != null) {
        this.e.height(val);
        return this;
      } else {
        return this.e.height();
      }
    };
    Widget.prototype.outerWidth = function() {
      return this.e.outerWidth();
    };
    Widget.prototype.outerHeight = function() {
      return this.e.outerHeight();
    };
    Widget.prototype.align = function(alignment) {
      this.e.css("text-align", alignment);
      return this;
    };
    Widget.prototype.css = function(prop, val) {
      if (val != null) {
        this.e.css(prop, val);
        return this;
      } else {
        return this.e.css(prop);
      }
    };
    Widget.prototype["do"] = function(fn) {
      fn.apply(this, [this.e]);
      return this;
    };
    return Widget;
  })();
  Moka.Label = (function() {
    __extends(Label, Moka.Widget);
    function Label(text) {
      this.text = text;
      Label.__super__.constructor.call(this, Moka.createLabel(this.text));
    }
    return Label;
  })();
  Moka.Input = (function() {
    __extends(Input, Moka.Widget);
    function Input() {
      Input.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-input").attr("tabindex", 0).css("cursor", "pointer").bind("focus.moka", Moka.gainFocus).bind("blur.moka", Moka.lostFocus).bind("focus.moka", __bind(function(ev) {
        return typeof this.focus === "function" ? this.focus(ev) : void 0;
      }, this)).bind("blur.moka", __bind(function(ev) {
        return typeof this.blur === "function" ? this.blur(ev) : void 0;
      }, this)).bind("click.moka", __bind(function(ev) {
        return typeof this.click === "function" ? this.click(ev) : void 0;
      }, this)).bind("dblclick.moka", __bind(function(ev) {
        return typeof this.dblclick === "function" ? this.dblclick(ev) : void 0;
      }, this)).bind("mouseup.moka", __bind(function(ev) {
        return typeof this.mouseup === "function" ? this.mouseup(ev) : void 0;
      }, this)).bind("mousedown.moka", __bind(function(ev) {
        return typeof this.mousedown === "function" ? this.mousedown(ev) : void 0;
      }, this)).bind("keydown.moka", __bind(function(ev) {
        return typeof this.keydown === "function" ? this.keydown(ev) : void 0;
      }, this)).bind("keyup.moka", __bind(function(ev) {
        return typeof this.keyup === "function" ? this.keyup(ev) : void 0;
      }, this));
    }
    Input.prototype.focus = function() {
      Moka.focus(this.e);
      return this;
    };
    Input.prototype.hasFocus = function() {
      return this.e.hasClass("moka-focus");
    };
    Input.prototype.remove = function() {
      var ee, v;
      ee = this.e.parent();
      v = Input.__super__.remove.apply(this, arguments);
      if (this.hasFocus()) {
        Moka.blur(this.e);
        while (ee.length) {
          if (Moka.focusFirst(ee)) {
            break;
          }
          ee = ee.parent();
        }
      }
      return v;
    };
    Input.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (keyHintFocus(keyname, this.e)) {
        return false;
      }
    };
    return Input;
  })();
  Moka.Container = (function() {
    __extends(Container, Moka.Widget);
    function Container(horizontal) {
      Container.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-container");
      this.widgets = [];
      this.vertical(horizontal != null ? !horizontal : true);
    }
    Container.prototype.update = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        return w[i].update();
      });
      return this;
    };
    Container.prototype.length = function() {
      return this.widgets.length;
    };
    Container.prototype.at = function(index) {
      return this.widgets[index];
    };
    Container.prototype.vertical = function(toggle) {
      if (toggle != null) {
        this.e.addClass(toggle ? "moka-vertical" : "moka-horizontal");
        this.e.removeClass(toggle ? "moka-horizontal" : "moka-vertical");
        return this;
      } else {
        return this.e.hasClass("moka-vertical");
      }
    };
    Container.prototype.append = function(widgets) {
      var e, id, widget, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        widget = arguments[_i];
        id = this.length();
        widget.parentWidget = this;
        this.widgets.push(widget);
        e = widget.e;
        if (id === 0) {
          e.addClass("moka-first");
        } else {
          this.widgets[id - 1].e.removeClass("moka-last");
        }
        e.addClass(this.itemcls + " moka-last");
        e.appendTo(this.e).bind("mokaSizeChanged", this.update.bind(this));
      }
      this.update();
      return this;
    };
    return Container;
  })();
  Moka.WidgetList = (function() {
    __extends(WidgetList, Moka.Container);
    WidgetList.prototype.default_keys = {
      LEFT: function() {
        if (this.e.hasClass("moka-horizontal")) {
          return this.prev();
        } else {
          return false;
        }
      },
      RIGHT: function() {
        if (this.e.hasClass("moka-horizontal")) {
          return this.next();
        } else {
          return false;
        }
      },
      UP: function() {
        if (!this.e.hasClass("moka-horizontal")) {
          return this.prev();
        } else {
          return false;
        }
      },
      DOWN: function() {
        if (!this.e.hasClass("moka-horizontal")) {
          return this.next();
        } else {
          return false;
        }
      },
      TAB: function() {
        if (this.current + 1 < this.length()) {
          return this.next();
        } else {
          return false;
        }
      },
      'S-TAB': function() {
        if (this.current > 0) {
          return this.prev();
        } else {
          return false;
        }
      }
    };
    function WidgetList(cls, itemcls) {
      WidgetList.__super__.constructor.apply(this, arguments);
      this.e.addClass(cls != null ? cls : "moka-widgetlist").bind("keydown.moka", __bind(function(ev) {
        return this.keydown(ev);
      }, this)).bind("mokaFocusUpRequest", __bind(function() {
        this.select(Math.max(0, this.current));
        return false;
      }, this)).bind("mokaFocusNextRequest", __bind(function() {
        this.next();
        return false;
      }, this)).bind("mokaFocusPrevRequest", __bind(function() {
        this.prev();
        return false;
      }, this));
      this.itemcls = itemcls != null ? itemcls : "moka-widgetlistitem";
      this.current = 0;
    }
    WidgetList.prototype.append = function(widgets) {
      var e, id, widget, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        widget = arguments[_i];
        id = this.length();
        e = widget.e;
        widget.parentWidget = this;
        e.bind("mokaFocused", __bind(function() {
          var _ref;
          if (this.current >= 0) {
            if ((_ref = this.widgets[this.current]) != null) {
              _ref.e.removeClass("moka-current");
            }
            e.trigger("mokaDeselected", [this.current]);
          }
          this.current = id;
          e.addClass("moka-current").trigger("mokaSelected", [id]);
          return this.update();
        }, this));
        if (id === this.current) {
          e.addClass("moka-current");
        }
      }
      WidgetList.__super__.append.apply(this, arguments);
      return this;
    };
    WidgetList.prototype.select = function(id) {
      var w;
      if (id >= 0) {
        w = this.widgets[id];
        if (w) {
          return Moka.focusFirstWidget(w);
        }
      }
    };
    WidgetList.prototype.next = function() {
      return this.select(this.current >= 0 && this.current < this.length() - 1 ? this.current + 1 : 0);
    };
    WidgetList.prototype.prev = function() {
      var l;
      l = this.length();
      return this.select(this.current >= 1 && this.current < l ? this.current - 1 : l - 1);
    };
    WidgetList.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (keyHintFocus(keyname, this.e)) {
        return false;
      }
    };
    return WidgetList;
  })();
  Moka.CheckBox = (function() {
    __extends(CheckBox, Moka.Input);
    CheckBox.prototype.default_keys = {
      SPACE: function() {
        return this.toggle();
      }
    };
    function CheckBox(text, checked) {
      CheckBox.__super__.constructor.call(this, Moka.createLabel(text).addClass("moka-checkbox"));
      this.checkbox = $('<input>', {
        tabindex: 1,
        type: "checkbox",
        "class": "moka-value"
      }).focus(this.focus.bind(this)).prependTo(this.e);
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
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return CheckBox;
  })();
  Moka.Combo = (function() {
    __extends(Combo, Moka.Input);
    Combo.prototype.default_keys = {
      SPACE: function() {
        return Moka.focus(this.combo);
      }
    };
    function Combo(text) {
      Combo.__super__.constructor.call(this, Moka.createLabel(text).addClass("moka-combo"));
      this.combo = $('<select>', {
        tabindex: 1,
        "class": "moka-value"
      }).focus(Moka.gainFocus).blur(Moka.lostFocus).appendTo(this.e);
    }
    Combo.prototype.append = function(texts) {
      var text, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        text = arguments[_i];
        $("<option>").text(text).attr("value", text).appendTo(this.combo);
      }
      return this;
    };
    Combo.prototype.focus = function() {
      Moka.focus(this.e);
      return this;
    };
    Combo.prototype.value = function(val) {
      if (val != null) {
        this.combo.val(val);
        return this;
      } else {
        return this.combo.val();
      }
    };
    Combo.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (ev.target === this.combo[0] && ["LEFT", "RIGHT", "UP", "DOWN"].indexOf(keyname) >= 0) {
        return ev.stopPropagation();
      }
    };
    return Combo;
  })();
  Moka.LineEdit = (function() {
    __extends(LineEdit, Moka.Input);
    LineEdit.prototype.default_keys = {};
    function LineEdit(label_text, text) {
      LineEdit.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-lineedit").attr("tabindex", 1);
      if (label_text) {
        Moka.createLabel(label_text, this.e);
      }
      this.edit = $("<input>").focus(Moka.gainFocus).blur(Moka.lostFocus).keyup(this.update.bind(this)).appendTo(this.e);
      if (text != null) {
        this.value(text);
      }
    }
    LineEdit.prototype.focus = function() {
      Moka.focus(this.edit);
      return this;
    };
    LineEdit.prototype.remove = function() {
      Moka.blur(this.edit);
      return LineEdit.__super__.remove.apply(this, arguments);
    };
    LineEdit.prototype.update = function() {
      return this.edit.attr("size", this.value().length + 2);
    };
    LineEdit.prototype.value = function(text) {
      if (text != null) {
        this.edit.attr("value", text);
        return this;
      } else {
        return this.edit.attr("value");
      }
    };
    LineEdit.prototype.keydown = function(ev) {
      var k, keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      k = keyname.split('-');
      k = k[k.length - 1];
      if (k.length === 1 || ["LEFT", "RIGHT", "BACKSPACE", "DELETE", "MINUS", "SPACE"].indexOf(k) >= 0) {
        return ev.stopPropagation();
      }
    };
    return LineEdit;
  })();
  Moka.TextEdit = (function() {
    __extends(TextEdit, Moka.Input);
    TextEdit.prototype.default_keys = {
      ENTER: function() {
        return Moka.focus(this.editor.win);
      }
    };
    function TextEdit(label_text, text) {
      TextEdit.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-textedit").attr("tabindex", 1);
      Moka.createLabel(label_text, this.e);
      this.text = text || "";
      this.textarea = $("<textarea>").appendTo(this.e).focus(Moka.gainFocus).blur(Moka.lostFocus).keydown(this.keydown);
    }
    TextEdit.prototype.update = function() {
      return this;
    };
    TextEdit.prototype.hide = function() {
      this.e.hide();
      return this;
    };
    TextEdit.prototype.value = function(text) {
      if (text != null) {
        this.textarea.value(text);
        this.text = text;
        return this;
      } else {
        return this.text;
      }
    };
    TextEdit.prototype.editorKeyDown = function(ev) {
      var k, keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      k = keyname.replace(/^S-/, "").replace(/^KP/, "");
      if (k === "TAB" || k.search(/^F[0-9]/) >= 0) {
        return this.e.trigger(ev);
      } else if (k === "ESCAPE") {
        this.hide();
        return this.show();
      }
    };
    TextEdit.prototype.focus = function(ev) {
      Moka.focus(this.textarea);
      return this;
    };
    TextEdit.prototype.remove = function() {
      Moka.blur(this.textarea);
      return TextEdit.__super__.remove.apply(this, arguments);
    };
    TextEdit.prototype.keydown = function(ev) {
      var keyname;
      ev.stopPropagation();
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return TextEdit;
  })();
  Moka.Button = (function() {
    __extends(Button, Moka.Input);
    function Button(label_text, onclick, tooltip) {
      Button.__super__.constructor.apply(this, arguments);
      Moka.createLabel(label_text, this.e);
      this.e.addClass("moka-button");
      this.click = onclick;
      if (tooltip) {
        this.e.attr("title", tooltip);
      }
    }
    Button.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (keyname === "ENTER" || keyname === "SPACE") {
        this.e.click();
        return false;
      }
    };
    return Button;
  })();
  Moka.ButtonBox = (function() {
    __extends(ButtonBox, Moka.WidgetList);
    function ButtonBox() {
      ButtonBox.__super__.constructor.apply(this, arguments);
      this.e.removeClass("moka-widgetlist").addClass("moka-buttonbox moka-horizontal");
    }
    ButtonBox.prototype.append = function(label_text, onclick, tooltip) {
      var widget;
      widget = new Moka.Button(label_text, onclick, tooltip);
      ButtonBox.__super__.append.call(this, widget);
      widget.e.removeClass("moka-widgetlistitem");
      this.update();
      return this;
    };
    return ButtonBox;
  })();
  Moka.Tabs = (function() {
    __extends(Tabs, Moka.Widget);
    Tabs.prototype.default_keys = {
      SPACE: function() {
        return this.pages_e.toggle();
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
    Tabs.prototype.default_tab_keys = {
      TAB: function() {
        var page;
        if ((page = this.pages[this.current])) {
          return Moka.focusFirstWidget(page, true);
        } else {
          return false;
        }
      }
    };
    function Tabs() {
      Tabs.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-tabwidget").bind("keydown.moka", __bind(function(ev) {
        return this.keydown(ev);
      }, this)).bind("mokaFocusUpRequest", __bind(function() {
        this.select(Math.max(0, this.current));
        return false;
      }, this));
      this.tabs = new Moka.WidgetList("moka-tabs", "moka-tab");
      this.widgets = this.tabs.widgets;
      this.tabs_e = this.tabs.e.appendTo(this.e).bind("mokaSelected", __bind(function(ev, id) {
        if (this.current === id) {
          return;
        }
        if (this.current >= 0) {
          this.pages[this.current].hide();
          this.tabs.at(this.current).e.attr("tabindex", -1);
        }
        this.current = id;
        this.tabs.at(this.current).e.attr("tabindex", 0);
        return this.pages[id].show();
      }, this));
      this.tabs.keydown = this.tabsKeyDown.bind(this);
      this.tabs.keys = this.tab_keys = {};
      this.pages_e = $("<div>", {
        "class": "moka-pages"
      }).appendTo(this.e);
      this.pages = [];
      this.current = -1;
      this.vertical(false);
    }
    Tabs.prototype.update = function() {
      this.tabs.update();
      if (this.current >= 0) {
        this.pages[this.current].show();
      }
      return this;
    };
    Tabs.prototype.focusUp = function() {
      if (!this.tabs_e.hasClass("moka-focus")) {
        this.select(Math.max(0, this.current));
      } else {
        this.e.parent().trigger("mokaFocusUpRequest");
      }
      return this;
    };
    Tabs.prototype.focusDown = function() {
      Moka.focusFirstWidget(this.pages[this.current]);
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
      tab = new Moka.Input()["do"](function(e) {
        return e.attr("tabindex", -1);
      });
      tab.parentWidget = this;
      Moka.createLabel(tabname, tab.e);
      this.tabs.append(tab);
      widget.hide();
      widget.parentWidget = this;
      page = widget.e.addClass("moka-page");
      page.parentWidget = this;
      if (page.parent().length === 0) {
        page.appendTo(this.pages_e);
      }
      page.keydown(this.keydown.bind(this));
      if (this.current < 0 || this.current === this.tabs.length() - 1) {
        this.select(Math.max(0, this.current));
      }
      this.update();
      return this;
    };
    Tabs.prototype.select = function(id) {
      this.tabs.select(id);
      return this;
    };
    Tabs.prototype.vertical = function(toggle) {
      if (toggle != null) {
        this.tabs.vertical(toggle);
        return this;
      } else {
        return this.tabs.vertical();
      }
    };
    Tabs.prototype.tabsKeyDown = function(ev) {
      var keyname, page;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.tab_keys, this.default_tab_keys, this)) {
        return false;
      }
      page = this.pages[this.current];
      if (((page != null) && keyHintFocus(keyname, page.e)) || keyHintFocus(keyname, this.tabs_e)) {
        return false;
      }
    };
    Tabs.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (keyHintFocus(keyname, this.tabs_e)) {
        return false;
      }
    };
    return Tabs;
  })();
  Moka.Image = (function() {
    __extends(Image, Moka.Widget);
    function Image(src, w, h, onload, onerror) {
      this.src = src;
      Image.__super__.constructor.call(this, $("<img>", {
        "class": "moka-widget moka-image",
        width: w,
        height: h
      }));
      this.img = this.e;
      this.owidth = this.oheight = 0;
      this.e.one("load", __bind(function() {
        var e;
        this.ok = true;
        e = this.e[0];
        this.owidth = img.naturalWidth;
        this.oheight = img.naturalHeight;
        return typeof onload === "function" ? onload() : void 0;
      }, this));
      this.e.one("error", __bind(function() {
        this.ok = false;
        this.width = this.height = 0;
        return typeof onerror === "function" ? onerror() : void 0;
      }, this));
      this.e.attr("src", this.src);
    }
    Image.prototype.resize = function(w, h) {
      if (w != null) {
        this.e.width(w);
      }
      if (h != null) {
        this.e.height(h);
      }
      return this;
    };
    Image.prototype.isLoaded = function() {
      return this.ok != null;
    };
    Image.prototype.originalWidth = function() {
      return this.owidth;
    };
    Image.prototype.originalHeight = function() {
      return this.oheight;
    };
    return Image;
  })();
  Moka.Canvas = (function() {
    __extends(Canvas, Moka.Widget);
    function Canvas(src, w, h, onload, onerror) {
      var e;
      this.src = src;
      e = null;
      if (window.fx && window.fx.canvas) {
        try {
          this.canvas = fx.canvas();
          e = $(this.canvas);
        } catch (_e) {}
      } else {
        log("Use glfx.js in HTML for WebGL support.");
      }
      if (e) {
        e.addClass("moka-widget moka-canvas");
        e.width(0);
        e.height(0);
        Canvas.__super__.constructor.call(this, e);
      } else {
        Canvas.__super__.constructor.call(this, $("<canvas>", {
          "class": "moka-widget moka-canvas",
          width: 0,
          height: 0
        }));
        this.ctx = this.e[0].getContext("2d");
      }
      this.owidth = this.oheight = 0;
      this.img = $("<img>", {
        width: w,
        height: h
      });
      this.img.one("load", __bind(function() {
        var img;
        this.ok = true;
        img = this.img[0];
        this.owidth = img.naturalWidth;
        this.oheight = img.naturalHeight;
        this.resize(this.owidth, this.oheight);
        return typeof onload === "function" ? onload() : void 0;
      }, this));
      this.img.one("error", __bind(function() {
        this.ok = false;
        return typeof onerror === "function" ? onerror() : void 0;
      }, this));
      this.img.attr("src", this.src);
    }
    Canvas.prototype.originalWidth = function() {
      return this.owidth;
    };
    Canvas.prototype.originalHeight = function() {
      return this.oheight;
    };
    Canvas.prototype.hide = function() {
      var e;
      if (this.t_sharpen) {
        window.clearTimeout(this.t_sharpen);
        e = this.e[0];
        e.width = e.height = 0;
      }
      return Canvas.__super__.hide.apply(this, arguments);
    };
    Canvas.prototype.resize = function(w, h) {
      var e, img, strength, texture;
      if (!this.ok) {
        return this;
      }
      e = this.e[0];
      if ((e.width === w && e.height === h) || (w <= 0 && h <= 0)) {
        return this;
      }
      e.width = w;
      e.height = h;
      img = this.img[0];
      if (this.canvas) {
        texture = e.texture(img);
        e.draw(texture);
        texture.destroy();
      } else {
        this.ctx.clearRect(0, 0, e.width, e.height);
        this.ctx.drawImage(img, 0, 0, e.width, e.height);
      }
      strength = this.sharpen_strength;
      this.sharpen_strength = null;
      if (strength) {
        this.sharpen(strength);
      } else if (this.canvas) {
        e.update();
      }
      return this;
    };
    Canvas.prototype.sharpen = function(strength) {
      var data, dataCopy, dataDesc, e, filter, h, mul, mulOther, w, w4, weight, y;
      if (!this.ok || this.sharpen_strength === strength) {
        return this;
      }
      if (this.t_sharpen) {
        window.clearTimeout(this.t_sharpen);
      }
      this.sharpen_strength = strength;
      if (!strength || strength < 0) {
        return this;
      }
      if (this.canvas) {
        this.canvas.unsharpMask(32, strength * 5).update();
        return this;
      } else if (strength > 1) {
        strength = 1;
      }
      e = this.e[0];
      w = Math.ceil(e.width);
      h = Math.ceil(e.height);
      dataDesc = this.ctx.getImageData(0, 0, w, h);
      data = dataDesc.data;
      dataCopy = this.ctx.getImageData(0, 0, w, h).data;
      mul = 15;
      mulOther = 1 + 3 * strength;
      weight = 1 / (mul - 4 * mulOther);
      mul *= weight;
      mulOther *= weight;
      w4 = w * 4;
      y = 1;
      filter = function(miny) {
        var b, g, nextY, offset, offsetNext, offsetPrev, offsetY, offsetYNext, offsetYPrev, prevY, r, x;
        offsetY = (y - 1) * w4;
        nextY = y === h ? y - 1 : y;
        prevY = y === 1 ? 0 : y - 2;
        offsetYPrev = prevY * w4;
        offsetYNext = nextY * w4;
        while (y < miny) {
          offsetY = (y - 1) * w4;
          nextY = y === h ? y - 1 : y;
          prevY = y === 1 ? 0 : y - 2;
          offsetYPrev = prevY * w4;
          offsetYNext = nextY * w4;
          x = w;
          offset = offsetY - 4 + w * 4;
          offsetPrev = offsetYPrev + (w - 2) * 4;
          offsetNext = offsetYNext + (w - 1) * 4;
          while (x) {
            r = dataCopy[offset] * mul - mulOther * (dataCopy[offsetPrev] + dataCopy[offset - 4] + dataCopy[offset + 4] + dataCopy[offsetNext]);
            g = dataCopy[offset + 1] * mul - mulOther * (dataCopy[offsetPrev + 1] + dataCopy[offset - 3] + dataCopy[offset + 5] + dataCopy[offsetNext + 1]);
            b = dataCopy[offset + 2] * mul - mulOther * (dataCopy[offsetPrev + 2] + dataCopy[offset - 2] + dataCopy[offset + 6] + dataCopy[offsetNext + 2]);
            data[offset] = Math.min(Math.max(r, 0), 255);
            data[offset + 1] = Math.min(Math.max(g, 0), 255);
            data[offset + 2] = Math.min(Math.max(b, 0), 255);
            if (x < w) {
              offsetNext -= 4;
            }
            --x;
            offset -= 4;
            if (x > 2) {
              offsetPrev -= 4;
            }
          }
          ++y;
          offsetY += w4;
          if (y !== h) {
            ++nextY;
            offsetYPrev += w4;
          }
          if (y > 2) {
            ++prevY;
            offsetYNext += w4;
          }
        }
        this.ctx.putImageData(dataDesc, 0, 0);
        return this.t_sharpen = y > h ? 0 : window.setTimeout(filter.bind(this, Math.min(y + 50, h + 1)), 0);
      };
      this.t_sharpen = window.setTimeout(filter.bind(this, 50), 0);
      return this;
    };
    Canvas.prototype.isLoaded = function() {
      return this.ok != null;
    };
    return Canvas;
  })();
  Moka.ImageView = (function() {
    __extends(ImageView, Moka.Input);
    ImageView.prototype.default_keys = {};
    function ImageView(src, use_canvas, sharpen) {
      this.use_canvas = use_canvas;
      this.sharpen = sharpen;
      ImageView.__super__.constructor.apply(this, arguments);
      this.e.addClass("moka-imageview");
      this.src = src;
    }
    ImageView.prototype.show = function() {
      var onerror, onload;
      if (this.image) {
        if (this.t_remove) {
          window.clearTimeout(this.t_remove);
          this.t_remove = null;
          this.image.show();
        }
        this.e.show();
        if (this.ok != null) {
          this.zoom(this.z, this.zhow);
          this.e.trigger("mokaLoaded");
          this.e.trigger("mokaDone", [!this.ok]);
        }
      } else {
        onload = __bind(function() {
          this.ok = true;
          this.zoom(this.z, this.zhow);
          this.e.trigger("mokaLoaded");
          return this.e.trigger("mokaDone", [false]);
        }, this);
        onerror = __bind(function() {
          this.ok = false;
          this.e.trigger("mokaError");
          return this.e.trigger("mokaDone", [true]);
        }, this);
        if (this.use_canvas) {
          this.image = new Moka.Canvas(this.src, "", "", onload, onerror);
        } else {
          this.image = new Moka.Image(this.src, "", "", onload, onerror);
        }
        this.image.appendTo(this.e);
        this.e.show();
      }
      return this;
    };
    ImageView.prototype.hide = function() {
      this.e.hide();
      if ((this.image != null) && !this.t_remove) {
        this.image.hide();
        this.t_remove = window.setTimeout(__bind(function() {
          dbg("removing image", this.image.img.attr("src"));
          this.ok = null;
          this.image.img.attr("src", "");
          this.image.remove();
          this.image = null;
          return this.t_remove = null;
        }, this), 60000);
      }
      return ImageView.__super__.hide.apply(this, arguments);
    };
    ImageView.prototype.isLoaded = function() {
      return this.ok != null;
    };
    ImageView.prototype.originalWidth = function() {
      return this.image.originalWidth();
    };
    ImageView.prototype.originalHeight = function() {
      return this.image.originalHeight();
    };
    ImageView.prototype.zoom = function(how, how2) {
      var d, d2, h, height, mh, mw, w, width;
      if (how != null) {
        this.z = how;
        this.zhow = how2;
        if (this.isLoaded() && this.e.parent().length) {
          width = this.image.outerWidth();
          height = this.image.outerHeight();
          w = h = mw = mh = "";
          if (how instanceof Array) {
            mw = how[0];
            mh = how[1];
            d = mw / mh;
            d2 = width / height;
            if (how2 === "fill") {
              if (d > d2) {
                w = mw;
                h = height * mw / width;
              } else {
                h = mh;
                w = width * mh / height;
              }
              mw = mh = "";
            } else {
              if (d > d2) {
                h = mh;
                w = width * mh / height;
              } else {
                w = mw;
                h = height * mw / width;
              }
              mw = mh = "";
            }
          } else {
            this.z = parseFloat(how) || 1;
            mw = Math.floor(this.z * this.image.originalWidth());
            mh = Math.floor(this.z * this.image.originalHeight());
          }
          if (how2 !== "fit" && how2 !== "fill") {
            if (width / height < mw / mh) {
              h = mh;
            } else {
              w = mw;
            }
          }
          this.image.css({
            'max-width': mw,
            'max-height': mh,
            width: w,
            height: h
          });
          this.image.resize(w || mw, h || mh);
          if (this.image.sharpen) {
            this.image.sharpen(this.sharpen);
          }
        }
        return this;
      } else {
        return this.z;
      }
    };
    ImageView.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      } else if ((keyname === "LEFT" || keyname === "RIGHT") && this.image.width() > this.width()) {
        return ev.stopPropagation();
      } else if ((keyname === "UP" || keyname === "DOWN") && this.image.height() > this.height()) {
        return ev.stopPropagation();
      }
    };
    return ImageView;
  })();
  Moka.Viewer = (function() {
    __extends(Viewer, Moka.Input);
    Viewer.prototype.default_keys = {
      RIGHT: function() {
        return isOnScreen(focused_widget, "right") && this.focusRight() || this.e.scrollLeft(this.e.scrollLeft() + 30);
      },
      LEFT: function() {
        return isOnScreen(focused_widget, "left") && this.focusLeft() || this.e.scrollLeft(this.e.scrollLeft() - 30);
      },
      UP: function() {
        return isOnScreen(focused_widget, "top") && this.focusUp() || this.e.scrollTop(this.e.scrollTop() - 30);
      },
      DOWN: function() {
        return isOnScreen(focused_widget, "bottom") && this.focusDown() || this.e.scrollTop(this.e.scrollTop() + 30);
      },
      TAB: function() {
        if (this.index + this.current + 1 < this.length() && this.currentcell + 1 < this.cellCount()) {
          return this.next();
        } else {
          return false;
        }
      },
      'S-TAB': function() {
        if (this.currentcell > 0) {
          return this.prev();
        } else {
          return false;
        }
      },
      KP6: function() {
        return this.next();
      },
      KP4: function() {
        return this.prev();
      },
      KP2: function() {
        return this.nextRow();
      },
      KP8: function() {
        return this.prevRow();
      },
      SPACE: function() {
        if (isOnScreen(focused_widget, "bottom")) {
          return this.next();
        } else {
          return this.e.scrollTop(this.e.scrollTop() + 0.9 * this.e.parent().height());
        }
      },
      'S-SPACE': function() {
        if (isOnScreen(focused_widget, "top")) {
          return this.prev();
        } else {
          return this.e.scrollTop(this.e.scrollTop() - 0.9 * this.e.parent().height());
        }
      },
      ENTER: function() {
        return typeof this.dblclick === "function" ? this.dblclick() : void 0;
      },
      '*': function() {
        this.layout([1, 1]);
        return this.zoom(1);
      },
      '/': function() {
        if (this.zhow === "fit") {
          return this.zoom(1);
        } else {
          return this.zoom("fit");
        }
      },
      '+': function() {
        return this.zoom("+");
      },
      '.': function() {
        if (this.zhow === "fill") {
          return this.zoom(1);
        } else {
          return this.zoom("fill");
        }
      },
      MINUS: function() {
        return this.zoom("-");
      },
      KP7: function() {
        return this.select(0);
      },
      HOME: function() {
        return this.select(0);
      },
      KP1: function() {
        return this.select(this.length() - 1);
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
      this.e.addClass("moka-viewer").resize(this.update.bind(this)).bind("scroll.moka", this.onScroll.bind(this)).css("cursor", "move").attr("tabindex", 1).bind("mokaFocusUpRequest", __bind(function() {
        this.select(this.index + this.current);
        return false;
      }, this));
      $(window).bind("resize.moka", this.update.bind(this));
      this.table = $("<table>", {
        "class": "moka-table",
        border: 0,
        cellSpacing: 0,
        cellPadding: 0
      }).appendTo(this.e);
      this.cells = [];
      this.items = [];
      this.index = 0;
      this.current = -1;
      this.currentcell = -1;
      this.preload_offset = 200;
      this.layout([1, 1]);
      this.orientation("lt");
      this.zoom(1);
    }
    Viewer.prototype.show = function() {
      this.e.show();
      return this.update();
    };
    Viewer.prototype.update = function() {
      if (!this.e.is(":visible")) {
        return;
      }
      this.view(this.index);
      return this;
    };
    Viewer.prototype.focus = function(ev) {
      var cell;
      cell = this.cells[this.currentcell > 0 ? this.currentcell : 0];
      Moka.focusFirst(cell.children()) || Moka.focus(cell);
      return this;
    };
    Viewer.prototype.appendFunction = function(fn, length) {
      var i, itemfn, l, last;
      last = this.length();
      itemfn = function(index) {
        return fn(index - last);
      };
      i = this.items.length;
      l = i + length;
      while (i < l) {
        this.items.push(itemfn);
        ++i;
      }
      if (this.lay[0] <= 0 || this.lay[1] <= 0) {
        this.updateTable();
      }
      this.update();
      return this;
    };
    Viewer.prototype.append = function(widget) {
      var id;
      id = this.length();
      widget.parentWidget = this;
      this.items.push(widget);
      if (this.lay[0] <= 0 || this.lay[1] <= 0) {
        this.updateTable();
      }
      this.update();
      return this;
    };
    Viewer.prototype.at = function(index) {
      var x;
      x = this.items[index];
      if (x instanceof Function) {
        x = this.items[index] = x(index);
        x.parentWidget = this;
      }
      return x;
    };
    Viewer.prototype.clean = function() {
      var i, l, x;
      i = 0;
      l = this.length();
      while (i < l) {
        x = this.items[i];
        if (!(x instanceof Function)) {
          x.remove();
        }
        ++i;
      }
      this.items = [];
      return this;
    };
    Viewer.prototype.remove = function() {
      this.clean();
      return Viewer.__super__.remove.apply(this, arguments);
    };
    Viewer.prototype.currentIndex = function() {
      if (this.current >= 0) {
        return this.index + this.current;
      } else {
        return -1;
      }
    };
    Viewer.prototype.currentItem = function() {
      var i;
      i = this.currentIndex();
      if (i >= 0) {
        return this.at(i);
      } else {
        return null;
      }
    };
    Viewer.prototype.length = function() {
      return this.items.length;
    };
    Viewer.prototype.clear = function() {
      var i, item, len, _results;
      i = 0;
      len = this.cellCount();
      _results = [];
      while (i < len) {
        item = this.at(this.index + i);
        if (item) {
          item.e.detach();
          item.hide();
        }
        _results.push(++i);
      }
      return _results;
    };
    Viewer.prototype.view = function(id) {
      var cell, i, item, len;
      if (id >= this.length()) {
        return this;
      }
      if (id < 0) {
        id = 0;
      }
      this.table.hide();
      this.clear();
      i = 0;
      len = this.cellCount();
      this.index = Math.floor(id / len) * len;
      dbg("displaying views", this.index + ".." + (this.index + len - 1));
      while (i < len) {
        cell = this.cell(i);
        item = this.at(this.index + i);
        cell.data("itemindex", i);
        if (item) {
          cell.attr("tabindex", -1);
          item.hide().appendTo(cell);
        } else {
          cell.attr("tabindex", "");
        }
        ++i;
      }
      this.table.show();
      this.zoom(this.zhow);
      this.updateVisible(true);
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
      cell = this.cell(this.current) || this.cell(0);
      Moka.blur(cell.children()) || Moka.blur(cell);
      count = this.cellCount();
      this.current = id % count;
      if (id < this.index || id >= this.index + count) {
        this.view(id);
      }
      cell = this.cell(id % count);
      Moka.focusFirst(cell.children()) || Moka.focus(cell);
      return this;
    };
    Viewer.prototype.zoom = function(how) {
      var d, factor, h, i, item, layout, len, offset, pos, s, w, wnd, _i, _len, _ref;
      if (how != null) {
        if (how === "fit" || how === "fill") {
          layout = this.layout();
          wnd = this.e.parent();
          offset = wnd.offset() || {
            top: 0,
            left: 0
          };
          pos = this.e.offset();
          pos.top -= offset.top;
          pos.left -= offset.left;
          if (wnd[0] === window.document.body) {
            wnd = $(window);
          }
          w = (wnd.width() - pos.left) / layout[0];
          h = (wnd.height() - pos.top) / layout[1];
          _ref = [this.table[0].cellSpacing, this.table[0].cellPadding, this.table[0].border];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            s = _ref[_i];
            if (s) {
              w += layout[0] * s;
              h += layout[0] * s;
            }
          }
          this.z = [w, h];
          this.zhow = how;
        } else if (how === "+" || how === "-") {
          if (!this.z) {
            this.z = 1;
          }
          if (this.z instanceof Array) {
            d = how === "-" ? 0.889 : 1.125;
            this.z[0] *= d;
            this.z[1] *= d;
          } else {
            this.z += how === "-" ? -0.125 : 0.125;
          }
          this.zhow = null;
        } else if (how instanceof Array) {
          this.z = how;
          this.zhow = null;
        } else {
          factor = parseFloat(how) || 1;
          this.z = factor;
          this.zhow = null;
        }
        i = this.index;
        len = i + this.cellCount();
        len = Math.min(len, this.length());
        dbg("zooming views", i + ".." + (len - 1), "using method", this.z, this.zhow);
        while (i < len) {
          item = this.at(i);
          if (typeof item.zoom === "function") {
            item.zoom(this.z, this.zhow);
          }
          ++i;
        }
        if (this.current >= 0) {
          ensureVisible(this.at(this.index + this.current).e);
        }
        this.updateVisible();
        this.e.trigger("mokaZoomChanged");
        return this;
      } else {
        if (this.zhow) {
          return this.zhow;
        } else {
          return this.z;
        }
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
      h = this.layout()[0];
      id = this.currentcell - 1;
      if ((id + 1) % h === 0) {
        cell = this.cells[id + h];
        if (cell && cell.width() - 8 <= this.e.width()) {
          id = cell.data("itemindex");
          how = -this.cellCount();
          if (__indexOf.call(this.o, "r") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.data("itemindex");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusRight = function() {
      var cell, h, how, id;
      h = this.layout()[0];
      id = this.currentcell + 1;
      if (id % h === 0) {
        cell = this.cells[id - h];
        if (cell && cell.width() - 8 <= this.e.width()) {
          id = cell.data("itemindex");
          how = this.cellCount();
          if (__indexOf.call(this.o, "r") >= 0) {
            how = -how;
          }
          this.select(Math.min(this.index + id + how, this.length() - 1));
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.data("itemindex");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusUp = function() {
      var cell, h, how, id, len;
      h = this.layout()[0];
      id = this.currentcell - h;
      if (id < 0) {
        len = this.cellCount();
        cell = this.cells[id + len];
        if (cell && cell.height() - 8 <= this.e.height()) {
          id = cell.data("itemindex");
          how = -this.cellCount();
          if (__indexOf.call(this.o, "b") >= 0) {
            how = -how;
          }
          this.select(this.index + id + how);
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.data("itemindex");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.focusDown = function() {
      var cell, h, how, id, len;
      h = this.layout()[0];
      len = this.cellCount();
      id = this.currentcell + h;
      if (id >= len) {
        cell = this.cells[id - len];
        if (cell && cell.height() - 8 <= this.e.height()) {
          id = cell.data("itemindex");
          how = this.cellCount();
          if (__indexOf.call(this.o, "b") >= 0) {
            how = -how;
          }
          this.select(Math.min(this.index + id + how, this.length() - 1));
        }
      } else {
        cell = this.cells[id];
        if (cell) {
          id = cell.data("itemindex");
          this.select(this.index + id);
        }
      }
      return this;
    };
    Viewer.prototype.appendRow = function() {
      return $("<tr>", {
        "class": "moka-row"
      }).height(this.e.height).appendTo(this.table);
    };
    Viewer.prototype.appendCell = function(row) {
      var cell, id, td;
      td = $("<td>").appendTo(row);
      cell = new Moka.Input().e;
      id = this.cellCount();
      cell.data("moka-cell-id", id);
      cell.css({
        "overflow": "hidden"
      });
      cell.addClass("moka-view").bind("mokaFocused", __bind(function(ev) {
        var _ref;
        if (this.currentcell === id && this.currentindex === this.index + id) {
          return;
        }
        if (ev.target === cell[0] && Moka.focusFirst(cell.children())) {
          return;
        }
        if ((_ref = this.cells[this.currentcell]) != null) {
          _ref.removeClass("moka-current").trigger("mokaDeselected", [this.index + this.current]);
        }
        this.currentindex = this.index + id;
        this.currentcell = id;
        this.current = cell.data("itemindex");
        cell.addClass("moka-current");
        return this.e.trigger("mokaSelected", [this.index + this.current]);
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
      this.table.empty().hide();
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
        ++j;
      }
      return this.table.show();
    };
    Viewer.prototype.layout = function(layout) {
      var i, id, j, x, y;
      if (layout) {
        x = Math.max(0, Number(layout[0]));
        y = Math.max(0, Number(layout[1]));
        if (!((x != null) && (y != null)) || (this.lay && x === this.lay[0] && y === this.lay[1])) {
          return this;
        }
        this.clear();
        if (this.lay) {
          this.e.removeClass("moka-layout-" + this.lay.join("x"));
        }
        this.lay = [x, y];
        this.e.addClass("moka-layout-" + this.lay.join("x"));
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
          i = Math.ceil(this.length() / j);
        } else if (j <= 0) {
          j = Math.ceil(this.length() / i);
        }
        return [i, j];
      }
    };
    Viewer.prototype.orientation = function(o) {
      var a, b, fns, x;
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
        dbg("setting orientation", o);
        fns = {
          lt: function(id, x, y) {
            return id;
          },
          rt: function(id, x, y) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return x - 1 - i + j * x;
          },
          lb: function(id, x, y) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return x * y - x + i - j * x;
          },
          rb: function(id, x, y) {
            var i, j;
            i = id % x;
            j = Math.floor(id / x);
            return x * y - 1 - i - j * x;
          },
          tl: function(id, x, y) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return i * x + j;
          },
          tr: function(id, x, y) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return x * y - 1 - (y - 1 - i) * x - j;
          },
          bl: function(id, x, y) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return (y - 1 - i) * x + j;
          },
          br: function(id, x, y) {
            var i, j;
            i = id % y;
            j = Math.floor(id / y);
            return x * y - 1 - i * x - j;
          }
        };
        this.indexfn = __bind(function(id) {
          var y;
          x = this.lay[0];
          y = this.lay[1];
          return fns[this.o].apply(this, [id, x, y]);
        }, this);
        this.view(this.index);
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
    Viewer.prototype.updateVisible = function(now) {
      var current_item, p, topreload, updateItems;
      if (!now) {
        if (this.t_update) {
          window.clearTimeout(this.t_update);
        }
        this.t_update = window.setTimeout(this.updateVisible.bind(this, true), 100);
        return;
      }
      p = this.cell(0).parent();
      topreload = 2;
      if (this.current >= 0) {
        current_item = this.at(this.index + this.current).e;
      }
      updateItems = __bind(function(index, direction) {
        var cell, d, h, item, loaded, next, pos, w, wndbottom, wndleft, wndright, wndtop;
        loaded = __bind(function() {
          var c, col, i, id, max, row, x;
          if (cell) {
            dbg("view", index, "loaded");
            id = cell.data("moka-cell-id");
            x = this.layout()[0];
            col = id % x;
            row = Math.floor(id / x);
            i = row * x;
            max = i + x;
            while (i < max && (c = this.cells[i])) {
              c.height("auto");
              ++i;
            }
            i = col;
            while (c = this.cells[i]) {
              c.width("auto");
              i += x;
            }
          } else {
            dbg("view", index, "preloaded");
            item.hide();
          }
          if (typeof item.zoom === "function") {
            item.zoom(this.z, this.zhow);
          }
          return next();
        }, this);
        next = updateItems.bind(this, index + direction, direction);
        cell = this.cell(index - this.index);
        item = this.at(index);
        if (!cell && item && topreload > 0) {
          --topreload;
          dbg("preloading view", index);
          item.e.one("mokaDone", loaded);
          item.show();
          return;
        }
        if (!item || !cell) {
          if (this.current >= 0 && !Moka.scrolling) {
            this.select(this.index + this.current);
          }
          dbg("updateItems finished for direction", direction);
          if (direction > 0) {
            updateItems.call(this, this.index + this.current - direction, -direction);
          }
          return;
        }
        if (item.e.is(":visible")) {
          return next();
        }
        w = p.width();
        h = p.height();
        pos = cell.parent().offset();
        d = this.preload_offset;
        wndleft = pos.left;
        wndtop = pos.top;
        wndright = wndleft + this.e.width();
        wndbottom = wndtop + this.e.height();
        if (pos.left + w + d < wndleft || pos.left - d > wndright || pos.top + h + d < wndtop || pos.top - d > wndbottom) {
          item.hide();
          return next();
        }
        dbg("loading view", index);
        item.e.one("mokaDone", loaded);
        return item.show();
      }, this);
      if (this.current >= 0) {
        return updateItems(this.index + this.current, 1);
      } else {
        return updateItems(this.index, 1);
      }
    };
    Viewer.prototype.onScroll = function(ev) {
      var lay;
      lay = this.layout();
      if (lay[0] !== 1 || lay[1] !== 1) {
        return this.updateVisible();
      }
    };
    Viewer.prototype.mousedown = function(ev) {
      if (ev.button === 0) {
        dragScroll(ev);
      }
      if (ev.button === 1) {
        if (this.zhow === "fit") {
          return this.zoom(1);
        } else {
          return this.zoom("fit");
        }
      }
    };
    Viewer.prototype.dblclick = function() {
      var lay, z;
      if (this.oldlay) {
        lay = this.oldlay;
        z = this.oldzoom;
      } else {
        lay = [1, 1];
        z = 1;
      }
      this.oldlay = this.layout();
      this.oldzoom = this.zhow;
      if (lay[0] === this.oldlay[0] && lay[1] === this.oldlay[1] && z === this.oldzoom) {
        lay = [1, 1];
        z = 1;
      }
      this.zoom(z);
      return this.layout(lay);
    };
    return Viewer;
  })();
  Moka.Notification = (function() {
    __extends(Notification, Moka.Widget);
    function Notification(html, notification_class, delay, animation_speed) {
      this.animation_speed = animation_speed;
      Notification.__super__.constructor.apply(this, arguments);
      if (!(Moka.notificationLayer != null)) {
        Moka.notificationLayer = $("<div>", {
          id: "moka-notification-layer"
        }).appendTo("body");
      }
      if (!(delay != null)) {
        delay = 8000;
      }
      if (!(this.animation_speed != null)) {
        this.animation_speed = 1000;
      }
      this.e.addClass("moka-notification " + notification_class).hide().html(html).bind("mouseenter.moka", __bind(function() {
        return window.clearTimeout(this.t_notify);
      }, this)).bind("mouseleave.moka", __bind(function() {
        return this.t_notify = window.setTimeout(this.remove.bind(this), delay / 2);
      }, this)).appendTo(Moka.notificationLayer).fadeIn(this.animation_speed);
      this.t_notify = window.setTimeout(this.remove.bind(this), delay);
    }
    Notification.prototype.remove = function() {
      window.clearTimeout(this.t_notify);
      return this.e.hide(this.animation_speed, Notification.__super__.remove.apply(this, arguments));
    };
    return Notification;
  })();
  Moka.clearNotifications = function() {
    var _ref;
    return (_ref = Moka.notificationLayer) != null ? _ref.empty() : void 0;
  };
  Moka.Window = (function() {
    __extends(Window, Moka.Input);
    Window.prototype.default_keys = {
      ESCAPE: function() {
        return this.close();
      },
      F4: function() {
        return this.close();
      },
      F2: function() {
        return this.title["do"](Moka.focus);
      },
      F3: function() {
        var e, edit, last_focused, pos, w, wnd;
        last_focused = focused_widget;
        wnd = new Moka.Window("Search");
        w = new Moka.LineEdit("Find string:");
        e = w.e;
        edit = w.edit;
        edit.blur(function() {
          return wnd.close();
        });
        wnd.addKey("ESCAPE", function() {
          Moka.focus(last_focused);
          return wnd.close();
        });
        wnd.addKey("ENTER", __bind(function() {
          var tofocus;
          tofocus = Moka.findInput(this.e, edit.attr("value"));
          Moka.focus(tofocus ? tofocus : last_focused);
          return wnd.close();
        }, this));
        pos = this.position();
        return wnd.append(w).appendTo(this.e.parent()).position(pos.left, pos.top).show().focus();
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
      },
      TAB: function() {
        return this.focus();
      }
    };
    function Window(title) {
      var body, e, edge, edges, s, self;
      Window.__super__.constructor.apply(this, arguments);
      self = this;
      this.e.addClass("moka-window").attr("tabindex", 1).hide().bind("mokaFocusUpRequest", __bind(function() {
        this.title["do"](Moka.focus);
        return false;
      }, this)).bind("mokaFocused", __bind(function() {
        var cls;
        cls = "moka-top_window";
        this.e.parent().children("." + cls).removeClass(cls);
        return this.e.addClass("moka-top_window");
      }, this));
      e = this.container = $("<div>").css({
        width: "100%",
        height: "100%"
      }).appendTo(this.e);
      $(window).bind("resize.moka", this.update.bind(this));
      this.title = new Moka.Input();
      this.title.keydown = this.keyDownTitle.bind(this);
      this.title.e.addClass("moka-title").appendTo(e);
      $("<div>", {
        'class': "moka-window-button moka-close"
      }).css('cursor', "pointer").click(this.close.bind(this)).appendTo(this.title.e);
      $("<div>", {
        'class': "moka-window-button moka-maximize"
      }).css('cursor', "pointer").click(this.maximize.bind(this)).appendTo(this.title.e);
      Moka.createLabel(title).appendTo(this.title.e);
      this.body = body = $("<div>", {
        "class": "moka-body"
      }).bind("scroll.moka", this.update.bind(this)).appendTo(e);
      this.title.dblclick = function() {
        body.toggle();
        Moka.focusFirst(body);
        return false;
      };
      this.title.mousedown = __bind(function(ev) {
        this.focus();
        return ev.preventDefault();
      }, this);
      edges = {
        'moka-n': [1, 1, 0, 1, 0, 1, "n"],
        'moka-e': [1, 1, 1, 0, 1, 0, "e"],
        'moka-s': [0, 1, 1, 1, 0, 1, "s"],
        'moka-w': [1, 0, 1, 1, 1, 0, "w"],
        'moka-n moka-e': [1, 1, 0, 0, 1, 1, "ne"],
        'moka-s moka-e': [0, 1, 1, 0, 1, 1, "se"],
        'moka-s moka-w': [0, 0, 1, 1, 1, 1, "sw"],
        'moka-n moka-w': [1, 0, 0, 1, 1, 1, "nw"]
      };
      for (edge in edges) {
        s = edges[edge];
        $("<div>", {
          "class": "moka-edge " + edge
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
            if ($this.hasClass("moka-n")) {
              body.height(body.height() - dy);
              pos.top += dy;
            }
            if ($this.hasClass("moka-e")) {
              body.width(body.width() + dx);
            }
            if ($this.hasClass("moka-s")) {
              body.height(body.height() + dy);
            }
            if ($this.hasClass("moka-w")) {
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
    Window.prototype.append = function(widgets) {
      var widget, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        widget = arguments[_i];
        widget.parentWidget = this;
        widget.e.appendTo(this.body);
        this.widgets.push(widget);
      }
      this.update();
      return this;
    };
    Window.prototype.center = function() {
      this.e.offset({
        left: (this.e.parent().width() - this.e.width()) / 2,
        top: (this.e.parent().height() - this.e.height()) / 2
      });
      return this;
    };
    Window.prototype.focus = function() {
      Moka.focus(this.title);
      Moka.focusFirst(this.body);
      return this;
    };
    Window.prototype.position = function(x, y) {
      var pos;
      if (x != null) {
        pos = this.e.parent().offset();
        if (pos) {
          this.e.offset({
            left: pos.left + x,
            top: pos.top + y
          });
        }
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
    Window.prototype.align = function(alignment) {
      this.body.css("text-align", alignment);
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
      wnds = this.e.siblings(".moka-window");
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
      return Moka.focus(e.find(".moka-title:first"));
    };
    Window.prototype.close = function() {
      return this.remove();
    };
    Window.prototype.keydown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (keyHintFocus(keyname, this.body)) {
        return false;
      }
    };
    Window.prototype.keyDownTitle = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_title_keys, this)) {
        return false;
      }
    };
    return Window;
  })();
  elementToWidget = function(e) {
    var h, label, m, onclick, src, title, tooltip, w;
    w = null;
    if (e.hasClass("moka-window")) {
      title = e.children(".moka-title").html() || "untitled";
      w = new Moka.Window(title);
      e.children().each(function() {
        var ww;
        ww = elementToWidget($(this));
        if (ww) {
          return w.append(ww);
        }
      });
    } else if (e.hasClass("moka-button")) {
      onclick = e[0].onclick;
      tooltip = e.attr("title");
      label = e.html() || "";
      w = new Moka.Button(label, onclick, tooltip);
    } else if (e.hasClass("moka-label")) {
      label = e.html() || "";
      w = new Moka.Label(label);
    } else if (e.hasClass("moka-image")) {
      src = e.text().trim() || "";
      m = e.attr("class").match(/\bmoka-size-([0-9]*)x([0-9]*)\b/);
      w = m ? m[1] : "";
      h = m ? m[2] : "";
      w = new Moka.Image(src, w, h);
    } else if (e.hasClass("moka-container")) {
      w = new Moka.Container().vertical(e.hasClass("moka-vertical"));
      e.children().each(function() {
        var ww;
        ww = elementToWidget($(this));
        if (ww) {
          return w.append(ww);
        }
      });
    } else if (e.hasClass("moka-widgetlist")) {
      w = new Moka.WidgetList().vertical(e.hasClass("moka-vertical"));
      e.children().each(function() {
        var ww;
        ww = elementToWidget($(this));
        if (ww) {
          return w.append(ww);
        }
      });
    } else if (e.hasClass("moka-buttonbox")) {
      w = new Moka.ButtonBox().vertical(e.hasClass("moka-vertical"));
      e.children().each(function() {
        onclick = this.onclick;
        tooltip = this.title;
        label = $(this).html() || "";
        return w.append(label, onclick, tooltip);
      });
    }
    if (w != null) {
      w["do"](function(we) {
        var attr;
        we.addClass(e.attr("class"));
        attr = e.attr("id");
        if (attr) {
          we.attr("id", attr);
        }
        attr = e.attr("style");
        if (attr) {
          return we.attr("style", attr);
        }
      });
      e.children(".moka-keys").each(function() {
        return $(this).children().each(function() {
          var fn, key;
          key = $(this).text();
          fn = this.onclick;
          return w.addKey(key, fn);
        });
      });
    }
    return w;
  };
  mokaInit = function() {
    return $("body").find(".moka-window").each(function() {
      var $this, w;
      $this = $(this);
      w = elementToWidget($(this));
      if (w) {
        w.appendTo($this.parent()).show();
        return $this.remove();
      }
    });
  };
  $(document).ready(mokaInit);
}).call(this);
