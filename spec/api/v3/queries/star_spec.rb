require 'spec_helper'
require 'rack/test'

describe 'API v3 Queries' do
  include Rack::Test::Methods

  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:manage_public_queries_role) { FactoryGirl.create(:role, permissions: [:manage_public_queries]) }
  let(:save_queries_role) { FactoryGirl.create(:role, permissions: [:save_queries]) }
  let(:role_without_query_permissions) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:unauthorize_user) { FactoryGirl.create(:user) }

  describe 'PATCH #star' do
    context 'when anonymous user' do
      describe 'public query' do

      end

      describe 'private query' do

      end
    end

    context 'when user without permissions' do
      describe 'public query' do

      end

      describe 'private query' do

      end
    end

    context 'when user with permissions' do
      describe 'public query' do

      end

      describe 'private query' do

      end
    end

    context 'when admin' do
      describe 'public query' do

      end

      describe 'private query' do

      end
    end
  end
end
