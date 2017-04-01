"""
Generate Host File

This takes the IP addresses from the Terrform output
command and generates a host ini file for Ansible
"""

import errno
import json
import os
import sys
from subprocess import check_output

cwd = os.path.dirname(os.path.realpath(__file__))

if len(sys.argv) > 1:
    output_file = sys.argv[1]
else:
    raise AttributeError('Please set an output file')

if len(sys.argv) > 2:
    key_name = sys.argv[2]
else:
    raise AttributeError('Please set a key name')

if len(sys.argv) > 3:
    build_base = sys.argv[3]
else:
    build_base = 'docker'


def get_data():
    output_data = check_output(['terraform', 'output', '-json'], cwd=cwd + '/../terraform/' + build_base)
    return json.loads(output_data)


def parse(output_data, element):

    output = '[' + element + ']\n'

    if element + '_ips' in output_data:

        item = output_data[element + '_ips']

        if 'value' in item:

            for ip in item['value']:
                output += ip
                output += '\t'
                output += 'ansible_ssh_private_key_file="' + key_name + '"'
                output += '\t'
                output += 'ansible_user="ubuntu"'
                output += '\t'
                output += 'ansible_python_interpreter="/usr/bin/env python3"'
                output += '\t\n'

    return output

data = get_data()

types = [
    'manager',
    'worker'
]

fileData = ''
for element in types:

    fileData += parse(data, element)

# Delete the old file
try:
    os.remove(output_file)
except OSError as err:
    if err.errno != errno.ENOENT:
        raise

writer = open(output_file, 'w')
writer.write(fileData)

print fileData
