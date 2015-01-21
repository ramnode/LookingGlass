#LookingGlass

##Overview
A \(simple\) Python port of the [LookingGlass](https://github.com/telephone/LookingGlass) software by [telephone](https://github.com/telephone).  HTML, CSS, and JS resources were copied and \(slightly)\ modified, only the backend was rewritten to simplify adding new features and for XSS protection.  This project uses the [Flask](http://flask.pocoo.org/) and [sh](https://amoffat.github.io/sh/) libraries and is MIT licensed.

##Design Decisions
The design is much simpler than the PHP original, leaving rate limiting up to the web server \(the example configs only allow 16 simultaneous connections\) and configuration does involve some manual setup right now \(more on this later\).  The original had the option of not presenting the IPv6 options, but this does not.  IPv6 adoption is critical and if you are rolling out a new looking glass without IPv6 connectivity you are doing the internet a disservice.

##Requirements
* Python 2.7 (may work on earlier/later versions, not currently tested)
* Virtualenv with all modules from requirements.txt installed (pip install -r requirements.txt)
* The ping, mtr, traceroute, and host utilities.  Other utilities may be added later.
* A method of serving a python WSGI application.  Example configs for nginx/uwsgi are included

##Setup Instructions
Example configuration files have been included for nginx and uwsgi in the `example\_configs` folder.

###nginx
The nginx config will need to be modified to change the `server\_name` directive and any paths that differ from your installation.  Copy or link it to your sites-enabled folder.

###uwsgi
The uwsgi config's ini file will need to have paths modified.  Pay special attention to the `CONFIG\_FILE` `env` directive as this is the file you must edit to change theme, set test IPs, and change the title/location/test files.  More on this in the next section.  The last file you'll need for uwsgi is the `wsgi.py` file in `example\_configs/uwsgi`.  Copy this to the same location as lookingglass.py and edit the shebang line to reflect your virtualenv.

###lookingglass
The default configuration file is in `instance/default.cfg`.  Copy this to another cfg file \(`instance/lg.cfg` for example\) and ensure this path is specified in your lg.ini uwsgi config.  Edit this file to customize your installation.  You will need to create test files that you reference.  For example, if you have a 100MB and 1000MB test file specified in your config, you would use the following commands to create them:

    dd if=/dev/zero of=static/100MB.test bs=1 count=0 seek=100MB
    dd if=/dev/zero of=static/1000MB.test bs=1 count=0 seek=1000MB

Keep in mind that the above files count in SI units, not IEC.  The result is that 1Kilobyte==1000Bytes instead of 1024, as you may expect.  To get that behavior, use MiB instead of MB.

##License
Code is licensed under MIT Public License.
