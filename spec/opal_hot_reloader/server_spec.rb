require 'spec_helper'

describe OpalHotReloader::Server do
  context 'directory management' do
    it 'handles passed in directory' do
      server = OpalHotReloader::Server.new(:directories => ['this/dir'])
      expect(server.directories).to eq(['this/dir'])
    end
    it 'handles passed in directory' do
      server = OpalHotReloader::Server.new(:directories => ['this/dir', 'that/dir'])
      expect(server.directories).to eq(['this/dir', 'that/dir'])
    end

    it 'has no default directories' do
      expect(OpalHotReloader::Server.new({}).directories).to eq []
    end
    
    it 'handles rails/reactrb-rails dirs automatically' do
      expect(File).to receive(:exists?).with('app/assets/javascripts').and_return(true)
      expect(File).to receive(:exists?).with('app/views/components').and_return(true)
      expect(File).to receive(:exists?).with('app/assets/stylesheets').and_return(true)
      server = OpalHotReloader::Server.new({})
      expect(server.directories).to eq(['app/assets/javascripts', 'app/assets/stylesheets', 'app/views/components'])
    end
  end
end
