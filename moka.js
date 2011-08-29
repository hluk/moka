(function() {
  var dbg, elementToWidget, keycodes, last_keyname, last_keyname_timestamp, log, logfn, logobj, mokaInit, tt;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  window.Moka = {};
  if (!Function.prototype.bind) {
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
  }
  ((logobj = window.console) && (logfn = logobj.log)) || ((logobj = window.opera) && (logfn = logobj.postError));
  log = logfn ? logfn.bind(logobj) : function() {};
  dbg = log.bind(this, "DEBUG:");
  keycodes = {
    8: "BACKSPACE",
    9: "TAB",
    13: "ENTER",
    27: "ESCAPE",
    32: "SPACE",
    37: "LEFT",
    38: "UP",
    39: "RIGHT",
    40: "DOWN",
    45: "INSERT",
    46: "DELETE",
    33: "PAGEUP",
    34: "PAGEDOWN",
    35: "END",
    36: "HOME",
    96: "KP0",
    97: "KP1",
    98: "KP2",
    99: "KP3",
    100: "KP4",
    101: "KP5",
    102: "KP6",
    103: "KP7",
    104: "KP8",
    105: "KP9",
    106: "*",
    107: "+",
    109: "MINUS",
    110: ".",
    111: "/",
    112: "F1",
    113: "F2",
    114: "F3",
    115: "F4",
    116: "F5",
    117: "F6",
    118: "F7",
    119: "F8",
    120: "F9",
    121: "F10",
    122: "F11",
    123: "F12",
    191: "?"
  };
  Moka.normalizeKeyName = function(keyname) {
    var k, key, modifiers;
    modifiers = keyname.toUpperCase().split("-");
    key = modifiers.pop();
    modifiers = modifiers.map(function(x) {
      return x[0];
    }).sort();
    k = modifiers.length ? modifiers.join("-") + "-" + key : key;
    return k;
  };
  last_keyname = last_keyname_timestamp = null;
  Moka.getKeyName = function(ev) {
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
  Moka.keyHintFocus = function(keyname, root) {
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
        text = text.substr(0, i) + '<span class="moka-keyhint"' + ' onclick="this.parentNode.click(event)">' + key + '</span>' + text.substr(i + 2);
      }
      e.html(text);
    }
    e.css("cursor", "pointer");
    return e;
  };
  Moka.findInput = function(e, str, next) {
    var find, first, prev_found, query, res;
    if (!str) {
      return null;
    }
    prev_found = !next;
    first = null;
    query = str.toUpperCase();
    res = null;
    find = function() {
      var $this;
      $this = $(this);
      if ($this.text().toUpperCase().search(query) >= 0) {
        res = $this.closest(".moka-input");
        if (!first) {
          first = res;
        }
        if (!prev_found) {
          prev_found = res.hasClass("moka-found");
          res = null;
          return;
        }
        return false;
      }
    };
    e.find(".moka-input.moka-label:visible, .moka-input > .moka-label:visible").each(find);
    return res || first;
  };
  Moka.initDraggable = function(e, handle_e) {
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
  Moka.initDragScroll = function(e) {
    e.bind("mousedown.moka.initdragscroll", function(ev) {
      if (ev.button === 0) {
        return Moka.dragScroll(ev);
      }
    });
    return e;
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
  Moka.dragScroll = function(ev) {
    var continueDragScroll, dt, dx, dy, from_mouseX, from_mouseY, mouseX, mouseY, pos, start, stop, stopDragScroll, t, w, wnd;
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
        Moka.focus($(ev.target).parents(".moka-input:first"));
        return;
      }
      t = ev.timeStamp;
      dt = t - start;
      if ((0 < dt && dt < 90) && (dx !== 0 || dy !== 0)) {
        accel = 200 / dt;
        vx = dx * accel;
        vy = dy * accel;
        tt = 100;
        w.stop(true).animate({
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
    $(window).one("mouseup.moka.dragscroll", stopDragScroll).one("mousemove.moka.dragscroll", continueDragScroll);
    return ev.preventDefault();
  };
  Moka.focused_e = null;
  Moka.focused = function(e) {
    var ee;
    if (e != null) {
      ee = Moka.focused_e;
      if (ee) {
        if (ee[0] === e[0]) {
          return e;
        }
        Moka.unfocused();
      }
      Moka.focused_e = e;
      e.addClass("moka-focus").trigger("mokaFocused");
      return e;
    }
    return Moka.focused_e;
  };
  Moka.unfocused = function() {
    var e;
    e = Moka.focused_e;
    if (e) {
      e.removeClass("moka-focus").trigger("mokaBlurred");
      return Moka.focused_e = null;
    }
  };
  Moka.focus = function(e, o) {
    var ee, eee;
    ee = Moka.focused_e;
    eee = e[0];
    if (ee && ee[0] === eee) {
      return;
    }
    Moka.toScreen(e, null, o);
    return eee.focus();
  };
  Moka.blur = function(e) {
    return e.blur();
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
  Moka.focusFirst = function(e, o) {
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
      Moka.focus(ee, o);
      return true;
    } else {
      return false;
    }
  };
  Moka.onScreen = function(e, how) {
    var d, pos, wnd, _ref, _ref2, _ref3, _ref4;
    if (!how) {
      return (Moka.onScreen(e, 'r') || Moka.onScreen(e, 'l')) && (Moka.onScreen(e, 't') || Moka.onScreen(e, 'b'));
    }
    pos = e.offset();
    wnd = $(window);
    d = 8;
    switch (how[0]) {
      case 'b':
        return (-d < (_ref = pos.top + e.height()) && _ref < wnd.height() + d);
      case 't':
        return (-d < (_ref2 = pos.top) && _ref2 < wnd.height() + d);
      case 'r':
        return (-d < (_ref3 = pos.left + e.width()) && _ref3 < wnd.width() + d);
      case 'l':
        return (-d < (_ref4 = pos.left) && _ref4 < wnd.width() + d);
    }
  };
  Moka.toScreen = function(e, wnd, o) {
    var a, b, ca, cb, ch, cleft, cpos, ctop, cw, h, left, pos, top, w;
    if (!o) {
      o = "lt";
    }
    if (!wnd) {
      wnd = e.parent();
      while (wnd.outerWidth() === wnd[0].scrollWidth && wnd.outerHeight() === wnd[0].scrollHeight) {
        if (wnd[0].nodeName === "BODY") {
          return;
        }
        wnd = wnd.parent();
      }
    }
    if (!wnd.length || wnd[0] === e[0]) {
      return;
    }
    pos = wnd.offset();
    w = wnd.width();
    h = wnd.height();
    left = wnd.scrollLeft();
    top = wnd.scrollTop();
    cpos = e.offset();
    cw = e.width();
    ch = e.height();
    cleft = cpos.left - pos.left;
    ctop = cpos.top - pos.top;
    a = left;
    b = a + w;
    ca = cleft + a;
    cb = ca + cw;
    if (__indexOf.call(o, 'l') >= 0) {
      if (ca < a) {
        left = ca;
      } else if (cb > b) {
        if (cw > w) {
          left = ca;
        } else {
          left = cb - w;
        }
      }
    } else if (__indexOf.call(o, 'r') >= 0) {
      if (cb > b) {
        left = cb - w;
      } else if (ca < a) {
        if (cw > w) {
          left = cb - w;
        } else {
          left = ca;
        }
      }
    }
    a = top;
    b = a + h;
    ca = ctop + a;
    cb = ca + ch;
    if (__indexOf.call(o, 't') >= 0) {
      if (ca < a) {
        top = ca;
      } else if (cb > b) {
        if (ch > h) {
          top = ca;
        } else {
          top = cb - h;
        }
      }
    } else if (__indexOf.call(o, 'b') >= 0) {
      if (cb > b) {
        top = cb - h;
      } else if (ca < a) {
        if (ch > h) {
          top = cb - h;
        } else {
          top = ca;
        }
      }
    }
    return Moka.scroll(wnd, {
      left: left,
      top: top,
      animate: true
    });
  };
  Moka.scroll = function(e, opts) {
    var a, duration, l, t;
    l = opts.left;
    t = opts.top;
    a = {};
    if (l) {
      a.scrollLeft = l + (opts.relative ? e.scrollLeft() : 0);
    }
    if (t) {
      a.scrollTop = t + (opts.relative ? e.scrollTop() : 0);
    }
    if (opts.animate) {
      l = l || 0;
      t = t || 0;
      duration = Math.min(1500, Math.sqrt(l * l + t * t) * (opts.speed || 1));
      return e.stop(true).animate(a, duration, opts.easing, opts.complete);
    } else {
      e.stop(true, true);
      if (l && t) {
        return e.scrollLeft(a.scrollLeft).scrollTop(a.scrollTop);
      } else if (l) {
        return e.scrollLeft(a.scrollLeft);
      } else if (t) {
        return e.scrollTop(a.scrollTop);
      }
    }
  };
  Moka.ensureVisible = function(e, wnd) {
    return toScreen(e, wnd);
  };
  Moka.doKey = function(keyname, keys, default_keys, object) {
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
  Moka.Widget = (function() {
    Widget.prototype.mainclass = "moka-widget";
    function Widget(from_element) {
      if (from_element instanceof $) {
        this.e = from_element;
      } else {
        this.e = $("<div>");
      }
      this.addClass(this.mainclass);
      this.bind("mokaFocused", this.addClass.bind(this, "moka-focus"));
      this.bind("mokaBlurred", this.removeClass.bind(this, "moka-focus"));
    }
    Widget.prototype.mainClass = function(cls) {
      if (cls != null) {
        this.removeClass(this.mainclass);
        this.mainclass = cls;
        this.addClass(cls);
        return this;
      } else {
        return this.mainclass;
      }
    };
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
    Widget.prototype.toggle = function() {
      if (this.isVisible()) {
        this.hide();
      } else {
        this.show();
      }
      return this;
    };
    Widget.prototype.isVisible = function() {
      return this.e.is(":visible");
    };
    Widget.prototype.update = function() {
      return this;
    };
    Widget.prototype.isLoaded = function() {
      return true;
    };
    Widget.prototype.appendTo = function(w_or_e) {
      if (w_or_e instanceof Moka.Widget && w_or_e.append) {
        w_or_e.append(this);
      } else {
        this.e.appendTo(w_or_e);
      }
      return this;
    };
    Widget.prototype.remove = function() {
      this.e.hide();
      this.e.trigger("mokaDestroyed");
      return this.e.remove();
    };
    Widget.prototype.parent = function() {
      return this.parentWidget;
    };
    Widget.prototype.addKey = function(keyname, fn) {
      if (!this.keys) {
        this.keys = {};
      }
      this.keys[Moka.normalizeKeyName(keyname)] = fn;
      return this;
    };
    Widget.prototype.connect = function(event, fn) {
      this.e.bind(event, __bind(function(ev) {
        if (ev.target === this.e[0]) {
          return fn.apply(this, arguments);
        }
      }, this));
      return this;
    };
    Widget.prototype.unbind = function(event) {
      this.e.unbind(event);
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
    Widget.prototype.offset = function(x, y) {
      if (x != null) {
        this.e.offset(x, y);
        return this;
      } else {
        return this.e.offset();
      }
    };
    Widget.prototype.hasFocus = function() {
      return this.e.hasClass("moka-focus");
    };
    Widget.prototype.addClass = function(cls) {
      this.e.addClass(cls);
      return this;
    };
    Widget.prototype.removeClass = function(cls) {
      this.e.removeClass(cls);
      return this;
    };
    Widget.prototype.trigger = function(event, data) {
      this.e.trigger(event, data);
      return this;
    };
    Widget.prototype.outerWidth = function(include_margin) {
      return this.e.outerWidth(include_margin);
    };
    Widget.prototype.outerHeight = function(include_margin) {
      return this.e.outerHeight(include_margin);
    };
    Widget.prototype.align = function(alignment) {
      this.e.css("text-align", alignment);
      return this;
    };
    Widget.prototype.tooltip = function(tooltip_text) {
      return this.e.attr("title", tooltip_text);
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
    Label.prototype.mainclass = "moka-label " + Moka.Widget.prototype.mainclass;
    function Label(text) {
      this.text = text;
      Label.__super__.constructor.call(this, Moka.createLabel(this.text));
    }
    return Label;
  })();
  Moka.Input = (function() {
    __extends(Input, Moka.Widget);
    Input.prototype.mainclass = "moka-input " + Moka.Widget.prototype.mainclass;
    function Input() {
      var e;
      Input.__super__.constructor.apply(this, arguments);
      this.bind("mokaFocused", this.onChildFocus.bind(this));
      this.bind("mokaBlurred", this.onChildBlur.bind(this));
      e = this.e.css("cursor", "pointer").bind("keydown.moka", __bind(function(ev) {
        return this.onKeyDown(ev);
      }, this));
      this.bind("focus.moka", __bind(function(ev) {
        this.onFocus(ev);
        return false;
      }, this));
      this.bind("blur.moka", __bind(function(ev) {
        this.onBlur(ev);
        return false;
      }, this));
      this.e_focus = this.e;
      this.tabindex(1);
      this.focusableElement(e);
    }
    Input.prototype.focusableElement = function(e) {
      var ee, tabindex;
      if (e != null) {
        ee = this.e_focus;
        tabindex = this.tabindex();
        this.other_focusable = this.e[0] !== e[0];
        this.e_focus = e;
        this.tabindex(tabindex);
        return this;
      } else {
        return this.e_focus;
      }
    };
    Input.prototype.addNotFocusableElement = function(e) {
      e.bind("mokaFocused.notfocusable", this.focus.bind(this));
      if (e.is(":focus")) {
        this.focus();
      }
      return this;
    };
    Input.prototype.removeNotFocusableElement = function(e) {
      e.unbind("mokaFocused.notfocusable");
      return this;
    };
    Input.prototype.onChildFocus = function(ev) {
      if (!Moka.focused()) {
        this.focus();
        return false;
      }
    };
    Input.prototype.onChildBlur = function(ev) {};
    Input.prototype.tabindex = function(index) {
      if (index != null) {
        if (this.other_focusable) {
          this.e.attr("tabindex", -1);
        }
        this.e_focus.attr("tabindex", index);
        return this;
      } else {
        return this.e_focus.attr("tabindex", index);
      }
    };
    Input.prototype.focus = function() {
      Moka.focus(this.e_focus);
      return this;
    };
    Input.prototype.blur = function() {
      Moka.unfocused();
      return this;
    };
    Input.prototype.remove = function() {
      var ee, v;
      ee = this.e.parent();
      v = Input.__super__.remove.apply(this, arguments);
      if (this.hasFocus()) {
        Moka.blur(Moka.focused_e);
        while (ee.length) {
          if (Moka.focusFirst(ee)) {
            break;
          }
          ee = ee.parent();
        }
      }
      return v;
    };
    Input.prototype.change = function(fn) {
      return this.e.bind("mokaValueChanged", fn);
    };
    Input.prototype.onFocus = function(ev) {
      if (this.other_focusable) {
        return Moka.focus(this.e_focus);
      } else {
        return Moka.focused(this.e_focus);
      }
    };
    Input.prototype.onBlur = function(ev) {
      Moka.unfocused();
    };
    Input.prototype.onKeyDown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (Moka.keyHintFocus(keyname, this.e)) {
        return false;
      }
    };
    return Input;
  })();
  Moka.Container = (function() {
    __extends(Container, Moka.Widget);
    Container.prototype.mainclass = "moka-container " + Moka.Widget.prototype.mainclass;
    Container.prototype.itemclass = "moka-container-item";
    function Container(horizontal) {
      Container.__super__.constructor.apply(this, arguments);
      this.vertical(horizontal != null ? !horizontal : true);
      this.widgets = [];
    }
    Container.prototype.itemClass = function(cls) {
      var oldcls, w;
      if (cls != null) {
        w = this.widgets;
        oldcls = this.itemclass;
        $.each(w, function(i) {
          return w[i].removeClass(oldcls).addClass(cls);
        });
        this.itemclass = cls;
        return this;
      } else {
        return this.itemclass;
      }
    };
    Container.prototype.update = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        return w[i].update();
      });
      return this;
    };
    Container.prototype.remove = function() {
      var w;
      this.e.hide();
      w = this.widgets;
      if (w) {
        $.each(w, function(i) {
          var _base;
          return typeof (_base = w[i]).remove === "function" ? _base.remove() : void 0;
        });
      }
      return Container.__super__.remove.apply(this, arguments);
    };
    Container.prototype.at = function(index) {
      return this.widgets[index];
    };
    Container.prototype.length = function() {
      return this.widgets.length;
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
      var id, widget, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        widget = arguments[_i];
        id = this.length();
        widget.parentWidget = this;
        this.widgets.push(widget);
        if (id === 0) {
          widget.addClass("moka-first");
        } else {
          this.at(id - 1).removeClass("moka-last");
        }
        widget.addClass(this.itemclass + " moka-last");
        widget.appendTo(this.e).bind("mokaSizeChanged", this.update.bind(this));
      }
      this.update();
      return this;
    };
    return Container;
  })();
  Moka.WidgetList = (function() {
    __extends(WidgetList, Moka.Input);
    WidgetList.prototype.mainclass = "moka-widgetlist " + Moka.Input.prototype.mainclass;
    WidgetList.prototype.itemclass = "moka-widgetlist-item";
    WidgetList.prototype.default_keys = {
      LEFT: function() {
        if (this.vertical()) {
          return false;
        } else {
          return this.prev();
        }
      },
      RIGHT: function() {
        if (this.vertical()) {
          return false;
        } else {
          return this.next();
        }
      },
      UP: function() {
        if (this.vertical()) {
          return this.prev();
        } else {
          return false;
        }
      },
      DOWN: function() {
        if (this.vertical()) {
          return this.next();
        } else {
          return false;
        }
      }
    };
    function WidgetList() {
      WidgetList.__super__.constructor.apply(this, arguments);
      this.tabindex(-1).bind("mokaFocusUpRequest", __bind(function() {
        this.select(Math.max(0, this.current));
        return false;
      }, this)).bind("mokaFocusNextRequest", __bind(function() {
        this.next();
        return false;
      }, this)).bind("mokaFocusPrevRequest", __bind(function() {
        this.prev();
        return false;
      }, this));
      this.c = new Moka.Container(false).addClass(this.mainclass.split(" ")[0] + "-container").itemClass(this.itemclass).appendTo(this.e);
      this.current = -1;
      this.widgets = [this.c];
    }
    WidgetList.prototype.mainClass = function(cls) {
      if (cls != null) {
        this.c.removeClass(this.mainclass.split(" ")[0] + "-container");
        this.c.addClass(cls.split(" ")[0] + "-container");
      }
      return WidgetList.__super__.mainClass.apply(this, arguments);
    };
    WidgetList.prototype.itemClass = function(cls) {
      if (cls != null) {
        this.c.itemClass(cls);
        return this.itemclass = cls;
      } else {
        return this.itemclass;
      }
    };
    WidgetList.prototype.length = function() {
      return this.c.length();
    };
    WidgetList.prototype.vertical = function(toggle) {
      if (toggle != null) {
        this.c.vertical(toggle);
        return this;
      } else {
        return this.c.vertical();
      }
    };
    WidgetList.prototype.at = function(index) {
      return this.c.at(index);
    };
    WidgetList.prototype.append = function(widgets) {
      var bindfocus, e, id, widget, _i, _len;
      bindfocus = __bind(function(widget, id) {
        return widget.bind("mokaFocused", __bind(function() {
          if (this.current >= 0) {
            this.c.at(this.current).removeClass("moka-current").trigger("mokaDeselected", [this.current]);
          }
          this.current = id;
          widget.addClass("moka-current").trigger("mokaSelected", [id]);
          return this.update();
        }, this));
      }, this);
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        widget = arguments[_i];
        id = this.length();
        e = widget.e;
        widget.parentWidget = this;
        this.c.append(widget);
        bindfocus(widget, id);
      }
      if (this.current < 0) {
        this.current = 0;
      }
      return this;
    };
    WidgetList.prototype.select = function(id) {
      var w;
      if (id >= 0) {
        w = this.at(id);
        if (w) {
          Moka.focusFirstWidget(w);
        }
      }
      return this;
    };
    WidgetList.prototype.next = function() {
      return this.select(this.current >= 0 && this.current < this.length() - 1 ? this.current + 1 : 0);
    };
    WidgetList.prototype.prev = function() {
      var l;
      l = this.length();
      return this.select(this.current >= 1 && this.current < l ? this.current - 1 : l - 1);
    };
    WidgetList.prototype.focus = function() {
      this.select(this.current);
      return this;
    };
    WidgetList.prototype.onFocus = function() {
      return this.focus();
    };
    return WidgetList;
  })();
  Moka.CheckBox = (function() {
    __extends(CheckBox, Moka.Input);
    CheckBox.prototype.mainclass = "moka-checkbox " + Moka.Input.prototype.mainclass;
    CheckBox.prototype.default_keys = {
      SPACE: function() {
        return this.toggle();
      }
    };
    function CheckBox(text, checked) {
      CheckBox.__super__.constructor.call(this, Moka.createLabel(text));
      this.checkbox = $('<input>', {
        type: "checkbox",
        "class": "moka-value"
      }).bind("change.moka", __bind(function() {
        return this.e.trigger("mokaValueChanged", [this.value()]);
      }, this)).prependTo(this.e);
      this.connect("click.moka", this.toggle.bind(this));
      this.addNotFocusableElement(this.checkbox);
      this.value(checked);
    }
    CheckBox.prototype.toggle = function() {
      this.value(!this.value());
      return this;
    };
    CheckBox.prototype.remove = function() {
      this.checkbox.remove();
      return CheckBox.__super__.remove.apply(this, arguments);
    };
    CheckBox.prototype.value = function(val) {
      var v;
      if (val != null) {
        v = val ? true : false;
        if (v !== this.checkbox.is(":checked")) {
          this.e.trigger("mokaValueChanged", [v]);
        }
        this.checkbox.attr("checked", v);
        return this;
      } else {
        return this.checkbox.is(":checked");
      }
    };
    CheckBox.prototype.onKeyDown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return CheckBox;
  })();
  Moka.Combo = (function() {
    __extends(Combo, Moka.Input);
    Combo.prototype.mainclass = "moka-combo " + Moka.Input.prototype.mainclass;
    Combo.prototype.default_keys = {
      SPACE: function() {
        return Moka.focus(this.combo);
      }
    };
    function Combo(text) {
      Combo.__super__.constructor.call(this, Moka.createLabel(text));
      this.combo = $('<select>', {
        "class": "moka-value"
      }).bind("change.moka", __bind(function() {
        return this.e.trigger("mokaValueChanged", [this.value()]);
      }, this)).appendTo(this.e);
    }
    Combo.prototype.append = function(texts) {
      var text, _i, _len;
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        text = arguments[_i];
        $("<option>").text(text).attr("value", text).appendTo(this.combo);
      }
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
    Combo.prototype.remove = function() {
      this.combo.remove();
      return Combo.__super__.remove.apply(this, arguments);
    };
    Combo.prototype.onKeyDown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (ev.target === this.e[0] && keyname === "TAB") {
        Moka.focus(this.combo);
        return false;
      } else if (ev.target === this.combo[0]) {
        if (["LEFT", "RIGHT", "UP", "DOWN", "SPACE", "ENTER"].indexOf(keyname) >= 0) {
          return ev.stopPropagation();
        } else if (keyname === "TAB" || keyname === "S-TAB") {
          return this.focus();
        }
      }
    };
    return Combo;
  })();
  Moka.LineEdit = (function() {
    __extends(LineEdit, Moka.Input);
    LineEdit.prototype.mainclass = "moka-lineedit " + Moka.Input.prototype.mainclass;
    LineEdit.prototype.default_keys = {};
    function LineEdit(label_text, text) {
      LineEdit.__super__.constructor.apply(this, arguments);
      if (label_text) {
        Moka.createLabel(label_text, this.e);
      }
      this.edit = $("<input>").appendTo(this.e).bind("change.moka", __bind(function() {
        return this.e.trigger("mokaValueChanged", [this.value()]);
      }, this)).keyup(this.update.bind(this));
      if (text != null) {
        this.value(text);
      }
      this.focusableElement(this.edit);
    }
    LineEdit.prototype.remove = function() {
      Moka.blur(this.edit);
      this.edit.remove();
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
    LineEdit.prototype.onKeyDown = function(ev) {
      var k, keyname;
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
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
    TextEdit.prototype.mainclass = "moka-textedit " + Moka.Input.prototype.mainclass;
    TextEdit.prototype.default_keys = {
      ENTER: function() {
        return Moka.focus(this.editor.win);
      }
    };
    function TextEdit(label_text, text) {
      TextEdit.__super__.constructor.apply(this, arguments);
      Moka.createLabel(label_text, this.e);
      this.text = text || "";
      this.textarea = $("<textarea>").appendTo(this.e).bind("change.moka", __bind(function() {
        return this.e.trigger("mokaValueChanged", [this.value()]);
      }, this));
      this.focusableElement(this.textarea);
    }
    TextEdit.prototype.remove = function() {
      Moka.blur(this.textarea);
      this.textarea.remove();
      return TextEdit.__super__.remove.apply(this, arguments);
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
    TextEdit.prototype.onKeyDown = function(ev) {
      var keyname;
      ev.stopPropagation();
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return TextEdit;
  })();
  Moka.Button = (function() {
    __extends(Button, Moka.Input);
    Button.prototype.mainclass = "moka-button " + Moka.Input.prototype.mainclass;
    Button.prototype.default_keys = {
      ENTER: function() {
        return this.press();
      },
      SPACE: function() {
        return this.press();
      }
    };
    function Button(label_text, onclick, tooltip) {
      Button.__super__.constructor.call(this, Moka.createLabel(label_text));
      this.connect("click.moka", onclick);
      if (tooltip) {
        this.tooltip(tooltip);
      }
    }
    Button.prototype.press = function() {
      this.e.click();
      return this;
    };
    return Button;
  })();
  Moka.ButtonBox = (function() {
    __extends(ButtonBox, Moka.WidgetList);
    ButtonBox.prototype.mainclass = "moka-buttonbox " + Moka.WidgetList.prototype.mainclass;
    ButtonBox.prototype.itemclass = "moka-buttonbox-item";
    function ButtonBox() {
      ButtonBox.__super__.constructor.apply(this, arguments);
      this.vertical(false);
    }
    ButtonBox.prototype.append = function(label_text, onclick, tooltip) {
      var widget;
      widget = new Moka.Button(label_text, onclick, tooltip);
      ButtonBox.__super__.append.call(this, widget);
      this.update();
      return this;
    };
    return ButtonBox;
  })();
  Moka.Tabs = (function() {
    __extends(Tabs, Moka.WidgetList);
    Tabs.prototype.mainclass = "moka-tabs " + Moka.WidgetList.prototype.mainclass;
    Tabs.prototype.itemclass = "moka-tab";
    Tabs.prototype.default_keys = {
      SPACE: function() {
        return this.pages.toggle();
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
      },
      TAB: function() {
        var page;
        if (this.pageHasFocus()) {
          return false;
        }
        page = this.pages.at(this.current);
        if (page) {
          return Moka.focusFirstWidget(page, true);
        } else {
          return false;
        }
      }
    };
    function Tabs() {
      Tabs.__super__.constructor.apply(this, arguments);
      this.tabindex(-1).bind("mokaFocusUpRequest", __bind(function() {
        this.select(Math.max(0, this.current));
        return false;
      }, this));
      this.pages = new Moka.Container().appendTo(this.e);
      this.vertical(false);
    }
    Tabs.prototype.remove = function() {
      this.e.hide();
      this.remove();
      this.pages.remove();
      return Tabs.__super__.remove.apply(this, arguments);
    };
    Tabs.prototype.update = function() {
      var _ref;
      if ((_ref = this.pages.at(this.current)) != null) {
        _ref.update();
      }
      return this;
    };
    Tabs.prototype.pageHasFocus = function() {
      var page;
      page = this.pages.at(this.current);
      return page && page.hasFocus();
    };
    Tabs.prototype.focusUp = function() {
      if (this.pageHasFocus()) {
        this.select(Math.max(0, this.current));
      } else {
        this.e.parent().trigger("mokaFocusUpRequest");
      }
      return this;
    };
    Tabs.prototype.focusDown = function() {
      Moka.focusFirstWidget(this.pages.at(this.current));
      return this;
    };
    Tabs.prototype.append = function(tabname, widget) {
      var tab;
      tab = new Moka.Input();
      Moka.createLabel(tabname, tab.e);
      Tabs.__super__.append.call(this, tab);
      tab.connect("mokaSelected", __bind(function(ev, id) {
        if (this.oldid >= 0) {
          this.pages.at(this.oldid).hide();
          this.at(this.oldid).tabindex(-1);
        }
        this.at(id).tabindex(1);
        this.pages.at(id).show();
        return this.oldid = id;
      }, this));
      tab.tabindex(-1);
      widget.hide().addClass("moka-page");
      this.pages.append(widget);
      this.update();
      return this;
    };
    return Tabs;
  })();
  Moka.Image = (function() {
    __extends(Image, Moka.Widget);
    Image.prototype.mainclass = "moka-image " + Moka.Widget.prototype.mainclass;
    function Image(src, w, h, onload, onerror) {
      this.src = src;
      Image.__super__.constructor.call(this, $("<img>", {
        width: w,
        height: h
      }));
      this.img = this.e;
      this.owidth = this.oheight = 0;
      this.e.one("load", __bind(function() {
        var img;
        this.ok = true;
        img = this.img[0];
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
    Canvas.prototype.mainclass = "moka-canvas " + Moka.Widget.prototype.mainclass;
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
        e.width(0);
        e.height(0);
        Canvas.__super__.constructor.call(this, e);
      } else {
        Canvas.__super__.constructor.call(this, $("<canvas>", {
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
    ImageView.prototype.mainclass = "moka-imageview " + Moka.Input.prototype.mainclass;
    ImageView.prototype.default_keys = {};
    function ImageView(src, use_canvas, sharpen) {
      this.src = src;
      this.use_canvas = use_canvas;
      this.sharpen = sharpen;
      ImageView.__super__.constructor.apply(this, arguments);
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
    ImageView.prototype.remove = function() {
      this.e.hide();
      if (this.image) {
        this.image.remove();
        if (this.t_remove) {
          window.clearTimeout(this.t_remove);
        }
      }
      return ImageView.__super__.remove.apply(this, arguments);
    };
    ImageView.prototype.isLoaded = function() {
      return this.ok === true || this.ok === false;
    };
    ImageView.prototype.originalWidth = function() {
      return this.image.originalWidth();
    };
    ImageView.prototype.originalHeight = function() {
      return this.image.originalHeight();
    };
    ImageView.prototype.zoom = function(how) {
      var d, d2, h, height, mh, mw, w, width, zhow;
      if (how != null) {
        this.z = how;
        zhow = this.zhow = this.z instanceof Array ? this.z[2] : null;
        if (this.ok && this.e.parent().length) {
          width = this.image.width();
          height = this.image.height();
          w = h = mw = mh = "";
          if (how instanceof Array) {
            mw = Math.floor(how[0]);
            mh = Math.floor(how[1]);
            d = mw / mh;
            d2 = width / height;
            if (zhow === "fill") {
              if (d > d2) {
                w = mw;
                h = Math.floor(mw / d2);
              } else {
                h = mh;
                w = Math.floor(mh * d2);
              }
              mw = mh = "";
            } else {
              if (d > d2) {
                h = mh;
                w = Math.floor(mh * d2);
              } else {
                w = mw;
                h = Math.floor(mw / d2);
              }
              mw = mh = "";
            }
          } else {
            this.z = parseFloat(how) || 1;
            mw = Math.floor(this.z * this.image.originalWidth());
            mh = Math.floor(this.z * this.image.originalHeight());
          }
          if (zhow !== "fit" && zhow !== "fill") {
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
          this.e.css({
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
    ImageView.prototype.onKeyDown = function(ev) {
      var keyname;
      if (ev.isPropagationStopped()) {
        return;
      }
      keyname = Moka.getKeyName(ev);
      if (Moka.doKey(keyname, this.keys, this.default_keys, this)) {
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
    Viewer.prototype.mainclass = "moka-viewer " + Moka.Input.prototype.mainclass;
    Viewer.prototype.default_keys = {
      RIGHT: function() {
        return Moka.onScreen(Moka.focused(), 'r') && this.focusRight() || Moka.scroll(this.e, {
          left: 30,
          relative: true
        });
      },
      LEFT: function() {
        return Moka.onScreen(Moka.focused(), 'l') && this.focusLeft() || Moka.scroll(this.e, {
          left: -30,
          relative: true
        });
      },
      UP: function() {
        return Moka.onScreen(Moka.focused(), 't') && this.focusUp() || Moka.scroll(this.e, {
          top: -30,
          relative: true
        });
      },
      DOWN: function() {
        return Moka.onScreen(Moka.focused(), 'b') && this.focusDown() || Moka.scroll(this.e, {
          top: 30,
          relative: true
        });
      },
      KP6: function() {
        if (__indexOf.call(this.orientation(), 'l') >= 0) {
          return this.next();
        } else {
          return this.prev();
        }
      },
      KP4: function() {
        if (__indexOf.call(this.orientation(), 'r') >= 0) {
          return this.next();
        } else {
          return this.prev();
        }
      },
      KP8: function() {
        if (__indexOf.call(this.orientation(), 't') >= 0) {
          return this.next();
        } else {
          return this.prev();
        }
      },
      KP2: function() {
        if (__indexOf.call(this.orientation(), 'b') >= 0) {
          return this.next();
        } else {
          return this.prev();
        }
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
      SPACE: function() {
        var how, opts, val;
        how = this.orientation()[1];
        switch (how) {
          case 't':
            how = 'b';
            break;
          case 'l':
            how = 'r';
            break;
          case 'r':
            how = 'l';
            break;
          default:
            how = 't';
        }
        if (Moka.onScreen(Moka.focused(), how)) {
          return this.next();
        } else {
          opts = {
            relative: true
          };
          val = how === 'l' || how === 't' ? -1 : 1;
          if (how === 'l' || how === 'r') {
            opts.left = val * 0.9 * this.e.parent().width();
          } else {
            opts.top = val * 0.9 * this.e.parent().height();
          }
          return Moka.scroll(this.e, opts);
        }
      },
      'S-SPACE': function() {
        var how, opts, val;
        how = this.orientation()[1];
        if (Moka.onScreen(Moka.focused(), how)) {
          this.prev();
          switch (how) {
            case 't':
              how = 'b';
              break;
            case 'l':
              how = 'r';
              break;
            case 'r':
              how = 'l';
              break;
            default:
              how = 't';
          }
          Moka.toScreen(Moka.focused(), this.e, how);
          return Moka.scroll(this.e, {
            animate: false
          });
        } else {
          opts = {
            relative: true
          };
          val = how === 'l' || how === 't' ? -1 : 1;
          if (how === 'l' || how === 'r') {
            opts.left = val * 0.9 * this.e.parent().width();
          } else {
            opts.top = val * 0.9 * this.e.parent().height();
          }
          return Moka.scroll(this.e, opts);
        }
      },
      ENTER: function() {
        return this.next();
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
      this.css("cursor", "move").tabindex(1).bind("mokaFocusUpRequest", __bind(function() {
        this.select(this.index + this.current);
        return false;
      }, this)).bind("mousedown", this.onMouseDown.bind(this)).bind("dblclick", this.onDoubleClick.bind(this));
      Moka.initDragScroll(this.e);
      $(window).bind("resize.moka", this.update.bind(this));
      this.table = $("<table>", {
        "class": "moka-table",
        border: 0,
        cellSpacing: 0,
        cellPadding: 0
      }).appendTo(this.e);
      this.cells = [];
      this.items = [];
      this.index = -1;
      this.current = -1;
      this.currentcell = -1;
      this.preload_offset = 200;
      this.layout([1, 1]);
      this.orientation("lt");
      this.zoom(1);
    }
    Viewer.prototype.update = function() {
      if (this.hasFocus()) {
        this.focus();
      }
      return this;
    };
    Viewer.prototype.focus = function(ev) {
      var cell;
      cell = this.cells[this.currentcell] || this.cells[0];
      Moka.focusFirst(cell.children(), this.o) || Moka.focus(cell, this.o);
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
      var cell, item, _i, _j, _len, _len2, _ref, _ref2;
      _ref = this.items;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (!(x instanceof Function)) {
          item.remove();
        }
      }
      _ref2 = this.cells;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        cell = _ref2[_j];
        cell.remove();
      }
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
      if (id >= this.length() || id < 0) {
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
      Moka.focusFirst(cell.children(), this.o) || Moka.focus(cell, this.o);
      return this;
    };
    Viewer.prototype.zoom = function(how) {
      var c, d, factor, h, i, item, layout, len, offset, pos, w, wnd;
      if (how != null) {
        this.zhow = null;
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
          c = this.cells[0];
          w -= c.outerWidth(true) - c.width();
          h -= c.outerHeight(true) - c.height();
          this.z = [w, h, how];
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
        } else if (how instanceof Array) {
          this.z = how;
        } else {
          factor = parseFloat(how) || 1;
          this.z = factor;
        }
        if (this.index < 0) {
          return;
        }
        i = this.index;
        len = i + this.cellCount();
        len = Math.min(len, this.length());
        dbg("zooming views", i + ".." + (len - 1), "using method", this.z);
        while (i < len) {
          item = this.at(i);
          if (typeof item.zoom === "function") {
            item.zoom(this.z);
          }
          ++i;
        }
        if (this.current >= 0) {
          Moka.toScreen(this.at(this.index + this.current).e, this.e, this.o);
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
      cell = $("<div>");
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
        if (ev.target === cell[0] && Moka.focusFirst(cell.children(), this.o)) {
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
      this.table.empty().hide();
      this.clear();
      _ref = this.cells;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        cell.remove();
      }
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
        if (this.lay) {
          this.e.removeClass("moka-layout-" + this.lay.join("x"));
        }
        this.lay = [x, y];
        this.e.addClass("moka-layout-" + this.lay.join("x"));
        dbg("setting layout", this.lay);
        id = this.index + this.currentcell;
        this.updateTable();
        this.view(this.index);
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
        h = cell.height() + "px";
        w = cell.width() + "px";
        cell.css({
          width: w,
          height: h
        });
        return item.hide();
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
          dbg("updateItems finished for direction", direction);
          if (direction > 0) {
            updateItems.call(this, this.index + this.current - direction, -direction);
          }
          this.update();
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
    Viewer.prototype.onMouseDown = function(ev) {
      if (ev.button === 1) {
        if (this.zhow === "fit") {
          return this.zoom(1);
        } else {
          return this.zoom("fit");
        }
      }
    };
    Viewer.prototype.onDoubleClick = function() {
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
    Notification.prototype.mainclass = "moka-notification " + Moka.Widget.prototype.mainclass;
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
      this.e.addClass(notification_class).hide().html(html).bind("mouseenter.moka", __bind(function() {
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
    Window.prototype.mainclass = "moka-window " + Moka.Input.prototype.mainclass;
    Window.prototype.default_keys = {
      ESCAPE: function() {
        return this.close();
      },
      F4: function() {
        return this.close();
      },
      F2: function() {
        return this.title.focus();
      },
      F3: function() {
        var e, edit, last_focused, mainwnd, pos, search, tofocus, val, w, wnd;
        last_focused = Moka.focused();
        wnd = new Moka.Window("Search");
        w = new Moka.LineEdit("Find string:");
        e = w.e;
        edit = w.edit;
        tofocus = null;
        val = "";
        mainwnd = this.e;
        search = function(next) {
          var newtofocus;
          newtofocus = Moka.findInput(mainwnd, val, next);
          if (newtofocus) {
            if (tofocus) {
              tofocus.removeClass("moka-found");
            }
            tofocus = newtofocus;
            return tofocus.addClass("moka-found");
          }
        };
        wnd.addKey("F3", function() {
          return search(true);
        });
        wnd.addKey("ESCAPE", function() {
          Moka.focus(last_focused);
          return wnd.close();
        });
        w.change(__bind(function(ev, value) {
          val = value;
          return search();
        }, this));
        wnd.addKey("ENTER", __bind(function() {
          Moka.focus(tofocus ? tofocus : last_focused);
          return wnd.close();
        }, this));
        wnd.connect("mokaDestroyed", __bind(function() {
          if (tofocus) {
            return tofocus.removeClass("moka-found");
          }
        }, this));
        pos = this.position();
        return wnd.append(w).appendTo(this.e.parent()).position(pos.left, pos.top).show().focus();
      },
      LEFT: function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.left -= 20;
        return this.e.offset(pos);
      },
      RIGHT: function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.left += 20;
        return this.e.offset(pos);
      },
      UP: function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.top -= 20;
        return this.e.offset(pos);
      },
      DOWN: function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.top += 20;
        return this.e.offset(pos);
      },
      'S-LEFT': function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.left = 0;
        return this.e.offset(pos);
      },
      'S-RIGHT': function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.left = this.e.parent().innerWidth() - this.e.outerWidth(true);
        return this.e.offset(pos);
      },
      'S-UP': function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.top = 0;
        return this.e.offset(pos);
      },
      'S-DOWN': function() {
        var pos;
        if (!this.titleHasFocus()) {
          return false;
        }
        pos = this.e.offset();
        pos.top = this.e.parent().innerHeight() - this.e.outerHeight(true);
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
        if (!this.titleHasFocus()) {
          return false;
        }
        return this.body.toggle();
      }
    };
    function Window(title) {
      var body, e, edge, edges, s, self;
      Window.__super__.constructor.apply(this, arguments);
      self = this;
      this.tabindex(-1).hide().bind("mokaFocusUpRequest", __bind(function() {
        this.title.focus();
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
      this.title = new Moka.Input().addClass("moka-title").appendTo(e);
      this.title_label = new Moka.Label(title).appendTo(this.title.e);
      this.noclose = false;
      this.e_close = $("<div>", {
        'class': "moka-window-button moka-close"
      }).css('cursor', "pointer").click(this.close.bind(this)).appendTo(this.title.e);
      this.nomax = true;
      this.e_max = $("<div>", {
        'class': "moka-window-button moka-maximize"
      }).css('cursor', "pointer").click(this.maximize.bind(this)).hide().appendTo(this.title.e);
      body = this.body = new Moka.Container().addClass("moka-body").appendTo(e);
      this.widgets = [this.title_label, this.title, this.body];
      this.title.dblclick = function() {
        body.toggle();
        Moka.focusFirstWidget(body);
        return false;
      };
      this.title.bind("mousedown", __bind(function(ev) {
        this.focus();
        return ev.preventDefault();
      }, this));
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
      Moka.initDraggable(this.e, this.title.e);
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
    Window.prototype.disableClose = function(noclose) {
      if (noclose) {
        this.noclose = true;
        this.e_close.hide();
      } else {
        this.noclose = false;
        this.e_close.show();
      }
      return this;
    };
    Window.prototype.disableMaximize = function(nomax) {
      if (nomax) {
        this.nomax = true;
        this.e_max.hide();
      } else {
        this.nomax = false;
        this.e_max.show();
      }
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
        this.body.append(widget);
      }
      this.update();
      return this;
    };
    Window.prototype.remove = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        var _base;
        return typeof (_base = w[i]).update === "function" ? _base.update() : void 0;
      });
      return Window.__super__.remove.apply(this, arguments);
    };
    Window.prototype.center = function(once) {
      this.e.css("opacity", 0);
      this.e.offset({
        left: (this.e.parent().width() - this.e.width()) / 2,
        top: (this.e.parent().height() - this.e.height()) / 2
      });
      if (once) {
        this.e.css("opacity", 1);
      }
      if (!once) {
        window.setTimeout(this.center.bind(this, true), 0);
      }
      return this;
    };
    Window.prototype.focus = function() {
      if (!Moka.focusFirstWidget(this.body)) {
        Moka.focus(this.title);
      }
      return this;
    };
    Window.prototype.titleHasFocus = function() {
      return this.title.hasFocus();
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
      wnds = this.e.siblings((" " + this.mainclass).split(" ").join(" ."));
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
      if (this.noclose) {
        return this;
      }
      return this.remove();
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
    var inputs;
    inputs = $("body,input,textarea,select");
    inputs.live("focus.moka", function(ev) {
      Moka.focused($(ev.target));
      return false;
    });
    inputs.live("blur.moka", function(ev) {
      Moka.unfocused();
      return false;
    });
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
