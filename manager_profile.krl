ruleset manager_profile {
    meta {
        logging on
        shares getProfile, __testing
        provides getProfile
    }

    global {
        getProfile = function() {
            ent:profile.defaultsTo({"toPhoneNumber": "13072140680"});
        }
        __testing = {
            "queries": [
                { "name": "getProfile" }
            ],
            "events": [
                { "domain": "manager", "type": "profile_updated", "attrs": [ "toPhoneNumber" ] }
            ]
        }
    }

    rule profile_updated {
        select when manager profile_updated
        pre {
            toPhoneNumber = event:attr("toPhoneNumber").defaultsTo(getProfile(){"toPhoneNumber"})
        }
        fired {
            ent:profile := {"toPhoneNumber": toPhoneNumber}
        }
    }
}
