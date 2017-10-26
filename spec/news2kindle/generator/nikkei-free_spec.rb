# -*- coding: utf-8 -*-

require './lib/news2kindle/dup_checker'
require File.expand_path('../../../../lib/news2kindle/generator/nikkei-free', __FILE__ )

describe 'nikkei-free generator' do
	context 'normal' do
		it 'makes OPF file' do
			Dir.mktmpdir do |dir|
				News2Kindle::Generator::NikkeiFree::new(dir).generate({now: Time::now}) do |opf|
					expect(opf).to eq "#{dir}/dst/nikkei-free.opf"
				end
			end
		end
	end
end
