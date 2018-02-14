ruleset sensor_profile {
    meta {
        logging on
        shares getProfile, __testing
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
        }
        fired {
            ent:profile{"location"} := location.defaultsTo(ent:profile{"location"})
        }
    }
}