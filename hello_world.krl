ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Blaine Backman"
    logging on
    shares hello, __testing
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                           { "name": "__testing" } ],
              "events": [ { "domain": "echo", "type": "hello",
                            "attrs": [ "name" ] } ]
            }
  }
  
  rule hello_world {
    select when echo hello
    pre {
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("say", {"something":"Hello " + name})
  }

  rule hello_monkey {
    select when echo monkey
    pre {
      name = event:attr("name").defaultsTo("monkey").klog("our passed in name: ") // event:attr("name") => event:attr("name") | "monkey"
    }
    send_directive("say", {"something":"Hello " + name})
  }
  
}