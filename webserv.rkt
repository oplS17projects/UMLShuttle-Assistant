#lang racket


(require net/url)
(require web-server/http/request-structs)
(require web-server/http/bindings)
(require json)
(require "shuttles.rkt")
(require "api.ai.rkt")
(require "spin.rkt")


(define (requestJSON req) (bytes->string/utf-8 (request-post-data/raw req)))

(define (check_content req) (extract-binding/single 'content-type (request-headers req)))

(define (post_response req) (if (equal? (check_content req) "application/json")
                                (jsexpr->string (requestJSON req))
                                "lol not json"
                                )
  )

(define (create_response request_string)
  (define query_input (parse_query request_string))
  ((eval (string->symbol (requested_line query_input))) (requested_stop query_input)))
;; Instead of matching each requested line using a cond, just evaluate the line as a symbol to get a function
;; extremely lazy
;; extremely unsafe when interfaced with the internet and will ultimately get changed for full deployment (Hopefully) 

(define drum_hill    0)
(define yellow_north 0)
(define yellow_south 0)
(define purple       0)
(define green_south  0)
(define green_north  0)
(define red_line     0)

(define (Blue_line stop) ;; 
  (define blue_line (hash-ref (routes_hash 'get_routes) "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
  (define blue_last_stop (line-last_stop blue_line))

  ;; use (eval stop) at the very bottom
 
  ;; check the shuttles vs stops to make sure there isn't one currently at a stop
  ;; after checking to make sure there isn't one currently there it will then
  ;; go about filtering the last stop list for any shuttle that is on it's way to the requested stop
  
  (define North  (stop_check (42.6559767410684 -71.32473349571217)  blue_shuttles))
  (define South  (stop_check (42.643473 -71.333985)                 blue_shuttles))
  (define Ucrossing (stop_check (42.64936974740417 -71.32332180489351) blue_shuttles))
  (define Riverview (stop_check (42.64064028574872 -71.33751713182983) blue_shuttles))
    
 
  ;; function to match stop up to the correct one
  ;; function to convert to gps cords -> gmaps api
  ;; function to parse gmaps api -> create json post response 
  (write "LOL")
  ;; (eval stop)
  )

(define (stop_check stop shuttles) ;; stop is a pair of gps coords
    (filter
     (λ (x) 
       (gps-in-range stop shuttles)
     shuttles)))


(post "/"
      (lambda (req) (create_response (requestJSON req))))

(define runner (thread (λ () (run))))



;; ------ DISTANCE STUFF

(define (gps->string gps_in) (string-append "" (number->string (car gps_in))"," (number->string (cdr gps_in))))


(define (distance origin destination)
  (string->url (string-append "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&"
                              "origins=" origin
                              "&destinations=" destination
                              "&key=APIKEYHERE")))
(define (distance-waypoint origin destination waypoints)
  (string->url (string-append "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&"
                              "origins=" origin
                              "&destinations=" destination
                              "&waypoints=" waypoints
                              "&key=APIKEYHERE")))

(define (test_distance destination) (url->string (distance "42.642698,-71.331370" destination)))
  
(define distance_json "{\n   \"destination_addresses\" : [ \"100 Pawtucket St, Lowell, MA 01854, USA\" ],\n   \"origin_addresses\" : [ \"136 Walker St, Lowell, MA 01854, USA\" ],\n   \"rows\" : [\n      {\n         \"elements\" : [\n            {\n               \"distance\" : {\n                  \"text\" : \"1.4 mi\",\n                  \"value\" : 2193\n               },\n               \"duration\" : {\n                  \"text\" : \"6 mins\",\n                  \"value\" : 353\n               },\n               \"status\" : \"OK\"\n            }\n         ]\n      }\n   ],\n   \"status\" : \"OK\"\n}")

(define (duration line_in) (hash-ref (hash-ref (car (hash-ref (car (hash-ref (string->jsexpr distance_json) 'rows)) 'elements)) 'duration) 'text))
