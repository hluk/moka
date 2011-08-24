(function() {
	var onLoad, viewer, gotownd, menu;

    createCounter = function (n, len, r, w1, w2, bg, fg, shadow, blur)
    {
        var e, ctx, pi, angle, x, y;

        e = $("<canvas class='counter'>");

        ctx = e[0].getContext("2d");
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
		var hash, key;

		if (typeof values != "undefined" && values !== null) {
			hash = "";
			for (var key in values) {
				hash += (hash ? "&" : "") + key + "=" + values[key];
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

    // show notification
    oldid = void 0;
    notify = function(v, id) {
        var item, itempath, html, notification, counter, label, r, w1, w2, e;

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
            if ( item.width() )
                html += "size: <i>" + item.width() + "x" + item.height() + "</i></br>";
            else
                item.one("mokaLoaded", function(){notify(v,id);})
            if ( v.zoom() !== 1 ) {
                html += "zoom: <i>" + (item.width ? Math.floor(100 * item.image.e.width() / item.width) + "%" : v.zoom()) + "</i>";
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
        var close, closed, accept, hash,
            lineedit_order, lineedit_layout, lineedit_zoom, lineedit_sharpen,
            widgets, buttons;

        if (menu) {
            menu.focus();
            return;
        }

        menu = new Moka.Window("Menu");

        hash = urlHash();

        close = function() {
            menu.close();
        }
        closed = function() {
            menu = null;
        }
        accept = function() {
            menu.close();
            hash.layout = lineedit_layout.value();
            hash.o = lineedit_order.value();
            hash.zoom = lineedit_zoom.value();
            hash.sharpen = lineedit_sharpen.value();
            urlHash(hash);
            window.location.reload();
        }

        widgets = new Moka.WidgetList();

        // item order
        lineedit_order = new Moka.LineEdit("O_rder:", hash.o);
        widgets.append( new Moka.Container().append(lineedit_order, new Moka.Label("Examples: <i>lt</i> for left-top or <i>br</i> for bottom-right")) );

        // layout
        lineedit_layout = new Moka.LineEdit("_Layout:", hash.layout);
        widgets.append( new Moka.Container().append(lineedit_layout, new Moka.Label("Examples: <i>2x3</i> or <i>2x-1</i> (for continuous view)")) )

        // zoom
        lineedit_zoom = new Moka.LineEdit("_Zoom factor:", hash.zoom);
        widgets.append( new Moka.Container().append(lineedit_zoom, new Moka.Label("Examples: <i>1</i>, <i>1.5</i>, <i>fit</i>, <i>fill</i>")) )

        // sharpen
        lineedit_sharpen = new Moka.LineEdit("_Sharpen factor:", hash.sharpen);
        widgets.append( new Moka.Container().append(lineedit_sharpen, new Moka.Label("Values from <i>0.0</i> to <i>1.0</i>")) )

        // buttons
        buttons = new Moka.ButtonBox();
        buttons.append("_Ok", accept);
        buttons.append("_Close", close);

        menu.append(widgets, buttons);

        menu.addKey("ENTER", accept);
        menu.connect("mokaDestroyed", closed);

        menu.appendTo("body").center().show().focus();
    }

    start = function(hash) {
		var item, itempath, map, onLoad, v, wnd, i, len, hash, value, sharpen;

		onLoad = void 0;
		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

		// gallery widget
		v = new Moka.Viewer();

		// get configuration from URL hash
		value = hash.zoom;
		if (value) {
            value = value.split(",");
            console.log(value);
			v.zoom(value.length === 1 ? value[0] : value);
		}

		// layout
		value = hash.layout;
		if (value) {
			v.layout( value.split("x") );
		}

        // orientation
		value = hash.o;
		if (value) {
			v.orientation(value);
		}

        // sharpen
		sharpen = hash.sharpen || 0;

        // TODO: create ImageViews on demand
		for (i = 0, len = ls.length; i < len; i++) {
			item = ls[i];
			if (item instanceof Array) {
				itempath = item[0];
			} else {
				itempath = item;
			}
			//console.log(itempath);
            if (sharpen > 0) {
                v.append(new Moka.ImageView(itempath, true, sharpen));
            } else {
                v.append(new Moka.ImageView(itempath));
            }
		}

        // current item
		value = hash.n;
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
			urlHash({
				layout: v.layout().join("x"),
				zoom:    v.zoom(),
                sharpen: sharpen,
                o:       v.orientation(),
				n:       v.index+v.current
			})

			return notify(v, id);
		});

		//wnd = new Moka.Window("HELP - <i>JavaScript generated window</i>");
		//wnd.addKey("shift-t", test);
		//wnd.appendTo("body").position(0, 150);

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
        var wnd, hash, counter, widgets;

		hash = urlHash();

        $("body").height( $(window).height() );
        $(window).resize( function(){$("body").height( $(this).height() );} );

		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

        if (hash.title === "0") {
            return start(hash);
        }

        wnd = new Moka.Window("<b>"+title+"</b> gallery");

        counter = createCounter(hash.n, ls.length, 80, 4, 6, "rgba(100,50,20,0.4)", "white", 16, 8);
        wnd.align("center");
        widgets = new Moka.WidgetList();
        widgets.append( new Moka.Button("_Browse", function(){wnd.close();}) );
        widgets.append( new Moka.Button("_Configure", showMenu) )
        wnd.append( new Moka.Widget(counter), widgets );
        wnd.addKey("ENTER", function(){wnd.close();});
        wnd.connect("mokaDestroyed", function(){start(hash);});

        wnd.appendTo("body").center().show().focus();
	};

	$(document).ready(onLoad);
}).call(this);
