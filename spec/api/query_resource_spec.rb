require 'spec_helper'
require 'rack/test'

describe 'API v3 Query resource' do
  include Rack::Test::Methods

  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:manage_public_queries_role) { FactoryGirl.create(:role, permissions: [:manage_public_queries]) }
  let(:save_queries_role) { FactoryGirl.create(:role, permissions: [:save_queries]) }
  let(:role_without_query_permissions) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:unauthorize_user) { FactoryGirl.create(:user) }

  describe '#star' do
    let(:star_path) { "/api/v3/queries/#{query.id}/star" }
    let(:filters) do
        query.filters.map{ |f| {f.field.to_s => { "operator" => f.operator, "values" => f.values }}}
      end
    let(:expected_response) do
      {
        "_type" => 'Query',
        "_links" => {
          "self" => {
            "href" => "http://localhost:3000/api/v3/queries/#{query.id}",
            "title" => query.name
          }
        },
        "id" => query.id,
        "name" => query.name,
        "projectId" => query.project_id,
        "projectName" => query.project.name,
        "userId" => query.user_id,
        "userName" => query.user.try(:name),
        "userLogin" => query.user.try(:login),
        "userMail" => query.user.try(:mail),
        "filters" => filters,
        "isPublic" => query.is_public.to_s,
        "columnNames" => query.column_names,
        "sortCriteria" => query.sort_criteria,
        "groupBy" => query.group_by,
        "displaySums" => query.display_sums.to_s,
        "isStarred" => "true"
      }
    end

    describe 'public queries' do
      let(:query) { FactoryGirl.create(:public_query, project: project) }

      context 'user with permission to manage public queries' do
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [manage_public_queries_role.id]
          member.save!
        end

        context 'when starring an unstarred query' do
          before(:each) { patch star_path }

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response)
          end

          it 'should return the query with "isStarred" property set to true' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('true')
          end
        end

        context 'when starring already starred query' do
          before(:each) { patch star_path }

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response)
          end

          it 'should return the query with "isStarred" property set to true' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('true')
          end
        end

        context 'when trying to star nonexistent query' do
          let(:star_path) { "/api/v3/queries/999/star" }
          before(:each) { patch star_path }

          it 'should respond with 404' do
            last_response.status.should eq(404)
          end

          it 'should respond with explanatory error message' do
            parsed_errors = JSON.parse(last_response.body)['errors']
            parsed_errors.should eq([{ 'key' => 'not_found', 'messages' => ['Couldn\'t find Query with id=999']}])
          end
        end
      end

      context 'user without permission to manage public queries' do
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [role_without_query_permissions.id]
          member.save!
          patch star_path
        end

        it 'should respond with 403' do
          last_response.status.should eq(403)
        end

        it 'should respond with explanatory error message' do
          parsed_errors = JSON.parse(last_response.body)['errors']
          parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
        end
      end
    end

    describe 'private queries' do
      context 'user with permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [save_queries_role.id]
          member.save!
          patch star_path
        end

        context 'starring his own query' do

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response)
          end

          it 'should return the query with "isStarred" property set to true' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('true')
          end
        end

        context 'trying to star somebody else\'s query' do
          let(:another_user) { FactoryGirl.create(:user) }
          let(:query) { FactoryGirl.create(:private_query, project: project, user: another_user) }

          it 'should respond with 403' do
            last_response.status.should eq(403)
          end

          it 'should respond with explanatory error message' do
            parsed_errors = JSON.parse(last_response.body)['errors']
            parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
          end
        end
      end

      context 'user without permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [role_without_query_permissions.id]
          member.save!
          patch star_path
        end

        it 'should respond with 403' do
          last_response.status.should eq(403)
        end

        it 'should respond with explanatory error message' do
          parsed_errors = JSON.parse(last_response.body)['errors']
          parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
        end
      end

    end
  end

  describe '#unstar' do
    let(:unstar_path) { "/api/v3/queries/#{query.id}/unstar" }
    let(:filters) do
        query.filters.map{ |f| {f.field.to_s => { "operator" => f.operator, "values" => f.values }}}
      end
    let(:expected_response) do
      {
        "_type" => 'Query',
        "_links" => {
          "self" => {
            "href" => "http://localhost:3000/api/v3/queries/#{query.id}",
            "title" => query.name
          }
        },
        "id" => query.id,
        "name" => query.name,
        "projectId" => query.project_id,
        "projectName" => query.project.name,
        "userId" => query.user_id,
        "userName" => query.user.try(:name),
        "userLogin" => query.user.try(:login),
        "userMail" => query.user.try(:mail),
        "filters" => filters,
        "isPublic" => query.is_public.to_s,
        "columnNames" => query.column_names,
        "sortCriteria" => query.sort_criteria,
        "groupBy" => query.group_by,
        "displaySums" => query.display_sums.to_s,
        "isStarred" => "true"
      }
    end

    describe 'public queries' do
      let(:query) { FactoryGirl.create(:public_query, project: project) }

      context 'user with permission to manage public queries' do
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [manage_public_queries_role.id]
          member.save!
        end

        context 'when unstarring a starred query' do
          before(:each) do
            FactoryGirl.create(:query_menu_item, query: query)
            patch unstar_path
          end

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response.tap{ |r| r["isStarred"] = "false" })
          end

          it 'should return the query with "isStarred" property set to false' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('false')
          end
        end

        context 'when unstarring an unstarred query' do
          before(:each) { patch unstar_path }

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response.tap{ |r| r["isStarred"] = "false" })
          end

          it 'should return the query with "isStarred" property set to true' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('false')
          end

        end

        context 'when trying to unstar nonexistent query' do
          let(:unstar_path) { "/api/v3/queries/999/unstar" }
          before(:each) { patch unstar_path }

          it 'should respond with 404' do
            last_response.status.should eq(404)
          end

          it 'should respond with explanatory error message' do
            parsed_errors = JSON.parse(last_response.body)['errors']
            parsed_errors.should eq([{ 'key' => 'not_found', 'messages' => ['Couldn\'t find Query with id=999']}])
          end
        end
      end

      context 'user without permission to manage public queries' do
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [role_without_query_permissions.id]
          member.save!
          patch unstar_path
        end

        it 'should respond with 403' do
          last_response.status.should eq(403)
        end

        it 'should respond with explanatory error message' do
          parsed_errors = JSON.parse(last_response.body)['errors']
          parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
        end
      end
    end

    describe 'private queries' do
      context 'user with permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [save_queries_role.id]
          member.save!
          patch unstar_path
        end

        context 'unstarring his own query' do

          it 'should respond with 200' do
            last_response.status.should eq(200)
          end

          it 'should return the query in HAL+JSON format' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response.should eq(expected_response.tap{ |r| r["isStarred"] = "false" })
          end

          it 'should return the query with "isStarred" property set to true' do
            parsed_response = JSON.parse(last_response.body)
            parsed_response['isStarred'].should eq('false')
          end
        end

        context 'trying to unstar somebody else\'s query' do
          let(:another_user) { FactoryGirl.create(:user) }
          let(:query) { FactoryGirl.create(:private_query, project: project, user: another_user) }

          it 'should respond with 403' do
            last_response.status.should eq(403)
          end

          it 'should respond with explanatory error message' do
            parsed_errors = JSON.parse(last_response.body)['errors']
            parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
          end
        end
      end

      context 'user without permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: project)
          member.role_ids = [role_without_query_permissions.id]
          member.save!
          patch unstar_path
        end

        it 'should respond with 403' do
          last_response.status.should eq(403)
        end

        it 'should respond with explanatory error message' do
          parsed_errors = JSON.parse(last_response.body)['errors']
          parsed_errors.should eq([{ 'key' => 'not_authorized', 'messages' => ['You are not authorize to access this resource']}])
        end
      end
    end

  end
end
