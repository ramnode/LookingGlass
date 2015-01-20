import flask
import re
import sh

app = flask.Flask(__name__)
app.config.from_pyfile('instance/default.cfg')
app.config.from_envvar('CONFIG_FILE', silent=True)

def get_and_validate_host(request):
    """Confirms that request's host parameter is a host or ip(v6)

    returns None on failure.
    """
    target = request.args.get('host')
    if target is None:
        return
    match = re.search("^[a-zA-Z0-9\-\.:]+$", target)
    if match is not None:
        return target
    return

def safe_run(command, *args, **kwargs):
    """Runs <command> with *args and **kwargs, returning (status, output)
    
    <command> is something imported from the sh library.
    """
    try:
        output = command(*args, **kwargs)
        status = 0
    except sh.ErrorReturnCode as exc:
        output = exc.stdout
        status = 1
    return status, output

def encode_output(encoder, status, output):
    """Encodes output in one of {raw, json}.

    The raw encoder does not use status.
    """
    if encoder == "raw":
        return flask.escape(output)
    elif encoder == "json":
        return flask.jsonify({
            "output": "{0}".format(output),
            "status": status
        })
    else:
        return flask.escape("Error, invalid encoder")

@app.route("/<encoder>/host")
def api_host(encoder):
    target = get_and_validate_host(flask.request)
    if target is None:
        return encode_output(encoder, "Error, invalid host", 1)
    return encode_output(
        encoder,
        *safe_run(sh.host, target)
    )

#mtr, mtr6, ping, ping6, traceroute, traceroute6
@app.route("/<encoder>/mtr<version>")
def api_mtr(encoder, version):
    target = get_and_validate_host(flask.request)
    if target is None:
        return encode_output(encoder, "Error, invalid host", 1)
    if version not in ('4', '6'):
        return encode_output(encoder, "Error, invalid ip version")
    return encode_output(
        encoder,
        *safe_run(
            sh.mtr,
            '-{0}'.format(version),
            '--report',
            '--report-wide',
            target,
            c=4
        )
    )

@app.route("/<encoder>/ping<version>")
def api_ping(encoder, version):
    target = get_and_validate_host(flask.request)
    if target is None:
        return encode_output(encoder, "Error, invalid host", 1)
    if version == '4':
        command = sh.ping
    elif version == '6':
        command = sh.ping6
    else:
        return encode_output(encoder, "Error, invalid ip version")
    return encode_output(
        encoder,
        *safe_run(
            command,
            target,
            c=4,
            i=1,
            w=8
        )
    )

@app.route("/<encoder>/traceroute<version>")
def api_traceroute(encoder, version):
    target = get_and_validate_host(flask.request)
    if target is None:
        return encode_output(encoder, "Error, invalid host", 1)
    if version not in ('4', '6'):
        return encode_output(encoder, "Error, invalid ip version")
    return encode_output(
        encoder,
        *safe_run(
            sh.traceroute,
            '-{0}'.format(version),
            target,
            w=2
        )
    )
    
@app.route("/")
def index():
    return flask.render_template(
        'index.html',
        site_name = app.config["SITE_NAME"],
        theme = app.config["THEME"],
        site_location = app.config["SITE_LOCATION"],
        test_ipv4 = app.config["TEST_IPV4"],
        test_ipv6 = app.config["TEST_IPV6"],
        test_files = app.config["TEST_FILES"]
    )

if __name__ == "__main__":
    app.run()
