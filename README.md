# UMLShuttle-Assistant

# Overview

Umass lowells shuttle tracking system is nice, but it's missing one thing to be truely useful to students, and that's ability to give an estimate of exactly how long it will take for the next shuttle to arrive at a certain stop. This project was created as a way to give students the ability to figure out exactly that through various platforms that api.ai intergrates with, which as of right now is just api.ai itself and facebook messenger. 


# shuttles.rkt 

This program starts off by immediatly initiating an parsing object that holds and delivers a hash-table(routes_hash)containing the different lines and an updater in a seperate thread.
 ```
 (define routes_hash
  (let
      ([routes (make-hash)]
       [active_lst '()])
```
 It does this automatically by checking in the dispatch if routes is empty and then returning the dispatch function  ```[(hash-empty? routes) (create_lines)  dispatch]``` 

The ```(create_lines)``` function uses for-each over a list that's generated from ```(active_lines)``` and it updates the routes hash that's defined above in the let definition.
It does this by parsing each individual route endpoint for the active shuttles which is a hash of the shuttle name to the shuttle struct using a foldl and function called ```create-buses``` which inititalizes all of the bus structs with the name, id, type, and location. and then passes it to ```active_shuttles_on``` which is set to the correct line in the hash table.

```
    (define (create_lines) ;; creates a list of lines with all active shuttles and last stop
      (for-each
       (λ (x)
         (let [(shuttlelst (active_shuttles_on (route_url (car x)))) (stoplst (get_stops (car (cddr x))))]
           (hash-set! routes
                      (cadr x)
                      (line
                       (cadr x) ;; name
                       (car x) ;; id     
                       shuttlelst ;; shuttles
                       stoplst
                       ) )))
       (active_lines)))

 (define (active_shuttles_on line_in)
      (define shuttles (make-hash))
      (define json_read (json_in line_in))
      (for-each  (λ (x)
                   (hash-set! shuttles
                              (bus-id x) x))   
                 (foldl create-buses '() json_read))
      shuttles)

  (define (create-buses shuttle shuttle-list) 
      (cons (let [(location (hash-ref shuttle 'Location))
                  (numb (hash-ref shuttle 'Number))]
              (bus 
               numb
               (string-ref numb 0) ; type
               (list
                (hash-ref location 'Latitude)
                (hash-ref location 'Longitude)) ;gps 
               "nope")) ;;nope is for last stop
            shuttle-list ))

```

Updating the hash table is taken care of in a seperate thread that recursively calls itself every 10 seconds. It does this by getting a new list of active shuttles, and then a list of if they are at a stop or not and passes it to the ```update-busses``` function which then compares the old shuttle hash and new shuttle hash keys to see which ones have changed and add/remove them accordingly. 

It then updates the each shuttles location and if it has been at a new stop or not.

```      
    (define (last_shuttle_stop shuttlelst stops) ;; hash of shuttle names to last stop
      (define shuttle_stops (make-hash))
      (hash-for-each shuttlelst (λ (x y)
                                  (hash-set! shuttle_stops
                                             (bus-id y) (check_stop (bus-location y) stops)))
                     )
      shuttle_stops)


   (define (update-buses old-shuttles new-shuttles last_stops) ;; if the shuttle is no longer in the new shuttle list make sure to remove it
    (let* [(shuttle_list_keys (hash-keys new-shuttles))
          (shuttle_list_keys_old (hash-keys old-shuttles))
          (shuttles_to_remove (remove* shuttle_list_keys_old shuttle_list_keys))
          (shuttles_to_add    (remove* shuttle_list_keys shuttle_list_keys_old))] 
          (for-each (lambda (x) (hash-remove old-shuttles x))  shuttles_to_remove) ;; remove shuttles that are no longer in the list
          (for-each (lambda (x) (hash-set! old-shuttles (hash-ref last_stops x))) shuttles_to_add) ;;add shuttles to the list
      )
      (hash-for-each old-shuttles
                     (λ (x y)
                       (let [(nsh (hash-ref new-shuttles (bus-id y)))]
                         (set-bus-location! y (bus-location nsh))
                         (cond
                           [(not (equal? "nope" (hash-ref last_stops (bus-id y)))) 
                            (set-bus-last_stop! y (hash-ref last_stops (bus-id y)))]
                           )              
                         ))
                     old-shuttles)
      )

    ;;functions for figuring out shuttle stops
  
    (define update_lines ;; updates routes with the new info in a seperate thread every minute
      (thread (λ () (define (loop)
                      
                      (hash-for-each routes
                                     (λ (z y);; z = line name ; y = line strut
                                       ;; use line ID to get the active shuttles
                                       (let* [(shuttle_update (active_shuttles_on (route_url (line-id y))))
                                              (at_stop (last_shuttle_stop shuttle_update (line-stops y)))]
                                         
                                         (update-buses (line-shuttles y) shuttle_update at_stop))))
                                        
                      (sleep 10) (loop))
                (loop)))) 
```

# webserv.rkt 

The webserver is ultiamtely just a webshook for api.ai to post querys to and post responses back in a formated json object. 

Api.ai sends a request to the server and it's recieved using this function 
```(post "/"  (λ (req) (create_response (requestJSON req))))``` which turns the json object into a string that resembles
 ```(define test_query "{\r\n  \"id\": \"036a07cf-fe90-4286-a8f0-0ca784e66d9e\",\r\n  \"timestamp\": \"2017-03-30T01:57:53.935Z\",\r\n  \"lang\": \"en\",\r\n  \"result\": {\r\n    \"source\": \"agent\",\r\n    \"resolvedQuery\": \"How far away is the blue line from south?\",\r\n    \"action\": \"blue_line\",\r\n    \"actionIncomplete\": false,\r\n    \"parameters\": {\r\n      \"destination\": {\r\n        \"line\": \"blue_line\",\r\n        \"bus_stops\": \"South\"\r\n      },\r\n      \"time_until\": \"how far away is\"\r\n    },\r\n    \"contexts\": [],\r\n    \"metadata\": {\r\n      \"intentId\": \"4c2adb65-e68f-4915-92be-549a5693fc43\",\r\n      \"webhookUsed\": \"false\",\r\n      \"webhookForSlotFillingUsed\": \"false\",\r\n      \"intentName\": \"Blue Line\"\r\n    },\r\n    \"fulfillment\": {\r\n      \"speech\": \"You are from north.\",\r\n      \"messages\": [\r\n        {\r\n          \"type\": 0,\r\n          \"speech\": \"You are from north.\"\r\n        }\r\n      ]\r\n    },\r\n    \"score\": 1\r\n  },\r\n  \"status\": {\r\n    \"code\": 200,\r\n    \"errorType\": \"success\"\r\n  },\r\n  \"sessionId\": \"ef2685f9-3a53-46d0-9952-c74a5f1c34ce\"\r\n}")```

which is then parsed by 

```
(define (parse_query query_request)
  (let ([query_json (hash-ref (string->jsexpr query_request)
                               'result)])
    (hash-ref query_json 'parameters)))
(define (parameters query) (cadr query))
(define (requested_line query) (hash-ref (hash-ref query 'destination) 'line))
(define (requested_stop query) (hash-ref (hash-ref query 'destination) 'bus_stops))
```
and depending on what's being asked exicutes a line request 
```
(define (create_response request_string)
   (define query_input (parse_query request_string))
   (cond [(equal? (requested_line query_input) "blue_line")  (car ((Blue_line) (requested_stop query_input)))]
         [(equal? (requested_line query_input) "red_line")  (car ((red_line) (requested_stop query_input)))]
         [(equal? (requested_line query_input) "yellow_north")  (yellow_north (requested_stop query_input))]
         [(equal? (requested_line query_input) "yellow_south")  (yellow_south (requested_stop query_input))]
         [(equal? (requested_line query_input) "purple") (purple (requested_stop query_input))]
         ))
```

The code for getting the time for a shuttle to north campus from south is fairly simple in compairson to other lines.


```
(define (Blue_line) ;; 
  (define blue_line (hash-ref (routes_hash 'get_routes)  "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
  
  ;; check the shuttles vs stops to make sure there isn't one currently at a stop
  ;; after checking to make sure there isn't one currently there it will then
  ;; go about filtering the last stop list for any shuttle that is on it's way to the requested stop
  
  (define (North)    (if (not (equal? '() (stop_check '(42.6559767410684 -71.32473349571217)  blue_shuttles)))
                        (list currently_at_stop )
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user --< Not done yet;
                            [(equal? (bus-last_stop y) "South - Broadway St")
                          ;check to see if the shuttle's gps is to the east of the waypoint, if not then use waypoint
                              (if (<  (latitude (bus-location y)) -71.327028)
                               (Build_response (bus-id y)  (duration(distance-waypoint (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217" "42.638522,-71.327028")))
                                 (Build_response (bus-id y) (duration (distance (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217"))))
                                 ] ;report back shuttle time
                             [(equal? (bus-last_stop y) "South - Wilder")
                              (Build_response (bus-id y) (duration (distance-waypoint "42.640755,-71.337500" "42.6559767410684,-71.32473349571217" "42.638522,-71.327028"))) ] ;; use time taken from riverview -> North and report that back
                             [else null]))
                        ))))
```

