#LookingGlass

##Overview
A (simple) Python port of the [LookingGlass](https://github.com/telephone/LookingGlass) software by [telephone](https://github.com/telephone).  HTML, CSS, and JS resources were copied and (slightly) modified, only the backend was rewritten to simplify adding new features and for XSS protection.  This project uses the [Flask](http://flask.pocoo.org/) and [sh](https://amoffat.github.io/sh/) libraries and is MIT licensed.

##Design Decisions
The design is much simpler than the PHP original, leaving rate limiting up to the web server (the example configs only allow 16 simultaneous connections) and configuration does involve some manual setup right now (more on this later).  The original had the option of not presenting the IPv6 options, but this does not.  IPv6 adoption is critical and if you are rolling out a new looking glass without IPv6 connectivity you are doing the internet a disservice.

##Requirements
* Python 2.7 (may work on earlier/later versions, not currently tested)
* The ping, mtr, traceroute, and host utilities.  Other utilities may be added later.
* A method of serving a python WSGI application.  Example configs for nginx/uwsgi are included

##Setup Instructions (nginx/uwsgi)

##Customizing
custom configs
test files
