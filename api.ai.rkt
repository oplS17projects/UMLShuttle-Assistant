#lang racket

(require net/url)
(require net/url-structs)
(require json)

(provide parse_query requested_line requested_stop)

;; ---------- API.AI STUFF

(define test_query "{\r\n  \"id\": \"036a07cf-fe90-4286-a8f0-0ca784e66d9e\",\r\n  \"timestamp\": \"2017-03-30T01:57:53.935Z\",\r\n  \"lang\": \"en\",\r\n  \"result\": {\r\n    \"source\": \"agent\",\r\n    \"resolvedQuery\": \"How far away is the blue line from south?\",\r\n    \"action\": \"blue_line\",\r\n    \"actionIncomplete\": false,\r\n    \"parameters\": {\r\n      \"destination\": {\r\n        \"line\": \"Blue_line\",\r\n        \"bus_stops\": \"South\"\r\n      },\r\n      \"time_until\": \"how far away is\"\r\n    },\r\n    \"contexts\": [],\r\n    \"metadata\": {\r\n      \"intentId\": \"4c2adb65-e68f-4915-92be-549a5693fc43\",\r\n      \"webhookUsed\": \"false\",\r\n      \"webhookForSlotFillingUsed\": \"false\",\r\n      \"intentName\": \"Blue Line\"\r\n    },\r\n    \"fulfillment\": {\r\n      \"speech\": \"You are from north.\",\r\n      \"messages\": [\r\n        {\r\n          \"type\": 0,\r\n          \"speech\": \"You are from north.\"\r\n        }\r\n      ]\r\n    },\r\n    \"score\": 1\r\n  },\r\n  \"status\": {\r\n    \"code\": 200,\r\n    \"errorType\": \"success\"\r\n  },\r\n  \"sessionId\": \"ef2685f9-3a53-46d0-9952-c74a5f1c34ce\"\r\n}")

(define (parse_query query_request)
  (let ([query_json (hash-ref (string->jsexpr query_request)
                               'result)])
    (hash-ref query_json 'parameters)))

(define (parameters query) (cadr query))

(define (requested_line query) (hash-ref (hash-ref query 'destination) 'line))
(define (requested_stop query) (hash-ref (hash-ref query 'destination) 'bus_stops))