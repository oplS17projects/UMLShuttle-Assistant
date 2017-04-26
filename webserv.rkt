#lang racket

(require net/url  
         web-server/http/request-structs
         web-server/http/bindings
         web-server/servlet
         web-server/templates
         json
         "shuttles.rkt"
         "api.ai.rkt"
         "spin.rkt")

(provide requestJSON (struct-out bus) routes_hash blue-test Blue_line duration distance-waypoint gps->string) 

(define (requestJSON req) (bytes->string/utf-8 (request-post-data/raw req)))

(define (check_content req) (extract-binding/single 'content-type (request-headers req)))

(define (post_response req) (if (equal? (check_content req) "application/json")
                                (jsexpr->string (requestJSON req))
                                "lol not json"
                                ))

(define (create_response request_string) "lol")
  ;(define query_input (parse_query request_string))
  ;((eval (string->symbol (requested_line query_input))) (requested_stop query_input)))
;; Instead of matching each requested line using a cond, just evaluate the line as a symbol to get a function
;; extremely lazy
;; extremely unsafe when interfaced with the internet and will ultimately get changed for full deployment (Hopefully) 

(define drum_hill    0)
(define yellow_north 0)
(define yellow_south 0)
(define purple       0)
(define red_line     0)


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


(define (Build_response bus time)
  "{ \"speech\": \"SPEECH HERE.\", \"displayText\": \" DISPLAY TEXT HERE \", \"data\": {}, \"contextOut\": [], \"source\": \"Google Maps\" }"
  )



(define (Blue_line) ;; 
  (define blue_line (hash-ref blue-test "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
  


  ;; check the shuttles vs stops to make sure there isn't one currently at a stop
  ;; after checking to make sure there isn't one currently there it will then
  ;; go about filtering the last stop list for any shuttle that is on it's way to the requested stop
  
  (define (North)    (if (not (equal? '() (stop_check '(42.6559767410684 -71.32473349571217)  blue_shuttles)))
                        (write "a shuttle is currently there")
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                            [(equal? (bus-last_stop y) "South - Broadway St")
                          ;check to see if the shuttle's gps is to the east of the waypoint, if not then use waypoint
                              (if (<  (latitude (bus-location y)) -71.327028)
                                (distance-waypoint (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217" "42.638522,-71.327028")
                                  (distance (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217"))] ;report back shuttle time
                             [(equal? (bus-last_stop y) "South - Wilder")
                              (distance-waypoint "42.640755,-71.337500" "42.6559767410684,-71.32473349571217" "42.638522,-71.327028") ] ;; use time taken from riverview -> North and report that back
                             [else null]))
                        ))))
                       
;; shuttle-search gets a list of all shuttles that have left the stop selected
;; use map to get the distance for each one and then select the shortest distance to report back to to the user
  

  
(define (South)     (if (not (equal? '() (stop_check '(42.643473 -71.333985)  blue_shuttles)))
                        (write "a shuttle is currently there") 
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                          (cond  ;; then pick the shortest distance and use that to report back to the user
                           [(equal? (bus-last_stop y) "University Crossing")
                             (if (>  (latitude (bus-location y)) -71.327028)
                                 (distance-waypoint "42.640755,-71.337500" "42.6559767410684,-71.32473349571217" "42.638522,-71.327028") ;; Middlesex waypoint
                                  (distance-waypoint "42.640755,-71.337500" "42.6559767410684,-71.32473349571217" "42.645632,-71.333838"))] ;pawtucket waypoint
                            [(equal? (bus-last_stop y) "North Campus") (distance-waypoint (gps->string (bus-location y) "42.643473,-71.333985" "42.649418,-71.323339|via:42.638522,-71.327028")) ] ;; use time taken from riverview -> North and report that back
                            [else null]))))))

(define (Riverview) (if (not (equal? '() (stop_check '(42.64064028574872 -71.33751713182983) blue_shuttles)))
                        (write "a shuttle is currently there")
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                           [(equal? (bus-last_stop y) "North Campus")] ;report back shuttle time
                           [(equal? (bus-last_stop y) "South - Wilder") ]
                            [else null])))))                                                
)
    
 
;; function to match stop up to the correct one
;; function to convert to gps cords -> gmaps api
;; function to parse gmaps api -> create json post response 
  
(define (dispatch e)
  (cond
    [(equal? e "North") (North)]
    [(equal? e "South")  (South)]
    
    [(equal? e "Riverview") (Riverview)]
    [else "lol what"]))
dispatch 
  
)

(define (stop_check stop shuttles) ;; stop is a pair of gps coords
  ;;shuttle list is now a hash filter doesn't work ;; the fix is to get the hash-values which is a list*
  (filter
   (λ (x) 
     (gps-in-range stop (bus-location x)))
   (hash-values shuttles)))

 
(post "/"
      (lambda (req) (create_response (requestJSON req))))



;;--- THIS CODE HERE IS TAKEN FROM SPIN'S EXAMPLE ---

;(define (json-response-maker status headers body)
;  (response status
;            (status->message status)
;            (current-seconds)
;            #"application/json;"
;            headers
;            (let ([jsexpr-body (string->jsexpr body)])
;              (lambda (op) (write-json (force jsexpr-body) op)))))
;
;(define (json-get path handler)
;  (define-handler "POST" path handler json-response-maker))
;
;(json-post "/json" (lambda (req) 
;                    "{\"body\":\"JSON GET\"}"))  ;; NEEDS TO BE A STRING
;
;;--- END OF SLIGHTLY COPIED CODE 


(define runner (thread (λ () (run))))



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
                            (read-json (get-pure-port (car line_in))) 
                            'routes)) 
                            'legs)) 
                            'duration_in_traffic) 
                            'text))
