require 'spec_helper'
require 'rack/test'
require_relative '../shared_examples/queries'

describe 'API v3 Queries' do
  include Rack::Test::Methods

  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:manage_public_queries_role) { FactoryGirl.create(:role, permissions: [:manage_public_queries]) }
  let(:save_queries_role) { FactoryGirl.create(:role, permissions: [:save_queries]) }
  let(:role_without_query_permissions) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:unauthorize_user) { FactoryGirl.create(:user) }
  let(:star_path) { "/api/v3/queries/#{query.id}/star" }

  describe 'PATCH #star' do

    # START behaviour for anonymous user
    context 'when anonymous user' do
      before(:each) { patch star_path }

      # START behaviour for public query
      describe 'public query' do
        let(:query) { FactoryGirl.create(:public_query, project: project) }

        context 'when login is not globally required' do
          it_should_behave_like "403 Forbidden response"
        end

        context 'when login is globally required' do
          it_should_behave_like '401 Unauthorized response'
        end

        context 'when trying to star nonexistent query' do
          let(:star_path) { "/api/v3/queries/999/star" }

          it 'should respond with 404' do
            last_response.status.should eq(404)
          end

          it 'should respond with explanatory error message' do
            errors = %([{"key":"not_found","messages":["Couldn't find Query with id=999"])
            last_response.body.should be_json_eql(errors).at_path("errors")
          end
        end
      end
      # END behaviour for public query
    end
    # END behaviour for anonymous user

    # START behaviour for user without permissions
    context 'when user without permissions' do
      before(:each) do
        klass = Class.new do include BecomeMember end
        klass.new.become_member_with_permissions(project, current_user, permissions = [:manage_public_queries])
        as_logged_in_user current_user do
          patch star_path
        end
      end

      # START behaviour for public query
      describe 'public query' do
        let(:query) { FactoryGirl.create(:public_query, project: project) }
        let(:name_json) { query.name.to_json }
        let(:starred_json) { "true".to_json }

        # START behaviour for starring an unstarred query
        context 'starring an unstarred query' do
          it_should_behave_like "API 200 OK response"
          # it 'should respond with 200' do
          #   last_response.status.should eq(200)
          # end

          # it 'should respond with the query' do
          #   last_response.body.should be_json_eql(name_json).at_path("name")
          # end

          it 'should respond with the query with "isStarred" property set tu true' do
            last_response.body.should be_json_eql(starred_json).at_path("isStarred")
          end
        end
        # END behaviour for starring an unstarred query

        # START behaviour for starring already starred query
        context 'starring already starred query' do
          before(:each) { FactoryGirl.create(:query_menu_item, query: query) }

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should respond with the query' do
            last_response.body.should be_json_eql(name_json).at_path("name")
          end

          it 'should respond with the query with "isStarred" property set tu true' do
            last_response.body.should be_json_eql(starred_json).at_path("isStarred")
          end
        end
        # END behaviour for starring already starred query

        context 'trying to star nonexistent query' do
          let(:star_path) { "/api/v3/queries/999/star" }

          it 'should respond with 404' do
            last_response.status.should eq(404)
          end

          it 'should respond with explanatory error message' do
            errors = %([{"key":"not_found","messages":["Couldn't find Query with id=999"])
            last_response.body.should be_json_eql(errors).at_path("errors")
          end
        end
      end
      # END behaviour for public query

      # START behaviour for private query
      describe 'private query' do
        let(:query) { FactoryGirl.create(:private, project: project) }
      end
      # END behaviour for private query
    end
    # END behaviour for user without permissions

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
