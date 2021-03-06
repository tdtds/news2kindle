# scraping tDiary's N-Year diary for News2Kindle
#

require 'nokogiri'
require 'open-uri'
require 'uri'

module News2Kindle
	module Generator
		class Tdiary
			def initialize( tmpdir )
				@current_dir = tmpdir
				resource = Pathname(__FILE__) + '../../../../resource'
				FileUtils.cp(resource + "tdiary.css", @current_dir)
			end

			def generate(opts)
				now = opts[:now]
				@top = opts[:tdiary_top] || ENV['TDIARY_TOP']

				html = title = author = now_str = nil
				begin
					retry_loop( 5 ) do
						html = Nokogiri(URI.open("#{@top}?date=#{now.strftime '%m%d'}", 'r:utf-8', &:read))
						title = (html / 'head title').text
						author = (html / 'head meta[name="author"]')[0]['content']
						now_str = now.strftime( '%m-%d' )
					end
				rescue => e
					News2Kindle.logger.info "failed by retry over: #{e.class}: #{e}"
				end

				#
				# generating html
				#
				html.css('head meta', 'head link', 'head style', 'script').remove
				html.css('div.adminmenu', 'div.sidebar', 'div.footer').remove
				(html / 'img').each do |img|
					file_name = save_image(img['src'])
					img['src'] = file_name
				end
				open( "#{@current_dir}/index.html", 'w' ){|f| f.write html.to_html}

				#
				# generating TOC in ncx
				#
				open( "#{@current_dir}/toc.ncx", 'w:utf-8' ) do |f|
					f.write <<-XML.gsub( /^\t/, '' )
					<?xml version="1.0" encoding="UTF-8"?>
					<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
					<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
					<docTitle><text>#{title}</text></docTitle>
					<navMap>
						<navPoint id="index" playOrder="1">
							<navLabel>
								<text>#{title}</text>
							</navLabel>
							<content src="index.html" />
						</navPoint>
					</navMap>
					</ncx>
					XML
				end
				
				#
				# generating OPF
				#
				open( "#{@current_dir}/tdiary.opf", 'w:utf-8' ) do |f|
					f.write <<-XML.gsub( /^\t/, '' )
					<?xml version="1.0" encoding="utf-8"?>
					<package unique-identifier="uid">
						<metadata>
							<dc-metadata xmlns:dc="http://purl.org/metadata/dublin_core" xmlns:oebpackage="http://openebook.org/namespaces/oeb-package/1.0/">
								<dc:Title>#{title}</dc:Title>
								<dc:Language>ja-JP</dc:Language>
								<dc:Creator>#{author}</dc:Creator>
								<dc:Description>tDiary N-Year Diary</dc:Description>
								<dc:Date>#{now.strftime( '%d/%m/%Y' )}</dc:Date>
							</dc-metadata>
						</metadata>
						<manifest>
							<item id="toc" media-type="application/x-dtbncx+xml" href="toc.ncx"></item>
							<item id="style" media-type="text/css" href="tdiary.css"></item>
							<item id="index" media-type="text/html" href="index.html"></item>
						</manifest>
						<spine toc="toc">
							<itemref idref="index" />
						</spine>
						<tours></tours>
						<guide>
							<reference type="start" title="Start Page" href="index.html"></reference>
						</guide>
					</package>
					XML
				end

				yield "#{@current_dir}/tdiary.opf"
			end

		private

			def retry_loop( times )
				count = 0
				begin
					yield
				rescue
					count += 1
					if count >= times
						raise
					else
						News2Kindle.logger.debug $!
						News2Kindle.logger.info "#{count} retry."
						sleep 1
						retry
					end
				end
			end

			def save_image(img)
				require 'securerandom'

				img = @top + img if /^https?:/ !~ img
				uri = URI(img)
				file_name = "#{SecureRandom.hex}#{uri.to_s.scan(/\.[^\.]+$/)[0]}"
				begin
					open("#{@current_dir}/#{file_name}", 'w') do |f|
						f.write URI.open(uri, &:read)
					end
				rescue OpenURI::HTTPError, RuntimeError, Errno::ENOENT
					News2Kindle.logger.warn "#$!: #{uri}"
				end
				return file_name
			end
		end
	end
end
