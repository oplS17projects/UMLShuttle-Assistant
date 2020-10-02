# UML Shuttle Assistant 

## (Tavis Sivat) 
### April 30, 2017

# Overview


Umass lowells shuttle tracking system is nice, but it's missing one thing to be truely useful to students, and that's ability to give an estimate of exactly how long it will take for the next shuttle to arrive at a certain stop. This project was created as a way to give students the ability to figure out exactly that through various platforms that api.ai intergrates with, which as of right now is just api.ai itself and facebook messenger. 



**Authorship note:** All of the code described here was written by myself. 

# Libraries Used
```
(require net/url)
(require web-server/http)
(require web-server/servlet)
(require json)
(require spin)
```

* The ```net/url``` library provides the ability to access the shuttle API endpoints from UML as well as the google maps distance API
* The ```web-server``` library is used to create a webhook for API.AI to access and return information to an end user
* The ```json``` library is used to parse the replies from all webservers involved
* The ```spin``` library is an abstraction layer for the web-server which makes RESTful API easier to create in racket. 

# External Technolgy

[api.ai](http://api.ai): is a natural language proccessing platform owned by google that intergrates in with a bunch of platforms including google assistant and facebook messenger which acts as interface points to the assistant. 
It works by accepting a message from one of the intergrating services and then sends a request to the assistant webhook for a post API call to get a response to send back to the end user.


# Examples

## 1. Initialization and using a Global Object (OO/StateModification)

The following code creates a global object, ```routes_hash``` that is used to generate the object that's in charge of parsing the shuttle endpoints for the location of each shuttle. 

```
(define routes_hash
  (let
      ([routes (make-hash)]
       [active_lst '()])
```
each of them are modified through various subfuctions of the parser object using hash_set! and set.

The following is how the start of each response is started to get generated. 

```
(define (Blue_line) ;; 
  (define blue_line (hash-ref (routes_hash 'get_routes)  "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))

  (define (North))
 ```
 
 While using global objects is not a central theme in the course, it's necessary to show this code to understand
 the later examples. 
 
## 2. Selectors and Predicates using Procedural Abstraction


Procedural Abstraction is used to various degrees, there could be a lot more for readability sake.
Due to the fact that racket has structs built in, and this is a web app that needs to focus on speed, I didn't create the 
abstractions as we were taught in class for everything but I did use them for the GPS locations and how the routes_hash is actually accessed (as seen above)

The structs are 
```
(struct bus   (id type location last_stop)  #:mutable  #:transparent ) ;;location is gps pair
(struct line  (name id shuttles stops)   #:mutable  #:transparent )
```
to access any element of a struct it's (struct-element obj) ex: (bus-id y) 
to set any element it's (struct-element-set! obj)

the gps coordinates are currently set up as a pair of (lat long) and the accessors were defined as 
```
(define (longitude gps) (cadr gps))
(define (latitude gps) (car gps))
```

For the webserver when trying to calculate the time each line stores information to be used like this

```
(define (Blue_line) ;; 
  (define blue_line (hash-ref (routes_hash 'get_routes)  "Blue "))
  (define blue_shuttles (line-shuttles blue_line))
  (define blue_stops (line-stops blue_line))
```

## 3. Using Recursion to Accumulate Results

Because of the fact that this is a web application recursion was tried to be kept to a minimuim to aid in effiency, it was however nessecary for multithreading the parser so it can continuiously update the routes_hash

```
(define update_lines ;; updates routes with the new info in a seperate thread every minute
      (thread (λ () (define (loop)
                      (hash-for-each routes
                                     (λ (z y);; z = line name ; y = line strut
                                       ;; use line ID to get the active shuttles
                                       (let* [(shuttle_update (active_shuttles_on (route_url (line-id y))))
                                              (at_stop (last_shuttle_stop shuttle_update (line-stops y)))]
                                         
                                         (update-buses (line-shuttles y) shuttle_update at_stop))))
                                        
                      (sleep 10) (loop))
                (loop)))))
```

## 4. Filtering/Mapping 

I used filtering and mapping a lot for various parts of the but the following uses both in one function.

filter-not does the opposite of filter where it returns anything that is false which is used to remove any null responses from a list that's generated from mapping a lambda function that checks to see if a shuttle matches the stop right before the one requested and builds a response of the time it gets from google maps.

in the lambda x is the key, y is the value.
```
(define (North)    (if (not (equal? '() (stop_check '(42.6559767410684 -71.32473349571217)  blue_shuttles)))
                        (list currently_at_stop )
                        (filter-not null? (hash-map blue_shuttles (λ (x y) ;; Use map on this list to get a list of distances
                         (cond  ;; then pick the shortest distance and use that to report back to the user
                            [(equal? (bus-last_stop y) "South - Broadway St")
                          ;check to see if the shuttle's gps is to the east of the waypoint, if not then use waypoint
                              (if (<  (latitude (bus-location y)) -71.327028)
                               (Build_response (bus-id y)  (duration (distance-waypoint (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217" "42.638522,-71.327028")))
                                 (Build_response (bus-id y) (duration (distance (gps->string (bus-location y)) "42.6559767410684,-71.32473349571217"))))
                                 ] ;report back shuttle time
                             [(equal? (bus-last_stop y) "South - Wilder")
                              (Build_response (bus-id y) (duration (distance-waypoint "42.640755,-71.337500" "42.6559767410684,-71.32473349571217" "42.638522,-71.327028"))) ] ;; use time taken from riverview -> North and report that back
                             [else null]))
                        ))))
```
