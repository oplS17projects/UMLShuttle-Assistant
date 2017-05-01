#lang racket

(require net/url)
(require net/url-structs)
(require json)


(provide routes_hash 
         (struct-out line)(struct-out bus)
         latitude longitude gps-in-range)

(define lines    (string->url "https://www.uml.edu/api/Transportation/RoadsterRoutes/Lines/?apiKey=87C6ACB0-C2A4-460A-AAF2-9493BAA3917B"))
(define (route_url num)  (string->url (string-append "https://www.uml.edu/api/Transportation/RoadsterRoutes/BusesOnLine/?apiKey=87C6ACB0-C2A4-460A-AAF2-9493BAA3917B&lineId="                                                     (number->string num))))
(define test_j   "{\"isError\":false,\"message\":null,\"statusCode\":200,x\"data\":[{\"Id\":48,\"Number\":\"T157\",\"Location\":{\"Latitude\":42.6492875,\"Longitude\":-71.323405499999993},\"Heading\":135},{\"Id\":44,\"Number\":\"T107\",\"Location\":{\"Latitude\":42.6492875,\"Longitude\":-71.323405499999993},\"Heading\":135}]}")


(struct bus   (id type location last_stop)  #:mutable  #:transparent ) ;; id/type = strings location is a list (lat long) 
(struct line  (name id shuttles stops)   #:mutable  #:transparent )


;; GPS STUFF

(define (longitude gps) (cadr gps))
(define (latitude gps) (car gps))

(define offset .00040)
(define (northbound gps_pair)
  (list (latitude gps_pair) (+ offset (longitude gps_pair))))
(define (southbound gps_pair)
  (list (latitude gps_pair) (- (longitude gps_pair) offset)))
(define (eastbound gps_pair)
  (list (+ offset (latitude gps_pair)) (longitude gps_pair)))
(define (westbound gps_pair)
  (list (- offset (latitude gps_pair)) (longitude gps_pair)))

(define (gps-in-range gps1 gps2)
  (let [(one gps1) (two gps2)]
    (and (< (longitude one) (longitude (northbound two))) ;; longitude
         (> (longitude one) (longitude (southbound two)))
         (< (latitude one) (latitude (eastbound two)))    ;;latitude
         (> (latitude one) (latitude (westbound two)))
         )))



(define routes_hash
  (let
      ([routes (make-hash)]
       [active_lst '()])

    (define (active_shuttles_on line_in)
      (define shuttles (make-hash))
      (define json_read (json_in line_in))
      (for-each  (λ (x)
                   (hash-set! shuttles
                              (bus-id x) x))   
                 (foldl create-buses '() json_read))
      shuttles)

    (define (find_line line_name linelst)
      (filter (λ (x) (equal? (line-name x) line_name)) linelst ))

    (define (json_in line_in)
      (hash-ref (if (string? line_in)
                    (string->jsexpr line_in)
                    (read-json (get-pure-port line_in))) 'data))

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
    
    (define (active_lines) ;; gets a list of all the lines with ID Number, Name, and Stops
      (map
       (λ (x)
         (let*
             [(id (hash-ref x 'Id))
              (name 
               (if (or (equal? 2 id) (equal? 11 id))
               "Red "
               (string-append
                     (hash-ref x 'Name)
                     " "
                     (hash-ref x 'Qualifier))))]
           
           (set! active_lst (cons (list name id) active_lst))
           (list
            (hash-ref x 'Id)
            name
            (hash-ref x 'Stops)))) ;; add in stop locations to check against
       (json_in lines))
      ) ;; creates a list of active lines

   
    ;; stuff for stops
    (define (get_stops line_in) ;; gets a list of stops for internal use to compare shuttle gps locations
      (foldl                    
       (λ (x y)
         (cons (list (hash-ref x 'Name)
                     (list
                      (hash-ref (hash-ref x 'Location) 'Latitude)
                      (hash-ref (hash-ref x 'Location) 'Longitude)
                      )
                     ) y))
       '()
       line_in)
      )
    (define (check_stop busgps stops) ;; check to see if the GPS is in range of the stop or not
      (let [(check (filter
                    (λ (x) 
                      (gps-in-range busgps (cadr x)))
                    stops))]
        (if (null? check)
            "nope"
            (caar check))))
      
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

    ;; DISPATCHER 
    (define (dispatch e)
      (cond
        [(equal? e 'get_routes) routes ]
        [(equal? e 'stop_updates) (thread-suspend update_lines)]
        [(equal? e 'resume_updates) (thread-resume update_lines)]
        [(equal? e 'active_lines) (active_lines)]
        [(equal? e 'get_line) active_lst]
        ))   
    (cond
      [(hash-empty? routes) (create_lines)  dispatch]
      [else dispatch]) ;; this condition creates the lines on initial call and then dispatch so that it can immediatly be used) 
    ))








;; ------- TEST STUFF



