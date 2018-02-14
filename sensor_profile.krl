ruleset sensor_profile {
    meta {
        logging on
        shares getProfile
        provides getProfile
    }

    global {
        getProfile = function() {
            ent:profile.defaultsTo({"location": "My House", 
                                    "name": "Super Sensor", 
                                    "temperature_threshold": 85, 
                                    "toPhoneNumber": "13072140680"})
        }
        __testing = {
            "queries": [
                { "name": "getProfile" }
            ],
            "events": [
                { "domain": "sensor", "type": "profile_updated", "attrs": [ "location", "name", "temperature_threshold", "toPhoneNumber" ] }
            ]
        }
    }
    
    rule profile_updated {
        select when sensor profile_updated
        pre {
            location = event.attr("location")
            name = event.attr("name")
            temperature_threshold = event.attr("temperature_threshold")
            toPhoneNumber = event.attr("toPhoneNumber")
        }
        fired {
            ent:profile := ent:profile.defaultsTo({"location": "My House", 
                                                    "name": "Super Sensor", 
                                                    "temperature_threshold": 85, 
                                                    "toPhoneNumber": "13072140680"})
            ent:profile{"location"} := location if (location != null)
            ent:profile{"name"} := name if (name != null)
            ent:profile{"temperature_threshold"} := temperature_threshold if (temperature_threshold != null)
            ent:profile{"toPhoneNumber"} := toPhoneNumber if (toPhoneNumber != null)
        }
    }
}