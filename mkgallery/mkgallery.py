#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Creates web gallery of images and fonts present in current directory

Script parameters are switches (see usage()) and filenames (files and
directories).

Script recursively finds usable items in specified files and directories by
examining file extensions.

Supported file types (and extensions) are:
    * images (jpg, png, apng, gif, svg),
    * fonts (otf, ttf),
    * audio/movies (mp4, mov, flv, ogg, mp3, wav).
    * HTML
    * PDF

Function create_gallery() returns list of items. The list format is:
    {
        "item": # this represents the item in gallery (i.e. "items/img.png")
            { # all keys are jQuery selectors and are optional
                # use another name (e.g. font name)
                ".alias": "item alias",
                # path to the original file
                ".link": "link to original filename",
                # thumbnail size (see description below)
                ".thumbnail_size": [width, height]
            }
        ...
    }

Function write_items() saves the list in JavaScript format:
var ls = [
    [ "item",
        {
            ".alias": "item alias",
            ".link": "link to original filename",
            ".thumbnail_size": [width, height],
        }
    ],
    ...
]

Creating thumbnails can take a long time to complete therefore if user wants to
view the gallery, the list of items is saved before without ".thumbnail_size"
property and the thumbnails are generated afterwards.
"""

import os, sys, re, shutil, glob, getopt, locale, codecs, subprocess

has_python3 = sys.version[0] == '3'

# Python Imaging Library (PIL)
has_pil = True
try:
    from PIL import Image, ImageFont, ImageDraw, ImageChops
except ImportError:
    has_pil = False

S = os.sep
# input/argument encoding
Locale = locale.getdefaultlocale()[1]

# default values:
title="default" # html title and gallery directory name
resolution = 300 # thumbnail resolution
d = os.path.dirname(sys.argv[0]) or "." # path to template
home = 'HOME' in os.environ and os.environ['HOME'] or os.environ['HOMEDRIVE']+os.environ['HOMEPATH']+S+"My Documents"
gdir = home +S+ "Galleries" +S+ "%s"; # path to gallery
url = "http://localhost:8080/<path_to_gallery>/index.html" # browser url
progress_len = 40 # progress bar length

force = False # force file deletion?
font_render = False # render fonts?
font_size, font_text = 16, ""

rm_error = "ERROR: Existing gallery contains files that aren't symbolic links!\n"+\
        "       Use -f (--force) to remove all files."

# python3: change u'...' to '...'
if has_python3:
    re_flags = re.IGNORECASE|re.UNICODE
    re_img  = re.compile(r'\.(jpg|png|apng|gif|svg)$', re_flags)
    re_font = re.compile(r'\.(otf|ttf)$', re_flags)
    re_vid = re.compile(r'\.(mp4|mov|flv|ogg|mp3|wav)$', re_flags)
    re_html = re.compile(r'\.html$', re_flags)
    re_remote = re.compile(r'^\w+://', re_flags)
    re_fontname = re.compile(r'[^a-z0-9_]+', re_flags)
    re_tag = re.compile(r'^\$\(<.*\)$', re_flags)
    re_pdf = re.compile(r'\.pdf$', re_flags)
else:
    re_flags = re.IGNORECASE|re.UNICODE
    re_img  = re.compile( unicode(r'\.(jpg|png|apng|gif|svg)$' ), re_flags )
    re_font = re.compile( unicode(r'\.(otf|ttf)$' ), re_flags )
    re_vid = re.compile( unicode(r'\.(mp4|mov|flv|ogg|mp3|wav)$' ), re_flags )
    re_html = re.compile( unicode(r'\.html$' ), re_flags )
    re_remote = re.compile( unicode(r'^\w+://' ), re_flags )
    re_fontname = re.compile( unicode(r'[^a-z0-9_]+' ), re_flags )
    re_tag = re.compile( unicode(r'^\$\(<.*\)$'), re_flags )
    re_pdf = re.compile( unicode(r'\.pdf$' ), re_flags )

local = False
page = 0
title_page = False
empty = False
pdfto = "html"

def from_locale(string):#{{{
    global Locale
    if has_python3:
        return string.replace('\\n', '\n')
    else:
        return string.decode( Locale ).replace('\\n', '\n')
#}}}

def copy(src, dest):#{{{
    if os.path.isdir(src):
        shutil.copytree( src, dest )
    else:
        shutil.copyfile( src, dest )
#}}}

# default is create symbolic links
# if operation not supported, copy all files
try:
    cp = os.symlink
except:
    cp = copy

def usage():#{{{
    global title, resolution, gdir, url, d
    print( """\
            usage: %s [options] [directories|filenames]

  Creates HTML gallery containing images and fonts recursively
  found in given directories and files or in the current directory.

  The gallery is automatically viewed with default web browsser.

  For the program to be able to generate thumbnails and font names,
  the Python Imaging Library (PIL) must be installed.

  Empty file or directory name (i.e. "") means that all following files
  will be put on new item list page in gallery. This allows to break the list
  on several pages and decrease memory and time consumption needed to
  load items into the list.

options:
  -h, --help              prints this help
  -t, --title=<title>     gallery title
                            (default: '%s')
  -d, --directory=<dir>   path to gallery (%%s is replaced by <title>)
                            (default: '%s')
  --template=<dir>        path to template html and support files
                            (default: '%s')
  -u, --url=<url>         url location for web browser (%%s is replaced by <title>)
                            (default: '%s')
  -r, --resolution=<res>  resolution for thumbnails in pixels
                            (default: %s)
  -c, --copy              copy files instead of creating symbolic links
  -f, --force             overwrites existing gallery
  -l, --local             don't copy or create links to gallery items,
                          browse items locally, i.e. protocol is "file://"
  -x, --render=<size>,<text>
                          render fonts instead using them directly
  -p, --page              maximal number of items on one page
                          (if the argument is a negative number then each
                          directory/filename will be on separate page)
                            (default: 0 (unlimited))
                          NOTE: Use empty filename (i.e. "") to break
                          page in specific place.
  -P, --PDF=<format>      convert PDF to <format> (can be HTML, PNG, SVG or PDF)
  -T, --title-page        create title page
  -e, --empty             create empty gallery

  -r 0, --resolution=0    don't generate thumbnails
  -u "", --url=""         don't launch web browser
""" % (sys.argv[0], title, gdir, d, url, resolution) )
    #}}}

def dirname(filename):#{{{
    return os.path.dirname(filename).replace(':','_')
#}}}

def to_url(filename):#{{{
    global local

    if filename.startswith('items'+S):
        url = filename.replace('#','%23').replace('?','%3F').replace(';','%3B')
    elif not is_local(filename) or not local:
        url = filename
    else:
        url = 'file://'+os.path.abspath(filename).replace(S,'/').replace(':',"_")

    # escape double quotes (filenames in items.js enclosed in double quotes)
    url.replace('"','\\"')

    return url
#}}}

def walk(root):#{{{
    if os.path.isdir(root):
        for f in os.listdir(root):
            for ff in walk(root == "." and f or root+S+f):
                yield ff
    else:
        yield root
#}}}

def launch_browser(url):#{{{
    sys.stdout.write("Lauching default web browser: ")
    ok = False;

    try:
        import webbrowser
        # open browser in background
        w = webbrowser.BackgroundBrowser( webbrowser.get().name )
        if w.open(url):
            ok = True;
    except:
        pass;

    print(ok and "DONE" or "FAILED!")
#}}}

def parse_args(argv):#{{{
    """
    parse switches and arguments
    returns array of pages with files/directories (empty string is page break)
        e.g. [ [item1_on_page1, item2_on_page1, ...], [item1_on_page2, ...], ... ]
    """
    global title, resolution, gdir, url, d, cp, force, local, page, \
            font_render, font_size, font_text, title_page, empty, pdfto

    allfiles = []

    try:
        opts, args = getopt.gnu_getopt(argv, "ht:r:d:u:cflx:p:TeP:",
                ["help", "title=", "resolution=", "directory=", "url=",
                    "template=", "copy", "force", "local", "render=", "page=",
                    "title-page", "empty", "PDF="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    newurl = None
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif opt in ("-t", "--title"):
            title = arg
        elif opt in ("-d", "--directory"):
            gdir = arg
        elif opt in ("-u", "--url"):
            newurl = arg
        elif opt == "--template":
            d = arg
        elif opt in ("-r", "--resolution"):
            try:
                resolution = int(arg)
                if resolution<0:
                    resolution = 0
            except:
                print("ERROR: Resolution must be a single number!")
                sys.exit(1)
        elif opt in ("-c", "--copy"):
            cp = copy
        elif opt in ("-l", "--local"):
            local = True
        elif opt in ("-f", "--force"):
            force = True
        elif opt in ("-x", "--render"):
            font_render = True
            try:
                font_size, font_text = arg.split(',', 1)
                font_size = int(font_size)
            except:
                usage()
                sys.exit(1)
        elif opt in ("-p", "--page"):
            try:
                page = int(arg)
            except:
                print("ERROR: Page must be a single number!")
                sys.exit(1)
        elif opt in ("-T", "--title-page"):
            title_page = True
        elif opt in ("-e", "--empty"):
            empty = True
        elif opt in ("-P", "--PDF"):
            pdfto = arg.lower()
            if pdfto not in ["pdf", "html", "png", "svg"]:
                print("ERROR: PDF can be converted only to HTML, PNG or SVG!")
                sys.exit(1)

    # no PIL: warnings, errors
    if not has_pil:
        # cannot render font without PIL
        if font_render:
            print("ERROR: Cannot render font -- please install Python Imaging Library (PIL) module first.")
            sys.exit(10)
        # no thumbnails
        if resolution:
            print("WARNING: Thumbnails not generated -- please install Python Imaging Library (PIL) module.")
            resolution = 0

    try:
        gdir = gdir % title
    except:
        pass

    if newurl != None:
        url = newurl
    else:
        url = "file://"+ os.path.abspath(gdir) + "/index.html"

    try:
        url = url % title
    except:
        pass

    # parse files
    if empty:
        allfiles = []
    elif args:
        files = []
        for arg in args:
            # empty filename is page divider
            if not arg or page < 0:
                if files:
                    allfiles.append(files)
                    files = []
            if arg:
                files.append(arg)
        if files:
            allfiles.append(files)
    else:
        allfiles = [["."]]

    return allfiles
#}}}

def clean_gallery():#{{{
    global rm_error, d, gdir, force

    if not os.path.isdir(gdir):
        os.makedirs(gdir)
    # TODO: port (symbolic links only on UNIX-like platforms)
    srcdir = d+S+".."+S
    dstdir = gdir+S
    links = {
            srcdir+"deps":dstdir+"deps",
            srcdir+"img":dstdir+"img",
            srcdir+"moka.js":dstdir+"moka.js",
            srcdir+"mkgallery"+S+"gallery.js":dstdir+"gallery.js",
            srcdir+"mkgallery"+S+"gallery.css":dstdir+"gallery.css",
            srcdir+"mkgallery"+S+"template.html":dstdir+"index.html",
            srcdir+"mkgallery"+S+"favicon.png":dstdir+"favicon.png"
            }
    for f in links:
        link = links[f]
        if os.path.islink(link):
            os.remove(link)
        elif force and os.path.isfile(link):
            os.remove(link)
        elif os.path.isdir(link):
            if force:
                shutil.rmtree(link)
            else:
                exit(rm_error)
        cp( os.path.abspath(f), link )

    # clean items directory
    itemdir = gdir+S+"items"
    if os.path.isdir(itemdir):
        for f in walk(itemdir):
            # TODO: port
            if not (os.path.islink(f) or force):
                exit(rm_error)
        shutil.rmtree(itemdir)

    # clean thumbnail directory
    thumbdir = gdir+S+"thumbs"
    if os.path.isdir(thumbdir):
        if not force:
            exit(rm_error)
        shutil.rmtree(thumbdir)

    # omit item directory when creating local gallery
    if not local:
        os.mkdir(itemdir)

    shutil.copyfile(d+S+"config.js", gdir+S+"config.js")
#}}}

def addFont(fontfile, cssfile):#{{{
    global re_fontname, gdir

    # font file path
    f = fontfile
    if not local and is_local(fontfile):
        f = gdir +S+ f

    # TODO: fetch remote font?
    if not is_local(f):
        exit("ERROR: Don't know how to handle remote fonts!")

    # font name
    fontname = None
    try:
        font = ImageFont.truetype(f,8)
        name = font.getname()
        fontname = name[0]
        if name[1]:
            fontname = fontname + " " + name[1]
    except Exception as e:
        print("ERROR: "+str(e)+" (file: \""+fontfile+"\")")

    # render font
    outfile = fontfile
    link = None
    if font_render:
        outfile = "items" +S+ fontfile + ".png"
        link = fontfile
        try:
            renderFont(f, font_size, font_text, gdir +S+ outfile)
        except Exception as e:
            print("ERROR: "+str(e)+" (file: \""+fontfile+"\")")
    else:
        p = from_locale(to_url(fontfile))
        cssfile.write("@font-face{font-family:"+re_fontname.sub("_", p)+";src:url('"+p+"');}\n")

    return outfile, fontname, link
#}}}

def renderFont(fontfile, size, text, outfile):#{{{
    f = ImageFont.truetype(fontfile, size, encoding="unic")

    w = 0
    h = size/2
    im = Image.new("RGB", (w,h), "white")

    # render lines
    for line in ( from_locale(text) +'\n').split('\n'):
        if line:
            w2,h2 = f.getsize(line)
            w2 = w2+size
            h2 = h2
            im2 = Image.new("RGB", (w2,h2), "white")

            # render line
            draw = ImageDraw.Draw(im2)
            draw.text( (size/2,0), line, fill="black", font=f )
        else:
            # empty line
            w2 = 0
            h2 = size/2
            im2 = Image.new("RGB", (w2,h2), "white")

        w3 = max(w,w2)
        h3 = h+h2
        im3 = Image.new("RGB", (w3,h3), "white")

        # join images
        im3.paste( im, (0,0,w,h) )
        im3.paste( im2, (0,h,w2,h3) )

        im = im3
        w, h = w3, h3

    d = dirname(outfile)
    if not os.path.isdir(d):
        os.makedirs(d)
    im.save(outfile, "PNG")
#}}}

def renderPDF(pdffile):#{{{
    sys.stdout.write("Generating pages for \"" + pdffile + "\" ... ")
    sys.stdout.flush()

    outdir = pdffile + "_pages"
    itemdir = gdir +S+ "items"
    os.makedirs(itemdir +S+ outdir)

    pages = []
    if pdfto == "pdf":
        pages = [pdffile]
    elif pdfto == "html":
        outfile = outdir +S+ "p.html"
        try:
            res = subprocess.call(["pdftohtml", "-p", "-c", pdffile, itemdir +S+ outfile])
            if res == 0:
                pages.append(outfile)
                print("DONE")
                pages = [outdir +S+ f for f in os.listdir(itemdir +S+ outdir) if f.startswith("p-")]
            else:
                print("ERROR")
                exit(1)
        except:
            print("NOT CONVERTED\nNOTE: To convert PDF pages to HTML pdftohtml application must be installed.")
    elif pdfto == "svg":
        outfile = outdir +S+ "%04d.svg"
        try:
            res = subprocess.call(["pdf2svg", pdffile, itemdir +S+ outfile, "all"])
            if res == 0:
                pages.append(outfile)
                print("DONE")
                pages = [outdir +S+ f for f in os.listdir(itemdir +S+ outdir)]
            else:
                print("ERROR")
                exit(1)
        except:
            print("NOT CONVERTED\nNOTE: To convert PDF pages to SVG pdf2svg application must be installed (more info at: http://www.cityinthesky.co.uk/pdf2svg.html).")
    elif pdfto == "png":
        outfile = outdir +S+ "p.html"
        try:
            res = subprocess.call(["pdftoppm", "-png", pdffile, itemdir +S+ outfile])
            if res == 0:
                pages.append(outfile)
                print("DONE")
                pages = [outdir +S+ f for f in os.listdir(itemdir +S+ outdir)]
            else:
                print("ERROR")
                exit(1)
        except:
            print("NOT CONVERTED\nNOTE: To convert PDF pages to images pdftoppm application must be installed.")

    return pages;
#}}}

def is_local(filename):#{{{
    global re_remote, re_tag

    return re_remote.search(filename) == None and re_tag.search(filename) == None
#}}}

def find_items(ff):#{{{
    """ return unfiltered list of items from specified directories """
    global gdir

    abs_gdir = os.path.abspath(gdir)

    # return remote file name
    if not is_local(ff):
        yield ff
    else:
        # recursively look for other files
        for f in walk(ff):
            abs_f = os.path.abspath(f)
            # ignore gallery generated directories
            if abs_f.startswith(abs_gdir+S+"deps"+S) or \
                    abs_f.startswith(abs_gdir+S+"img"+S) or \
                    abs_f.startswith(abs_gdir+S+"items"+S) or \
                    abs_f.startswith(abs_gdir+S+"thumbs"+S):
                        continue

            yield f
#}}}

# item type#{{{
class Type:
    UNKNOWN = 0
    IMAGE = 1
    FONT  = 2
    VIDEO = 3
    HTML = 4
    PDF = 5
    TAG = 6

def item_type(f):
    global re_img, re_font, re_vid, re_tag

    types = {
            Type.IMAGE: re_img,
            Type.FONT:  re_font,
            Type.VIDEO: re_vid,
            Type.HTML:  re_html,
            Type.PDF:   re_pdf,
            Type.TAG:   re_tag
            }

    for t, re in types.items():
        if re.search(f) != None:
            return t

    return Type.UNKNOWN
#}}}

def gallery_items(files, allitems):#{{{
    """
    finds all usable items in specified files/directories (argument),
    copy items to "items/" (if --local not set),
    return items
    """
    global re_img, re_font, re_vid, gdir

    imgdir = gdir+S+"items"
    # find items in input files/directories
    for ff in files:
        items = {}
        for f in find_items(ff):
            # filetype (image, font, audio/video)
            t = item_type(f)

            if t>0:
                # file is local and not viewed locally
                if not local and is_local(f):
                    destdir = dirname(f)
                    basename = os.path.basename(f)
                    fdir = imgdir +S+ destdir
                    if not os.path.isdir(fdir):
                        os.makedirs(fdir)
                    cp( os.path.abspath(f), fdir +S+ basename )
                    itempath = "items" +S+ (destdir and destdir+S or "") + os.path.basename(f)

                # TODO: fetch remote PDF before rendering
                if t == Type.PDF:
                    for page in renderPDF(f):
                        items["items" +S+ page] = {'.link':itempath}
                else:
                    items[itempath] = {}

        add_sorted(items, allitems)
#}}}

def create_fontfaces(items):#{{{
    cssfile = codecs.open( gdir +S+ "fonts.css", "w", "utf-8" )

    fonts = [font for font in filter(lambda x: re_font.search(x[0]), items)]

    # number of fonts
    n = len(fonts)
    if n == 0:
        return # no fonts

    # progress bar
    i = 0
    bar = ">" + (" "*progress_len)
    sys.stdout.write( "Creating fontfaces: [%s] %d/%d\r"%(bar,0,n) )

    for font in fonts:
        # if file is font: create font-face line in css or render it
        f, alias, link = addFont(font[0], cssfile)
        font[0] = f

        props = font[1]
        if alias:
            props['.alias'] = alias
        if link:
            props['.link'] = to_url(link)

        # show progress bar
        i=i+1
        l = int(i*progress_len/n)
        bar = ("="*l) + ">" + (" "*(progress_len-l))
        sys.stdout.write( "Creating fontfaces: [%s] %d/%d%s"%(bar,i,n,i==n and "\n" or "\r") );
        sys.stdout.flush()

    cssfile.close()
#}}}

def create_thumbnail(filename, resolution, outfile):#{{{
    # create directory for output file
    d = dirname(outfile)
    if not os.path.exists(d):
        os.makedirs(d)

    im = Image.open(filename)

    # better scaling quality when image is in RGB or RGBA
    #if not im.mode.startswith("RGB"):
        #im = im.convert("RGB")

    # scale and save
    im.thumbnail( (resolution,resolution), Image.ANTIALIAS )
    im.save( outfile + ".png", "PNG", quality=60 )

    return im.size
#}}}

def create_thumbnails(items):#{{{
    global local, resolution, force, gdir

    thumbdir = gdir+S+"thumbs"

    images = [img for img in filter(lambda x: re_img.search(x[0]), items)]

    # number of images
    n = len(images)
    if n == 0:
        return # no images

    # create thumbnail directory
    os.makedirs(thumbdir)

    # progress bar
    i = 0
    bar = ">" + (" "*progress_len)
    sys.stdout.write( "Creating thumbnails: [%s] %d/%d\r"%(bar,0,n) )

    lines = "var ls=[\n"
    for img in images:
        f = img[0]
        props = img[1]
        w = h = 0
        try:
            if '.link' in props:
                # use rendered image in '<gallery>/items/<filename>.png'
                infile = gdir +S+ f.replace(':','_')
                if local:
                    outfile = thumbdir +S+ f.replace(':','_')
                else:
                    outfile = thumbdir +S+ f.replace(':','_')
            else:
                if not local and is_local(f):
                    infile = gdir +S+ f.replace(':','_')
                else:
                    infile = os.path.abspath(f)
                outfile = thumbdir +S+ to_url(f).replace(':','_')

            w,h = create_thumbnail(infile, resolution, outfile)
            props['.thumbnail_size'] = [w,h]
        except Exception as e:
            print("ERROR: "+str(e)+" (file: \""+f+"\")")

        # show progress bar
        i=i+1
        l = int(i*progress_len/n)
        bar = ("="*l) + ">" + (" "*(progress_len-l))
        sys.stdout.write( "Creating thumbnails: [%s] %d/%d%s"%(bar,i,n,i==n and "\n" or "\r") );
        sys.stdout.flush()

    print("Thumbnails successfully generated.")
#}}}

def thumbnail_size(filename, resolution):#{{{
    """ return same resolution as Image.thumbnail() """
    try:
        im = Image.open(filename)
        w,h = im.size
        if w>h:
            if w>resolution:
                h = h*resolution/w
                w = resolution
        else:
            if h>resolution:
                w = w*resolution/h
                h = resolution

        return [w,h]
    except:
        return [0,0]
#}}}

def write_items(items):#{{{
    itemfile = codecs.open( gdir +S+ "items.js", "w", "utf-8" )
    itemfile.write('var title = "'+title+'";\nvar ls=[\n');

    for item in items:
        if len(item) == 2:
            itemfile.write( from_locale(str([to_url(item[0]),item[1]]))+',\n' )
        else:
            itemfile.write( from_locale(str(item))+',\n' )

    itemfile.write("];\n");
    itemfile.close()
#}}}

def add_sorted(items, allitems):#{{{
    """ create pages of sorted items """
    global page

    def try_int(s):
        "Convert to integer if possible."
        try: return int(s)
        except: return s

    def natsort_key(s):
        "Used internally to get a tuple by which s is sorted."
        import re
        return map(try_int, re.findall(r'(\d+|\D+)', s))

    i = 0
    # maximal number of items per page
    #for item in sorted( items, key=lambda x: x.lower() ):
    for item in sorted( items, key=lambda x: list(natsort_key(x)) ):
        allitems.append([item, items[item]])
        if page > 0:
            i=i+1
            if i%page == 0:
                allitems.append([""])

    return allitems
#}}}

def main(argv):#{{{
    global title, resolution, gdir, url, d, force, page, title_page

    # arguments
    allfiles = parse_args(argv)

    # clean gallery directory
    clean_gallery()

    # sorted items with page dividers
    allitems = []
    for files in allfiles:
        # page divider
        if allitems:
            allitems.append([""])
        items = gallery_items(files, allitems)

    # no usable items found
    if not empty and not allitems:
        print("No items in gallery!")
        exit(1)

    # write font faces to CSS file
    create_fontfaces(allitems)

    # create title page
    if title_page:
        line = '<div id="title_page">'

        # FIXME: replace single quotes
        line = line + '<div class="title">' + title + '</div>'

        # date
        from datetime import date
        line = line + '<div class="date">' + date.today().isoformat() + '</div>'

        # number of items
        count = {}
        cls = {
                Type.IMAGE:'images',
                Type.FONT: 'fonts',
                Type.VIDEO:'videos',
                Type.HTML: 'html',
                'pages': 'pages',
                'items': 'items'
                }
        for item in allitems:
            if item[0]:
                t = item_type(item[0])
                if t in cls:
                    count['items'] = count.get('items',0)+1
                    count[t] = count.get(t,0)+1
            else:
                cls['pages'] = count.get('pages',0)+1
        for t in count:
            line = line + '<div class="stat '+cls[t]+'_total">' + str(count[t]) + '</div>'

        # prepend title page to item list
        allitems.insert( 0, ["$("+line+"</div>)",{'.alias':'Title page'}] )

    # open browser?
    if url:
        # write items.js so we can open it in browser
        write_items(allitems)
        launch_browser(url)

    if resolution:
        create_thumbnails(allitems)

    if not url or resolution:
        write_items(allitems)

    print("New gallery was created in: '"+gdir+"'")
#}}}

if __name__ == "__main__":
    main(sys.argv[1:])

