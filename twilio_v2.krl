ruleset twilio_v2 {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides
        send_sms, messages
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
    messages = function(PageSize, Page, To, From) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>;
       ToStr = (To == null) => "" | "&To=" + To;
       FromStr = (From == null) => "" | "&From=" + From;
       response = http:get(base_url + "?PageSize=" + PageSize.defaultsTo(50) + "&Page=" + Page.defaultsTo(0) + ToStr + FromStr);
      response
    }
  }
}