ruleset use_twilio_v2 {
  meta {
    use module twilio_keys
    configure using account_sid = keys:twilio("account_sid")
                    auth_token = keys:twilio("auth_token")
    provides send_sms
    shares __testing, send_sms
  }
 
  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
            })
    }
    __testing = {
      "queries": [ { "name": "send_sms", "args": [ "to", "from", "message" ] },
                           { "name": "send_sms" } ],
      "events": [ { "domain": "test", "type": "messages",
                            "attrs": [ "NumSegments" ] } ]
    }
  }
 
  rule test_send_sms {
    select when test new_message
    send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }

  rule test_get_messages {
    select when test messages
    send_directive(http:get(<<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>, form = {
                "NumSegments":event:attr("NumSegments")
            }){"content"})
  }
}