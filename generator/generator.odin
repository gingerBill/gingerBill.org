package generator

import "core:fmt"
import "core:io"
import "core:time"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:encoding/json"
import "core:mem/virtual"
import os "core:os/os2"

import cm "vendor:commonmark"

PUBLIC_PREFIX :: "public"

Website :: struct {
	arena: virtual.Arena,

	articles: [dynamic]Article,

	aliases: map[string]string,

	series: map[string]^Series,
}

Article :: struct {
	title:       string,
	url:         string,
	date:        string,
	description: string,
}

Series :: struct {
	name:     string,
	url_name: string,
	articles: [dynamic]Article,
}

Archetype :: struct {
	title:       string,
	description: string,
	slug:        string,
	author:      string,
	date:        string,
	categories:  []string,
	tags:        []string,
	aliases:     []string,
	series:      []string,

	year, month, day: int `json:"-"`,
}

add_article :: proc(website: ^Website, url: string, a: Archetype) -> Article {
	arena_allocator := virtual.arena_allocator(&website.arena)
	a := Article{
		title       = strings.clone(a.title, arena_allocator),
		url         = strings.clone(strings.trim_suffix(url, "index.html"), arena_allocator),
		date        = fmt.aprintf("%04d-%02d-%02d", a.year, a.month, a.day, allocator=arena_allocator),
		description = strings.clone(a.description, arena_allocator),
	}
	append(&website.articles, a)
	return a
}

@(require_results)
validate_archetype :: proc(a: ^Archetype, arena: ^virtual.Arena) -> bool {
	@(require_results)
	validate_date :: proc(date: string, a: ^Archetype) -> (y, m, d: int, ok: bool) {
		if date == "" {
			fmt.eprintln("Date is empty", a)
			return
		}
		if len(date) != 10 || date[4] != '-' || date[7] != '-' {
			fmt.eprintln("Date not in YYYY-MM-DD format", a)
			return
		}

		year  := date[0:4]
		month := date[5:7]
		day   := date[8:10]

		y = strconv.parse_int(year)  or_return
		m = strconv.parse_int(month) or_return
		d = strconv.parse_int(day)   or_return
		ok = true
		return
	}


	arena_allocator := virtual.arena_allocator(arena)

	a.year, a.month, a.day = validate_date(a.date, a) or_return

	if a.title == "" {
		fmt.eprintln("Missing title")
		return false
	}

	if a.slug == "" {
		slug := strings.to_lower(a.title, arena_allocator)
		slug, _ = strings.replace_all(slug, " ", "-", arena_allocator)

		a.slug = slug
	}

	if strings.has_suffix(a.slug, ".html") {
		fmt.eprintln("slug cannot end with .html")
		return false
	}

	if a.author == "" {
		a.author = "Ginger Bill"
	}

	return true
}

write_header :: proc(w: io.Writer, info: union{Archetype, string}, summary: string = "") {
	io.write_string(w,
`<!DOCTYPE html>
<html lang="en-gb">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
`)

	#partial switch v in info {
	case Archetype:
		fmt.wprintfln(w,`<meta name="twitter:card" content="summary">`)
		fmt.wprintfln(w,`<meta name="twitter:title" content="%s">`, v.title)
		fmt.wprintfln(w,`<meta name="twitter:description" content="%s">`, summary if summary != "" else v.description)
	}

	io.write_string(w, `
	<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
	<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
	<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
	<link rel="manifest" href="/site.webmanifest">
	<link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5">
	<meta name="msapplication-TileColor" content="#da532c">
	<meta name="theme-color" content="#ffffff">

`)
	switch v in info {
	case Archetype: fmt.wprintf    (w, ` <title>%s - gingerBill</title>`+"\n", v.title)
	case string:    fmt.wprintf    (w, ` <title>%s</title>`+"\n", v)
	case:           io.write_string(w, ` <title>gingerBill</title>`+"\n")
	}

	io.write_string(w, `
	<link rel="stylesheet" href="/css/normalize.css" />
	<link rel="stylesheet" href="/css/style.css" />
	<link rel="stylesheet" href="/highlight/style.css" />
	<script src="/highlight/highlight.pack.js"></script>
	<script>hljs.initHighlightingOnLoad();</script>
	<script async src="https://www.googletagmanager.com/gtag/js?id=UA-67516878-1"></script>
	<script>
		window.dataLayer = window.dataLayer || [];
		function gtag(){dataLayer.push(arguments);}
		gtag('js', new Date());

		gtag('config', 'UA-67516878-1');
	</script>
</head>
<body>
<div class="wrapper">
<header>
	<nav>
		<h1 id="logo"><a href="/"><span class="ginger">ginger</span>Bill</a></h1>
		<ul class="menu">
			<li><a href="/">Home</a></li>
			<li><a href="/article/">Articles</a></li>
			<li><a href="https://odin-lang.org">Odin</a></li>
			<!--<li><a href="/article/index.xml">Subscribe</a></li>-->
		</ul>
	</nav>
</header>
`)
}


write_footer :: proc(w: io.Writer) {
	FOOTER :: `</div>
</body>
<script async src="//mathjax.rstudio.com/latest/MathJax.js?config=TeX-MML-AM_CHTML"></script>
<script>
	(function addHeadingLinks(){
		var article = document.getElementsByClassName('article-meta')[0];
		var headings = article.querySelectorAll('h1, h2, h3');
		headings.forEach(function(heading){
			if (heading.id){
				var a = document.createElement('a');
				a.innerHTML = heading.innerHTML;
				a.href = '#'+heading.id;
				heading.innerHTML = '';
				heading.appendChild(a);
			}
		});
	})();

	const DARK  = '(prefers-color-scheme: dark)';
	const LIGHT = '(prefers-color-scheme: light)';

	function setColourScheme(scheme) {
		console.log(scheme);
		if (scheme == 'dark') {

		} else if (scheme == 'light') {

		}
	}


	(function changeStyle(){
		function detectColourScheme() {
			if (!window.matchMedia) {
				return;
			}

			function listener({matches, media}) {
				if (!matches) {
					return;
				}
				if (media == DARK) {
					setColourScheme('dark');
				} else if (media == LIGHT) {
					setColourScheme('light');
				}
			}

			const mqDark  = window.matchMedia(DARK);
			const mqLight = window.matchMedia(LIGHT);
			mqDark.addListener(listener);
			mqLight.addListener(listener);
		}
	})();
</script>
</html>
`
	fmt.wprintf(w, `<footer>© 2007–%04d Ginger Bill</footer>`+"\n", time.year(time.now()))
	io.write_string(w, FOOTER)
}

sidenote_md_to_html :: proc(text: string, arena: ^virtual.Arena) -> string {
	html := cm.markdown_to_html_from_string(text, {.Unsafe})
	defer cm.free_string(html)

	if html == "" {
		return ""
	}

	body := strings.trim_space(html)
	if strings.has_prefix(body, "<p>") && strings.has_suffix(body, "</p>") {
		body = body[3:len(html)-5]
	}

	return strings.clone(body, virtual.arena_allocator(arena))
}

@(require_results)
build_article :: proc(website: ^Website, fi: os.File_Info, archetype: Archetype, html: string, summary: string, arena: ^virtual.Arena) -> bool {
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	write_header(w, archetype, summary)

	io.write_string(w, `<main><article class="article-meta">`+"\n")
	{
		io.write_string(w, `<header>`+"\n")
		defer io.write_string(w, `</header>`+"\n")

		io.write_string(w, "<h1>")
		io.write_string(w, sidenote_md_to_html(archetype.title, arena))
		io.write_string(w, "</h1>\n\n")

		if archetype.description != "" {
			io.write_string(w, "<h2>")
			io.write_string(w, archetype.description)
			io.write_string(w, "</h2>\n\n")
		}

		io.write_string(w, `<div class="info">`+"\n")
		defer io.write_string(w, `</div>`+"\n")

		for series in archetype.series {
			series_url := strings.to_lower(series, arena_allocator)
			series_url, _ = strings.replace_all(series_url, " ", "-", arena_allocator)
			fmt.wprintfln(w, `<p><span class="series">Series:</span> <a href="/series/%s">%s</a></p>`, series_url, series)
		}

		fmt.wprintfln(w, `<p><span class="date">%s</span></p>`, archetype.date)
		if archetype.author != "Ginger Bill" {
			fmt.wprintfln(w, `<p><span class="series">Author:</span> <span class="author">%s</span></p>`, archetype.author)
		}
	}

	io.write_string(w, html)

	io.write_string(w, `</article></main>`+"\n")

	write_footer(w)

	path := fmt.aprintf(PUBLIC_PREFIX+"/article/%04d/%02d/%02d/%s/index.html", archetype.year, archetype.month, archetype.day, archetype.slug, allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	url := path[len(PUBLIC_PREFIX):]
	article := add_article(website, url, archetype)

	for alias in archetype.aliases {
		from := strings.clone(alias, virtual.arena_allocator(&website.arena))
		to   := strings.clone(url, virtual.arena_allocator(&website.arena))
		to = to[:len(to)-len("index.html")]
		website.aliases[from] = to
	}

	for series in archetype.series {
		if series not_in website.series {
			name := strings.clone(series, virtual.arena_allocator(&website.arena))
			s := new(Series)
			s.name = name
			s.url_name = strings.to_lower(series, arena_allocator)
			s.url_name, _ = strings.replace_all(s.url_name, " ", "-", virtual.arena_allocator(&website.arena))
			website.series[name] = s

		}

		s := website.series[series]
		append(&s.articles, article)
	}

	return os.write_entire_file(path, strings.to_string(b)) == nil
}


/*
	Handle Margin Notes
*/
preprocessor_pass_over_article :: proc(text: string, arena: ^virtual.Arena) -> string {
	Margin_Note :: struct {
		label: string,
		desc:  string,
	}

	@(require_results)
	find_margin_notes :: proc(text: string, arena: ^virtual.Arena) -> (margin_notes: [dynamic]Margin_Note) {
		text := text

		margin_notes = make([dynamic]Margin_Note, virtual.arena_allocator(arena))

		for len(text) > 0 {
			i := strings.index(text, "[^")
			if i < 0 {
				break
			}

			margin_note_text := text[i+2:]

			i = strings.index(margin_note_text, "]")
			assert(i > 0, "invalid margin_note syntax")
			margin_note_label := margin_note_text[:i]
			if margin_note_text[i+1] == ':' {
				j := strings.index(margin_note_text, "\n")
				if j < 0 {
					j = len(margin_note_text)
				}

				margin_note_desc := strings.trim_space(margin_note_text[i+2:j])
				text = margin_note_text[j:]

				#reverse for &f in margin_notes {
					if f.label == margin_note_label {
						f.desc = margin_note_desc
						break
					}
				}
			} else {
				text = margin_note_text[i+1:]
				append(&margin_notes, Margin_Note{margin_note_label, ""})
			}
		}

		return
	}

	arena_allocator := virtual.arena_allocator(arena)

	text := text

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	margin_notes := find_margin_notes(text, arena)

	margin_notes_used := 0

	for len(text) > 0 {
		YOUTUBE_PREFIX :: "@@youtube:"

		footnote_index := strings.index(text, "[^")
		youtube_index := strings.index(text, YOUTUBE_PREFIX)

		if footnote_index >= 0 && youtube_index >= 0 {
			if youtube_index < footnote_index {
				footnote_index = -1
			} else {
				youtube_index = -1
			}
		}

		switch {
		case footnote_index >= 0:
			i := footnote_index
			io.write_string(w, text[:i])

			margin_note_text := text[i+2:]

			i = strings.index(margin_note_text, "]")
			assert(i > 0, "invalid margin_note syntax")
			margin_note_label := margin_note_text[:i]
			if margin_note_text[i+1] == ':' {
				j := strings.index(margin_note_text, "\n")
				if j < 0 {
					j = len(margin_note_text)
				}
				text = margin_note_text[j:]

			} else {
				text = margin_note_text[i+1:]

				for &f in margin_notes {
					if f.label == margin_note_label {
						margin_notes_used += 1
						fmt.wprintf(w, `&nbsp;<label for="%s" class="margin-toggle sidenote-number"></label> `, f.label)
						fmt.wprintf(w, "\n"+`<input type="checkbox" id="%s" class="margin-toggle"></input>`+"\n", f.label)
						fmt.wprintf(w, `<span class="sidenote">%s</span>`, sidenote_md_to_html(f.desc, arena))
						break
					}
				}
			}
			continue
		case youtube_index >= 0:
			i := youtube_index
			io.write_string(w, text[:i])

			link := text[i:]
			i = strings.index(link, "\n")
			if i < 0 { i = len(link) }
			text = link[i:]
			link = link[len(YOUTUBE_PREFIX):i]

			io.write_string(w, `<div class="youtube"><iframe width="560" height="315" src="https://www.youtube.com/embed/`)
			io.write_string(w, link)
			io.write_string(w, `" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></div><br>`+"\n")
			continue
		}
		io.write_string(w, text)
		break
	}

	fmt.assertf(margin_notes_used == len(margin_notes), "%v vs %v %v", margin_notes_used, len(margin_notes), margin_notes)

	return strings.to_string(b)
}

@(require_results)
handle_article :: proc(website: ^Website, fi: os.File_Info, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	data, err := os.read_entire_file(fi.fullpath, arena_allocator)
	if err != nil {
		return false
	}
	text := string(data)

	fmt.println("[building]", fi.name)

	if !strings.has_prefix(text, "---") {
		fmt.eprintln("Missing Archetype for %q", fi.fullpath)
		return false
	}

	text = text[3:]
	archetype_end_text := "---\n"

	archetype_end := strings.index(text, archetype_end_text)
	if archetype_end < 0 {
		archetype_end_text = "---\r\n"
		archetype_end = strings.index(text, archetype_end_text)
	}

	if archetype_end < 0 {
		fmt.eprintln("Missing paired --- for Archetype for %q", fi.fullpath)
		return false
	}

	archetype: Archetype
	json.unmarshal_string(text[:archetype_end], &archetype, .JSON5, arena_allocator)
	validate_archetype(&archetype, arena) or_return

	article := strings.trim_space(text[archetype_end+len(archetype_end_text):])

	article = preprocessor_pass_over_article(article, arena)


	article_html := cm.markdown_to_html_from_string(article, {.Unsafe})
	defer cm.free_string(article_html)

	// TODO(bill): Determine summary from the article
	summary := ""

	return build_article(website, fi, archetype, article_html, summary, arena)
}

build_article_listing :: proc(website: ^Website, w: io.Writer, arena: ^virtual.Arena) {
	io.write_string(w, "<h1>Articles</h1>\n\n")

	slice.sort_by_key(website.articles[:], proc(a: Article) -> string {
		return a.date
	})

	io.write_string(w, `<ul class="articles">`+"\n")

	#reverse for article in website.articles {
		io.write_string(w, "\t<li>")
		fmt.wprintf(w, `<a href="%s">%s</a>`+"\n", article.url, sidenote_md_to_html(article.title, arena))
		if article.description != "" {
			fmt.wprintf(w, `<p class="description">%s</p>`+"\n", article.description)
		}
		fmt.wprintf(w, `<p class="date">%s</p>`+"\n", article.date)
		io.write_string(w, "</li>\n")
	}

	io.write_string(w, `</ul>`+"\n")
}

@(require_results)
build_article_index :: proc(website: ^Website, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	write_header(w, "Articles - gingerBill")

	build_article_listing(website, w, arena)

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/article/index.html", allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

@(require_results)
handle_articles :: proc(website: ^Website, path: string, arena: ^virtual.Arena) -> os.Error {
	arena_allocator := virtual.arena_allocator(arena)
	defer virtual.arena_free_all(arena)

	files := os.read_all_directory_by_path(path, arena_allocator) or_return

	// os.remove_all(PUBLIC_PREFIX+"/article")

	for f in files {
		ok := handle_article(website, f, arena)
		if !ok {
			return nil
		}
	}

	_ = build_article_index(website, arena)

	return nil
}

HOME_TEXT :: `<h1 id="contact">Contact Info</h1>
<table class="gbt2">
<tbody>
	<tr><td>  Email:</td><td><a href="#">bill <em>[at]</em> gingerbill <em>[dot]</em> org</a></td></tr>
	<tr><td>Twitter:</td><td><a href="//twitter.com/TheGingerBill">@TheGingerBill</a></td></tr>
	<tr><td> GitHub:</td><td><a href="//github.com/gingerBill">github.com/gingerBill</a></td></tr>
	<tr><td>YouTube:</td><td><a href="//youtube.com/GingerGames">youtube.com/GingerGames</a></td></tr>
</tbody>
</table>

<h1 id="public">Public Projects</h1>
<table class="gbt2">
<tbody>
	<tr>
		<td>
			<a href="/odin">Odin: Programming Language</a><br>
			2016–now
		</td>
		<td>
			<p>An open source systems programming language designed for the modern computer and programmer</p><p>
			</p><p>Odin is fast, concise, readable, and pragmatic. It is designed with the intent of replacing C with the following goals:</p><p>
			</p>
			<ul>
				<li>simplicity</li>
				<li>high performance</li>
				<li>built for modern systems</li>
				<li>joy of programming</li>
			</ul>
			<table class="gbt2">
			<tbody>
				<tr><td>Website:</td><td><a href="https://odin-lang.org/">odin-lang.org</a></td></tr>
			</tbody>
			</table>
		</td>
	</tr>
</tbody>
</table>
`

build_home :: proc(website: ^Website, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	write_header(w, "gingerBill")

	io.write_string(w, HOME_TEXT)

	build_article_listing(website, w, arena)

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/index.html", allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

build_404 :: proc(website: ^Website, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	write_header(w, "404 - gingerBill")

io.write_string(w, \
`<main>
<h2><span class="ginger">404</span> Page Not Found. That's an error.</h2>
<p>The page you were looking for has gone walkabouts. Return to the <a href="/">homepage</a>?</p>
</main>
`)

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/404.html", allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

build_alias :: proc(website: ^Website, from, to: string, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

fmt.wprintf(w,
`<!DOCTYPE html>
<html lang="en-gb">
	<head>
		<title>{0:s}</title>
		<link rel="canonical" href="{0:s}">
		<meta name="robots" content="noindex">
		<meta charset="utf-8">
		<meta http-equiv="refresh" content="0; url={0:s}">
	</head>
</html>`, to)

	path := fmt.aprintf("%s%s", PUBLIC_PREFIX, from, allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, strings.to_string(b)) == nil
}

build_series :: proc(website: ^Website, name: string, series: ^Series, arena: ^virtual.Arena) -> bool {
	arena_temp := virtual.arena_temp_begin(arena)
	defer virtual.arena_temp_end(arena_temp)
	arena_allocator := virtual.arena_allocator(arena)

	b := strings.builder_make(arena_allocator)
	w := strings.to_writer(&b)

	write_header(w, fmt.aprintf("%s - gingerBill", name, allocator=arena_allocator))

	fmt.wprintf(w, "<h1>%s&mdash;Article Series</h1>\n\n", series.name)

	slice.sort_by_key(series.articles[:], proc(a: Article) -> string {
		return a.date
	})
	{
		io.write_string(w, `<ul class="articles">`+"\n")
		defer io.write_string(w, `</ul>`+"\n")

		for article in series.articles {
			io.write_string(w, "\t<li>")
			defer io.write_string(w, "</li>\n")

			fmt.wprintf(w, `<a href="%s">%s</a>`+"\n", article.url, sidenote_md_to_html(article.title, arena))
			if article.description != "" {
				fmt.wprintf(w, `<p class="description">%s</p>`+"\n", article.description)
			}
			fmt.wprintf(w, `<p class="date">%s</p>`+"\n", article.date)
		}
	}

	write_footer(w)

	path := fmt.aprintf(PUBLIC_PREFIX+"/series/%s/index.html", series.url_name, allocator=arena_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, strings.to_string(b)) == nil
}


main :: proc() {
	arena: virtual.Arena
	defer virtual.arena_destroy(&arena)

	website: Website
	defer delete(website.aliases)
	defer delete(website.series)

	_ = handle_articles(&website, "content/article", &arena)

	_ = build_home(&website, &arena)
	_ = build_404(&website, &arena)

	for from, to in website.aliases {
		_ = build_alias(&website, from, to, &arena)
	}

	for name, series in website.series {
		_ = build_series(&website, name, series, &arena)
	}

}