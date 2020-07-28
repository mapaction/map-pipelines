#!/usr/bin/env python
import json
import logging
import netrc
import os
import sys
import xml.etree.ElementTree as ET

from gocdapi import admin, pipeline
from gocdapi.go import Go


def get_gocd_server():
    gocd_hostname = 'gocd.mapaction.org'

    possible_netrx_locations = [
        None,
        os.path.join(os.environ['USERPROFILE'], '.netrc'),
        os.environ.get('MAPCHEF_NETRC', None)
    ]

    secrets = None
    for netrc_path in possible_netrx_locations:
        try:
            secrets = netrc.netrc(netrc_path)
        except IOError:
            pass

    if not secrets:
        raise ValueError('Unable to locate or load suitable `.netrc` file for GoCD automation')

    user, gocd_url, apikey = secrets.authenticators(gocd_hostname)
    # print('user, gocd_url, apikey')
    # print(user, gocd_url, apikey)

    go_server = Go(gocd_url, username=user, password=apikey)
    return go_server


def get_new_event_details():
    try:
        new_event_desc_path = os.environ['mapchef_event_desc_path']
    except KeyError as ke:
        logging.error('Unable to find an input event description file. Please set'
                      ' the environment variable "mapchef_event_desc_path"')
        raise ke
    
    if not os.path.exists(new_event_desc_path):
        msg = ('Unable to find an input event description file at location'
               ' "{}".'.format(new_event_desc_path))
        logging.error(msg)
        raise ValueError(msg)

    with open(new_event_desc_path, 'r') as f:
        evt = json.loads(f.read())

    event_id = (evt['operation_id']).lower()

    return event_id, new_event_desc_path

def get_pipeline_pattern(go_server):
    master_pln = go_server.get_pipeline('per-country-pattern')
    return master_pln.get_config_xml(to_string=False)


def create_new_pipeline_xml(master_pipe, event_id, new_event_desc_path):
    master_pipe.attrib['name'] = event_id

    xpath_str = ".//environmentvariables/variable[@name='event_desc_path']/value"
    for val in (master_pipe.findall(xpath_str)):
        val.text = new_event_desc_path

    return ET.tostring(master_pipe)


def apply_pipeline_to_gocd(go_server, new_pipe_xml, event_id):

    if go_server.pipeline_exist(event_id):
        go_server.admin.update_pipeline_from_xml(new_pipe_xml)
        logging.info('Pipeline "{}" was successfully updated'.format(event_id))
    else:
        go_server.admin.create_pipeline_from_xml('Per-Country-Map-Creation', new_pipe_xml)
        logging.info('Pipeline "{}" was successfully created'.format(event_id))


if __name__ == "__main__":
    try:
        go_server = get_gocd_server()
        event_id, new_event_desc_path = get_new_event_details()
        master_pipe = get_pipeline_pattern(go_server)
        new_pipe_xml = create_new_pipeline_xml(master_pipe, event_id, new_event_desc_path)
        apply_pipeline_to_gocd(go_server, new_pipe_xml, event_id)
    except Exception as exp:
        logging.error(exp)
        sys.exit(1)
