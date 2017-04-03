# UMLShuttle-Assistant

### Statement
We're creating an Actions on Google module using api.ai to interact with google assistant/home in order to let users figure out how when the next shuttle will be at one of the stops using google maps distance API. This project is especially interesting because it's using brand new technology that has only come to market in the past year and will give us a solid groundwork to create more projects involving this technology in the future. 


### Analysis
There will be data abstraction to various degrees throughout the entire project. All data is organized and collected in meaningful ways be it with lists, hash-tables, or structs and have proper functions to access them.

The only recursion that has been added in so far is for multithreading the proccess that updates the tables containing the last stop each shuttle was at. 

Map and for-each are used excessively throughout the parsing of the various json objects involved, and filtering is used exclusively for checking to see if shuttles are currently at a stop.

There is object orientation, the shuttle backend is encapsulated in an entire object and depending on how the rest progresses there might be more.

Seeing as there are objects, there are also state-modification using set! which is how all of the tables containing line/shuttle data are updated.


### External Technologies
This project connects to

Actions on Google (Google Asstant)
API.AI 
api.uml.edu

People will access the API for this module by asking Google Assistant how far away a shuttle is from whatever stop they are at. Google Assistant (on their phone) then sends their query to actions on google, which immediately sends it to API.AI which then processes it and sends a request for the data to the racket webserver. The racket webserver (this program) will then query the uml shuttle api's for their locations, query google maps api and then send the response back to API.AI which bounces it back to the end user.

### Data Sets or other Source Materials

All data is collected/taken from various https://www.uml.edu/api/Transportation/RoadsterRoutes/ endpoints 

### Deliverable and Demonstration

By the end of the project and the time of the live demo this program should be able to be interacted with fully to get information about all shuttles from 7am-7pm monday-friday without any issues as well as get average times. All data will be collected/analyzed live. 


The live demo for this project will more than likely actually start up the week before the actual event and will just continue running indefinitely and be accessable for anyone with an android phone running marshmellow or nougat with google assitant because the entire point of this project to to help out other students.

### Evaluation of Results
Ultimately to test the real effectiveness of this project it will have to involve it just being fully running and doing live tests. However, if we can get a test case for at least one shuttle line up and running we can get some early feedback from users and see exactly how useful this is to them and present them during the live demo. 

## Architecture Diagram
![arch](arch.png)

## Schedule

### First Milestone (Sun Apr 9)
The backend involving the parsing of lines (already 99% completed)
Basic interactivty with at least one shuttle line 

### Second Milestone (Sun Apr 16)
The rest of the lines should be completed by this date seeing as they will more or less follow the same patterns/issues of one line. 
Documentation should be mostly completed

### Public Presentation (Mon Apr 24, Wed Apr 26, or Fri Apr 28 [your date to be determined later])
Adding in asking for average time and what time they should leave their current location to get to a stop.
All documentation completed 

## Group Responsibilities

### Tavis Sivat @sivat394
The parsing backend and basic groundwork for api.ai/actions on google intergration 

### Nicholas Puopolo @npuopolo
will work on...

