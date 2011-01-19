wnd_count = 0
window.test = () -># {{{
    wnd = new Moka.Window("Widget Test - Window #{++wnd_count}")

    p0 = new Moka.WidgetList()

    p1 = new Moka.WidgetList()
        .append( new Moka.TextEdit("text _edit widget:", "type some text\nhere", true) )
        .append( new Moka.TextEdit("text _edit widget:", "type some text here") )
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
# }}}

onLoad = () -># {{{
    onLoad = undefined

    # vim cmd: .!cd ??? && ls|sed 's_^_        "file://'"$PWD"'/_;s/$/",/g'
    items = [# {{{
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/AlbedoSublimis.jpg",
        #"BAD.png"
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/AeternaSaltatus.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/amore.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Magia of the Heart.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Aura Gloriae.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/In The Wake of the.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Sapientia.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Seraphim Awakening.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/SirensDream.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Soror Mystica.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/Telluric Womb.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Angel of Nekyia.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Breath of Dakini.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Love of Souls.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Oracle of the Pearl.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Summoning of the Muse.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/The Visitation.jpg",
        "file:///home/lukas/Pictures/paintings/Andrew Gonzales/UnioMystica.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/_Color_Me_Blood_Red__by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/Eros_Psyche_by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/_Kohtalo_.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/_MoonGoddess__by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/_Seven_Deadly_Sins__ENVY__by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__AVARICE_by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__LUST_by_blackeri.jpg",
        #"file:///home/lukas/Pictures/paintings/blackeri/The_Seven_Deadly_Sins__VANITY_by_blackeri.jpg",
        #"http://th00.deviantart.net/fs71/150/f/2010/291/f/4/emoticon_complete_set_by_deviantwear-d2eyuej.jpg",
        #"BAD.PNG"
        #"http://fc02.deviantart.net/fs70/i/2011/004/2/6/hand_study_by_moni158-d36ghy8.png",
        #"http://th01.deviantart.net/fs70/150/i/2010/194/c/f/Brainiac_Revival_by_deviantWEAR.jpg",
        #"http://fc00.deviantart.net/fs71/i/2011/004/0/e/tabunne_used_attract_by_purplekecleon-d36gjbo.png",
        #"http://fc05.deviantart.net/fs71/f/2011/005/6/6/66d4e85d1495eba5b234f5d552847c47-d36gl37.jpg",
        #"http://a.deviantart.net/avatars/s/c/scarabuss.jpg",
        #"http://fc08.deviantart.net/fs71/f/2011/005/4/7/47a8a74e458d99fd29323469273fd342-d36gr39.jpg",
        #"http://fc09.deviantart.net/fs70/i/2011/004/f/b/the_piazza_by_hougaard-d36gjw2.jpg",
        #"http://fc05.deviantart.net/fs71/f/2011/005/b/6/b676f3b93048c2763c5d4d0390b55ce3-d36gpaa.jpg",
        #"http://fc06.deviantart.net/fs70/i/2011/005/3/6/when_i_turn__i_know_u_re_there_by_piddling-d36gr3o.jpg",
        #"http://fc06.deviantart.net/fs70/f/2011/005/9/e/pirate_bat_thing_by_kikariz-d36gpfb.jpg",
        #"http://fc06.deviantart.net/fs71/i/2011/005/0/2/__traitor___by_moni158-d36grnr.png",
        #"http://fc08.deviantart.net/fs71/f/2011/004/a/b/legend_of_zelda__bartering_by_teh_akuma_yoru-d36gi4z.png",
        #"http://fc07.deviantart.net/fs71/i/2011/005/f/e/__why_so_curious____by_whitespiritwolf-d36grdg.jpg",
        #"http://fc02.deviantart.net/fs70/i/2011/004/7/d/happy_new_year_2011_by_jurithedreamer-d36gga7.jpg",
        #"http://fc02.deviantart.net/fs71/f/2011/005/c/8/lifeless_by_konoe_lifestream-d36gpue.jpg",
        #"http://a.deviantart.net/avatars/a/n/anndr.jpg",
        #"http://fc09.deviantart.net/fs70/i/2011/005/4/5/sophie_concept_by_anndr-d36glbl.jpg",
        #"http://fc05.deviantart.net/fs71/i/2011/005/d/a/show_me_how_you_burlesque_by_aramismarron-d36gjlq.jpg",
        #"http://fc03.deviantart.net/fs71/f/2011/004/a/e/ae8ff2e616b52995f2a0ad1123c41156-d36ghb2.jpg",
        #"http://fc04.deviantart.net/fs70/f/2011/004/1/7/179e9294b584e883a23d5c75d765eb04-d36ghb1.png",
        #"http://fc02.deviantart.net/fs70/f/2011/005/4/4/44d9adc4cf8255876545e6bd04425055-d36gktx.jpg",
        #"http://fc09.deviantart.net/fs70/f/2011/005/f/7/f7b7a7d2bd6faa5e92d2e97fe55bbafb-d36gt8q.jpg",
        #"http://fc02.deviantart.net/fs71/f/2011/005/c/2/c2c781adcc82df1c799a0d893c493ad3-d36gpk5.jpg",
        #"http://fc01.deviantart.net/fs71/i/2011/005/9/b/stand_in_the_heavens_by_moni158-d36gu2p.png",
        #"http://fc01.deviantart.net/fs70/f/2011/004/0/c/wabam_by_larkismyname-d36gk25.png",
        #"http://fc08.deviantart.net/fs70/i/2010/328/f/9/snow_white_death_by_andyfloss2000-d2v7ho9.jpg",
        #"http://th01.deviantart.net/fs70/150/i/2010/328/f/9/snow_white_death_by_andyfloss2000-d2v7ho9.jpg",
        #"http://fc02.deviantart.net/fs70/f/2010/363/4/5/v_day_in_deland_by_doubtful_della-d35zffu.jpg",
        #"http://th09.deviantart.net/fs70/150/f/2010/363/4/5/v_day_in_deland_by_doubtful_della-d35zffu.jpg",
        #"http://th06.deviantart.net/fs71/PRE/i/2010/332/5/1/the_jealous_by_gsackesen-d33stab.jpg",
        #"http://fc00.deviantart.net/fs71/i/2010/332/5/1/the_jealous_by_gsackesen-d33stab.jpg",
        #"http://th09.deviantart.net/fs71/150/i/2010/332/5/1/the_jealous_by_gsackesen-d33stab.jpg",
        #"http://th03.deviantart.net/fs71/150/i/2010/347/4/b/unaware___wallpaper_pack_by_mpk-d34tr3h.jpg",
        #"http://th07.deviantart.net/fs70/PRE/f/2010/049/8/4/evo_VS_gtr__drift__by_3dmanipulasi.jpg",
        #"http://fc06.deviantart.net/fs70/f/2010/049/8/4/evo_VS_gtr__drift__by_3dmanipulasi.jpg",
        #"http://th05.deviantart.net/fs70/150/f/2010/049/8/4/evo_VS_gtr__drift__by_3dmanipulasi.jpg",
        #"http://th06.deviantart.net/fs35/150/i/2008/239/d/5/The_Naked_Truth_by_kjcharmedfreak.jpg",
        #"http://th08.deviantart.net/fs70/150/i/2010/118/d/b/Acrylic_training_3_by_Pendalune.jpg",
    ]# }}}

    #items=[
        #'http://4.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/0000.jpg','http://6.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/disclaimer.jpg','http://7.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side001.jpg','http://3.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side002.jpg','http://3.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side003.jpg','http://7.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side004.jpg','http://2.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side005.jpg','http://9.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side006.jpg','http://9.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side007.jpg','http://0.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side008.jpg','http://5.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side009.jpg','http://4.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side010.jpg','http://5.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side011.jpg','http://8.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side012.jpg','http://1.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side013.jpg','http://8.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side014.jpg','http://6.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side015.jpg','http://0.p.s.mfcdn.net/store/manga/150/00-001.0/compressed/side016.jpg','',
        #'http://0.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/0000.jpg','http://1.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/disclaimer.jpg','http://9.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side017.jpg','http://4.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side018.jpg','http://3.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side019.jpg','http://7.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side020.jpg','http://6.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side021.jpg','http://8.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side022.jpg','http://2.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side023.jpg','http://5.p.s.mfcdn.net/store/manga/150/00-002.0/compressed/side024.jpg','',
    #]

    map = {}
    location.search.replace( /[?&]+([^=&]+)=([^&]*)/gi,
        (m,key,value) -> map[key] = value )

    # Viewer test {{{
    v = new Moka.Viewer()
       .layout(map.layout.split("x"))
       .orientation(if map.o then map.o else "lt")
       #.layout([2,1])
       #.layout([0,1])
    #v.append(
        #new Moka.ButtonBox().append("Button _1", () -> alert "click 1!")
                       #.append("Button _2", () -> alert "click 2!")
    #)
    v.append( new Moka.ImageView(item) ) for item in items
    #v.append( new Moka.Image(item) ) for item in items
    #v.append( new Moka.Button(i, ((x) ->-> alert x)(i)) ) for i in [0..36]

    # Viwer in document
    v.e.appendTo("body")
    v.show()

    # notifications
    oldid = undefined
    notify = (id) ->
        if id?
            oldid = id
        else
            id = oldid
        Moka.notificationLayer?.empty()
        img = v.at(id)
        new Moka.Notification(
            "<b>#{id+1}/#{items.length}</b><br/>"+
            "URL: <i>#{items[id]}</i><br/>"+
            (if img.width then "size: <i>#{img.width}x#{img.height}</i></br>" else "") +
            "zoom: <i>#{if img.width then Math.floor(100*img.image.e.width()/img.width)+"%" else img.zhow}</i>",
            "", 4000, 300
        )

    v.e.bind "mokaSelected mokaZoomChanged", (ev, id) ->
        return if ev.target isnt this or not (id? or oldid?)
        notify(id)

    # Viewer in window
    #wnd = new Window("Viewer")
         #.append(v)
         #.resize(500, 300)
         #.show()
    #wnd.e.appendTo("body")
    #wnd.focus()
    # }}}

    wnd = new Moka.Window("HELP - <i>JavaScript generated window</i>")
    wnd.append(
        new Moka.Container(true).append(
            new Moka.Container().append(
                new Moka.Label("Moka is JavaScript GUI framework."),
                new Moka.ButtonBox().append("Add _New Window", test).append("_Close", () -> wnd.close())
            ),
            new Moka.Image("img/moka.png", 96, 96).show()
        )
    )
    wnd.addKey("shift-t", test)
    wnd.do( (e) -> e.prependTo("body") )
       .position(0, 150)
       .show()
       .focus()

    v.zoom(map.zoom)
# }}}

$(document).ready(onLoad)

