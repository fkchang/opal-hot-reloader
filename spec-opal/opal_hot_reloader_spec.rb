require 'opal_hot_reloader'
describe OpalHotReloader do
  context 'alerts' do
    it 'should be controllable' do
      expect(subject.use_alert?).to eq true
      OpalHotReloader.alerts_off!
      expect(subject.use_alert?).to eq false
    end
  end
end
