require 'news2kindle/version'
require 'news2kindle/task'
require 'news2kindle/dup_checker'
require 'logger'

module News2Kindle
	@logger = Logger.new(STDERR)
	@logger.level = Logger::ERROR
	@logger.formatter = proc{|severity, _, _, msg| "#{severity}: #{msg}\n"}
	def self.logger; @logger; end
	def self.logger=(logger); @logger = logger; end
end
