(function() {
	var onLoad;

    createCounter = function (n, len, r, w1, w2, bg, fg, shadow, blur)
    {
        var e, ctx, pi, angle, x, y;

        e = $("<canvas class='counter'>");

        ctx = e[0].getContext("2d");
        pi = 3.1415;
        angle = len ? 2*pi*n/len : 0;
        x = r+blur/2;
        y = r+blur/2;

        e[0].setAttribute("width", r*2+blur);
        e[0].setAttribute("height", r*2+blur);

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
        var item, itempath, html, notification, counter;

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
            html =  "<b>" + (id + 1) + "/" + ls.length + "</b><br/>";
            // escape anchor and html
            html += "URL: <a href='"+itempath+"'>" + itempath + "</a></i><br/>";
            if ( item.e.width ) {
                html += "size: <i>" + item.e.width() + "x" + item.e.height() + "</i></br>";
            }
            html += "zoom: <i>" + (item.width ? Math.floor(100 * item.image.e.width() / item.width) + "%" : v.zoom()) + "</i>";
        }

        Moka.clearNotifications()
        if (html) {
            notification = new Moka.Notification("<table><tr><td></td><td>"+html, "", 4000, 300);
            counter = createCounter(id+1, ls.length, 24, 8, 4, "rgba(100,50,20,0.4)", "white", 12, 10);
            counter.appendTo(notification.e.find('td:first'));
            return notification;
        }
    }

	// onLoad
	onLoad = function() {
		var item, itempath, map, onLoad, v, wnd, i, len, hash, value;

		onLoad = void 0;
		if (typeof title != "undefined" && title !== null) {
			document.title = title;
		}

		// gallery widget
		v = new Moka.Viewer();

		// get configuration from URL hash
		hash = urlHash();
		value = hash.zoom;
		if (value) {
            value = value.split(",");
			v.zoom(value.length === 1 ? value[0] : value);
		}

		// layout, orientation
		value = hash.layout;
		if (value) {
			v.layout( value.split("x") );
		}

		value = hash.o;
		if (value) {
			v.orientation(value);
		}

		for (i = 0, len = ls.length; i < len; i++) {
			item = ls[i];
			if (item instanceof Array) {
				itempath = item[0];
			} else {
				itempath = item;
			}
			//console.log(itempath);
			v.append(new Moka.ImageView(itempath));
		}

        // current item
		value = hash.n;
		if (value) {
			v.view(value);
		}

		v.e.appendTo("body");
		v.show();

		// show notification and update URL when viewing new item or changing zoom level
		v.e.bind("mokaSelected mokaZoomChanged", function(ev, id) {
			if (ev.target !== this || !((id != null) || (oldid != null))) {
				return;
			}
			// URL: remember layout, zoom, orientation, current item number
			urlHash({
				layout: v.layout().join("x"),
				zoom:   v.zoom(),
                o:      v.orientation(),
				n:      v.index+v.current
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

		Moka.focus(v.e);

        $("body").height( $(window).height() );
        $(window).resize( function(){$("body").height( $(this).height() );} );
	};

	$(document).ready(onLoad);
}).call(this);
