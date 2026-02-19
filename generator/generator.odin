package generator

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:time"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:unicode"
import "core:unicode/utf8"
import "core:encoding/json"
import "core:encoding/entity"
import "core:mem/virtual"
import "core:os"

import cm "vendor:commonmark"

PUBLIC_PREFIX :: "public"

CMARK_OPTIONS :: cm.Options{.Unsafe, .Smart}

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

	year, month, day: int,

	summary: string,
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

add_article :: proc(website: ^Website, url: string, a: Archetype, summary: string) -> Article {
	allocator := website.perm_allocator
	a := Article{
		title       = strings.clone(a.title, allocator),
		url         = strings.clone(strings.trim_suffix(url, "index.html"), allocator),
		date        = fmt.aprintf("%04d-%02d-%02d", a.year, a.month, a.day, allocator=allocator),
		description = strings.clone(a.description, allocator),
		summary     = strings.clone(summary, allocator),
		year        = a.year,
		month       = a.month,
		day         = a.day,
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
	original_summary := summary
	summary := summary
	MAX_SUMMARY_SIZE :: 140*4
	summary = summary[:min(len(summary), MAX_SUMMARY_SIZE)]

	io.write_string(w, #load("header-01.html", string))

	#partial switch v in info {
	case Archetype:
		desc := v.description if v.description != "" else summary

		fmt.wprintfln(w, `<meta name="twitter:card" content="summary" />`)
		fmt.wprintfln(w, `<meta name="twitter:title" content="%s" />`, v.title)
		fmt.wprintf(w, `<meta name="twitter:description" content="%s`, desc)
		if desc == summary && len(summary) != len(original_summary) {
			fmt.wprintf(w, `...`)
		}
		fmt.wprintfln(w, `" />`)
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
	html := cm.markdown_to_html_from_string(text, CMARK_OPTIONS)
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

		io.write_string(w, `<div class="info" id="article-info">`+"\n")
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
	article := add_article(website, url, archetype, summary)

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


	article_html := render_html(&website.scratch_arena, article)

	summary := render_summary(&website.scratch_arena, article)

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
build_rss_feed :: proc(website: ^Website) -> bool {
	arena_temp := virtual.arena_temp_begin(&website.scratch_arena)
	defer virtual.arena_temp_end(arena_temp)

	b := strings.builder_make(website.scratch_allocator)
	w := strings.to_writer(&b)

	{
		io.write_string(w, `<?xml version="1.0" encoding="UTF-8" ?>`+"\n")
		io.write_string(w, `<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">`+"\n")
		defer io.write_string(w, `</rss>`+"\n")

		io.write_string(w, "<channel>\n")
		defer io.write_string(w, "</channel>\n")

		io.write_string(w, "\t<atom:link href=\"https://www.gingerbill.org/article/index.xml\" rel=\"self\" type=\"application/rss+xml\" />\n")

		io.write_string(w, "\t<title>gingerBill - Articles</title>\n")
		io.write_string(w, "\t<link>https://www.gingerbill.org/article/</link>\n")
		io.write_string(w, "\t<description>Articles by gingerBill</description>\n")

		slice.sort_by_key(website.articles[:], proc(a: Article) -> string {
			return a.date
		})
		#reverse for article in website.articles {
			io.write_string(w, "\t<item>\n")
			defer io.write_string(w, "\t</item>\n")


			io.write_string(w, "\t\t<title>")
			title := strings.trim_space(article.title)
			title, _ = strings.replace_all(title, "&mdash;", "", website.scratch_allocator)
			title, _ = strings.replace_all(title, "&nbsp;", "", website.scratch_allocator)
			io.write_string(w, title)
			io.write_string(w, "</title>\n")
			io.write_string(w, "\t\t<link>")
			io.write_string(w, "https://www.gingerbill.org")
			io.write_string(w, article.url)
			io.write_string(w, "</link>\n")

			io.write_string(w, "\t\t<guid>")
			io.write_string(w, "https://www.gingerbill.org")
			io.write_string(w, article.url)
			io.write_string(w, "</guid>\n")

			io.write_string(w, "\t\t<pubDate>")
			{
				year, m, d := article.year, article.month, article.day
				t, _ := time.components_to_time(year, m, d, 9, 0, 0, 0)
				day := time.weekday(t)
				mon := time.month(t)

				switch day {
				case .Sunday:    io.write_string(w, "Sun, ")
				case .Monday:    io.write_string(w, "Mon, ")
				case .Tuesday:   io.write_string(w, "Tue, ")
				case .Wednesday: io.write_string(w, "Wed, ")
				case .Thursday:  io.write_string(w, "Thu, ")
				case .Friday:    io.write_string(w, "Fri, ")
				case .Saturday:  io.write_string(w, "Sat, ")
				}

				fmt.wprintf(w, "%02d ", d)

				switch mon {
				case .January:   io.write_string(w, "Jan ")
				case .February:  io.write_string(w, "Feb ")
				case .March:     io.write_string(w, "Mar ")
				case .April:     io.write_string(w, "Apr ")
				case .May:       io.write_string(w, "May ")
				case .June:      io.write_string(w, "Jun ")
				case .July:      io.write_string(w, "Jul ")
				case .August:    io.write_string(w, "Aug ")
				case .September: io.write_string(w, "Sep ")
				case .October:   io.write_string(w, "Oct ")
				case .November:  io.write_string(w, "Nov ")
				case .December:  io.write_string(w, "Dec ")
				}

				fmt.wprintf(w, "%04d 09:00:00 +0000", year)

			}
			io.write_string(w, "</pubDate>\n")


			io.write_string(w, "\t\t<description>")

			if article.description != "" {
				io.write_string(w, article.description)
			} else {
				summary := article.summary
				summary = summary[:min(len(summary), 4*140)]

				new_summary := make([]byte, len(summary))
				dst := 0
				for src := 0; src < len(summary); /**/ {
					r, w := utf8.decode_rune(summary[src:]); src += w

					switch r {
					case '“': new_summary[dst] = '"';  dst += 1
					case '”': new_summary[dst] = '"';  dst += 1
					case '’': new_summary[dst] = '\''; dst += 1
					case '&':
						r, w = utf8.decode_rune(summary[src:]); src += w
						switch {
						case strings.has_prefix(summary[src:], "mdash"):
							src += 6
						case strings.has_prefix(summary[src:], "ndash"):
							src += 6
						case:
							for src+1 < len(summary) {
								src += 1
								if summary[src] == ';' {
									break
								}
							}
						}

					case:
						if r == 0 {
							continue
						}
						if unicode.is_print(r) {
							new_summary[dst] = byte(r)
							dst += 1
						}
					}
				}

				// summary, _ = strings.replace_all(summary, "￿?", "", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "&mdash;", "", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "&mdash;", "", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "&nbsp;", "", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "&#34;", "\"", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "&#39;", "\'", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "“", "\"", website.scratch_allocator)
				// summary, _ = strings.replace_all(summary, "”", "\"", website.scratch_allocator)


				io.write_string(w, string(new_summary[:dst]))
				if dst != len(article.summary) {
					io.write_string(w, "...")
				}
			}
			io.write_string(w, "</description>\n")
		}

	}


	path := fmt.aprintf(PUBLIC_PREFIX+"/article/index.xml", allocator=website.scratch_allocator)
	dir, _ := os.split_path(path)
	_ = os.make_directory_all(dir)

	return os.write_entire_file(path, strings.to_string(b)) == nil
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

	_ = build_rss_feed(website)


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