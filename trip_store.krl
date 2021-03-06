ruleset trip_store {
  	meta {
	    name "trip_store"
	    description <<
	A second Basic ruleset for part 1 of the pico Lab
	>>
	    author "Andrew King"
	    logging on
	    use module io.picolabs.pico alias wrangler
	    shares __testing, long_trip, trips, long_trips, short_trips
	    provides trips, short_trips, long_trips
  	}
  	global {
	    __testing = {"queries":[{ "name": "__testing" }],
	    			 "events": [{"domain" : "car", "type" : "trip_reset"}, 
	    			 {"domain" : "clear", "type" : "seq"}]}

	    clear_trip = { "0": { "mileage": "0".as("Number"), "timestamp" : timestamp } }

	    clear_long_trip = { "0": { "mileage": "0".as("Number"), "timestamp" : timestamp } }

	    clear_id = { "_0": { "trip_id": "0".as("Number"), "long_trip_id" : "0".as("Number") } }

	    long_trip = "100".as("Number")

	    clear_seq = {"_0": {"seq" : "0".as("Number")}}

	    trips = function(){
      		ent:trips.defaultsTo({},"ent:trips was empty")
		}

		long_trips = function(){
    		ent:long_trips
		}

		short_trips = function(){
			trips = ent:trips.defaultsTo(clear_trip,"ent:trips was empty");
			short_trips = trips.filter(function(v){
 				v{["mileage"]} < long_trip
 			});
			short_trips
		}
	}

	rule report_requested{
		select when report request
		pre{
			child_eci = wrangler:myself().eci
			parent_eci = wrangler:parent().eci
			myTrips = trips()
			seq = event:attr("report_num")
			cor_id = wrangler:myself().eci + "_" + seq.defaultsTo("0".as("Number"), "defaulting to 0")
		}
		if cor_id.klog("request sent from this cor_id: ")
			then
				event:send(
   					{ "eci": parent_eci, "eid": "returning report",
     				"domain": "child", "type": "reporting",
     				"attrs": { "cor_id": cor_id, "trips" : myTrips} } )                          
	}

	rule collect_trips{
		select when explicit trip_processed
		pre{
			passed_mileage = event:attr("mileage").klog("our passed in mileage to be stored: ")
			attributes = event:attrs().klog("our attributes")
			passed_timestamp = event:attr("timestamp").klog("our passed in timestamp")
		}
		always{
      		ent:trips := ent:trips.defaultsTo(clear_trip,"initialization was needed");
      		ent:trip_id := ent:trip_id.defaultsTo(clear_id,"initializing trip_ids");
      		ent:trips{[ent:trip_id{["_0","trip_id"]},"mileage"]} := passed_mileage;
      		ent:trips{[ent:trip_id{["_0","trip_id"]},"timestamp"]} := passed_timestamp;
      		ent:trip_id{["_0","trip_id"]} := ent:trip_id{["_0","trip_id"]} + 1
		}
	}

	rule collect_long_trips{
		select when explicit found_long_trip
		pre{
			passed_mileage = event:attr("mileage").klog("our passed in long mileage to be stored: ")
			passed_timestamp = event:attr("timestamp").klog("our passed in timestamp")
		}
		always{
			ent:long_trips := ent:long_trips.defaultsTo(clear_long_trip, "initilization was needed");
			ent:trip_id := ent:trip_id.defaultsTo(clear_id, "initializing trip_ids");
			ent:long_trips{[ent:trip_id{["_0","long_trip_id"]},"mileage"]} := passed_mileage;
			ent:long_trips{[ent:trip_id{["_0","long_trip_id"]},"timestamp"]} := passed_timestamp;
			ent:trip_id{["_0","long_trip_id"]} := ent:trip_id{["_0","long_trip_id"]} + 1
		}
	}
	rule clear_trips{
		select when car trip_reset
		pre{
			s_trips = short_trips()
		}
		always {
			ent:trips.klog("trips before we cleared them: ");
			ent:long_trips.klog("long_trips before we cleared them: ");
			s_trips.klog("short trips before everything was cleared: ");
			ent:trips := clear_trip;
			ent:long_trips := clear_long_trips;
			ent:trip_id := clear_id
		}
	}
	rule clear_seq{
		select when clear seq
		always{
			ent:seq := clear_seq
		}
	}
 }