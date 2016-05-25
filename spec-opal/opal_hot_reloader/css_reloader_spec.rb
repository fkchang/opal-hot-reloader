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


end
