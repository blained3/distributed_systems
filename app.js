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
	var high_temps = [];
	var url = "http://ec2-18-219-184-183.us-east-2.compute.amazonaws.com:8080/sky";
	var eci = "MQJizVGZCNXm9tGvwc2umF";
	var channel = "G9Rv9jSvMC59J8JfbyQF2v";

	$scope.updateProfile = function(){
		$http.post(url + '/event/' + eci + '/' + channel + '/sensor/profile_updated?name=' + $scope.profile.name
					+ '&location=' + $scope.profile.location + '&temperature_threshold=' + $scope.profile.temperature_threshold + '&toPhoneNumber=' + $scope.profile.toPhoneNumber).success(function(data){
			alert('Successfully update the profile');
		});
	};

	$scope.checkTemp = function(temp) {
		return high_temps.some(function(val){
			return val.timestamp === temp.timestamp;
		});
	};

	$scope.getAll = function() {
		$http.get(url + '/cloud/' + eci + '/temperature_store/threshold_violations').success(function(data){
			angular.copy(data, high_temps);
		  });
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
