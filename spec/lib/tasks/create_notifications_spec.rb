require 'rails_helper'

Rails.application.load_tasks

describe 'notifications_create' do
  after(:each) do
    Rake::Task['notifications:create'].reenable
  end

  let(:country) { create :country }
  let(:required_operator_document) { create :required_operator_document, country: country }
  let(:user1) { create :user, country: country }
  let(:user2) { create :user, country: country }
  let(:operator) { create :operator, country: country, users: [user1, user2] }
  subject { Rake::Task["notifications:create"].invoke }

  shared_examples 'no notifications change' do
    it { expect{ subject }.not_to change{ Notification.count } }
  end

  context 'when there are no notification groups' do
    let!(:operator_document) {
      create :operator_document, operator: operator,
             required_operator_document: required_operator_document, expire_date: Date.today + 1.year
    }
    it_behaves_like 'no notifications change'
  end

  context 'when there are notification groups' do
    let!(:notification_group) { create :notification_group }

    context 'when there are no documents' do
      it_behaves_like 'no notifications change'
    end

    context "when the date to expire is bigger than document's expire date" do
      let(:operator_document) {
        create :operator_document, operator: operator,
               required_operator_document: required_operator_document, expire_date: Date.today + 1.year
      }
      it_behaves_like 'no notifications change'
    end

    context "when the date to expire is smaller than the document's expire date" do
      context 'when there are no associated notifications' do
        context 'when there are documents expired' do
          let!(:operator_document) {
            create :operator_document, operator: operator,
                   required_operator_document: required_operator_document, expire_date: Date.today
          }
          it { expect{ subject }.to change{ Notification.count }.by(2) }
        end
      end

      context 'when there are associated notifications' do
        let!(:operator_document) {
          create :operator_document,
                 operator: operator, required_operator_document: required_operator_document, expire_date: Date.tomorrow
        }

        context 'when the notification has not been displayed' do
          let!(:notification) {
            create :notification,
                   operator_document: operator_document, user: user1,
                   operator: operator, notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been displayed' do
          let!(:notification) {
            create :notification, :seen,
                   operator_document: operator_document, user: user1,
                   operator: operator, notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been dismissed' do
          let!(:notification) {
            create :notification, :dismissed,
                   operator_document: operator_document, user: user1,
                   operator: operator, notification_group: notification_group
          }
          it_behaves_like 'no notifications change'
        end

        context 'when the notification has been solved' do
          let!(:notification) {
            create :notification, :solved,
                   operator_document: operator_document, user: user1,
                   operator: operator, notification_group: notification_group
          }
          it { expect { subject }.to change { Notification.count }.by(2) }

          context 'when the document did not expire' do
            before do
              operator_document.update(expire_date: Date.today + 1.year)
            end
            it_behaves_like 'no notifications change'
          end
        end
      end
    end

    context 'when there are more than one notification groups' do
      let!(:notification_group_large) { create :notification_group, days: 20 }

      context "when both notification groups' date to expire are smaller than the document's expire date" do
        let!(:operator_document) {
          create :operator_document, operator: operator,
                 required_operator_document: required_operator_document, expire_date: Date.today
        }
        it { expect { subject }.to change { Notification.count }.by(2) } # TODO: update to check if it's the right group

        context 'when there is a notification for the notification group with the biggest days' do
          context 'when the notification is active' do
            let!(:notification) {
              create :notification,
                     operator: operator, user: user1, operator_document: operator_document,
                     notification_group: notification_group_large
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
          context 'when the notification is solved' do
            let!(:notification) {
              create :notification, :solved,
                     operator: operator, user: user1, operator_document: operator_document,
                     notification_group: notification_group_large
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
        end

        context 'when there is a notification for the notification group with the smallest days' do
          context 'when the notification is active' do
            let!(:notification) {
              create :notification,
                     operator: operator, user: user1, operator_document: operator_document,
                     notification_group: notification_group
            }
            it_behaves_like 'no notifications change'
          end

          context 'when the notification is solved' do
            let!(:notification) {
              create :notification, :solved,
                     operator: operator, user: user1, operator_document: operator_document,
                     notification_group: notification_group
            }
            it { expect { subject }.to change { Notification.count }.by(2) } # TODO
          end
        end
      end
    end
  end
end
