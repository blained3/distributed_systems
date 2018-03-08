ruleset use_twilio_v2 {
	meta {
		use module manager_profile
		use module twilio_keys
		use module twilio_v2 alias twilio
				with account_sid = keys:twilio("account_sid")
						 auth_token =  keys:twilio("auth_token")
		provides send_sms
		shares __testing, messages
	}

	global {
		messages = function(PageSize, Page, To, From) {
			twilio:messages(PageSize, Page, To, From)
		}
		__testing = {
			"queries": [ {
				"name": "messages",
				"args": [ "PageSize", "Page", "To", "From" ]
			}],
			"events": [ {
				"domain": "test",
				"type": "new_message",
				"attrs": [ "to", "from", "message" ] } ]
		}
	}

	rule test_send_sms {
		select when test new_message
		pre {
			toPhoneNumber = manager_profile:getProfile(){"toPhoneNumber"}.defaultsTo(event:attr("to"))
		}
		twilio:send_sms(toPhoneNumber,
										event:attr("from"),
										event:attr("message"))
	}
}
