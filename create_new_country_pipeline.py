#!/usr/bin/env python
import json
import logging
import netrc
import os
import sys
import xml.etree.ElementTree as ET
import traceback

from gocdapi import admin, pipeline
from gocdapi.go import Go


import pycountry
from slugify import slugify


def get_slugified_name(event_id):

    country = pycountry.countries.get(alpha_3=event_id.upper())

    if country:
        return slugify(country.name)
    else:
        print("didn't find {}".format(event_id))
        return event_id


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


def dequote(s):
    """
    From https://stackoverflow.com/a/20577580

    If a string has single or double quotes around it, remove them.
    Make sure the pair of quotes match.
    If a matching pair of quotes is not found, return the string unchanged.
    """
    if (s[0] == s[-1]) and s.startswith(("'", '"')):
        return s[1:-1]
    return s

def get_new_event_details():
    try:
        new_event_desc_path = os.environ['mapchef_event_desc_path']
        print(new_event_desc_path)
        new_event_desc_path = dequote(new_event_desc_path)
        print(new_event_desc_path)
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
    # try:
    #     all_pipelines = go_server.pipelines
    #     print('got all_pipelines')
    #     # print('\n'.join(all_pipelines.keys()))
    # except Exception as exp:
    #     # traceback.print_exception(type(exp), exp, None)
    #     # traceback.print_exc()
    #     pass

    master_pln = go_server.get_pipeline('per-country-pattern')
    print('got master_pln. attempting to convert to xml')
    return master_pln.get_config_xml(to_string=False)


def create_new_pipeline_xml(master_pipe, pipeline_name, new_event_desc_path):
    master_pipe.attrib['name'] = pipeline_name

    xpath_str = ".//environmentvariables/variable[@name='event_desc_path']/value"
    for val in (master_pipe.findall(xpath_str)):
        # val.text = new_event_desc_path
        val.text = '"{}"'.format(new_event_desc_path)

    return ET.tostring(master_pipe)


def apply_pipeline_to_gocd(go_server, new_pipe_xml, pipeline_name):

    if go_server.pipeline_exist(pipeline_name):
        go_server.admin.update_pipeline_from_xml(new_pipe_xml)
        logging.info('Pipeline "{}" was successfully updated'.format(pipeline_name))
    else:
        go_server.admin.create_pipeline_from_xml('Per-Country-Map-Creation', new_pipe_xml)
        logging.info('Pipeline "{}" was successfully created'.format(pipeline_name))


if __name__ == "__main__":
    try:
        go_server = get_gocd_server()
        event_id, new_event_desc_path = get_new_event_details()
        pipeline_name = get_slugified_name(event_id)
        print('new_event_desc_path=[{}]'.format(new_event_desc_path))
        master_pipe = get_pipeline_pattern(go_server)
        print('Attempting to create xml for new/updated pipeline')
        new_pipe_xml = create_new_pipeline_xml(master_pipe, pipeline_name, new_event_desc_path)
        apply_pipeline_to_gocd(go_server, new_pipe_xml, pipeline_name)
    except Exception as exp:
        logging.error(exp)
        sys.exit(1)
