ruleset gossip_node {
	meta {
		use module io.picolabs.subscription alias Subscriptions
		use module temperature_store
	}

	global {
		getPeer = function() {

		}

		getSubscriber = function(seen) {

		}

		prepareMessage = function(subscriber, type) {
			m = (type == "rumor") => makeRumor(subscriber) | makeSeen();
			m
		}

		makeRumor = function(subscriber) {
			// TODO
			m = {
				"MessageID": "ABCD-1234-ABCD-1234-ABCD-1234:5",
				"SensorID": "BCDA-9876-BCDA-9876-BCDA-9876",
				"Temperature": "78",
				"Timestamp": <ISO DATETIME>,
			};
			m
		}

		makeSeen = function() {
			m = ent:peers.map(function(v,k) {
				nums = v.keys().sort("numeric")
				nums = nums.filter(function(n){
					nums.index(n) == n
				});
				nums[nums.length() - 1];
			});
			m
		}

		send = defaction(subscriber, m, type) {
			event:send({
				"eci": subscriber,
				"domain": "gossip",
				"type": type,
				"attrs": m
			});
		}
	}

	rule start_gossip {
		select when wrangler ruleset_added where rids >< meta:rid
		fired {
			ent:interval := 30;
			ent:peers := ent:peers.defaultsTo({});
			ent:sequenceNumber := 0;
			raise gossip event "heartbeat"
		}
	}

	rule gossip_heartbeat {
		select when gossip heartbeat
		pre {
			interval = event:attr("interval").as("Number").defaultsTo(ent:interval).klog("Interval: ")
			type = (random:integer(1) == 0) => "rumor" | "seen"
			subscriber = getPeer()
			m = prepareMessage(subscriber, type)
		}
		every {
			send(subscriber, m, type);
			ent:interval := interval;
			schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:interval})
		}
	}
	
	rule gossip_rumor {
		select when gossip rumor
		pre {
			MessageIDArray = event:attr("MessageID").split(":")
			originId = MessageIDArray[0]
			sequenceNumber = MessageIDArray[1].as("Number")
		}
		fired {
			ent:peers{[originId, sequenceNumber]} := event:attrs();
		}
	}

	}

	rule gossip_seen {
		select when gossip seen
		pre {
			subscriber = getSubscriber(event:attrs())
			type = "rumor"
			m = prepareMessage(subscriber, type)
		}
		every {
			send(subscriber, m, type)
		}
	}
}