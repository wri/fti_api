require 'spec_helper'

RSpec.shared_examples 'activable' do |model_name, model|
  if model.attributes.key? 'deactivated_at'
    context 'hooks' do
      context '#set_deactivated_at' do
        it "set deactivated_at when #{model_name} is saved" do
          model.deactivate

          expect(model.deactivated_at).not_to eql nil
        end
      end
    end
  end

  context '#activate' do
    it "mark #{model_name} as actived" do
      model.activate
      expect(model.is_active).to eql true
    end
  end

  context '#deactivate' do
    it "mark #{model_name} as deactivated" do
      model.deactivate
      expect(model.is_active).to eql false
    end
  end

  context '#deactivated?' do
    context "when #{model_name} is actived" do
      it 'returns false' do
        model.is_active = true
        expect(model.deactivated?).to eql false
      end
    end

    context "when #{model_name} is deactivated" do
      it 'returns true' do
        model.is_active = false
        expect(model.deactivated?).to eql true
      end
    end
  end

  context '#activated?' do
    context "when #{model_name} is actived" do
      it 'returns true' do
        model.is_active = true
        expect(model.activated?).to eql true
      end
    end

    context "when #{model_name} is deactivated" do
      it 'returns false' do
        model.is_active = false
        expect(model.activated?).to eql false
      end
    end
  end

  context '#status' do
    context "when #{model_name} is actived" do
      it 'returns activated' do
        model.is_active = true
        expect(model.status).to eql 'activated'
      end
    end

    context "when #{model_name} is deactivated" do
      it 'returns deactivated' do
        model.is_active = false
        expect(model.status).to eql 'deactivated'
      end
    end
  end
end
