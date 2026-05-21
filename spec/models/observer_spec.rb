# == Schema Information
#
# Table name: observers
#
#  id                 :integer          not null, primary key
#  observer_type      :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  is_active          :boolean          default(TRUE), not null
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

  describe "callbacks" do
    describe "when responsible_qc1 is removed" do
      let(:qc1_user) { create(:ngo_manager) }
      let(:observer) { create(:observer, responsible_qc1: qc1_user) }

      def create_observation_in(status)
        create(:observation, force_status: status).tap do |o|
          # to override observers taken from observation_report
          o.observers = [observer]
        end
      end

      it "moves `Ready for QC1` observations to `Ready for QC2`" do
        observation = create_observation_in("Ready for QC1")

        expect {
          observer.update!(responsible_qc1: nil)
        }.to change { observation.reload.validation_status }.from("Ready for QC1").to("Ready for QC2")
      end

      it "moves `QC1 in progress` observations to `Ready for QC2`" do
        observation = create_observation_in("QC1 in progress")

        expect {
          observer.update!(responsible_qc1: nil)
        }.to change { observation.reload.validation_status }.from("QC1 in progress").to("Ready for QC2")
      end

      it "leaves the observation in QC1 if another observer still has responsible_qc1" do
        other_observer = create(:observer, responsible_qc1: create(:ngo_manager))
        observation = create_observation_in("Ready for QC1")
        observation.observers << other_observer

        expect {
          observer.update!(responsible_qc1: nil)
        }.not_to change { observation.reload.validation_status }
      end

      it "does not touch observations in other statuses" do
        observation = create_observation_in("Ready for QC2")

        expect {
          observer.update!(responsible_qc1: nil)
        }.not_to change { observation.reload.validation_status }
      end

      it "does nothing when responsible_qc1 is reassigned to another user" do
        observation = create_observation_in("Ready for QC1")
        new_qc1 = create(:ngo_manager)

        expect {
          observer.update!(responsible_qc1: new_qc1)
        }.not_to change { observation.reload.validation_status }
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
