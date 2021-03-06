# uri duplication checker
#
# Copyright (C) 2017 by TADA Tadashi <t@tdtds.jp>
# Distributed under GPL.
#
require 'mongoid'

module News2Kindle
	class DupChecker
		Mongo::Logger.level = Logger::WARN
		@@mongoid_conf = nil

		include Mongoid::Document
		include Mongoid::Timestamps
		store_in collection: 'uri'
		field :uri, type: String

		def self.setup(mongoid_conf)
			@@mongoid_conf = mongoid_conf
		end

		def self.dup?(uri)
			return false unless @@mongoid_conf
			Mongoid::Config.load_configuration(@@mongoid_conf) if Mongoid::Config.clients.size == 0

			begin
				url = uri.to_s
				if self.where(uri: uri.to_s).size == 0
					self.create(uri: uri.to_s)
					return false
				else
					return true
				end
			rescue
				News2Kindle.logger.error $!
				@@mongoid_conf = nil
				return false
			end
		end
	end
end
