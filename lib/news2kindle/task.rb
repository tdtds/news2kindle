# task controller
#
# Copyright (C) 2017 by TADA Tadashi <t@tdtds.jp>
# Distributed under GPL.
#
require 'kindlegen'
require 'mail'

module News2Kindle
	class Task
		def initialize( name )
			require "news2kindle/generator/#{name}"
			@generator = News2Kindle::Generator.const_get( name.split(/-/).map{|a| a.capitalize}.join )
		end

		def run( to, from, opts )
			Dir.mktmpdir do |dir|
				@generator::new( dir ).generate( opts ) do |opf|
					Kindlegen.run( opf, '-o', 'kindlizer.mobi', '-locale', 'ja' )
					mobi = Pathname( opf ).dirname + 'kindlizer.mobi'
					if mobi.file?
						News2Kindle.logger.info "generated #{mobi} successfully."
						deliver( [to].flatten, from, mobi )
					else
						News2Kindle.logger.error 'failed mobi generation.'
					end
				end
			end
		end

	private
		def deliver( to_address, from_address, mobi )
			to_dropbox = to_address.map{|a| /^dropbox:/ =~ a ? a : nil}.compact
			deliver_via_dropbox(to_dropbox, mobi)
			deliver_via_mail(to_address - to_dropbox, from_address, mobi)
		end

		def deliver_via_mail(to_address, from_address, mobi)
			return if to_address.empty?
			Mail.deliver do
				from from_address
				to  to_address
				subject 'sent by kindlizer'
				body 'dummy text'
				attachments[mobi.basename.to_s] = {
					:mime_type => 'application/octet-stream',
					:content => open(mobi, &:read)
				}
			end
			News2Kindle.logger.info "sent mails successfully."
		end

		def deliver_via_dropbox(to_address, mobi)
			return if to_address.empty?

			begin
				require 'dropbox_sdk'
	
				session = DropboxSession.new(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
				session.set_request_token(ENV['DROPBOX_REQUEST_TOKEN_KEY'], ENV['DROPBOX_REQUEST_TOKEN_SECRET'])
				session.set_access_token(ENV['DROPBOX_ACCESS_TOKEN_KEY'], ENV['DROPBOX_ACCESS_TOKEN_SECRET'])
				client = DropboxClient.new(session, :dropbox)
				to_address.each do |address|
					to_path = address.sub(/^dropbox:/, '')
					open(mobi) do |f|
						file = Pathname(to_path) + "#{mobi.basename('.mobi').to_s}#{Time::now.to_i}.mobi"
						client.put_file(file.to_s, f)
					end
					News2Kindle.logger.info "saved to #{address} successfully."
				end
			rescue
				News2Kindle.logger.error "failed while saving to dropbox."
				News2Kindle.logger.error $!
				$@.each{|l| News2Kindle.logger.error l}
			end
		end
	end
end
