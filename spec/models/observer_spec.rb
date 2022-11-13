# == Schema Information
#
# Table name: observers
#
#  id                   :integer          not null, primary key
#  observer_type        :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  is_active            :boolean          default(TRUE)
#  logo                 :string
#  address              :string
#  information_name     :string
#  information_email    :string
#  information_phone    :string
#  data_name            :string
#  data_email           :string
#  data_phone           :string
#  organization_type    :string
#  public_info          :boolean          default(FALSE)
#  responsible_user_id  :integer
#  responsible_admin_id :integer
#  name                 :string
#  organization         :string
#

require 'rails_helper'

RSpec.describe Observer, type: :model do
  subject(:observer) { FactoryBot.build(:observer) }

  it 'is valid with valid attributes' do
    expect(observer).to be_valid
  end

  it_should_behave_like 'translatable', :observer, %i[name organization]

  describe 'Instance methods' do
    describe '#cache_key' do
      it 'return the default value with the locale' do
        expect(observer.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    before do
      create_list(:observer, 3)
    end

    describe '#fetch_all' do
      it 'fetch all operators' do
        expect(Observer.fetch_all(nil)).to eq(Observer.includes(:countries, :users))
      end
    end

    describe '#observer_select' do
      it 'return formatted information of observer sorted by name asc' do
        expect(Observer.observer_select).to eql(
          Observer.by_name_asc.map { |c| ["#{c.name} (#{c.observer_type})", c.id] }
        )
      end
    end

    describe '#types' do
      it 'return types for the observers' do
        expect(Observer.types).to eql %w(Mandated SemiMandated External Government).freeze
      end
    end

    describe '#translated_types' do
      it 'return transated types for the observers' do
        translated_types =
          Observer.types.map { |t| [I18n.t("observer_types.#{t}", default: t), t.camelize] }

        expect(Observer.translated_types).to eql translated_types
      end
    end
  end
end
