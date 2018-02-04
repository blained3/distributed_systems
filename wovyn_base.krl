ruleset wovyn_base {
  meta {
  	logging on
    shares __testing
  }
  global {
  	temperature_threshold = 85
  	toPhoneNumber = "13072140680"
  	fromPhoneNumber = "13073164633"
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "temp", "baro" ] } ] }
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat where genericThing != null
    pre {
      attrs = event:attrs().klog("attrs")
    }
    fired {
		raise wovyn event "new_temperature_reading"
		attributes {
	    	"temperature": attrs.genericThing.data.temperature[0].temperatureF,
	    	"timestamp": time:now()
	    }
    }
  }

  rule find_high_temps {
  	select when wovyn new_temperature_reading
  	pre {
  		isHigher = event:attr("temperature") > temperature_threshold
  		nothing = isHigher.klog("Is it higher? ")
  		temp = event:attr("temperature").klog("Current Temp: ")
  	}
  	if isHigher then
  		send_directive("say", {"something": "The temperature is higher!"})
	fired {
		raise wovyn event "threshold_violation"
		attributes event:attrs()
	}
  }

  rule threshold_notification {
  	select when wovyn threshold_violation
  	pre {
  		nothing = event:attrs().klog("Sent a message: ")
  	}
  	fired {
	  	raise test event "new_message"
	  	attributes {
	  		"to": toPhoneNumber,
	  		"from": fromPhoneNumber,
	  		"message": "The temperature was " + event:attr("temperature") + " at " + event:attr("timestamp") + "!!"
	  	}
  	}
  }
}