ruleset trip_tracker {
  	meta {
	    name "trip_tracker"
	    description <<
	A modified track_trips ruleset renamed.
	>>
	    author "Andrew King"
	    logging on
	    shares long_trip,__testing
  	}
	global {
	    __testing = {"queries":[{ "name": "__testing" }],
	    			 "events": [{"domain" : "car", "type" : "new_trip", "attrs": ["mileage"]}]}
	    long_trip = "100".as("Number")
	}
	rule process_trip{
		select when car new_trip
		pre{
			passed_mileage =  event:attr("mileage").klog("our passed in mileage: ")
			event_attributes = event:attrs()
			timestamp = {"timestamp" : time:now()}
			new_attributes = event_attributes.put(timestamp)
		}
		send_directive("trip") with
			trip_length = passed_mileage + " miles"
		fired{
			raise explicit event "trip_processed"
				attributes new_attributes
		}
	}
	rule find_long_trips{
		select when explicit trip_processed
		pre{
			passed_mileage = event:attr("mileage").klog("our passed in mileage: ")
			event_attributes = event:attrs()
			timestamp = {"timestamp" : time:now()}
			new_attributes = event_attributes.put(timestamp)
			is_long_trip = passed_mileage > long_trip
		}
		fired{
			raise explicit event "found_long_trip"
				attributes new_attributes
			if (is_long_trip)
		}
	}
	
	rule auto_accept {
    	select when wrangler inbound_pending_subscription_added
    	pre {
      		attributes = event:attrs().klog("subcription:")
    	}
    	always {
      		raise wrangler event "pending_subscription_approval"
        		attributes attributes
    	}
  	}
}
