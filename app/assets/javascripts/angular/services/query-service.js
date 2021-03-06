//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

angular.module('openproject.services')

.service('QueryService', [
  'Query',
  'Sortation',
  '$http',
  '$location',
  'PathHelper',
  '$q',
  'AVAILABLE_WORK_PACKAGE_FILTERS',
  'StatusService',
  'TypeService',
  'PriorityService',
  'UserService',
  'VersionService',
  'RoleService',
  'GroupService',
  'ProjectService',
  'WorkPackagesTableHelper',
  'I18n',
  function(Query, Sortation, $http, $location, PathHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService, VersionService, RoleService, GroupService, ProjectService, WorkPackagesTableHelper, I18n) {

  var query;

  var availableColumns = [],
      availableUnusedColumns = [],
      availableFilterValues = {},
      availableFilters = {},
      availableGroupedQueries;

  var totalEntries;

  var QueryService = {
    initQuery: function(queryId, queryData, selectedColumns, exportFormats, afterQuerySetupCallback) {
      query = new Query({
        id: queryId,
        name: queryData.name,
        project_id: queryData.project_id,
        displaySums: queryData.display_sums,
        groupSums: queryData.group_sums,
        sums: queryData.sums,
        columns: selectedColumns,
        groupBy: queryData.group_by,
        isPublic: queryData.is_public,
        exportFormats: exportFormats,
        starred: queryData.starred,
        links: queryData._links
      });
      query.setSortation(new Sortation(queryData.sort_criteria));

      QueryService.getAvailableFilters(query.project_id)
        .then(function(availableFilters) {
          query.setAvailableWorkPackageFilters(availableFilters);
          if (query.isDefault()) {
            query.setDefaultFilter();
          } else {
            query.setFilters(queryData.filters);
          }

          return query;
        })
        .then(afterQuerySetupCallback);

      return query;
    },

    getQuery: function() {
      return query;
    },

    getQueryName: function() {
      if (query && query.hasName()) {
        return query.name;
      }
    },

    setTotalEntries: function(numberOfEntries) {
      totalEntries = numberOfEntries;
    },

    getTotalEntries: function() {
      return totalEntries;
    },

    getAvailableUnusedColumns: function() {
      return availableUnusedColumns;
    },

    hideColumns: function(columnNames) {
      WorkPackagesTableHelper.moveColumns(columnNames, this.getSelectedColumns(), availableUnusedColumns);
    },

    showColumns: function(columnNames) {
      WorkPackagesTableHelper.moveColumns(columnNames, availableUnusedColumns, this.getSelectedColumns());
    },

    getAvailableGroupedQueries: function() {
      return availableGroupedQueries;
    },

    // data loading

    loadAvailableGroupedQueries: function(projectIdentifier) {
      if (availableGroupedQueries) {
        return $q.when(availableGroupedQueries);
      }

      return QueryService.fetchAvailableGroupedQueries(projectIdentifier);
    },

    fetchAvailableGroupedQueries: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectGroupedQueriesPath(projectIdentifier) : PathHelper.apiGroupedQueriesPath();

      return QueryService.doQuery(url)
        .then(function(groupedQueriesResults) {
          availableGroupedQueries = groupedQueriesResults;
          return availableGroupedQueries;
        });
    },

    loadAvailableUnusedColumns: function(projectIdentifier) {
      return QueryService.loadAvailableColumns(projectIdentifier)
        .then(function(available_columns) {
          availableUnusedColumns = WorkPackagesTableHelper.getColumnDifference(available_columns, QueryService.getSelectedColumns());
          return availableUnusedColumns;
        });
    },

    loadAvailableColumns: function(projectIdentifier) {
      // TODO: Once we have a single page app we need to differentiate between different project columns
      if(availableColumns.length) {
        return $q.when(availableColumns);
      }

      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doGet(url, function(response){
        availableColumns = response.data.available_columns;
        return availableColumns;
      });
    },

    getGroupBy: function() {
      return query.groupBy;
    },

    setGroupBy: function(groupBy) {
      query.setGroupBy(groupBy);
    },

    getSelectedColumns: function() {
      return this.getQuery().getSelectedColumns();
    },

    setSelectedColumns: function(selectedColumnNames) {
      var currentColumns = this.getSelectedColumns();

      this.hideColumns(currentColumns.map(function(column) { return column.name; }));
      this.showColumns(selectedColumnNames);
    },

    updateSortElements: function(sortation) {
      return query.updateSortElements(sortation);
    },

    getSortation: function() {
      return query.getSortation();
    },

    getAvailableFilters: function(projectIdentifier){
      // TODO once this is becoming more single-page-app-like keep the available filters of the query model in sync when the project identifier is changed on the scope but the page isn't reloaded
      var identifier = 'global';
      var getFilters = QueryService.getCustomFieldFilters;
      var getFiltersArgs = [];
      if(projectIdentifier){
        identifier = projectIdentifier;
        getFilters = QueryService.getProjectCustomFieldFilters;
        getFiltersArgs.push(identifier);
      }
      if(availableFilters[identifier]){
        return $q.when(availableFilters[identifier]);
      } else {
        return getFilters.apply(this, getFiltersArgs)
          .then(function(data){
            return QueryService.storeAvailableFilters(identifier, angular.extend(AVAILABLE_WORK_PACKAGE_FILTERS, data.custom_field_filters));
          });
      }

    },

    getProjectCustomFieldFilters: function(projectIdentifier) {
      return QueryService.doQuery(PathHelper.apiProjectCustomFieldsPath(projectIdentifier));
    },

    getCustomFieldFilters: function() {
      return QueryService.doQuery(PathHelper.apiCustomFieldsPath());
    },

    getAvailableFilterValues: function(filterName, projectIdentifier) {
      return QueryService.getAvailableFilters(projectIdentifier)
        .then(function(filters){
          var filter = filters[filterName];
          var modelName = filter.modelName;

          if(filter.values) {
            // Note: We have filter values already because it is a custom field and the server gives the possible values.
            var values = filter.values.map(function(value){
              if(Array.isArray(value)){
                return { id: value[1], name: value[0] };
              } else {
                return { id: value, name: value };
              }
            });
            return $q.when(QueryService.storeAvailableFilterValues(modelName, values));
          }

          if(availableFilterValues[modelName]) {
            return $q.when(availableFilterValues[modelName]);
          } else {
            var retrieveAvailableValues;

            switch(modelName) {
              case 'status':
                retrieveAvailableValues = StatusService.getStatuses(projectIdentifier);
                break;
              case 'type':
                retrieveAvailableValues = TypeService.getTypes(projectIdentifier);
                break;
              case 'priority':
                retrieveAvailableValues = PriorityService.getPriorities(projectIdentifier);
                break;
              case 'user':
                retrieveAvailableValues = UserService.getUsers(projectIdentifier);
                break;
              case 'version':
                retrieveAvailableValues = VersionService.getProjectVersions(projectIdentifier);
                break;
              case 'role':
                retrieveAvailableValues = RoleService.getRoles();
                break;
              case 'group':
                retrieveAvailableValues = GroupService.getGroups();
                break;
              case 'project':
                retrieveAvailableValues = ProjectService.getProjects();
                break;
              case 'sub_project':
                retrieveAvailableValues = ProjectService.getSubProjects(projectIdentifier);
                break;
            }

            return retrieveAvailableValues.then(function(values) {
              return QueryService.storeAvailableFilterValues(modelName, values);
            });
          }
        });

    },

    storeAvailableFilterValues: function(modelName, values) {
      availableFilterValues[modelName] = values;
      return values;
    },

    storeAvailableFilters: function(projectIdentifier, filters){
      availableFilters[projectIdentifier] = filters;
      return availableFilters[projectIdentifier];
    },

    // synchronization

    saveQuery: function() {
      var url = query.project_id ? PathHelper.apiProjectQueryPath(query.project_id, query.id) : PathHelper.apiQueryPath(query.id);

      return QueryService.doQuery(url, query.toUpdateParams(), 'PUT', function(response){
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_update') }} );
      });
    },

    saveQueryAs: function(name) {
      query.setName(name);
      var url = query.project_id ? PathHelper.apiProjectQueriesPath(query.project_id) : PathHelper.apiQueriesPath();

      return QueryService.doQuery(url, query.toParams(), 'POST', function(response){
        query.save(response.data.query);
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_create') }} );
      });
    },

    deleteQuery: function() {
      var url = PathHelper.apiProjectQueryPath(query.project_id, query.id);
      return QueryService.doQuery(url, query.toUpdateParams(), 'DELETE', function(response){
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_delete') }} );
      });
    },

    toggleQueryStarred: function() {
      if(query.starred) {
        return QueryService.unstarQuery();
      } else {
        return QueryService.starQuery();
      }
    },

    starQuery: function() {
      var url = PathHelper.apiQueryStarPath(query.id);
      var theQuery = query;

      return QueryService.doPatch(url, function(response){
        theQuery.star();
        return response.data;
      });
    },

    unstarQuery: function() {
      var url = PathHelper.apiQueryUnstarPath(query.id);
      var theQuery = query;

      return QueryService.doPatch(url, function(response){
        theQuery.unstar();
        return response.data;
      });
    },

    updateHighlightName: function() {
      // TODO Implement an API endpoint for updating the names or add an appropriate endpoint that returns query names for all highlighted queries
      return this.unstarQuery().then(this.starQuery);
    },

    doGet: function(url, success, failure) {
      return QueryService.doQuery(url, null, 'GET', success, failure);
    },

    doPatch: function(url, success, failure) {
      return QueryService.doQuery(url, null, 'PATCH', success, failure);
    },

    doQuery: function(url, params, method, success, failure) {
      method = method || 'GET';
      success = success || function(response){
        return response.data;
      };
      failure = failure || function(response){
        return angular.extend(response, { status: { text: I18n.t('js.notice_bad_request'), isError: true }} );
      };

      return $http({
        method: method,
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(success, failure);
    }
  };

  return QueryService;
}]);
