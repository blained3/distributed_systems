angular.module('temps', [])
.controller('MainCtrl', [
  '$scope','$http',
  function($scope,$http){
    $scope.temperatures = [];
    var url = "http://ec2-18-219-184-183.us-east-2.compute.amazonaws.com:8080/sky";
    var eci = "NgBFjfKcGmNNrQxrN2b51";
    // var channel = "NBeJtRZhnGVp5b7zFuA4b4";

    // var bURL = '/sky/event/'+$scope.eci+'/eid/timing/started';

    $scope.checkTemp = function(degree) {
        return degree > 85;
    }

    $scope.getAll = function() {
      return $http.get(url + '/cloud/' + eci + '/temperature_store/temperatures').success(function(data){
        angular.copy(data, $scope.temperatures);
      });
    };

    $scope.getAll();
  }
]);