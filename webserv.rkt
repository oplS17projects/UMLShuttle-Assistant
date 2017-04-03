#lang racket


(require net/url)
(require web-server/http/request-structs)
(require web-server/http/bindings)
(require json)
(require "shuttles.rkt")
(require "api.ai.rkt")
(Require “spin.rkt”)


(define (requestJSON req) (bytes->string/utf-8 (request-post-data/raw req)))

(define (check_content req) (extract-binding/single 'content-type (request-headers req)))

(define (post_response req) (if (equal? (check_content req) "application/json")
                                (jsexpr->string (requestJSON req))
                                "lol not json"
                                )
  )

(define (create_response request_string)
  (define query_input (create_query request_string))
  (cond [(equal? (requested_line query_input) "blue_line") (blue (requested_stop query_input))]
        [(equal? (requested_line query_input) "red_line") (red (requested_stop query_input))]
        [(equal? (requested_line query_input) "yellow_north") (yellow_north (requested_stop query_input))]
        [(equal? (requested_line query_input) "yellow_south") (yellow_south (requested_stop query_input))]
        [(equal? (requested_line query_input) "green_south") (green_south (requested_stop query_input))]
        [(equal? (requested_line query_input) "green_north") (green_north (requested_stop query_input))]
        [(equal? (requested_line query_input) "purple") (purple (requested_stop query_input))]))


(define drum_hill
(define yellow_north 0)
(define yellow_south 0)
(define purple 0)
(define green_south 0)
(define green_north 0)



(define red
  (define blue_line (hash-ref routes_hash "Red "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
  (define blue_last_stop (line-last_stop blue_line))

  0)
  
(define (blue stop) ;; 
  (define blue_line (hash-ref routes_hash "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
  (define blue_last_stop (line-last_stop blue_line))

  ;; function to match stop up to the correct one
  ;; function to convert to gps cords -> gmaps api
  ;; function to parse gmaps api -> create json post response 
  0
  )




(post "/"
  (lambda (req) (create_response (requestJSON req))))




(run)



;; ------ DISTANCE STUFF

(define (gps->string gps_in) (string-append "" (number->string (car gps_in))"," (number->string (cdr gps_in))))


(define (distance origin destination)
  (string->url (string-append "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&"
                              "origins=" origin
                              "&destinations=" destination
                              "&key=AIzaSyAEgUDOGLAWMKRhlH7uz-ZtUoaPaFpHRZA")))
(define (distance-waypoint origin destination waypoints)
  (string->url (string-append "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&"
                              "origins=" origin
                              "&destinations=" destination
                              "&waypoints=" waypoints
                              "&key=AIzaSyAEgUDOGLAWMKRhlH7uz-ZtUoaPaFpHRZA")))

(define (test_distance destination) (url->string (distance "42.642698,-71.331370" destination)))
  
(define distance_json "{\n   \"destination_addresses\" : [ \"100 Pawtucket St, Lowell, MA 01854, USA\" ],\n   \"origin_addresses\" : [ \"136 Walker St, Lowell, MA 01854, USA\" ],\n   \"rows\" : [\n      {\n         \"elements\" : [\n            {\n               \"distance\" : {\n                  \"text\" : \"1.4 mi\",\n                  \"value\" : 2193\n               },\n               \"duration\" : {\n                  \"text\" : \"6 mins\",\n                  \"value\" : 353\n               },\n               \"status\" : \"OK\"\n            }\n         ]\n      }\n   ],\n   \"status\" : \"OK\"\n}")

(define (duration line_in) (hash-ref (hash-ref (car (hash-ref (car (hash-ref (string->jsexpr distance_json) 'rows)) 'elements)) 'duration) 'text))
