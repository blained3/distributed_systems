angular.module('temps', [])
.controller('MainCtrl', [
  '$scope','$http',
  function($scope,$http){
    $scope.temperatures = [];
    $scope.profile = {
        location: "Here",
        name: "The Name",
        toPhoneNumber: "8675309",
        temperature_threshold: 85
    };
    var url = "http://ec2-18-219-184-183.us-east-2.compute.amazonaws.com:8080/sky";
    var eci = "NgBFjfKcGmNNrQxrN2b51";
    // var channel = "NBeJtRZhnGVp5b7zFuA4b4";

    // var bURL = '/sky/event/'+$scope.eci+'/eid/timing/started';

    $scope.updateProfile = function(){
        $http.post(url + '/event/' + eci + '/NBeJtRZhnGVp5b7zFuA4b4/sensor/profile_updated?name=' + $scope.profile.name
                    + '&location=' + $scope.profile.location + '&temperature_threshold=' + $scope.profile.temperature_threshold + '&toPhoneNumber=' + $scope.profile.toPhoneNumber).success(function(data){
            alert('Successfully update the profile');
        });
    };

    $scope.checkTemp = function(degree) {
        return degree > $scope.profile.temperature_threshold;
    };

    $scope.getAll = function() {
        $http.get(url + '/cloud/' + eci + '/sensor_profile/getProfile').success(function(data){
            $scope.profile = data;
        });
      return $http.get(url + '/cloud/' + eci + '/temperature_store/temperatures').success(function(data){
        angular.copy(data, $scope.temperatures);
      });
    };

    $scope.getAll();
  }
]);