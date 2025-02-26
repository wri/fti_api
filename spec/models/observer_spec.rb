# == Schema Information
#
# Table name: observers
#
#  id                 :integer          not null, primary key
#  observer_type      :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  is_active          :boolean          default(TRUE), not null
#  logo               :string
#  address            :string
#  information_name   :string
#  information_email  :string
#  information_phone  :string
#  data_name          :string
#  data_email         :string
#  data_phone         :string
#  organization_type  :string
#  public_info        :boolean          default(FALSE), not null
#  responsible_qc2_id :integer
#  name               :string           not null
#  responsible_qc1_id :bigint
#

require "rails_helper"

RSpec.describe Observer, type: :model do
  subject(:observer) { FactoryBot.build(:observer) }

  it "is valid with valid attributes" do
    expect(observer).to be_valid
  end

  describe "Instance methods" do
    describe "#cache_key" do
      it "return the default value with the locale" do
        expect(observer.cache_key).to match(/-#{Globalize.locale}\z/)
      end
    end
  end

  describe "Class methods" do
    before do
      create_list(:observer, 3)
    end

    describe "#observer_select" do
      it "return formatted information of observer sorted by name asc" do
        expect(Observer.observer_select).to eql(
          Observer.by_name_asc.map { |c| ["#{c.name} (#{c.observer_type})", c.id] }
        )
      end
    end

    describe "#types" do
      it "return types for the observers" do
        expect(Observer.types).to eql %w[Mandated SemiMandated External Government].freeze
      end
    end

    describe "#translated_types" do
      it "return transated types for the observers" do
        translated_types =
          Observer.types.map { |t| [I18n.t("observer_types.#{t}", default: t), t.camelize] }

        expect(Observer.translated_types).to eql translated_types
      end
    end
  end
end
