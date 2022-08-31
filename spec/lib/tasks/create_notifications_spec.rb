require 'rails_helper'

Rails.application.load_tasks

describe 'notifications_create' do
  after(:each) do
    Rake::Task['scheduler:create_notifications'].reenable
  end

  let(:country) { create :country }
  let(:required_operator_document) { create :required_operator_document_country, country: country }
  let(:operator) { create :operator, country: country }
  let!(:user1) { create :operator_user, country: country, operator: operator }
  let!(:user2) { create :operator_user, country: country, operator: operator }
  subject { Rake::Task["scheduler:create_notifications"].invoke }

  shared_examples 'no notifications change' do
    it { expect{ subject }.not_to change{ Notification.count } }
  end

  shared_context 'with document' do
    let!(:operator_document) {
      create :operator_document_country, operator: operator,
             required_operator_document: required_operator_document, expire_date: expire_date
    }
    before do
      operator_document.update(status: OperatorDocument.statuses[:doc_valid])
    end
  end

  context 'when there are no notification groups' do
    let(:expire_date) { Date.today + 1.year }
    include_context 'with document'
    it_behaves_like 'no notifications change'
  end

  context 'when there are notification groups' do
    let!(:notification_group) { create :notification_group }

    context 'when there are no documents' do
      it_behaves_like 'no notifications change'
    end

    context "when the date to expire is bigger than document's expire date" do
      let(:expire_date) { Date.today + 1.year }
      include_context 'with document'
      it_behaves_like 'no notifications change'
    end

    context "when the date to expire is smaller than the document's expire date" do
      context 'when there are no associated notifications' do
        let(:expire_date) { Date.today }
        include_context 'with document'
        it { expect{ subject }.to change{ Notification.count }.by(2) }
      end

      context 'when there are associated notifications' do
        let(:expire_date) { Date.tomorrow }
        include_context 'with document'

        context 'when the notification has not been displayed' do
          let!(:notification) {
            create :notification,
                   operator_document: operator_document, user: user1,
                   notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been displayed' do
          let!(:notification) {
            create :notification, :seen,
                   operator_document: operator_document, user: user1,
                   notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been dismissed' do
          let!(:notification) {
            create :notification, :dismissed,
                   operator_document: operator_document, user: user1,
                   notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been solved' do
          let!(:notification) {
            create :notification, :solved,
                   operator_document: operator_document, user: user1,
                   notification_group: notification_group
          }
          it { expect { subject }.to change { Notification.count }.by(2) }

          context 'when the document did not expire' do
            let(:expire_date) { Date.today + 1.year }
            include_context 'with document'
            it_behaves_like 'no notifications change'
          end
        end
      end
    end

    context 'when there are more than one notification groups' do
      let!(:notification_group_large) { create :notification_group, days: 20 }

      context "when both notification groups' date to expire are smaller than the document's expire date" do
        let(:expire_date) { Date.today }
        include_context 'with document'
        it { expect { subject }.to change { Notification.count }.by(2) } # TODO: update to check if it's the right group

        context 'when there is a notification for the notification group with the biggest days' do
          context 'when the notification is active' do
            let!(:notification) {
              create :notification,
                     user: user1, operator_document: operator_document,
                     notification_group: notification_group_large
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
          context 'when the notification is solved' do
            let!(:notification) {
              create :notification, :solved,
                     user: user1, operator_document: operator_document,
                     notification_group: notification_group_large
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
        end

        context 'when there is a notification for the notification group with the smallest days' do
          context 'when the notification is active' do
            let!(:notification) {
              create :notification,
                     user: user1, operator_document: operator_document,
                     notification_group: notification_group
            }
            it_behaves_like 'no notifications change'
          end

          context 'when the notification is solved' do
            let!(:notification) {
              create :notification, :solved,
                     user: user1, operator_document: operator_document,
                     notification_group: notification_group
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
        end
      end
    end
  end
end
