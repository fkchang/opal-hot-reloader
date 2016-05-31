require 'native'
require 'opal_hot_reloader'
require 'opal_hot_reloader/css_reloader'
describe OpalHotReloader::CssReloader do
  # Creates a DOM stylesheet link
  # @param href [String] the link url
  def create_link( href)
    %x|
    var ss = document.createElement("link");
    ss.type = "text/css";
    ss.rel = "stylesheet";
    ss.href = #{href};
    return ss;
  |
  end

  # Creates a document test double and the link to check whether it has been altered right
  # @param href [String] the link url
  def fake_links_document(href)
    link = create_link(href)
    doc = `{ getElementsByTagName: function(name) { links = [ #{link}]; return links;}}`
    { link: link, document: doc}
  end


  context 'Rack::Sass::Plugin' do
    it 'should append t_hot_reload to a css path' do
      css_path = 'stylesheets/base.css'
      doubles = fake_links_document(css_path)
      link = Native(doubles[:link])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}$/
      subject.reload({ url: css_path}, doubles[:document])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}\?t_hot_reload=\d+/
    end

    it 'should update t_hot_reload argument if there is one already' do 
      css_path = 'stylesheets/base.css?t_hot_reload=1111111111111'
      doubles = fake_links_document(css_path)
      link = Native(doubles[:link])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}$/
      subject.reload({ url: css_path}, doubles[:document])
      expect(link[:href]).to match /#{Regexp.escape('stylesheets/base.css?t_hot_reload=')}(\d)+/
      expect($1).to_not eq '1111111111111'
    end

    it 'should append t_hot_reload if there are existing arguments' do
      css_path = 'stylesheets/base.css?some-arg=1'
      doubles = fake_links_document(css_path)
      link = Native(doubles[:link])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}$/
      subject.reload({ url: css_path}, doubles[:document])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}\&t_hot_reload=(\d)+/
    end
  end

  context "Rails asset pipeline" do
    it 'should append t_hot_reload to a css path' do
      css_path = "http://localhost:8080/assets/company.self-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.css?body=1"
      doubles = fake_links_document(css_path)
      link = Native(doubles[:link])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}$/
      raw_scss_path = "app/assets/stylesheets/company.css.css"
      subject.reload({ url: raw_scss_path}, doubles[:document])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}\&t_hot_reload=\d+/
    end

    it 'should update t_hot_reload arguments' do
      css_path ="http://localhost:8080/assets/company.self-055b3f2f4bbc772b1161698989ee095020c65e0283f4e732c66153e06b266ca8.css?body=1&t_hot_reload=1464733023"
      doubles = fake_links_document(css_path)
      link = Native(doubles[:link])
      expect(link[:href]).to match /#{Regexp.escape(css_path)}$/
      raw_scss_path = "app/assets/stylesheets/company.css.css"
      subject.reload({ url: raw_scss_path}, doubles[:document])
      if link[:href] =~ /(.+)\&t_hot_reload=(\d+)/
        new_timestamp = $2
        expect(new_timestamp).to_not eq("1464733023")
      else
        fail("new link_path is broken")
      end
    end
  end
end
