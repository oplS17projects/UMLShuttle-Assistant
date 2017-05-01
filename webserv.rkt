#lang racket

(require net/url  
         web-server/http/request-structs
         web-server/http/bindings
         web-server/servlet
         web-server/templates
         json
         openssl
         "shuttles.rkt"
         "api.ai.rkt"
         "spin.rkt")

(provide requestJSON (struct-out bus) create_response test_query routes_hash blue-test Blue_line duration distance-waypoint gps->string) 

(define (requestJSON req) (bytes->string/utf-8 (request-post-data/raw req)))

(define (check_content req) (extract-binding/single 'content-type (request-headers req)))

(define (post_response req) (if (equal? (check_content req) "application/json")
                                (jsexpr->string (requestJSON req))
                                "lol not json"
                                ))

(define test_query "{\r\n  \"id\": \"036a07cf-fe90-4286-a8f0-0ca784e66d9e\",\r\n  \"timestamp\": \"2017-03-30T01:57:53.935Z\",\r\n  \"lang\": \"en\",\r\n  \"result\": {\r\n    \"source\": \"agent\",\r\n    \"resolvedQuery\": \"How far away is the blue line from south?\",\r\n    \"action\": \"blue_line\",\r\n    \"actionIncomplete\": false,\r\n    \"parameters\": {\r\n      \"destination\": {\r\n        \"line\": \"blue_line\",\r\n        \"bus_stops\": \"South\"\r\n      },\r\n      \"time_until\": \"how far away is\"\r\n    },\r\n    \"contexts\": [],\r\n    \"metadata\": {\r\n      \"intentId\": \"4c2adb65-e68f-4915-92be-549a5693fc43\",\r\n      \"webhookUsed\": \"false\",\r\n      \"webhookForSlotFillingUsed\": \"false\",\r\n      \"intentName\": \"Blue Line\"\r\n    },\r\n    \"fulfillment\": {\r\n      \"speech\": \"You are from north.\",\r\n      \"messages\": [\r\n        {\r\n          \"type\": 0,\r\n          \"speech\": \"You are from north.\"\r\n        }\r\n      ]\r\n    },\r\n    \"score\": 1\r\n  },\r\n  \"status\": {\r\n    \"code\": 200,\r\n    \"errorType\": \"success\"\r\n  },\r\n  \"sessionId\": \"ef2685f9-3a53-46d0-9952-c74a5f1c34ce\"\r\n}")

(define (create_response request_string)
   (define query_input (parse_query request_string))
   (cond [(equal? (requested_line query_input) "blue_line")  (car ((Blue_line) (requested_stop query_input)))]
         [(equal? (requested_line query_input) "red_line")  (car ((red_line) (requested_stop query_input)))]
         [(equal? (requested_line query_input) "yellow_north")  (yellow_north (requested_stop query_input))]
         [(equal? (requested_line query_input) "yellow_south")  (yellow_south (requested_stop query_input))]
         [(equal? (requested_line query_input) "purple") (purple (requested_stop query_input))]
         ))


(define drum_hill    0)
(define yellow_north 0)
(define yellow_south 0)
(define purple       0)

(define (red_line)    

;;make sure to check for shuttle type when determining travel time; anything with type M can go over the pawtucket st bridge
  (define red_line (hash-ref (routes_hash 'get_routes) "Red "))
  (define red_shuttles (line-shuttles red_line))
  (define red_stops (line-stops red_line))
  
  (define (East)    (if (not (equal? '() (stop_check '(42.65246507383046 -71.32075744907377)  red_shuttles)))
                        (list currently_at_stop )
                        (filter-not null? (hash-map red_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                            [(equal? (bus-last_stop y) "South - Broadway St")
                          ;check to see if the shuttle's gps is to the east of the waypoint, if not then use waypoint
                              (if (<  (latitude (bus-location y)) -71.327028)
                               (Build_response (bus-id y)  (duration(distance-waypoint (gps->string (bus-location y)) "42.65246507383046,-71.32075744907377" "42.638522,-71.327028")))
                                 (Build_response (bus-id y) (duration (distance (gps->string (bus-location y)) "42.65246507383046,-71.32075744907377"))))
                                 ] ;report back shuttle time
                             [(equal? (bus-last_stop y) "University Crossing") ;; Need to figure out way to differentiate between East bound/south bound shuttles for this part; Probably reintroduce bearing and check what angle it's facing it won't be perfect but it'll be something.
                              (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y)) "42.65246507383046,-71.32075744907377" "42.638522,-71.327028"))) ] ;; use time taken from riverview -> North and report that back
                             [else null]))
                        )))
  
  )
  (define (South)     
      (if (not (equal? '() (stop_check '(42.643473 -71.333985)  red_shuttles)))
                        (list currently_at_stop )
                        (filter-not null? (hash-map red_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                          (cond  ;; then pick the shortest distance and use that to report back to the user
                           [(equal? (bus-last_stop y) "University Crossing")
                             (if (>  (latitude (bus-location y)) -71.327028)
                              (Build_response (bus-id y)   (distance-waypoint (gps->string (bus-location y))  "42.643473,-71.333985" "42.638522,-71.327028")) ;; Middlesex waypoint
                              (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y))  "42.643473,-71.333985" "42.645632,-71.333838"))))] ;pawtucket waypoint
                            [(equal? (bus-last_stop y) "Fox Hall")
                             (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y)) "42.643473 -71.333985" "42.649418,-71.323339|via:42.638522,-71.327028"))) ] ;; use time taken from riverview -> North and report that back
                            [else null])))))) 
  (define (Riverview)  (if (not (equal? '() (stop_check '(42.64064028574872 -71.33751713182983) red_shuttles)))
                        (list currently_at_stop)
                        (filter-not null? (hash-map red_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                          [(equal? (bus-last_stop y) "University Crossing")
                             (if (>  (latitude (bus-location y)) -71.327028)
                                (Build_response (bus-id y) (duration  (distance-waypoint (gps->string (bus-location y))  "42.64064028574872,-71.33751713182983" "42.638522,-71.327028"))) ;; Middlesex waypoint
                               (Build_response (bus-id y) (duration    (distance-waypoint (gps->string (bus-location y))  "42.64064028574872,-71.33751713182983"  "42.645632,-71.333838"))))] ;pawtucket waypoint
                           [(equal? (bus-last_stop y) "Fox Hall") (Build_response (bus-id y) (duration ((gps->string (bus-location y)) "42.64064028574872,-71.33751713182983" "42.649418,-71.323339|via:42.638522,-71.327028"))) ] ;report back shuttle time
                           [(equal? (bus-last_stop y) "South - Wilder") '( riverview_almost_there ) ]
                            [else null])))))              
  )

 (define (dispatch e)
  (cond
    [(equal? e "East") (East)]
    [(equal? e "South")  (South)]
    [(equal? e "Riverview") (Riverview)]
    [else "lol what"]))
dispatch )


(define blue-test
  (hash
   "Blue "
   (line
    "Blue "
    1
    (hash
      "T105"
           (bus "T105" #\T '(42.6500153 -71.3246993) "University Crossing")
       "T101"
          (bus "T101" #\T '(42.6434546 -71.333917) "South - Broadway St"))  
      '(("South - Wilder" (42.643473 -71.333985))
        ("South-Broadway St "
        (42.64064028574872 -71.33751713182983))
        ("South-Broadway St "
        (42.64064028574872 -71.33751713182983))
        ("North Campus"
        (42.6559767410684 -71.32473349571217))
        ("University Crossing"
        (42.64936974740417 -71.32332180489351))
      )
    )
   )
  )


(define (Build_response bus trav_time)
(string-append 
  "{ \"speech\": \"The shuttle " bus " is at least " trav_time " away\" , \"displayText\": \"The shuttle " bus " is at least " trav_time " away\", \"data\": {}, \"contextOut\": [], \"source\": \"Google Maps\" }" )
  )

 (define currently_at_stop 
  "{ \"speech\": \"The shuttle is currently already there\" , \"displayText\": \"The shuttle is currently already there\", \"data\": {}, \"contextOut\": [], \"source\": \"Google Maps\" }" )

(define riverview_almost_there
 "{ \"speech\": \"The shuttle is currently at South, it should be at riverview soon.\" , \"displayText\": \"The shuttle is currently at South, it should be at riverview soon.\", \"data\": {}, \"contextOut\": [], \"source\": \"Google Maps\" }" 
)
 
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
                         (cond  ;; then pick the shortest distance and use that to report back to the user
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
                       
;; shuttle-search gets a list of all shuttles that have left the stop selected
;; use map to get the distance for each one and then select the shortest distance to report back to to the user
  
(define (South)     (if (not (equal? '() (stop_check '(42.643473 -71.333985)  blue_shuttles)))
                        (list currently_at_stop )
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                          (cond  ;; then pick the shortest distance and use that to report back to the user
                           [(equal? (bus-last_stop y) "University Crossing")
                             (if (>  (latitude (bus-location y)) -71.327028)
                                (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y))  "42.6559767410684,-71.32473349571217" "42.638522,-71.327028"))) ;; Middlesex waypoint
                                  (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y))  "42.6559767410684,-71.32473349571217" "42.645632,-71.333838"))))] ;pawtucket waypoint
                            [(equal? (bus-last_stop y) "North Campus")  (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y)) "42.643473,-71.333985" "42.649418,-71.323339|via:42.638522,-71.327028")) )] ;; use time taken from riverview -> North and report that back
                            [else null])))))) 

(define (Riverview) (if (not (equal? '() (stop_check '(42.64064028574872 -71.33751713182983) blue_shuttles)))
                        (list currently_at_stop)
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                          [(equal? (bus-last_stop y) "University Crossing")
                             (if (>  (latitude (bus-location y)) -71.327028)
                                (Build_response (bus-id y) (duration  (distance-waypoint (gps->string (bus-location y))  "42.6559767410684,-71.32473349571217" "42.638522,-71.327028"))) ;; Middlesex waypoint
                               (Build_response (bus-id y) (duration (distance-waypoint (gps->string (bus-location y))  "42.6559767410684,-71.32473349571217" "42.645632,-71.333838"))))] ;pawtucket waypoint
                           [(equal? (bus-last_stop y) "North Campus") (Build_response (bus-id y)  (duration (distance-waypoint ((gps->string (bus-location y)) "42.643473,-71.333985" "42.649418,-71.323339|via:42.638522,-71.327028")))) ] ;report back shuttle time
                           [(equal? (bus-last_stop y) "South - Wilder") '( riverview_almost_there ) ]
                            [else null])))))                                                
)
    
(define (dispatch e)
  (cond
    [(equal? e "North") (North)]
    [(equal? e "South")  (South)]
    
    [(equal? e "Riverview") (Riverview)]
    [else "lol what"]))
dispatch 
  
)

(define (stop_check stop shuttles) 
 1;; stop is a pair of gps coords
  ;;shuttle list is now a hash filter doesn't work ;; the fix is to get the hash-values which is a list*
  (filter
   (λ (x) 
     (gps-in-range stop (bus-location x)))
   (hash-values shuttles)))

 
(post "/"
    (λ (req) (write req) (newline) (create_response (requestJSON req))))



(define root (path->string (current-directory)))
(define cert (string-append root "/server-cert.pem"))
(define key (string-append root "/private-key.pem"))

(define runner (thread (λ ()
 (run  #:port 8080
     ;  #:ssl? #t
      ; #:ssl-cert cert
      ; #:ssl-key  key
       #:listen-ip #f))))



;; ------ DISTANCE STUFF

(define (gps->string gps_in) (string-append "" (number->string (car gps_in))"," (number->string (cadr gps_in))))


(define (distance origin destination)
  (string->url (string-append "https://maps.googleapis.com/maps/api/directions/json?units=imperial"
                              "&origin=" origin
                              "&destination=" destination
                              "&departure_time=" (number->string (current-seconds))
                              "&key=AIzaSyAEgUDOGLAWMKRhlH7uz-ZtUoaPaFpHRZA")))
                             
(define (distance-waypoint origin destination waypoints)
  (string->url (string-append "https://maps.googleapis.com/maps/api/directions/json?units=imperial"
                              "&origin=" origin
                              "&destination=" destination
                              "&waypoints=via:" waypoints
                              "&departure_time=" (number->string (current-seconds))
                              "&key=AIzaSyAEgUDOGLAWMKRhlH7uz-ZtUoaPaFpHRZA")))

(define (duration line_in) (hash-ref 
                            (hash-ref (car (hash-ref (car (hash-ref 
                            (read-json (get-pure-port line_in)) 
                            'routes)) 
                            'legs)) 
                            'duration_in_traffic) 
                            'text))
