#!/usr/bin/env python
from __future__ import print_function
import sys
import json
import base64

if sys.version_info[0] > 2:
    from urllib.request import urlopen, Request
else:
    from urllib import urlopen, Request


# should we have a global exit status, or just exit early for any errors?


def node_health_check(node_address):
    request = Request("http://" + node_address + "/consul/v1/health/state/any")
    auth = b'Basic ' + base64.b64encode('admin:admin')
    request.add_header("Authorization", auth)
    try:
        f = urlopen(request)
    except Exception, e:
        print("Node address: "+node_address+" caused an error:\n{}".format(e))

    health_checks = json.loads(f.read().decode('utf8'))

    for check in health_checks:
        if check['Status'] != "passing":
            print(check['Name'] + ": not passing. Exiting now")
            sys.exit(1)
        else:
            print(check['Name'] + ": passing. Continuing")


def cluster_health_check(ip_addresses):
    for node_address in ip_addresses:
        print("Testing node at IP: " + node_address)
        node_health_check(node_address)
        print("Done testing " + node_address)


if __name__ == "__main__":
    address_list = sys.argv[1:]
    cluster_health_check(address_list)
    print("Health check finished. Exiting now")
    sys.exit(0)
