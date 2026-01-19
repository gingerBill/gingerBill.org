package generator

import "base:runtime"
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
	perm_arena:    virtual.Arena,
	scratch_arena: virtual.Arena,

	perm_allocator:    runtime.Allocator,
	scratch_allocator: runtime.Allocator,

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
	allocator := website.perm_allocator
	a := Article{
		title       = strings.clone(a.title, allocator),
		url         = strings.clone(strings.trim_suffix(url, "index.html"), allocator),
		date        = fmt.aprintf("%04d-%02d-%02d", a.year, a.month, a.day, allocator=allocator),
		description = strings.clone(a.description, allocator),
	}
	append(&website.articles, a)
	return a
}

@(require_results)
validate_archetype :: proc(a: ^Archetype, allocator: runtime.Allocator) -> bool {
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

	valid_date: bool
	a.year, a.month, a.day, valid_date = validate_date(a.date, a)
	if !valid_date {
		fmt.eprintln("Invalid date", a.date)
		return false
	}

	if a.title == "" {
		fmt.eprintln("Missing title")
		return false
	}

	if a.slug == "" {
		slug := strings.to_lower(a.title, allocator)
		slug, _ = strings.replace_all(slug, " ", "-", allocator)

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
	io.write_string(w, #load("header-01.html", string))

	#partial switch v in info {
	case Archetype:
		fmt.wprintfln(w,`<meta name="twitter:card" content="summary">`)
		fmt.wprintfln(w,`<meta name="twitter:title" content="%s">`, v.title)
		fmt.wprintfln(w,`<meta name="twitter:description" content="%s">`, summary if summary != "" else v.description)
	}

	switch v in info {
	case Archetype: fmt.wprintf    (w, ` <title>%s - gingerBill</title>`+"\n", v.title)
	case string:    fmt.wprintf    (w, ` <title>%s</title>`+"\n", v)
	case:           io.write_string(w, ` <title>gingerBill</title>`+"\n")
	}

	io.write_string(w, #load("header-02.html", string))
}


write_footer :: proc(w: io.Writer) {
	fmt.wprintf(w, `<footer>© 2007–%04d Ginger Bill</footer>`+"\n", time.year(time.now()))
	io.write_string(w, #load("footer.html", string))
}

sidenote_md_to_html :: proc(text: string, allocator: runtime.Allocator) -> string {
	html := cm.markdown_to_html_from_string(text, {.Unsafe, .Smart})
	defer cm.free_string(html)

	if html == "" {
		return ""
	}

	body := strings.trim_space(html)
	if strings.has_prefix(body, "<p>") && strings.has_suffix(body, "</p>") {
		body = body[3:len(html)-5]
	}

	return strings.clone(body, allocator)
}

@(require_results)
build_article :: proc(website: ^Website, fi: os.File_Info, archetype: Archetype, html: string, summary: string) -> bool {
	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	write_header(w, archetype, summary)

	io.write_string(w, `<main><article class="article-meta">`+"\n")
	{
		io.write_string(w, `<header>`+"\n")
		defer io.write_string(w, `</header>`+"\n")

		io.write_string(w, "<h1>")
		io.write_string(w, sidenote_md_to_html(archetype.title, website.scratch_allocator))
		io.write_string(w, "</h1>\n\n")

		if archetype.description != "" {
			io.write_string(w, "<h2>")
			io.write_string(w, archetype.description)
			io.write_string(w, "</h2>\n\n")
		}

		io.write_string(w, `<div class="info">`+"\n")
		defer io.write_string(w, `</div>`+"\n")

		for series in archetype.series {
			series_url := strings.to_lower(series, website.scratch_allocator)
			series_url, _ = strings.replace_all(series_url, " ", "-", website.scratch_allocator)
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

	path := fmt.aprintf(PUBLIC_PREFIX+"/article/%04d/%02d/%02d/%s/index.html", archetype.year, archetype.month, archetype.day, archetype.slug, allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	url := path[len(PUBLIC_PREFIX):]
	article := add_article(website, url, archetype)

	for alias in archetype.aliases {
		from := strings.clone(alias, website.perm_allocator)
		to   := strings.clone(url, website.perm_allocator)
		to = to[:len(to)-len("index.html")]
		website.aliases[from] = to
	}

	for series in archetype.series {
		if series not_in website.series {
			name := strings.clone(series, website.perm_allocator)
			s := new(Series)
			s.name = name
			s.url_name = strings.to_lower(series, website.scratch_allocator)
			s.url_name, _ = strings.replace_all(s.url_name, " ", "-", website.perm_allocator)
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
preprocessor_pass_over_article :: proc(website: ^Website, text: string) -> string {
	Margin_Note :: struct {
		label: string,
		desc:  string,
	}

	@(require_results)
	find_margin_notes :: proc(website: ^Website, text: string) -> (margin_notes: [dynamic]Margin_Note) {
		text := text

		margin_notes = make([dynamic]Margin_Note, website.scratch_allocator)

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

	text := text

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	margin_notes := find_margin_notes(website, text)

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
						fmt.wprintf(w, `<span class="sidenote">%s</span>`, sidenote_md_to_html(f.desc, website.scratch_allocator))
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
handle_article :: proc(website: ^Website, fi: os.File_Info) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	data, err := os.read_entire_file(fi.fullpath, website.scratch_allocator)
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
	json.unmarshal_string(text[:archetype_end], &archetype, .JSON5, website.scratch_allocator)
	validate_archetype(&archetype, website.scratch_allocator) or_return

	article := strings.trim_space(text[archetype_end+len(archetype_end_text):])

	article = preprocessor_pass_over_article(website, article)


	article_html: string
	defer cm.free_string(article_html)


	{
		options := cm.Options{.Unsafe, .Smart}

		p := cm.parser_new(options)
		defer cm.parser_free(p)

		root := cm.parse_document(raw_data(article), len(article), options)
		defer cm.node_free(root)

		article_html = string(cm.render_html(root, options))
	}


	// TODO(bill): Determine summary from the article
	summary := ""

	return build_article(website, fi, archetype, article_html, summary)
}

build_article_listing :: proc(website: ^Website, w: io.Writer) {
	io.write_string(w, "<h1>Articles</h1>\n\n")

	slice.sort_by_key(website.articles[:], proc(a: Article) -> string {
		return a.date
	})

	io.write_string(w, `<ul class="articles">`+"\n")

	#reverse for article in website.articles {
		io.write_string(w, "\t<li>")
		fmt.wprintf(w, `<a href="%s">%s</a>`+"\n", article.url, sidenote_md_to_html(article.title, website.scratch_allocator))
		if article.description != "" {
			fmt.wprintf(w, `<p class="description">%s</p>`+"\n", article.description)
		}
		fmt.wprintf(w, `<p class="date">%s</p>`+"\n", article.date)
		io.write_string(w, "</li>\n")
	}

	io.write_string(w, `</ul>`+"\n")
}

@(require_results)
build_article_index :: proc(website: ^Website) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	write_header(w, "Articles - gingerBill")

	build_article_listing(website, w)

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/article/index.html", allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

@(require_results)
handle_articles :: proc(website: ^Website, path: string) -> os.Error {
	defer virtual.arena_free_all(&website.scratch_arena)

	files := os.read_all_directory_by_path(path, website.scratch_allocator) or_return

	// os.remove_all(PUBLIC_PREFIX+"/article")

	for f in files {
		ok := handle_article(website, f)
		if !ok {
			return nil
		}
	}

	_ = build_article_index(website)

	return nil
}

build_home :: proc(website: ^Website) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	write_header(w, "gingerBill")

	io.write_string(w, #load("home.html", string))

	build_article_listing(website, w)

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/index.html", allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

build_404 :: proc(website: ^Website) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	write_header(w, "404 - gingerBill")

	io.write_string(w, #load("not-found-404.html", string))

	write_footer(w)

	s := strings.to_string(b)

	path := fmt.aprintf(PUBLIC_PREFIX+"/404.html", allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, s) == nil
}

build_alias :: proc(website: ^Website, from, to: string) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
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

	path := fmt.aprintf("%s%s", PUBLIC_PREFIX, from, allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, strings.to_string(b)) == nil
}

build_series :: proc(website: ^Website, name: string, series: ^Series) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	write_header(w, fmt.aprintf("%s - gingerBill", name, allocator=website.scratch_allocator))

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

			fmt.wprintf(w, `<a href="%s">%s</a>`+"\n", article.url, sidenote_md_to_html(article.title, website.scratch_allocator))
			if article.description != "" {
				fmt.wprintf(w, `<p class="description">%s</p>`+"\n", article.description)
			}
			fmt.wprintf(w, `<p class="date">%s</p>`+"\n", article.date)
		}
	}

	write_footer(w)

	path := fmt.aprintf(PUBLIC_PREFIX+"/series/%s/index.html", series.url_name, allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, strings.to_string(b)) == nil
}

main :: proc() {
	website: Website
	website.perm_allocator    = virtual.arena_allocator(&website.perm_arena)
	website.scratch_allocator = virtual.arena_allocator(&website.scratch_arena)
	defer virtual.arena_destroy(&website.perm_arena)
	defer virtual.arena_destroy(&website.scratch_arena)

	website.articles.allocator = website.perm_allocator
	website.aliases.allocator  = website.perm_allocator
	website.series.allocator   = website.perm_allocator

	_ = handle_articles(&website, "content/article")

	_ = build_home(&website)
	_ = build_404(&website)

	for from, to in website.aliases {
		_ = build_alias(&website, from, to)
	}

	for name, series in website.series {
		_ = build_series(&website, name, series)
	}
}