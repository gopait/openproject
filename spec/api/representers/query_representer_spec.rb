#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::QueryRepresenter do
  let(:query) { FactoryGirl.build(:query) }
  let(:model) { ::API::V3::Queries::QueryModel.new(query: query) }
  let(:representer) { described_class.new(model) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('Query'.to_json).at_path('_type') }

    it { should have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(subject).to have_json_path('_links/self/href')
    end

    describe 'acitivity' do
      it { should have_json_path('id') }
      it { should have_json_path('name') }
      it { should have_json_path('projectId') }
      it { should have_json_path('projectName') }
      it { should have_json_path('filters') }
      it { should have_json_path('isPublic') }
      it { should have_json_path('columnNames') }
      it { should have_json_path('groupBy') }
      it { should have_json_path('displaySums') }
      it { should have_json_path('isStarred') }

      it 'should link to user' do
        expect(subject).to have_json_path('_links/user/href')
      end
    end
  end
end
