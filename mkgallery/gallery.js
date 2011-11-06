(function() {
	var onLoad, viewer, gotownd, menu, options, t_notify;

    // a_function.bind(object, arg1, ...)
    if (!Function.prototype.bind) {
        Function.prototype.bind = function(thisObj, var_args) {
            var self = this;
            var staticArgs = Array.prototype.splice.call(arguments, 1, arguments.length);

            return function() {
                var args = staticArgs.concat();
                for (var i = 0; i < arguments.length; i++) {
                    args.push(arguments[i]);
                }
                return self.apply(thisObj, args);
            }
        }
    }

    options = {
        "": {
            n: [0],
            skiptitle_once: []
        },
        _General: {
            skiptitle: [false, "Skip _title dialog on start"],
            notify: [true, "Show item _info while browsing"],
            background: ["transparent", "Item _background color"],
            notify_delay: [4000, "Item info _delay in milliseconds"]
        },
        _Images: {
            zoom: ["1", "_Zoom factor",
            "Examples: <b>1</b>; <b>1.5</b>; <b>fit</b>; <b>fill</b>; fit to rectangle 100x100: <b>100,100,fit</b>"
                ],
            sharpen: [0.0, "_Sharpen factor", "Values from <b>0.0</b> to <b>1.0</b> (slow)"],
            invert: [false, "_Invert colors"]
        },
        _Layout: {
            tip: [null, "<b>Tip:</b> Use <b>right top</b> order and <b>2x1</b> layout for Japanese manga."],
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
        pi = Math.PI;
        angle = len ? 2*pi*n/len : 0;
        //blur *= 2*n/len;
        w2 = Math.max(2, w2*n/len);
        x = y = w = h = r+Math.max(shadow,blur);

        e[0].setAttribute("width", 2*w);
        e[0].setAttribute("height", 2*h);

        ctx.save();

        //ctx.clearRect(x-r,y-r,2*r,2*r);

        // empty pie
        ctx.shadowBlur = shadow;
        ctx.shadowColor = "black";
        ctx.lineWidth = w1;
        ctx.strokeStyle = bg || "rgba(0,0,0,0.8)";
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

        ctx.shadowBlur = 0;
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

    saveOptions = function(opts) {
        urlHash( getOptions(opts, true) );
    }

    getOptions = function(hash, nodefaults) {
        var opts, cat, options_cat, x, default_value;

        hash = hash || {};
        opts = {};

        for (cat in options) {
            options_cat = options[cat];
            for (name in options_cat) {
                default_value = options_cat[name][0];
                x = hash[name];

                if (default_value instanceof Array) {
                    default_value = default_value[0];
                }

                if (typeof x != "undefined" && x !== null) {
                    // user value should have same type as the default value
                    switch(typeof default_value) {
                        case "boolean":
                            x = (x === "0" || x === "false" || !x) ? false : true;
                            break;
                        case "number":
                            x = parseFloat(x);
                            break;
                        case "string":
                            x = ""+x;
                            break;
                    }
                } else if (typeof default_value == "undefined") {
                    continue;
                } else {
                    x = default_value;
                }
                if (!nodefaults || x !== default_value) {
                    opts[name] = x;
                }
            }
        }

        return opts;
    }

    // show notification
    notify = function(id) {
        var item, itempath, html, notification, counter, r, w1, w2, e, z;

        item = viewer.item(id);

        it = ls[id];
        if (it instanceof Array) {
            itempath = it[0];
        } else {
            itempath = it;
        }
        html = "";
        // escape anchor and html
        html += "URL: <a href='"+itempath+"'>" + itempath.replace(/^items\//,"") + "</a></i><br/>";
        if ( item.isLoaded() ) {
            z = viewer.zoom();
            html += "size: <i>" +
                item.originalWidth() + "x" + item.originalHeight() + "</i>" +
                ((z !== 1) ? " <small>zoom:"+(typeof z === "number" ? (Math.floor(100*z)+"%") : z)+"</small>" : "") +
                "</br>";
        } else {
            item.one("mokaLoaded", notify.bind(null,id))
        }

        Moka.clearNotifications()
        if (html) {
            notification = new Moka.Notification("<table><tr><td valign='middle'></div></td><td>"+html, "", opts.notify_delay, 300);
            e = notification.element()
            td = notification.element().find('td:first');

            createCounter(id+1, ls.length, 24, 4, 4, null, "white", 8, 0)
                .css("margin", "-12px -8px -12px -24px")
                .appendTo(td);

            return notification;
        }
    }

    popup = function(wnd) {
        wnd.appendTo("body").center().show().focus();
    }

    showGoToDialog = function() {
        var closed, accept, lineedit, buttons;

        if (gotownd) {
            gotownd.focus();
            return;
        }

        gotownd = new Moka.Window("Go to");
        lineedit = new Moka.LineEdit("_Go to item number:");
        buttons = new Moka.ButtonBox();
        gotownd.append(lineedit, buttons);

        closed = function() {
            gotownd = null;
        }
        accept = function() {
            viewer.select(lineedit.value());
            gotownd.close();
        }

        buttons.append("_Ok", accept);
        buttons.append("_Close", gotownd.close.bind(gotownd));
        gotownd.addKey("ENTER", accept);
        gotownd.connect("mokaDestroyed", closed);

        popup(gotownd);
    }

    showMenu = function(opts) {
        var closed, accept, name, cat, options_cat, i, tabs, page,
            val, w, ww, container, tabs, widgets, buttons, opt, label;

        if (menu) {
            menu.focus();
            return;
        }

        w = {};

        menu = new Moka.Window("Menu");

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
                saveOptions(opts);
                window.location.reload();
            }
            saveOptions(opts);
        }
        reset = function() {
            var opts, widegt;
            opts = getOptions();
            for (name in opts) {
                widget = w[name];
                if ( widget ) {
                    widget.value(opts[name]);
                }
            }
        }

        tabs = new Moka.Tabs();
        //tabs.vertical(true);
        for (cat in options) {
            if (!cat) continue;
            page = new Moka.Container();
            widgets = new Moka.WidgetList();
            options_cat = options[cat];
            for (name in options_cat) {
                opt = options_cat[name];
                label = opt[1];

                val = opts[name];
                def = opt[0];
                if ( typeof def == "boolean" ) {
                    w[name] = new Moka.CheckBox(label, val);
                } else if (def instanceof Array ) {
                    ww = w[name] = new Moka.Combo(label+":");
                    for (i in def) {
                        ww.append(def[i]);
                    }
                    ww.value(val);
		        } else if (typeof val == "undefined" || val === null) {
                    page.append( new Moka.Label(label) );
                    continue;
                } else {
                    w[name] = new Moka.LineEdit(label+":", val);
                }
                container = new Moka.Container();
                container.append(w[name]);

                // additional info
                label = opt[2];
                if (label) {
                    container.append( new Moka.Label("<small>"+label+"</small>") );
                }

                widgets.append(container);
                page.append(widgets);
            }
            tabs.append(cat, page);
        }

        // buttons
        buttons = new Moka.ButtonBox();
        buttons.append("_Ok", accept);
        buttons.append("R_eset", reset);
        buttons.append("_Cancel", menu.close.bind(menu));

        menu.append(tabs, buttons);

        menu.addKey("ENTER", accept);
        menu.connect("mokaDestroyed", closed);

        popup(menu);
    }

    getItem = function(opts, i){
        var item, itempath, filter, filters = [];

        if (opts.invert && Filters.Invert) {
            f = new Filters.Invert();
            filters.push({
                filename: "deps/invert.js",
                callback: f.apply.bind(f)
            });
        }
        if (opts.sharpen > 0 && Filters.Sharpen) {
            f = new Filters.Sharpen(opts.sharpen);
            filters.push({
                filename: "deps/sharpen.js",
                callback: f.apply.bind(f)
            });
        }

        item = ls[i];
        itempath = (item instanceof Array) ? item[0] : item;
            return filters.length ?
                    ( new Moka.ImageView(itempath, true, filters) ) :
                    ( new Moka.ImageView(itempath) );
    }

    start = function(opts) {
		var map, onLoad, wnd, i, len, value;

		// gallery widget
		viewer = new Moka.Viewer();

		// parse options
        value = opts.zoom.split(",");
        if (value.length === 1) {
            viewer.zoom(value[0]);
        } else {
            viewer.zoom(value, value[2]);
        }

		// layout
        viewer.layout(opts.layout.split("x"));

        // orientation
        viewer.orientation(opts.o);

        // items on demand
        viewer.append(getItem.bind(null, opts), ls.length);

		viewer.appendTo("body").show();

        // current item
        viewer.select(opts.n);

		// show notification and update URL when viewing new item or changing zoom level
        viewer.connect("mokaSelected mokaZoomChanged mokaLayoutChanged", function(ev, id) {
            if (typeof id == "undefined") {
                id = opts.n;
            }
            // URL: remember layout, zoom, orientation, current item number
            opts.zoom = viewer.zoom();
            opts.n = viewer.currentIndex();
            opts.layout = viewer.layout().join("x");
            saveOptions(opts);

            if (opts.notify) {
                if (!t_notify) t_notify = new Moka.Timer({callback:notify, delay:100});
                t_notify.data(id).start();
            }
        });

        viewer.addKey("G", showGoToDialog);
        viewer.addKey("C", showMenu.bind(null, opts));
        viewer.addKey("KP5",
                function(){
                    v.layout([4,3]);
                    v.zoom("fit");
                });

		viewer.focus();
    }

	onLoad = function() {
        var wnd, counter, widgets;

		opts = getOptions( urlHash() );

        $("body").height( $(window).height() );
        $(window).resize( function(){$("body").height( $(this).height() );} );

		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

        $("<style type='text/css'>.moka-view img{background:"+opts.background+"}</style>")
            .appendTo("head");

        if (opts.skiptitle_once) {
            delete opts.skiptitle_once;
            saveOptions(opts)
            return start(opts);
        }

        if (opts.skiptitle) {
            return start(opts);
        }

        wnd = new Moka.Window("<b>"+title+"</b> gallery");

        select = function(i, e){
            opts.n = i;
            if (opts.n < 0) {
                opts.n = ls.length-1;
            }
            if (opts.n >= ls.length) {
                opts.n = 0;
            }
            //return createCounter(opts.n, ls.length, 80, 4, 6, "rgba(100,50,20,0.4)", "white", 16, 8, e);
            return createCounter(opts.n, ls.length, 80, 4, 6, null, "white", 16, 8, e);
        }

        next = function(i, e){
            opts.n += i;
            select(opts.n, e);
        }

        prev = function(i, e){
            opts.n -= i;
            select(opts.n, e);
        }

        counter = new Moka.Input( select(opts.n) );

        widgets = new Moka.WidgetList();
        widgets.append( new Moka.Button("_Browse", wnd.close.bind(wnd)) );
        widgets.append( new Moka.Button("_Configure", showMenu.bind(null, opts)) );
        widgets.append(counter);
        wnd.append(widgets);

        next1 = next.bind(null, 1, counter.element())
        prev1 = prev.bind(null, 1, counter.element())
        next10 = next.bind(null, 10, counter.element())
        prev10 = prev.bind(null, 10, counter.element())

        wnd.addKey("+", next1);
        wnd.addKey("MINUS", prev1);
        wnd.addKey("PAGEDOWN", next10);
        wnd.addKey("PAGEUP", prev10);
        wnd.addKey("S-+", next10);
        wnd.addKey("S-MINUS", prev10);
        wnd.align("center");
        wnd.addKey("ENTER", wnd.close.bind(wnd));
        counter.addKey("RIGHT", next1);
        counter.addKey("LEFT", prev1);
        counter.addKey("S-RIGHT", next10);
        counter.addKey("S-LEFT", prev10);

        wnd.connect("mokaDestroyed", start.bind(null, opts));
        popup(wnd);
	};

	$(document).ready(onLoad);
}).call(this);
