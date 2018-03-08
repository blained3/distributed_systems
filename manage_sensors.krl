ruleset manage_sensors {
	meta {
		use module io.picolabs.subscription alias Subscriptions
		use module manager_profile
		shares __testing, sensors, allTemperatures
	}
	global {
		__testing = {
			"queries": [ { "name": "__testing" },
					{ "name": "sensors" },
					{ "name": "allTemperatures" } ],
			"events": [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] },
					{ "domain": "sensor", "type": "unneeded_sensor", "attrs": [ "sensor_id" ] },
					{ "domain": "sensor", "type": "add_sensor", "attrs": [ "name", "otherHost", "eci" ] } ]
		}

		temperature_threshold = 78

		sensors = function() {
			ent:sensors.defaultsTo({});
		}

		allTemperatures = function() {
			Subscriptions:established("Rx_role","sensor").map(function(sub){
				obj = http:get(sub{"Tx_host"}.defaultsTo("http://localhost:8080") + "/sky/cloud/" + sub{"Tx"} + "/temperature_store/temperatures"){"content"};
				obj
			});
		}

		nameFromID = function(sensor_id) {
			"Sensor " + sensor_id + " Pico"
		}
	}

	rule create_sensor {
		select when sensor new_sensor
		pre {
			sensor_id = event:attr("sensor_id")
			exists = ent:sensors >< sensor_id
		}
		fired {
			raise wrangler event "child_creation"
				attributes { "name": nameFromID(sensor_id),
							"color": "#ffff00",
							"sensor_id": sensor_id } if not exists
		}
	}

	rule store_new_sensor {
		select when wrangler child_initialized
		pre {
			eci = event:attr("eci")
			sensor_id = event:attr("rs_attrs"){"sensor_id"}
		}
		if sensor_id.klog("found sensor_id")
		then
			event:send(
			{ "eci": eci,
				"eid": "install-ruleset",
				"domain": "wrangler",
				"type": "install_rulesets_requested",
				"attrs": { "rids": ["io.picolabs.subscription", "temperature_store", "sensor_profile", "wovyn_base"] } } )
		fired {
			ent:sensors := ent:sensors.defaultsTo({});
			ent:sensors{[nameFromID(sensor_id)]} := eci;
			raise sensor event "update_sensor" attributes {"sensor_id": sensor_id,"eci": eci} on final
		}
	}

	rule update_sensor {
		select when sensor update_sensor
		pre {
			eci = event:attr("eci")
			sensor_id = event:attr("sensor_id")
		}
		every {
			event:send({ "eci": eci,
						"domain": "sensor",
						"type": "profile_updated",
						"attrs": { "name": nameFromID(sensor_id),
									"temperature_threshold": temperature_threshold,
									"location": "My House",
									"toPhoneNumber": manager_profile:getProfile(){"toPhoneNumber"} } } );

			event:send({ "eci": eci,
						"domain": "wrangler",
						"type": "subscription",
						"attrs": { "name": nameFromID(sensor_id),
								   "Rx_role": "sensor",
								   "Tx_role": "manager",
								   "channel_type": "subscription",
								   "wellKnown_Tx": meta:eci } } )
		}
	}

	rule add_sensor {
		select when sensor add_sensor
		pre {
			name = event:attr("name")
			otherHost = event:attr("otherHost")
			eci = event:attr("eci")
		}
		event:send({ "eci": eci,
					"domain": "wrangler",
					"type": "subscription",
					"attrs": { "name": name,
							"Tx_host": meta:host,
							"Rx_role": "sensor",
							"Tx_role": "manager",
							"channel_type": "subscription",
							"wellKnown_Tx": meta:eci } }, host = otherHost )
	}

	rule remove_sensor {
		select when sensor unneeded_sensor
		pre {
			sensor_id = event:attr("sensor_id")
			name = nameFromID(sensor_id)
			pico_id = engine:getPicoIDByECI(ent:sensors{[name]})
		}
		engine:removePico(pico_id)
		always {
			clear ent:sensors{[name]}
		}
	}

	rule auto_accept {
		select when wrangler inbound_pending_subscription_added
		fired {
			raise wrangler event "pending_subscription_approval"
			attributes event:attrs
		}
	}

}
