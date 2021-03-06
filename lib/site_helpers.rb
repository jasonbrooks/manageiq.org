class SiteHelpers < Middleman::Extension
  def initialize(app, options_hash={}, &block)
    super
  end

  helpers do

    def normalize_url(dirty_URL)
      r = url_for Middleman::Util.normalize_path(dirty_URL)
      r.sub(/\/$/, '')
    end

    def pretty_date(sometime, length = "long")
      return unless sometime

      sometime = Time.parse(sometime) if sometime.class == String

      format = length == "short" ? "%a %e %b" : "%A %e %B"
      format << " %Y" unless sometime.year == Time.now.year

      sometime.to_time.strftime(format) rescue ""
    end

    # Use the title from frontmatter metadata,
    # or peek into the page to find the H1,
    # or fallback to a filename-based-title
    def discover_title(page = current_page)
      page.data.title || page.render({layout: false}).match(/<h1>(.*?)<\/h1>/) do |m|
        m ? m[1] : page.url.split(/\//).last.titleize
      end
    end

    def word_unwrap content
      content.to_s.gsub(/\n\n/, '!ಠ_ಠ!').gsub(/\n/, ' ').squeeze(' ').gsub(/!ಠ_ಠ!/, "\n\n")
    end

    def markdown_to_html content
      Tilt['markdown'].new(config[:markdown]) { content.strip }.render if content
    end

    def markdown_to_plaintext content
      word_unwrap Nokogiri::HTML(markdown_to_html(content)).text.strip
    end

    def demote_headings content
      h_add = case content
        when /<h1>/
          2
        when /<h2>/
          1
        else
          nil
      end

      if h_add
        content.to_str.gsub(/<(\/?)h([1-6])>/) {|m| "<#{$1}h#{$2.to_i + h_add}>"}.html_safe
      else
        content
      end
    end

    def markdown_to_html content
      Tilt['markdown'].new { content.strip }.render if content
    end

    # Convert a Nokogiri fragment's H2s to a linked table of contents
    def h2_to_toc nokogiri_fragment, filename
      capture_haml do

        haml_tag :ol do
          nokogiri_fragment.css('h2').each do |heading|

            haml_tag :li do
              haml_tag :a, href: "#{filename}/##{heading.attr('id')}" do
                #haml_content heading.content
                haml_concat heading.content
              end
            end

          end
        end

      end
    end

    # Pull in a Markdown document's ToC or generate one based on H2s
    def doc_toc source_filename, someclass = ''
      current_dir = current_page.source_file.sub(/[^\/]*$/, '')
      tasks_md = File.read "#{current_dir}/#{source_filename}.html.md"
      doc = Nokogiri::HTML(markdown_to_html(tasks_md))
      toc = doc.css('#markdown-toc').attr(:id, '')

      # Rewrite all links in the ToC (only done if ToC exists)
      toc.css('li a').each do |link|
        link[:href] = "#{source_filename}/#{link[:href]}"
      end

      # ToC: Either in-page or (otherwise) generated
      toc = toc.any? ? toc : h2_to_toc(doc, source_filename)

      toc.attr(:class, "toc-interpage #{someclass}")
    end

  end
end

::Middleman::Extensions.register(:site_helpers, SiteHelpers)
