package generator

import "core:fmt"
import "core:io"
import "core:strings"
import "core:mem/virtual"
import "core:encoding/entity"
import "core:unicode"

import cm "vendor:commonmark"

Render_State :: struct {
	w:       ^strings.Builder,
	plain:   ^cm.Node,

	heading_count: int,
}

escape_html_bytes :: proc(state: ^Render_State, data: []byte) {
	res, _ := entity.escape_html(string(data))
	strings.write_string(state.w, res)
}

escape_html_string :: proc(state: ^Render_State, data: string) {
	res, _ := entity.escape_html(data)
	strings.write_string(state.w, res)
}

escape_html :: proc{
	escape_html_bytes,
	escape_html_string,
}

escape_href :: proc(state: ^Render_State, link: string) {
	@(static, rodata)
	href_safe := [?]byte{
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	}

	x := transmute([]byte)link

	for c in x {
		if href_safe[c] != 0 {
			strings.write_byte(state.w, c)
			continue
		}

		switch c {
		case '&':
			strings.write_string(state.w, "&amp;")
		case '\'':
			strings.write_string(state.w, "&#39;")

		case:
			hex_chars := "0123456789ABCDEF"
			hex: [3]byte
			hex[0] = '%'
			hex[1] = hex_chars[(c>>4) & 0xf]
			hex[2] = hex_chars[c & 0xf]
			strings.write_bytes(state.w, hex[:])
		}
	}
}


render_html_node :: proc(state: ^Render_State, node: ^cm.Node, ev_type: cm.Event_Type) -> bool {
	cr :: proc(state: ^Render_State) {
		if len(state.w.buf) > 0 && state.w.buf[len(state.w.buf)-1] != '\n' {
			strings.write_byte(state.w, '\n')
		}
	}

	assert(node != nil)

	entering := ev_type == .Enter

	if state.plain == node {
		state.plain = nil
	}

	if state.plain != nil {
		#partial switch node.type {
		case .Text, .Code, .HTML_Inline:
			escape_html(state, node.data[:node.len])
		case .Line_Break, .Soft_Break:
			strings.write_byte(state.w, ' ')
		}
		return true
	}

	switch node.type {
	case .None:
		// ignore

	case .Document: // .First_Block
		// ignore

	case .Block_Quote:
		if entering {
			cr(state)
			strings.write_string(state.w, "<blockquote>")
		} else {
			cr(state)
			strings.write_string(state.w, "</blockquote>\n")
		}
	case .List:
		list_type := cm.List_Type(node.as.list.list_type)
		start := node.as.list.start

		if entering {
			cr(state)
			if list_type == .Bullet {
				strings.write_string(state.w, "<ul>\n")
			} else if start == 1 {
				strings.write_string(state.w, "<ol>\n")
			} else {
				strings.write_string(state.w, "<ol start=\"")
				strings.write_int(state.w, int(start))
				strings.write_string(state.w, "\">\n")
			}
		} else {
			if list_type == .Bullet {
				strings.write_string(state.w, "</ul>\n")
			} else {
				strings.write_string(state.w, "</ol>\n")
			}
		}

	case .Item:
		if entering {
			cr(state)
			strings.write_string(state.w, "<li>")
		} else {
			strings.write_string(state.w, "</li>\n")
		}


	case .Heading:
		start_heading: [3]byte = "<h0"
		end_heading:   [4]byte = "</h0"

		if entering {
		 	cr(state)
		 	level := int(node.as.heading.level)
		 	start_heading[2] = byte('0' + level)
		 	strings.write_bytes(state.w, start_heading[:])

		 	switch level {
		 	case 1..=3:
			 	state.heading_count += 1
			 	strings.write_string(state.w, " id=\"heading-")
			 	strings.write_int(state.w, level)
			 	strings.write_string(state.w, "-")
			 	strings.write_int(state.w, state.heading_count)
			 	strings.write_string(state.w, "\"")
			 }

		 	strings.write_byte(state.w, '>')
		 } else {
		 	end_heading[3] = byte(int('0' + node.as.heading.level))
		 	strings.write_bytes(state.w, end_heading[:])
		 	strings.write_string(state.w, "/>\n")
		 }

	case .Code_Block:
	 	cr(state)

	 	if node.as.code.info == nil || node.as.code.info == "" {
			strings.write_string(state.w, "<pre><code>")
	 	} else {
	 		first_tag := 0
	 		info := string(node.as.code.info)
	 		for first_tag < len(info) && !unicode.is_space(rune(info[first_tag])) {
	 			first_tag += 1
	 		}

	 		strings.write_string(state.w, "<pre><code class=\"")
	 		if strings.has_prefix(info, "language-") {
		 		strings.write_string(state.w, "language-")
	 		}
	 		escape_html(state, info[:first_tag])
	 		strings.write_string(state.w, "\">")
	 	}

	 	escape_html(state, node.data[:node.len])
 		strings.write_string(state.w, "</code></pre>\n")

	case .HTML_Block:
	 	cr(state)
	 	strings.write_bytes(state.w, node.data[:node.len])
	 	cr(state)


	case .Custom_Block:
		block := entering ? node.as.custom.on_enter : node.as.custom.on_exit

		cr(state)
		if block != nil {
		 	strings.write_string(state.w, string(block))
		}
		cr(state)

	case .Thematic_Break: // .Last_Block
		cr(state)
 		strings.write_string(state.w, "<hr />\n")

	case .Paragraph:
		parent := cm.node_parent(node)
		grandparent := cm.node_parent(parent)

		tight := false
		if grandparent != nil && grandparent.type == .List {
			tight = grandparent.as.list.tight
		}

		if !tight {
			if entering {
				cr(state)
		 		strings.write_string(state.w, "<p>")
			} else {
		 		strings.write_string(state.w, "</p>\n")
			}
		}

	case .Text: // .First_Inline
		escape_html(state, node.data[:node.len])

	case .Line_Break:
		strings.write_string(state.w, "<br />")

	case .Soft_Break:
		strings.write_string(state.w, "\n")

	case .Code:
		strings.write_string(state.w, "<code>")
		escape_html(state, node.data[:node.len])
		strings.write_string(state.w, "</code>")

	case .HTML_Inline:
	 	strings.write_bytes(state.w, node.data[:node.len])

	case .Custom_Inline:
		block := entering ? node.as.custom.on_enter : node.as.custom.on_exit
		if block != nil {
			strings.write_string(state.w, string(block))
		}

	case .Strong:
		if entering {
			strings.write_string(state.w, "<strong>")
		} else {
			strings.write_string(state.w, "</strong>")
		}

	case .Emph:
		if entering {
			strings.write_string(state.w, "<em>")
		} else {
			strings.write_string(state.w, "</em>")
		}

	case .Link:
		if entering {
			strings.write_string(state.w, "<a href=\"")
			if node.as.link.url != nil {
				escape_href(state, string(node.as.link.url))
			}
			if node.as.link.title != nil {
				strings.write_string(state.w, "\" title=\"")
				escape_html(state, string(node.as.link.title))
			}
			strings.write_string(state.w, "\">")
		} else {
			strings.write_string(state.w, "</a>")
		}

	case .Image: // .Last_Inline
		if entering {
			strings.write_string(state.w, "<img src=\"")
			if node.as.link.url != nil {
				escape_href(state, string(node.as.link.url))
			}
			strings.write_string(state.w, "\" alt=\"")
			state.plain = node
		} else {
			if node.as.link.title != nil {
				strings.write_string(state.w, "\" title=\"")
				escape_html(state, string(node.as.link.title))
			}

			strings.write_string(state.w, "\" />")
		}

	case:
		panic("unhandled node")

	}
	return true
}


render_html :: proc(arena: ^virtual.Arena, article: string) -> string {
	options := cm.Options{.Unsafe, .Smart}

	p := cm.parser_new(options)
	defer cm.parser_free(p)

	root := cm.parse_document(raw_data(article), len(article), options)
	defer cm.node_free(root)

	context.allocator = virtual.arena_allocator(arena)

	buf := strings.builder_make()

	state := Render_State{&buf, nil, 0}

	iter := cm.iter_new(root)
	defer cm.iter_free(iter)

	for {
		ev_type := cm.iter_next(iter)
		if ev_type == .Done {
			break
		}

		curr := cm.iter_get_node(iter)
		render_html_node(&state, curr, ev_type)
	}

	return strings.to_string(buf)
}


render_summary_node :: proc(state: ^Render_State, node: ^cm.Node, ev_type: cm.Event_Type) -> bool {
	cr :: proc(state: ^Render_State) {
		if len(state.w.buf) > 0 && state.w.buf[len(state.w.buf)-1] != '\n' {
			strings.write_byte(state.w, '\n')
		}
	}

	assert(node != nil)

	entering := ev_type == .Enter

	if state.plain == node {
		state.plain = nil
	}

	if state.plain != nil {
		#partial switch node.type {
		case .Text, .Code, .HTML_Inline:
			escape_html(state, node.data[:node.len])
		case .Line_Break, .Soft_Break:
			strings.write_byte(state.w, ' ')
		}
		return true
	}

	switch node.type {
	case .None:
		// ignore

	case .Document: // .First_Block
		// ignore

	case .Block_Quote:

	case .List:

	case .Item:

	case .Heading:

	case .Code_Block:

	case .HTML_Block:

	case .Custom_Block:

	case .Thematic_Break: // .Last_Block

	case .Paragraph:

	case .Text: // .First_Inline
		escape_html(state, node.data[:node.len])

	case .Line_Break, .Soft_Break:
		strings.write_byte(state.w, ' ')

	case .Code:

	case .HTML_Inline:

	case .Custom_Inline:

	case .Strong:

	case .Emph:

	case .Link:

	case .Image: // .Last_Inline

	case:
		panic("unhandled node")

	}
	return true
}


render_summary :: proc(arena: ^virtual.Arena, article: string) -> string {
	options := cm.Options{.Unsafe, .Smart}

	p := cm.parser_new(options)
	defer cm.parser_free(p)

	root := cm.parse_document(raw_data(article), len(article), options)
	defer cm.node_free(root)

	context.allocator = virtual.arena_allocator(arena)

	buf := strings.builder_make()

	state := Render_State{&buf, nil, 0}

	iter := cm.iter_new(root)
	defer cm.iter_free(iter)

	for {
		ev_type := cm.iter_next(iter)
		if ev_type == .Done {
			break
		}

		curr := cm.iter_get_node(iter)
		render_summary_node(&state, curr, ev_type)
	}

	return strings.to_string(buf)
}
