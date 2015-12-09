#!/usr/bin/env python
from __future__ import print_function
import sys
import json
import base64
import urllib2


# should we have a global exit status, or just exit early for any errors?
EXIT_STATUS = 0


def node_health_check(node_address):
    global EXIT_STATUS
    url = "https://" + node_address + "/consul/v1/health/state/any"
    request = urllib2.Request(url)
    auth = b'Basic ' + base64.b64encode(b'admin:admin')
    request.add_header("Authorization", auth)
    try:
        f = urllib2.urlopen(request)
        health_checks = json.loads(f.read().decode('utf8'))

        for check in health_checks:
            if check['Status'] != "passing":
                print(check['Name'] + ": not passing.")
                EXIT_STATUS = 1
            else:
                print(check['Name'] + ": passing.")
    except Exception, e:
        print("Skipping IP ", node_address, " due to this error\n", e)


def cluster_health_check(ip_addresses):
    for node_address in ip_addresses:
        print("Testing node at IP: " + node_address)
        node_health_check(node_address)
        print("Done testing " + node_address)


if __name__ == "__main__":

    address_list = sys.argv[1:]
    cluster_health_check(address_list)
    print("Health check finished. Exiting now")
    sys.exit(EXIT_STATUS)
