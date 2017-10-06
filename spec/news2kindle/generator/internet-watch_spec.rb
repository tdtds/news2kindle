require 'news2kindle/dup_checker'
require 'news2kindle/generator/internet-watch'

describe 'internet-watch generator' do
	context 'normal' do
		it 'makes OPF file' do
			Dir.mktmpdir do |dir|
				News2Kindle::Generator::InternetWatch::new(dir).generate({now: Time::now}) do |opf|
					expect(opf).to eq "#{dir}/dst/internet-watch.opf"
				end
			end
		end
	end
end
