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
				require 'pit'
				require 'dropbox_api'
				auth = Pit::get('news2kindle')
				unless auth[:dropbox_token]
					print "Enter dropbox app key: "
					api_key = $stdin.gets.chomp

					print "Enter dropbox app secret: "
					api_secret = $stdin.gets.chomp

					authenticator = DropboxApi::Authenticator.new(api_key, api_secret)
					puts "\nGo to this url and click 'Authorize' to get the token:"
					puts authenticator.authorize_url

					print "Enter the token: "
					code = $stdin.gets.chomp

					auth[:dropbox_token] = authenticator.get_token(code).token
					Pit::set('news2kindle', data: auth)
				end
				client = DropboxApi::Client.new(auth[:dropbox_token])
	
				to_address.each do |address|
					to_path = address.sub(/^dropbox:/, '')
					open(mobi) do |f|
						file = Pathname(to_path) + "#{mobi.basename('.mobi').to_s}#{Time::now.to_i}.mobi"
						info = DropboxApi::Metadata::CommitInfo.new('path'=>file, 'mode'=>:add)
						cursor = client.upload_session_start('')
						while data = f.read(10_000_000)
							client.upload_session_append_v2(cursor, data)
						end
						client.upload_session_finish(cursor, info)
					end
					News2Kindle.logger.info "saved to #{address} successfully."
				end
			rescue
				News2Kindle.logger.error "failed while saving to dropbox."
				News2Kindle.logger.debug $!
				$@.each{|l| News2Kindle.logger.debug l}
			end
		end
	end
end
