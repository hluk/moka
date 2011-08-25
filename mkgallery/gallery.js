(function() {
	var onLoad, viewer, gotownd, menu, options, opts;

    options = {
        "": {
            n: [0],
            skiptitle_once: []
        },
        _General: {
            skiptitle: [false, "Skip _title dialog on start"],
            notify: [true, "Show item _informations"]
        },
        _Images: {
            zoom: ["1", "_Zoom factor", "Examples: <b>1</b>, <b>1.5</b>, <b>fit</b>, <b>fill</b>"],
            sharpen: [0.0, "_Sharpen factor", "Values from <b>0.0</b> to <b>1.0</b> (slow)"]
        },
        _Layout: {
            o: [
                ["left top", "right top", "top left", "top right",
                 "bottom left", "bottom right", "left bottom", "right bottom"],
                "O_rder"],
            layout: ["1x1", "L_ayout", "Examples: <b>2x3</b> or <b>2x-1</b> (for continuous view)"]
        }
    }

    createCounter = function (n, len, r, w1, w2, bg, fg, shadow, blur, el)
    {
        var e, ctx, pi, angle, x, y;

        e = el || $("<canvas class='counter'>");

        ctx = e[0].getContext("2d");
        if (el) {
            ctx.clearRect(0,0,el.width,el.height)
        }
        pi = 3.1415;
        angle = len ? 2*pi*n/len : 0;
        x = r+blur;
        y = r+blur;
        w = r+blur;
        h = r+blur;

        e[0].setAttribute("width", 2*w);
        e[0].setAttribute("height", 2*h);

        ctx.save();

        //ctx.clearRect(x-r,y-r,2*r,2*r);

        // empty pie
        ctx.shadowBlur = shadow;
        ctx.shadowColor = "black";
        ctx.lineWidth = w1;
        ctx.strokeStyle = bg;
        ctx.moveTo(x, y);
        ctx.beginPath();
        ctx.arc(x, y, r-w1/2, 0, 2*pi, false);
        ctx.stroke();

        // filled part of pie
        ctx.shadowBlur = blur;
        ctx.shadowColor = fg;
        ctx.lineWidth = w2;
        ctx.strokeStyle = fg;
        ctx.moveTo(x, y);
        ctx.beginPath();
        ctx.arc(x, y, r-w1/2, -pi/2, angle-pi/2, false);
        ctx.stroke();

        ctx.font = (r*0.7)+"px serif";
        ctx.textAlign = "center";
        ctx.fillText(n, w, h);
        ctx.font = (r*0.45)+"px serif";
        ctx.fillText(len, w, h+r*0.5);

        ctx.restore();

        return e
    }


	// URL hash
	urlHash = function(values) {
		var hash, key, v;

		if (typeof values != "undefined" && values !== null) {
			hash = "";
			for (var key in values) {
                v = values[key];
                if (typeof v != "undefined") {
                    hash += (hash ? "&" : "") + key + "=" + v;
                }
			}
			location.hash = hash;
		} else {
			hash = {};
			location.hash.replace(/[#&]+([^=&]+)=([^&]*)/gi,
				function (m,key,value) {
					hash[key] = value;
				});
			return hash;
		}
	}

    getOptions = function(hash) {
        var opts, cat, options_cat, x, default_value;

        opts = {};

        for (cat in options) {
            options_cat = options[cat];
            for (name in options_cat) {
                default_value = options_cat[name][0];
                x = hash[name];

                if (typeof x != "undefined" && x !== null) {
                    // value should be same type as the default value
                    switch(typeof default_value) {
                        case "boolean":
                            x = (x === "1" || x === "true") ? true : false;
                            break;
                        case "number":
                            x = parseFloat(x);
                            break;
                        case "string":
                            x = ""+x;
                            break;
                        case "object":
                            x = ""+x;
                            break;
                    }
                } else if (typeof default_value != "undefined") {
                    continue;
                } else {
                    x = default_value;
                }
                opts[name] = x;
            }
        }

        return opts;
    }

    // show notification
    oldid = void 0;
    notify = function(v, id) {
        var item, itempath, html, notification, counter, label, r, w1, w2, e, z;

        if (id != null) {
            oldid = id;
        } else {
            id = oldid;
        }
        item = v.at(id);

        if (item.image) {
            it = ls[id];
            if (it instanceof Array) {
                itempath = it[0];
            } else {
                itempath = it;
            }
            html = "";
            // escape anchor and html
            html += "URL: <a href='"+itempath+"'>" + itempath.replace(/^items\//,"") + "</a></i><br/>";
            if ( item.width() ) {
                html += "size: <i>" + item.width() + "x" + item.height() + "</i></br>";
            } else {
                item.one("mokaLoaded", function(){notify(v,id);})
            }
            z = v.zoom();
            if ( z !== 1 ) {
                html += "zoom: <i>" +
                        (typeof z == "number" ? (Math.floor(100*z)+"%") : z) +
                        "</i>";
            }
        }

        Moka.clearNotifications()
        if (html) {
            notification = new Moka.Notification("<table><tr><td valign='middle'></div></td><td>"+html, "", 4000, 300);
            e = notification.e.find('td:first');

            counter = createCounter(id+1, ls.length, 24, 6, 4, "rgba(100,50,20,0.4)", "white", 12, 10);
            counter.css("margin", "-12px -10px -12px -24px");
            counter.appendTo(e);

            return notification;
        }
    }

    showGoToDialog = function() {
        var close, closed, accept, lineedit, buttons;

        if (gotownd) {
            gotownd.focus();
            return;
        }

        gotownd = new Moka.Window("Go to");
        lineedit = new Moka.LineEdit("_Go to item number:");
        buttons = new Moka.ButtonBox();
        gotownd.append(lineedit, buttons);

        close = function() {
            gotownd.close();
        }
        closed = function() {
            gotownd = null;
        }
        accept = function() {
            viewer.select(lineedit.value());
            gotownd.close();
        }

        buttons.append("_Ok", accept);
        buttons.append("_Close", close);
        gotownd.addKey("ENTER", accept);
        gotownd.connect("mokaDestroyed", closed);

        gotownd.appendTo("body").center().show().focus();
    }

    showMenu = function() {
        var close, closed, accept, name, cat, options_cat, i, tabs,
            val, w, ww, container, tabs, widgets, buttons, opt, label;

        if (menu) {
            menu.focus();
            return;
        }

        w = {};

        menu = new Moka.Window("Menu");

        close = function() {
            menu.close();
        }
        closed = function() {
            menu = null;
        }
        accept = function() {
            menu.close();
            for (name in w) {
                opts[name] = w[name].value();
            }
            if (viewer) {
                opts.skiptitle_once = 1;
                urlHash(opts);
                window.location.reload();
            }
            urlHash(opts);
        }
        reset = function() {
            var opts = getOptions({});
            for (cat in options) {
                options_cat = options[cat];
                for (name in options_cat) {
                    if ( w[name] ) {
                        w[name].value( options_cat[name][0] );
                    }
                }
            }
        }

        tabs = new Moka.Tabs();
        for (cat in options) {
            if (!cat) continue;
            widgets = new Moka.WidgetList();
            options_cat = options[cat];
            for (name in options_cat) {
                opt = options_cat[name];
                label = opt[1];
                container = new Moka.Container();

                val = opts[name];
                def = opt[0];
                if ( typeof val == "boolean" ) {
                    w[name] = new Moka.CheckBox(label, val);
                } else if ( typeof def == "object" ) {
                    ww = w[name] = new Moka.Combo(label+":");
                    for (i in def) {
                        ww.append(def[i]);
                    }
                    ww.value(val);
                } else {
                    w[name] = new Moka.LineEdit(label+":", val);
                }
                container.append(w[name]);

                label = opt[2];
                if (label) {
                    container.append( new Moka.Label("<small>"+label+"</small>") );
                }

                widgets.append(container);
            }
            tabs.append(cat, widgets);
        }

        // buttons
        buttons = new Moka.ButtonBox();
        buttons.append("_Ok", accept);
        buttons.append("R_eset", reset);
        buttons.append("_Close", close);

        menu.append(tabs, buttons);

        menu.addKey("ENTER", accept);
        menu.connect("mokaDestroyed", closed);

        menu.appendTo("body").center().show().focus();
    }

    start = function() {
		var item, itempath, map, onLoad, v, wnd, i, len, value, sharpen;

		onLoad = void 0;
		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

		// gallery widget
		v = new Moka.Viewer();

		// parse options
		value = opts.zoom;
		if (value) {
            value = value.split(",");
            console.log(value);
			v.zoom(value.length === 1 ? value[0] : value);
		}

		// layout
		value = opts.layout;
		if (value) {
			v.layout( value.split("x") );
		}

        // orientation
		value = opts.o;
		if (value) {
			v.orientation(value);
		}

        // sharpen
		sharpen = opts.sharpen || 0;

        // items on demand
        v.appendFunction(function(i){
			item = ls[i];
			if (item instanceof Array) {
				itempath = item[0];
			} else {
				itempath = item;
			}
            if (sharpen > 0) {
                return new Moka.ImageView(itempath, true, sharpen);
            } else {
                return new Moka.ImageView(itempath);
            }
        }, ls.length);

        // current item
		value = opts.n;
		if (value) {
			v.view(value);
		}

		v.e.appendTo("body");
		v.show();

		// show notification and update URL when viewing new item or changing zoom level
        v.bind("mokaSelected mokaZoomChanged", function(ev, id) {
            if (ev.target !== this || !((id != null) || (oldid != null))) {
                return;
            }
            // URL: remember layout, zoom, orientation, current item number
            opts.zoom = v.zoom();
            opts.n = v.currentIndex();
            opts.layout = v.layout().join("x");
            urlHash(opts);

            if (opts.notify) {
                notify(v, id);
            }
        });

        v.addKey("KP5",
                function(){
                    v.layout([4,3]);
                    v.zoom("fit");
                });
        v.addKey("G", showGoToDialog);
        v.addKey("C", showMenu);

		Moka.focus(v.e);

        viewer = v;
    }

	onLoad = function() {
        var wnd, counter, widgets;

		opts = getOptions( urlHash() );

        $("body").height( $(window).height() );
        $(window).resize( function(){$("body").height( $(this).height() );} );

		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

        if (opts.skiptitle || opts.skiptitle_once) {
            delete opts.skiptitle_once;
            return start();
        }

        next = function(i){
            opts.n += i || 1;
            if (opts.n >= ls.length) {
                opts.n = 0;
            }
            createCounter(opts.n, ls.length, 80, 4, 6, "rgba(100,50,20,0.4)", "white", 16, 8, counter.element());
        }
        prev = function(i){
            opts.n -= i || 1;
            if (opts.n < 0) {
                opts.n = ls.length-1;
            }
            createCounter(opts.n, ls.length, 80, 4, 6, "rgba(100,50,20,0.4)", "white", 16, 8, counter.element());
        }

        counter = new Moka.Input( createCounter(opts.n, ls.length, 80, 4, 6,
                    "rgba(100,50,20,0.4)", "white", 16, 8) );

        widgets = new Moka.WidgetList();
        widgets.append( new Moka.Button("_Browse", function(){wnd.close();}) );
        widgets.append( new Moka.Button("_Configure", showMenu) );
        widgets.append(counter);

        wnd = new Moka.Window("<b>"+title+"</b> gallery");
        wnd.addKey("RIGHT", next);
        wnd.addKey("LEFT", prev);
        wnd.addKey("+", next);
        wnd.addKey("-", prev);
        wnd.addKey("PAGEDOWN", function(){next(10);});
        wnd.addKey("PAGEUP", function(){prev(10);});
        wnd.addKey("S-RIGHT", function(){next(10);});
        wnd.addKey("S-LEFT", function(){prev(10);});
        wnd.addKey("S-+", function(){next(10);});
        wnd.addKey("S--", function(){prev(10);});
        wnd.align("center");
        wnd.addKey("ENTER", function(){wnd.close();});
        wnd.append(widgets);

        wnd.connect("mokaDestroyed", start);
        wnd.appendTo("body").center().show().focus();
	};

	$(document).ready(onLoad);
}).call(this);
