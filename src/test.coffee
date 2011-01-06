wnd_count = 0
test = () -># {{{
    wnd = new Window("Widget Test - Window #{++wnd_count}")

    p0 = new WidgetList()

    p1 = new WidgetList()
        .append( new TextEdit("text _edit widget:", "type some text\nhere", true) )
        .append( new TextEdit("text _edit widget:", "type some text here") )
        .append( new Button("_Button", () -> alert "CLICKED") )
        .append( new CheckBox("_Checkbox") )
        .append( new CheckBox("C_heckbox", true) )

    p2 = new ButtonBox()
        .append("Button_1", () -> alert "1 CLICKED")
        .append("Button_2", () -> alert "2 CLICKED")
        .append("Button_3", () -> alert "3 CLICKED")
        .append("Button_4", () -> alert "4 CLICKED")

    p3_2_1 = new Tabs()
          .setVertical()
          .append("page _U", $("<div>"))
          .append("page _V", $("<div>"))
          .append("page _W", $("<div>"))
    p3_1 = new Tabs()
          .setVertical()
          .append("page _1", $("<div>"))
          .append("page _2", p3_2_1)
          .append("page _3", $("<div>"))
    p3 = new Tabs()
       .setVertical()
       .append("page _X", p3_1)
       .append("page _Y", $("<div>"))
       .append("page _Z", $("<div>"))

    p4_2_1 = new Tabs()
          .append("page _U", $("<div>"))
          .append("page _V", $("<div>"))
          .append("page _W", $("<div>"))
    p4_1 = new Tabs()
          .append("page _1", $("<div>"))
          .append("page _2", p4_2_1)
          .append("page _3", $("<div>"))
    p4 = new Tabs()
       .append("page _X", p4_1)
       .append("page _Y", $("<div>"))
       .append("page _Z", $("<div>"))

    w = new Tabs()
       .setVertical()
       .append("page _A", p1)
       .append("page _B", p2)
       .append("page _C", p3)
       .append("page _D", p4)
    wnd.append(w)

    $(".value").css 'font-family': "monospace"
    $(".page").addClass("valign")

    $(".widgetlistitem").bind("mokaSelected", (e, id) -> log "ITEM #{id} SELECTED")
    $(".buttonbox .button").bind("mokaSelected", (e, id) -> log "BUTTON #{id} SELECTED")
    $(".tab").bind("mokaSelected", (e, id) -> log "TAB #{id} SELECTED")

    wnd.e.prependTo("body")
    wnd.show()
    wnd.focus()
# }}}

onLoad = () -># {{{
    onLoad = undefined

    init_GUI()

    items = [
        "file:///home/lukas/Pictures/drawings/Arantza/arantza001.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza002.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza003.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza004.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza005.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza006.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza007.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza009.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza010.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza011.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza012.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza013.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza014.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza015.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza016.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza017.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza018.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza021.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza022.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza023.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza024.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza025.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza026.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza027.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza028.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza030.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza031.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza032.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza033.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza034.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza035.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza036.jpg",
        "file:///home/lukas/Pictures/drawings/Arantza/arantza037.jpg",
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
    ]

    v = new Viewer()
       .layout([2,1])
       .zoom("")
    v.append( new ImageView(item) ) for item in items
    v.e.appendTo("body")
    v.show()

    #wnd = new Window("HELP")
         #.append( createLabel("Double click on the button to add new window!") )
         #.append( new Button("Add _New Window", test) )
         #.show()
    #wnd.e.css({'right':0, 'bottom':0}).appendTo("body")
    #wnd.focus()
# }}}

$(document).ready(onLoad)

