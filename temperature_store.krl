ruleset temperature_store {
    meta {
        logging on
        shares __testing, temperatures, threshold_violations, inrange_temperatures
        provides temperatures, threshold_violations, inrange_temperatures
    }

    global {
        temperatures = function() {
            ent:temps.defaultsTo([])
        }
        threshold_violations = function() {
            ent:violations.defaultsTo([])
        }
        inrange_temperatures = function() {
            ent:temps.filter(function(temp){
                ent:violations.all(function(viol){
                    temp != viol
                })
            })
        }
        __testing = {
            "queries": [
                { "name": "temperatures" },
                { "name": "threshold_violations" },
                { "name": "inrange_temperatures" }
            ],
            "events": [
                { "domain": "sensor", "type": "reading_reset" }
            ]
        }
    }
    
    rule collect_temperatures {
        select when wovyn new_temperature_reading
        send_directive("say", {"something": "You got temperature!"})
        always {
            ent:temps := ent:temps.defaultsTo([]).append(event:attrs())
        }
    }
    
    rule collect_threshold_violations {
        select when wovyn threshold_violation
        send_directive("say", {"something": "You got violation!"})
        always {
            ent:violations := ent:violations.defaultsTo([]).append(event:attrs())
        }
    }
    
    rule clear_temperatures {
        select when sensor reading_reset
        send_directive("say", {"something": "You cleared it!"})
        always {
            ent:temps := [];
            ent:violations := []
        }
    }
}