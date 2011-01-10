(function() {
  var Button, ButtonBox, CheckBox, ImageView, Selection, Tabs, TextEdit, Viewer, Widget, WidgetList, Window, createLabel, dbg, doKey, dragScroll, ensure_position, ensure_visible, focus, focus_first, focus_timestamp, focused_widget, getKeyName, initDraggable, init_GUI, is_on_screen, keyHintFocus, keycodes, last_keyname, last_keyname_timestamp, log, logfn, logobj, onLoad, test, tt, userAgent, userAgents, wnd_count;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
        var $this, parent, _ref, _ref2;
        $this = $(this);
        if ($this.is(":visible") && keyhint === $this.text().toUpperCase()) {
          parent = $this.parent();
          if (!parent.hasClass("focused")) {
            if (parent.hasClass("tab")) {
              e = parent;
              e.trigger("click");
            } else if (parent.hasClass("input")) {
              e = parent;
              if ((_ref = e[0]) != null) {
                _ref.focus();
              }
            } else {
              e = parent.find(".input").eq(0);
              if ((_ref2 = e[0]) != null) {
                _ref2.focus();
              }
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
  createLabel = function(text) {
    var c, e, i, key;
    e = $("<div>", {
      'class': "widget label"
    });
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
            return $(document).unbind("mousemove.mokaDrag");
          } else {
            return e.offset({
              left: ev.pageX - x,
              top: ev.pageY - y
            });
          }
        };
        $(document).bind("mousemove.mokaDrag", move);
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
        ev.target.focus();
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
  focus = function(e) {
    if (e.length) {
      return window.setTimeout((function() {
        return e[0].focus();
      }), 0);
    }
  };
  focus_first = function(e) {
    var ee;
    ee = e.find(".input:first");
    if (ee.length) {
      focus(ee);
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
    wnd = $(window);
    if (how === "right" || how === "left") {
      min = wnd.scrollLeft();
      max = min + wnd.width();
    } else {
      min = wnd.scrollTop();
      max = min + wnd.height();
    }
    pos = e.offset();
    pos.right = pos.left + e.width();
    pos.bottom = pos.top + e.height();
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
  init_GUI = function() {
    var ensure_fns, ensure_position_tmp;
    $(".input").live("focus", function(ev) {
      if (focus_timestamp === ev.timeStamp) {
        return;
      }
      focus_timestamp = ev.timeStamp;
      focused_widget = $(ev.target);
      focused_widget.addClass("focused").trigger("mokaFocused");
      ensure_visible(focused_widget);
      return dbg("focused element", focused_widget);
    }).live("blur", function() {
      focused_widget = $();
      return $(this).removeClass("focused").trigger("mokaLostFocus");
    });
    $(".widget").live("focusin", function() {
      return $(this).addClass("focused");
    }).live("focusout", function() {
      return $(this).removeClass("focused");
    });
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
  Widget = (function() {
    Widget.prototype.default_keys = {};
    function Widget() {
      this.e = $("<div>", {
        'class': "widget"
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
    Widget.prototype.keyPress = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      if (keyHintFocus(keyname, this.body)) {
        return false;
      }
    };
    return Widget;
  })();
  Selection = (function() {
    __extends(Selection, Widget);
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
      pos = e.offset();
      this.e.width(e.outerWidth()).height(e.outerHeight()).offset({
        top: pos.top,
        left: pos.left
      });
      if (this.current) {
        this.current.removeClass("current");
      }
      this.current = e.addClass("current");
      return ensure_position(this.e, e, true);
    };
    return Selection;
  })();
  CheckBox = (function() {
    __extends(CheckBox, Widget);
    CheckBox.prototype.default_keys = {
      SPACE: function() {
        return this.value(!this.value());
      },
      ENTER: function() {
        return this.value(!this.value());
      }
    };
    function CheckBox(text, checked) {
      var label;
      CheckBox.__super__.constructor.apply(this, arguments);
      label = createLabel(text);
      this.e.css("cursor", "pointer").keydown(this.keyPress.bind(this));
      this.checkbox = $('<input>', {
        type: "checkbox",
        'class': "input value"
      }).prependTo(label).click(function(ev) {
        return ev.stopPropagation();
      });
      label.click(function() {
        if (!checkbox.attr('disabled')) {
          return checkbox.focus().attr("checked", checkbox.is(':checked') ? 0 : 1);
        }
      }).appendTo(this.e);
      this.value(checked);
    }
    CheckBox.prototype.value = function(val) {
      if (val != null) {
        this.checkbox.attr("checked", val);
        return this;
      } else {
        return this.checkbox.attr("checked");
      }
    };
    CheckBox.prototype.keyPress = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    return CheckBox;
  })();
  TextEdit = (function() {
    __extends(TextEdit, Widget);
    TextEdit.prototype.default_keys = {
      LEFT: function() {
        return this.moveCursor(-1, 0);
      },
      RIGHT: function() {
        return this.moveCursor(1, 0);
      },
      UP: function() {
        return this.moveCursor(0, -1);
      },
      DOWN: function() {
        return this.moveCursor(0, 1);
      },
      HOME: function() {
        var e;
        e = this.getChars().eq(this.pos).parent().children(".c").eq(0);
        return this.moveCursor(this.index(e) - this.pos, 0);
      },
      END: function() {
        var e;
        e = this.getChars().eq(this.pos).parent().children(".c").eq(-1);
        this.moveCursor(this.index(e) - this.pos, 0);
        return this.left = 999999;
      },
      DELETE: function() {
        if (this.sel1 === this.sel2) {
          this.removeChars(this.sel1, this.sel1 + 1);
        } else {
          this.removeChars(this.sel1, this.sel2);
        }
        return this.selection(this.sel1, this.sel1);
      },
      BACKSPACE: function() {
        var pos;
        if (this.sel1 === this.sel2) {
          pos = this.sel1 - 1;
          this.removeChars(pos, this.sel1);
        } else {
          pos = this.sel1;
          this.removeChars(this.sel1, this.sel2);
        }
        return this.selection(pos, pos);
      },
      'S-LEFT': function() {
        return this.moveCursor(-1, 0, true);
      },
      'S-RIGHT': function() {
        return this.moveCursor(1, 0, true);
      },
      'S-UP': function() {
        return this.moveCursor(0, -1, true);
      },
      'S-DOWN': function() {
        return this.moveCursor(0, 1, true);
      },
      'S-HOME': function() {
        var e;
        e = this.getChars().eq(this.pos).parent().children(".c").eq(0);
        return this.moveCursor(this.index(e) - this.pos, 0, true);
      },
      'S-END': function() {
        var e;
        e = this.getChars().eq(this.pos).parent().children(".c").eq(-1);
        return this.moveCursor(this.index(e) - this.pos, 0, true);
      },
      'C-A': function() {
        return this.selection(0, this.text.length);
      }
    };
    function TextEdit(label_text, text, multiline) {
      var cursor, edit, editor, label, self;
      this.multiline = multiline;
      TextEdit.__super__.constructor.apply(this, arguments);
      self = this;
      this.keys = {};
      if (this.multiline) {
        edit = this.edit = $("<textarea>");
      } else {
        edit = this.edit = $("<input>");
        this.keys.UP = this.keys.DOWN = this.keys['S-UP'] = this.keys['S-DOWN'] = function() {
          return;
        };
      }
      edit.addClass("input value").keydown(this.keyPress.bind(this)).blur(this.blur.bind(this));
      this.e.addClass("textedit");
      if (label_text) {
        label = createLabel(label_text).mousedown(function(ev) {
          var _ref;
          if (!edit.is(":focus")) {
            if ((_ref = edit[0]) != null) {
              _ref.focus();
            }
          }
          return ev.preventDefault();
        }).appendTo(this.e);
      }
      editor = this.editor = $("<div>");
      editor.addClass((this.multiline ? "multi" : "") + "lineedit");
      editor.mousedown(function(ev) {
        var from, index, _ref;
        if (ev.button !== 0) {
          return;
        }
        if (!edit.is(":focus")) {
          if ((_ref = edit[0]) != null) {
            _ref.focus();
          }
        }
        index = function(e) {
          if (e.hasClass("l")) {
            e = e.children(".c").eq(-1);
          } else if (e.hasClass("linenumber")) {
            e = e.next();
          }
          return self.index(e);
        };
        from = index($(ev.target));
        if (from === -1) {
          return;
        }
        self.select(from, from);
        editor.mousemove(function(ev) {
          var to;
          to = index($(ev.target));
          if (to === -1) {
            return;
          }
          return self.select(from, to);
        });
        $(document).one("mouseup", function(ev) {
          if (ev.button === 0) {
            return editor.unbind("mousemove");
          }
        });
        return ev.preventDefault();
      });
      editor.dblclick(function(ev) {
        var chars, e, ee, from, nbsp, to;
        e = $(ev.target);
        nbsp = String.fromCharCode(160);
        if (e.hasClass("l")) {
          chars = e.children(".c");
          from = self.index(chars.eq(0));
          to = self.index(chars.eq(-1));
        } else {
          chars = self.chars.children(".l").children(".c");
          if (e.hasClass("linenumber")) {
            chars = e.parent().children(".c");
            from = self.index(chars.eq(0));
            to = self.index(chars.eq(-1));
          } else {
            e = chars.eq(self.sel1);
            if (e.text() !== nbsp) {
              ee = e;
              while (ee.length && ee.text()[0] !== nbsp) {
                to = self.index(ee);
                ee = ee.next();
              }
              ++to;
              ee = e;
              while (ee.length && ee.text()[0] !== nbsp) {
                from = self.index(ee);
                ee = ee.prev();
              }
            }
          }
        }
        self.select(from, to);
        return ev.preventDefault();
      });
      editor.appendTo(label);
      cursor = this.cursor = $("<div>", {
        "class": "cursor"
      }).css({
        position: "absolute"
      }).css({
        'cursor': "text"
      }).mousedown(function(ev) {
        return ev.preventDefault();
      }).hide().appendTo(editor);
      edit.css({
        opacity: 0,
        position: "absolute",
        left: "-10000px",
        tabindex: 100000
      }).focus(function() {
        cursor.show();
        self.selection();
        return editor.addClass("focused");
      }).blur(function() {
        cursor.hide();
        return editor.removeClass("focused");
      }).appendTo(label);
      this.chars = $("<div>", {
        "class": "cs"
      }).appendTo(editor);
      this.value(text ? text : "");
      this.sel1 = this.sel2 = 0;
    }
    TextEdit.prototype.dirty = function() {
      return this.lines = this.characters = null;
    };
    TextEdit.prototype.getLines = function() {
      if (!this.lines) {
        this.lines = this.chars.children(".l");
      }
      return this.lines;
    };
    TextEdit.prototype.getChars = function() {
      if (!this.characters) {
        this.characters = this.getLines().children(".c");
      }
      return this.characters;
    };
    TextEdit.prototype.index = function(e) {
      return this.getChars().index(e);
    };
    TextEdit.prototype.indexOnLine = function(e) {
      return e.parent().children(".c").index(e);
    };
    TextEdit.prototype.appendLine = function() {
      var l;
      l = $("<div>", {
        "class": "l"
      }).css("min-height", "1em").hide();
      $("<span>", {
        "class": "linenumber"
      }).appendTo(l);
      l.appendTo(this.chars);
      this.characters = null;
      return l;
    };
    TextEdit.prototype.char = function(c) {
      var ce;
      ce = $("<span>", {
        "class": "c"
      }).css("cursor", "text");
      if (c === ' ') {
        ce.html("&nbsp;");
      } else if (c === '\n') {
        ce.html("&nbsp;").addClass("eol");
      } else if (c === null) {
        ce.html("&nbsp;").addClass("eof");
      } else if (c === '\t') {
        ce.html("&nbsp;&nbsp;&nbsp;&nbsp;");
      } else {
        ce.text(c);
      }
      return ce;
    };
    TextEdit.prototype.appendChar = function(c, line) {
      this.characters = null;
      return this.char(c).appendTo(line);
    };
    TextEdit.prototype.insertChars = function(text, to) {
      var e, i, len, newline, p, target;
      target = this.getChars().eq(to);
      i = 0;
      len = text.length;
      while (i < len) {
        e = this.char(text[i++]);
        e.insertBefore(target);
        if (e.hasClass("eol")) {
          p = e.parent();
          newline = this.appendLine().insertAfter(p);
          e.nextAll(p.children(".c")).appendTo(newline);
        }
      }
      this.dirty();
      if (newline) {
        return this.updateLines();
      }
    };
    TextEdit.prototype.remove = function(ce) {
      var nextline;
      if (ce.hasClass("eol")) {
        nextline = ce.parent().next();
        nextline.children(".c").insertAfter(ce);
        nextline.remove();
      }
      return ce.remove();
    };
    TextEdit.prototype.replaceChars = function(from, to, replacement) {
      var i, len, self;
      if (from < 0 || to < 0 || from > to) {
        return;
      }
      this.text = this.text.slice(0, from) + replacement + this.text.slice(to);
      i = 0;
      len = replacement.length;
      self = this;
      this.getChars().slice(from, to).each(function() {
        return self.remove($(this));
      });
      return this.insertChars(replacement, to);
    };
    TextEdit.prototype.removeChars = function(from, to) {
      return this.replaceChars(from, to, "");
    };
    TextEdit.prototype.updateText = function() {
      var c, i, l, len;
      this.chars.empty();
      i = 0;
      len = this.text.length;
      l = null;
      while (i < len) {
        if (l === null) {
          l = this.appendLine();
        }
        c = this.text[i];
        this.appendChar(c, l);
        if (c === '\n') {
          l = null;
        }
        ++i;
      }
      if (l === null) {
        l = this.appendLine();
      }
      this.appendChar(null, l);
      this.updateLines();
      this.selection(0, 0);
      return true;
    };
    TextEdit.prototype.updateLines = function() {
      var e, i, j, len, lines, ln, num, padding;
      lines = this.getLines();
      ln = lines.children(":first-child");
      len = ln.length;
      i = 0;
      j = 1;
      padding = new Array(Math.floor(Math.log(len) / 2.3) + 1).join("&nbsp;");
      while (i < len) {
        num = String(i + 1);
        if (j < num.length) {
          padding = padding.slice(6);
          ++j;
        }
        num = padding + num;
        e = ln[i];
        if (e.innerHTML !== num) {
          e.innerHTML = num;
        }
        ++i;
      }
      return lines.show();
    };
    TextEdit.prototype.moveCursor = function(dx, dy, anchored) {
      var a, b, ch, char, chars, left, line, ln, pos;
      pos = this.pos;
      if (dx) {
        chars = this.getChars().eq(pos).parent().children(".c");
        a = this.index(chars.eq(0));
        b = this.index(chars.eq(-1));
        pos += dx;
        if (pos > b) {
          pos = b;
        } else if (pos < a) {
          pos = a;
        }
        this.left = this.getChars().eq(pos).offset().left;
      }
      if (dy) {
        char = this.getChars().eq(pos);
        ln = char.parent();
        if (dy > 0) {
          while ((ln = ln.next()) && (--dy) >= 0) {
            line = ln;
          }
        } else {
          while ((ln = ln.prev()) && (++dy) <= 0) {
            line = ln;
          }
        }
        left = char.offset().left;
        if (!this.left || left > this.left) {
          this.left = left;
        } else {
          left = this.left;
        }
        ch = line.children(".c").eq(0);
        while (ch.length && left >= ch.offset().left) {
          char = ch;
          ch = ch.next();
        }
        pos = this.index(char);
      }
      if (pos >= 0) {
        if (anchored) {
          if (this.pos === this.sel1) {
            return this.selection(this.sel2, pos);
          } else {
            return this.selection(this.sel1, pos);
          }
        } else {
          return this.selection(pos, pos);
        }
      }
    };
    TextEdit.prototype.selection = function(from, to) {
      var c, c_pos, c_s, chars, d, pos, s, scroll;
      if (from < 0 || to < 0 || !this.cursor.is(":visible")) {
        return;
      }
      if (from === void 0) {
        from = this.sel1;
      }
      if (to === void 0) {
        to = this.sel2;
      }
      this.pos = to;
      chars = this.getChars();
      chars.eq(this.sel1).parent().removeClass("current");
      chars.eq(this.sel2).parent().removeClass("current");
      chars.slice(this.sel1, this.sel2).each(function() {
        return $(this).removeClass("selected");
      });
      if (from <= to) {
        this.sel1 = from;
        this.sel2 = to;
      } else {
        this.sel1 = to;
        this.sel2 = from;
      }
      chars.slice(this.sel1, this.sel2).each(function() {
        return $(this).addClass("selected");
      });
      c = chars.eq(this.pos);
      c.parent().addClass("current");
      c_pos = c.offset();
      pos = this.chars.offset();
      c_s = c.height() + 16;
      s = this.chars.innerHeight();
      d = c_pos.top - pos.top;
      scroll = this.chars.scrollTop();
      if (d - c_s < 0) {
        this.chars.scrollTop(scroll + d - c_s);
      } else if (d + 2 * c_s > s) {
        this.chars.scrollTop(scroll + d + 2 * c_s - s);
      }
      c_s = c.width() + 16;
      s = this.chars.innerWidth();
      d = c_pos.left - pos.left;
      scroll = this.chars.scrollLeft();
      if (d - c_s < 0) {
        this.chars.scrollLeft(scroll + d - c_s);
      } else if (d + 2 * c_s > s) {
        this.chars.scrollLeft(scroll + d + 2 * c_s - s);
      }
      ensure_position(this.cursor, c, true);
      if (this.size_t != null) {
        window.clearTimeout(this.size_t);
      }
      return this.size_t = window.setTimeout((function() {
        var h, w;
        this.size_t = null;
        w = this.e.width();
        h = this.e.height();
        if (this.w !== w || this.h !== h) {
          this.w = w;
          this.h = h;
          return this.e.trigger("mokaSizeChanged");
        }
      }).bind(this), 200);
    };
    TextEdit.prototype.update = function() {
      this.selection();
      return this;
    };
    TextEdit.prototype.blur = function() {
      this.e.removeClass('focused');
      return this.edit.removeClass('focused');
    };
    TextEdit.prototype.keyPress = function(ev) {
      var k, keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
      k = keyname.split('-');
      k = k[k.length - 1];
      if (k.length === 1 || k === "MINUS" || k === "SPACE" || (this.multiline && keyname === "ENTER") || (keyname === "C-V" || keyname === "C-C" || keyname === "C-X" || keyname === "S-INSERT" || keyname === "S-DELETE")) {
        this.edit.trigger("keyup");
        if (this.sel1 !== this.sel2) {
          this.edit.attr("value", this.text.slice(this.sel1, this.sel2)).select();
        } else {
          this.edit.attr("value", "");
        }
        this.edit.one("keyup", (function() {
          var e, len, pos, text;
          text = this.edit.attr("value");
          e = this.edit[0];
          if ((this.sel1 === this.sel2 && text) || (text.slice(e.selectionStart, e.selectionEnd) !== this.text.slice(this.sel1, this.sel2))) {
            len = text.length;
            this.replaceChars(this.sel1, this.sel2, text);
            pos = this.sel1 + len;
            return this.selection(pos, pos);
          }
        }).bind(this));
        return ev.stopPropagation();
      }
    };
    TextEdit.prototype.value = function(val) {
      if (val != null) {
        this.text = val;
        this.updateText();
        return this;
      } else {
        return this.text;
      }
    };
    return TextEdit;
  })();
  Button = (function() {
    __extends(Button, Widget);
    function Button(label_text, onclick) {
      Button.__super__.constructor.apply(this, arguments);
      this.e = createLabel(label_text).addClass("widget input button").attr("tabindex", 0).click(onclick).keydown(this.keyPress.bind(this));
    }
    Button.prototype.keyPress = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (keyname === "ENTER" || keyname === "SPACE") {
        this.e.click();
        return false;
      }
    };
    return Button;
  })();
  WidgetList = (function() {
    __extends(WidgetList, Widget);
    function WidgetList() {
      var sel;
      WidgetList.__super__.constructor.apply(this, arguments);
      this.e.addClass("widgetlist").keydown(this.keyPress.bind(this));
      this.widgets = [];
      this.items = [];
      this.selection = sel = new Selection(this.e);
      this.current = -1;
    }
    WidgetList.prototype.update = function() {
      var w;
      w = this.widgets;
      $.each(w, function(i) {
        var _base;
        return typeof (_base = w[i]).update === "function" ? _base.update() : void 0;
      });
      this.updateSelection();
      return this;
    };
    WidgetList.prototype.next = function() {
      return this.select(this.current >= 0 && this.current < this.items.length - 1 ? this.current + 1 : 0);
    };
    WidgetList.prototype.prev = function() {
      var l;
      l = this.items.length;
      return this.select(this.current >= 1 && this.current < l ? this.current - 1 : l - 1);
    };
    WidgetList.prototype.select = function(id, no_focus) {
      var e, item, old_id, _ref;
      old_id = this.current;
      if (old_id !== id) {
        this.current = id;
        item = this.items[id];
        if (!no_focus) {
          e = item.filter(".input");
          if (!e.length) {
            e = item.find(".input");
          }
          if ((_ref = e[0]) != null) {
            _ref.focus();
          }
        }
        this.updateSelection();
        return item.trigger("mokaSelected", [id]);
      }
    };
    WidgetList.prototype.append = function(widget) {
      var ee, id;
      if (widget.e != null) {
        ee = widget.e;
        this.widgets.push(widget);
      } else {
        ee = widget;
      }
      id = this.items.length;
      if (id === 0) {
        ee.addClass("first");
      } else {
        this.items[id - 1].removeClass("last");
      }
      this.items.push(ee);
      ee.addClass("widget widgetlistitem last");
      ee.filter(".input").focus(this.select.bind(this, id, false));
      ee.find(".input").focus(this.select.bind(this, id, false));
      ee.appendTo(this.e).bind("mokaSizeChanged", this.updateSelection.bind(this)).children().focus(this.updateSelection.bind(this));
      return this;
    };
    WidgetList.prototype.updateSelection = function() {
      if (this.current >= 0) {
        return this.selection.select(this.items[this.current]);
      }
    };
    WidgetList.prototype.keyPress = function(ev) {
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
  ButtonBox = (function() {
    __extends(ButtonBox, WidgetList);
    function ButtonBox() {
      ButtonBox.__super__.constructor.apply(this, arguments);
      this.e.removeClass("widgetlist").addClass("buttonbox horizontal");
    }
    ButtonBox.prototype.updateSelection = function() {};
    ButtonBox.prototype.append = function(label_text, onclick) {
      var widget;
      widget = new Button(label_text, onclick);
      ButtonBox.__super__.append.call(this, widget);
      widget.e.removeClass("widgetlistitem");
      return this;
    };
    return ButtonBox;
  })();
  Tabs = (function() {
    __extends(Tabs, Widget);
    function Tabs() {
      var self;
      Tabs.__super__.constructor.apply(this, arguments);
      this.e.addClass("tabs_widget").keydown(this.keyPress.bind(this));
      self = this;
      this.tabs_e = $("<div>", {
        "class": "tabs input",
        tabindex: 0
      }).appendTo(this.e);
      this.tabs_e.focus(function() {
        var id;
        id = self.current;
        if (id >= 0) {
          return self.tabs_e.children(".tab").eq(id).addClass("focused");
        }
      });
      this.tabs_e.blur(function() {
        var id;
        id = self.current;
        if (id >= 0) {
          return self.tabs_e.children(".tab").eq(id).removeClass("focused");
        }
      });
      this.pages_e = $("<div>", {
        "class": "pages"
      }).appendTo(this.e);
      this.pages = [];
      this.current = -1;
      this.selection = new Selection(this.tabs_e);
      this.setVertical(false);
    }
    Tabs.prototype.update = function() {
      var _base;
      if (this.current >= 0) {
        if (typeof (_base = this.pages[this.current]).update === "function") {
          _base.update();
        }
      }
      this.updateSelection();
      return this;
    };
    Tabs.prototype.next = function() {
      if (this.current >= 0 && this.current < this.pages.length - 1) {
        return this.select(this.current + 1);
      } else {
        return this.select(0);
      }
    };
    Tabs.prototype.prev = function() {
      var l;
      l = this.pages.length;
      if (this.current >= 1 && this.current < l) {
        return this.select(this.current - 1);
      } else {
        return this.select(l - 1);
      }
    };
    Tabs.prototype.select = function(id) {
      var old_id, page, tab, _ref;
      if ((_ref = this.tabs_e[0]) != null) {
        _ref.focus();
      }
      old_id = this.current;
      if (old_id !== id) {
        if (old_id >= 0) {
          this.pages[old_id].hide();
          this.tabs_e.children(".tab").eq(old_id).removeClass("focused");
        }
        page = this.pages[id];
        page.show();
        tab = this.tabs_e.children(".tab").eq(id).trigger("mokaSelected", [id]);
        this.current = id;
      }
      this.updateSelection();
      return this;
    };
    Tabs.prototype.updateSelection = function() {
      var tab;
      if (!this.e.is(":visible")) {
        return;
      }
      if (this.current >= 0) {
        tab = this.tabs_e.children(".tab").eq(this.current);
        return this.selection.select(tab);
      }
    };
    Tabs.prototype.append = function(tabname, widget) {
      var id, page, tab;
      this.pages.push(widget);
      page = widget.e ? widget.e : widget;
      tab = createLabel(tabname);
      tab.addClass("tab");
      tab.appendTo(this.tabs_e);
      widget.hide();
      page.addClass("widget page");
      page.appendTo(this.pages_e);
      id = this.pages.length - 1;
      tab.click(this.select.bind(this, id));
      if (id === 0) {
        this.select(0);
      }
      return this;
    };
    Tabs.prototype.setVertical = function(toggle) {
      this.tabs_e.addClass(toggle === false ? "horizontal" : "vertical");
      this.tabs_e.removeClass(toggle === false ? "vertical" : "horizontal");
      return this;
    };
    Tabs.prototype.keyPress = function(ev) {
      var go_focus_down, go_focus_up, go_next, go_prev, keyname, page, _ref, _ref2, _ref3;
      keyname = getKeyName(ev);
      go_next = go_prev = go_focus_up = go_focus_down = false;
      if (this.tabs_e.hasClass("vertical")) {
        if (keyname === "UP") {
          go_prev = true;
        } else if (keyname === "DOWN") {
          go_next = true;
        } else if (keyname === "LEFT") {
          go_focus_up = true;
        } else if (keyname === "RIGHT") {
          go_focus_down = true;
        }
      } else {
        if (keyname === "LEFT") {
          go_prev = true;
        } else if (keyname === "RIGHT") {
          go_next = true;
        } else if (keyname === "UP") {
          go_focus_up = true;
        } else if (keyname === "DOWN") {
          go_focus_down = true;
        }
      }
      if (go_next || go_prev || go_focus_up || go_focus_down) {
        if ((_ref = this.tabs_e[0]) != null) {
          _ref.focus();
        }
        if (go_next) {
          this.next();
        } else if (go_prev) {
          this.prev();
        } else if (go_focus_up) {
          if ((_ref2 = this.e.parents().children(".input").eq(-1)[0]) != null) {
            _ref2.focus();
          }
        } else {
          page = this.pages[this.current];
          if (page.e != null) {
            page = page.e;
          }
          if ((_ref3 = page.find(".input")[0]) != null) {
            _ref3.focus();
          }
        }
        return false;
      }
      if (this.current >= 0) {
        page = this.pages[this.current];
        if (page.keyPress) {
          if (page.keyPress(ev) === false) {
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
  ImageView = (function() {
    var default_keys;
    __extends(ImageView, Widget);
    default_keys = {};
    function ImageView(src) {
      ImageView.__super__.constructor.apply(this, arguments);
      this.e.addClass("imageview").keydown(this.keyPress.bind(this));
      this.view = $("<img>", {
        "class": "input",
        tabindex: 0,
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
  Viewer = (function() {
    __extends(Viewer, Widget);
    Viewer.prototype.default_keys = {
      RIGHT: function() {
        return is_on_screen(focused_widget, "right") && this.next();
      },
      LEFT: function() {
        return is_on_screen(focused_widget, "left") && this.prev();
      },
      UP: function() {
        return is_on_screen(focused_widget, "top") && this.prevRow();
      },
      DOWN: function() {
        return is_on_screen(focused_widget, "bottom") && this.nextRow();
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
        if (this.current % c === 0) {
          return this.select(this.index - c);
        } else {
          return this.select(this.index);
        }
      },
      PAGEDOWN: function() {
        var c;
        c = this.cellCount();
        if ((this.current + 1) % c === 0) {
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
      this.e.addClass("viewer").keydown(this.keyPress.bind(this)).resize(this.update.bind(this)).bind("scroll.mokaViewerScroll", this.onScroll.bind(this)).mousedown(function(ev) {
        if (ev.button === 0) {
          return dragScroll(ev);
        }
      }).css("cursor", "move");
      this.table = $("<table>", {
        "class": "table",
        cellSpacing: 0,
        cellPadding: 0
      }).appendTo(this.e).bind("mokaFocused", __bind(function(ev) {
        var e;
        e = $(ev.target).parents(".view:last");
        if (!e.length) {
          return;
        }
        this.current = e.data("index");
        return e.addClass("current");
      }, this)).bind("mokaLostFocus", __bind(function(ev) {
        var e;
        e = $(ev.target).parents(".view:last");
        if (this.current !== e.data("index")) {
          return;
        }
        this.current = -1;
        return e.removeClass("current");
      }, this));
      this.updateTimestamp = 0;
      this.cells = [];
      this.items = [];
      this.index = 0;
      this.current = -1;
      this.preload_count = 2;
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
      len = this.cells.length;
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
          item.e.hide().appendTo(cell);
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
      ensure_visible(this.at(id).e);
      focus(cell);
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
          log(w, h);
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
            log(this.z, d);
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
    Viewer.prototype.appendRow = function() {
      return $("<tr>", {
        "class": "row"
      }).hide().appendTo(this.table);
    };
    Viewer.prototype.appendCell = function(row) {
      var cell, td;
      td = $("<td>").appendTo(row);
      cell = $("<div>", {
        "class": "widget input view"
      }).data("index", this.cells.length).focus(function() {
        return focus_first(cell);
      }).appendTo(td);
      this.cells.push(cell);
      return cell;
    };
    Viewer.prototype.cell = function(index) {
      return this.cells[index];
    };
    Viewer.prototype.updateTable = function() {
      var cell, i, ilen, j, jlen, layout, row, _i, _len, _ref, _results;
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
      _results = [];
      while (j < jlen) {
        row = this.appendRow();
        i = 0;
        while (++i <= ilen) {
          this.appendCell(row);
        }
        row.show();
        _results.push(++j);
      }
      return _results;
    };
    Viewer.prototype.layout = function(layout) {
      var i, id, j, x, y;
      if (layout) {
        x = Math.max(0, Number(layout[0]));
        y = Math.max(0, Number(layout[1]));
        if (this.lay && x === this.lay[0] && y === this.lay[1]) {
          return;
        }
        if (this.lay) {
          this.e.removeClass("layout_" + this.lay.join("x"));
        }
        this.lay = [x, y];
        this.e.addClass("layout_" + this.lay.join("x"));
        dbg("setting layout", this.lay);
        id = this.index + this.current;
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
    Viewer.prototype.hideItem = function(index) {
      var cell, h, item, w;
      item = this.at(index);
      cell = this.cells[index % this.cellCount()];
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
        cell = this.cells[index - this.index];
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
              log("XXX");
              ensure_visible(current_item);
            } else {
              if (pos.left < wndleft + this.e.width() / 2 && ww > w) {
                log("SCROLL", (ww - w) / 2);
                this.e.scrollLeft(left + (ww - w) / 2);
              }
              if (pos.top < wndtop + this.e.height() / 2 && hh > h) {
                log("SCROLL", (hh - h) / 2);
                this.e.scrollTop(top + (hh - h) / 2);
              }
            }
          }
          return next();
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
    Viewer.prototype.keyPress = function(ev) {
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
  Window = (function() {
    __extends(Window, Widget);
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
      this.e.addClass("window").attr("tabindex", -1).keydown(this.keyPress.bind(this)).hide();
      e = this.container = $("<div>").css({
        width: "100%",
        height: "100%"
      }).appendTo(this.e);
      $(window).resize(this.update.bind(this));
      this.title = $("<div>", {
        "class": "title",
        html: title,
        tabindex: 0
      }).css('cursor', "pointer").keydown(this.keyPressTitle.bind(this)).appendTo(e);
      $("<div>", {
        'class': "window_control close"
      }).css('cursor', "pointer").click(this.hide.bind(this)).appendTo(this.title);
      $("<div>", {
        'class': "window_control maximize"
      }).css('cursor', "pointer").click(this.maximize.bind(this)).appendTo(this.title);
      this.body = body = $("<div>", {
        "class": "body"
      }).appendTo(e);
      this.title.dblclick(function() {
        body.toggle();
        focus_first(body);
        return false;
      }).click(function() {
        return this.focus();
      }).mousedown(function(ev) {
        return ev.preventDefault();
      });
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
          $(document).bind("mousemove.mokaResize", function(ev) {
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
            return $(document).unbind("mousemove.mokaResize");
          });
          return false;
        });
      }
      this.widgets = [];
      initDraggable(this.e, this.title);
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
      focus(this.title);
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
      var d, e, wnds, x, _ref;
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
      return (_ref = e.find(".title:first")[0]) != null ? _ref.focus() : void 0;
    };
    Window.prototype.close = function() {
      return this.e.remove();
    };
    Window.prototype.keyPress = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (keyHintFocus(keyname, this.body)) {
        return false;
      }
      if (doKey(keyname, this.keys, this.default_keys, this)) {
        return false;
      }
    };
    Window.prototype.keyPressTitle = function(ev) {
      var keyname;
      keyname = getKeyName(ev);
      if (doKey(keyname, this.keys, this.default_title_keys, this)) {
        return false;
      }
    };
    return Window;
  })();
  $(document).ready(init_GUI);
  wnd_count = 0;
  test = function() {
    var p0, p1, p2, p3, p3_1, p3_2_1, p4, p4_1, p4_2_1, w, wnd;
    wnd = new Window("Widget Test - Window " + (++wnd_count));
    p0 = new WidgetList();
    p1 = new WidgetList().append(new TextEdit("text _edit widget:", "type some text\nhere", true)).append(new TextEdit("text _edit widget:", "type some text here")).append(new Button("_Button", function() {
      return alert("CLICKED");
    })).append(new CheckBox("_Checkbox")).append(new CheckBox("C_heckbox", true));
    p2 = new ButtonBox().append("Button_1", function() {
      return alert("1 CLICKED");
    }).append("Button_2", function() {
      return alert("2 CLICKED");
    }).append("Button_3", function() {
      return alert("3 CLICKED");
    }).append("Button_4", function() {
      return alert("4 CLICKED");
    });
    p3_2_1 = new Tabs().setVertical().append("page _U", $("<div>")).append("page _V", $("<div>")).append("page _W", $("<div>"));
    p3_1 = new Tabs().setVertical().append("page _1", $("<div>")).append("page _2", p3_2_1).append("page _3", $("<div>"));
    p3 = new Tabs().setVertical().append("page _X", p3_1).append("page _Y", $("<div>")).append("page _Z", $("<div>"));
    p4_2_1 = new Tabs().append("page _U", $("<div>")).append("page _V", $("<div>")).append("page _W", $("<div>"));
    p4_1 = new Tabs().append("page _1", $("<div>")).append("page _2", p4_2_1).append("page _3", $("<div>"));
    p4 = new Tabs().append("page _X", p4_1).append("page _Y", $("<div>")).append("page _Z", $("<div>"));
    w = new Tabs().setVertical().append("page _A", p1).append("page _B", p2).append("page _C", p3).append("page _D", p4);
    wnd.append(w);
    $(".value").css({
      'font-family': "monospace"
    });
    $(".page").addClass("valign");
    $(".widgetlistitem").bind("mokaSelected", function(e, id) {
      return log("ITEM " + id + " SELECTED");
    });
    $(".buttonbox .button").bind("mokaSelected", function(e, id) {
      return log("BUTTON " + id + " SELECTED");
    });
    $(".tab").bind("mokaSelected", function(e, id) {
      return log("TAB " + id + " SELECTED");
    });
    wnd.e.prependTo("body");
    wnd.show();
    return wnd.focus();
  };
  onLoad = function() {
    var item, items, map, onLoad, v, wnd, _i, _len;
    onLoad = void 0;
    init_GUI();
    items = ["file:///home/lukas/Pictures/paintings/Andrew Gonzales/AlbedoSublimis.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/AeternaSaltatus.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/amore.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Magia of the Heart.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Aura Gloriae.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/In The Wake of the.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Sapientia.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Seraphim Awakening.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/SirensDream.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Soror Mystica.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Telluric Womb.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Angel of Nekyia.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Breath of Dakini.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Love of Souls.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Oracle of the Pearl.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Summoning of the Muse.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Visitation.jpg", "file:///home/lukas/Pictures/paintings/Andrew Gonzales/UnioMystica.jpg", "file:///home/lukas/Pictures/paintings/blackeri/_Color_Me_Blood_Red__by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/Eros_Psyche_by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/_Kohtalo_.jpg", "file:///home/lukas/Pictures/paintings/blackeri/_MoonGoddess__by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/_Seven_Deadly_Sins__ENVY__by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__AVARICE_by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__LUST_by_blackeri.jpg", "file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__VANITY_by_blackeri.jpg"];
    map = {};
    location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m, key, value) {
      return map[key] = value;
    });
    v = new Viewer().layout(map.layout.split("x"));
    for (_i = 0, _len = items.length; _i < _len; _i++) {
      item = items[_i];
      v.append(new ImageView(item));
    }
    v.e.appendTo("body");
    v.show();
    wnd = new Window("HELP").append(createLabel("Double click on the button to add new window!")).append(new Button("Add _New Window", test)).show();
    wnd.e.css({
      right: 0,
      bottom: 0
    }).appendTo("body");
    return v.zoom(map.zoom);
  };
  $(document).ready(onLoad);
}).call(this);
