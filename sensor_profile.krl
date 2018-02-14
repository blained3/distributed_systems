ruleset sensor_profile {
    meta {
        logging on
        shares getProfile, __testing
        provides getProfile
    }

    global {
        getProfile = function() {
            ent:profile.defaultsTo({"location": "My House", 
                                    "name": "Supers Sensor", 
                                    "temperature_threshold": 85, 
                                    "toPhoneNumber": "13072140680"});
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
        fired {
            ent:profile := ent:profile.defaultsTo({}).put("location", event.attr("location"));
        }
    }
}