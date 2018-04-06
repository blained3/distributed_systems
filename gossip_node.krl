ruleset gossip_node {
	meta {
		use module io.picolabs.subscription alias Subscriptions
		use module temperature_store
		logging on
		shares __testing, rumors, peers, getPeer, makeSeen
		provides rumors, peers, getPeer, makeSeen
	}

	// ent:rumors = { picoId: { seqNum: RUMOR } }
	//
	// ent:peers = { metaPicoId: SEEN }
	//
	// RUMOR = { picoId:seqNum, SensorID, Temperature, Timestamp }
	//
	// SEEN = { otherPicoId : latestSeqNum }

	global {
		__testing = {
			"queries": [
				{ "name": "rumors" },
				{ "name": "peers" },
				{ "name": "getPeer" },
				{ "name": "makeSeen" }
			],
			"events": [
				{ "domain": "create", "type": "rumor", "attrs": [ "SensorID", "Temperature" ] },
				{ "domain": "gossip", "type": "heartbeat", "attrs": [ "interval" ] },
				{ "domain": "toggle", "type": "process" }
			]
		}
		rumors = function() {
			ent:rumors.defaultsTo({})
		}
		peers = function() {
			ent:peers.defaultsTo({})
		}

		getPeer = function() {
			possibleSubs = Subscriptions:established("Tx_role","node").filter(function(sub){
				picoId = engine:getPicoIDByECI(sub{"Tx"});
				ent:peers{picoId} == ent:peers{meta:picoId}
			});
			(possibleSubs.length() > 0) => possibleSubs[0]{"Tx"} | Subscriptions:established("Tx_role","node")[0]{"Tx"}
		}

		prepareMessage = function(oPicoId, type) {
			m = (type == "rumor") => makeRumor(ent:peers{oPicoId}.defaultsTo({})) | makeSeen();
			m
		}

		makeRumor = function(seen) {
			seen.klog("Seen Map: ");
			m = {};

			// Get any rumors never heard of before
			newRumors = ent:rumors.filter(function(v,r_picoId){
				(seen >< r_picoId) => false | true
			}).values().klog("newRumors: ");

			// Get any rumors that need updating
			next = seen.map(function(s_seqNum, s_picoId){
				num = s_seqNum.as("Number");
				(ent:rumors{[s_picoId]}.keys() >< (num + 1).as("String")).klog("Rumor has next:") => (num + 1) | num
			}).klog("Next Map: ").filter(function(n_seqNum, picoId){
				seen{picoId} != n_seqNum
			}).klog("unseen: ");

			m = (newRumors.length() > 0) => newRumors[0]{0} | (next.values().length() > 0) => ent:rumors{[next.keys()[0], next.values()[0]]}.klog("GET IT") | {};
			ent:rumors.klog("The Rumors: ");
			m.klog("The Message: ")
		}

		makeSeen = function() {
			m = ent:rumors.map(function(v,k) {
				nums = v.keys().sort("numeric");
				nums = nums.filter(function(n){
					nums.index(n) == n.as("Number")
				});
				nums[nums.length() - 1].as("Number");
			});
			m
		}

		send = defaction(eci, m, type) {
			eci = eci.klog("SEND eci:");
			type = type.klog("SEND type:");
			message = {
				"returnEci": meta:eci, // TODO: Im not sure about this
				"message": m
			}
			event:send({
				"eci": eci,
				"domain": "gossip",
				"type": type,
				"attrs": message
			});
		}
	}

	rule start_gossip {
		select when wrangler ruleset_added where rids >< meta:rid
		fired {
			ent:interval := 30;
			ent:shouldProcess := true;
			ent:rumors := ent:rumors.defaultsTo({});
			ent:peers := ent:peers.defaultsTo({});
			ent:sequenceNumber := 0;
			raise gossip event "heartbeat"
		}
	}

	rule gossip_heartbeat {
		select when gossip heartbeat
		pre {
			interval = event:attr("interval").defaultsTo(ent:interval).as("Number")
			type = (random:integer(1) == 0) => "rumor" | "seen"
			eci = getPeer()
			picoId = engine:getPicoIDByECI(eci).klog("ENGINE PICO ID")
			metaPicoId = meta:picoId.klog("META PICO ID")
			m = prepareMessage(picoId, type)
		}
		if ent:shouldProcess then
		every {
			send(eci, m, type);
		}
		fired {
			ent:interval := interval;
			schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:interval})
		}
	}
	
	rule gossip_rumor {
		select when gossip rumor
		pre {
			rumor = event:attr("message").klog("RECIEVED RUMOR: ")
			MessageIDArray = rumor{"MessageID"}.split(":")
			picoId = MessageIDArray[0].klog("rumor picoid: ")
			sequenceNumber = MessageIDArray[1].as("Number").klog("rumor seqNum")
		}
		fired {
			ent:rumors{[picoId, sequenceNumber]} := rumor if picoId != "null";
			ent:peers{[picoId, picoId]} := sequenceNumber if picoId != "null";
		}
	}

	rule gossip_seen {
		select when gossip seen
		pre {
			seen = event:attr("message").klog("RECIEVED SEEN: ")
			eci = event:attr("returnEci").klog("SEEN eci:")
			picoId = engine:getPicoIDByECI(eci)
			type = "rumor"
			m = makeRumor(seen)
		}
		send(eci, m, type);
	}

	rule create_rumor {
		select when create rumor
		pre {
			MessageID = meta:picoId + ":" + ent:sequenceNumber
			SensorID = event:attr("SensorID")
			Temperature = event:attr("Temperature")
			Timestamp = time:now()
		}
		fired {
			ent:rumors{[meta:picoId, ent:sequenceNumber]} := {
				"MessageID": MessageID,
				"SensorID": SensorID,
				"Temperature": Temperature,
				"Timestamp": Timestamp
			};
			ent:peers{[meta:picoId, meta:picoId]} := ent:sequenceNumber;
			ent:sequenceNumber := ent:sequenceNumber.as("Number") + 1;
		}
	}

	rule toggle_process {
		select when toggle process
		fired {
			ent:shouldProcess := not ent:shouldProcess;
		}
	}
}