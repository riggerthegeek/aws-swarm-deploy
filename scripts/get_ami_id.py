"""
Get AMI ID

Opens up the Packer log and searches for 
the region and AMI IDs. Outputs as a JSON
object for use elsewhere
"""
import json
import re
import sys

file_name = sys.argv[1]

ami_data = open(file_name, 'r').read().split('\n')

amis = {}

for line in ami_data:
    ami = re.search('(ami-\w+)', line)

    if ami:
        lines = line.split(',')

        if lines[2] == 'error' or lines[2] == 'artifact':
            amis[lines[1]] = ami.group(0)

print json.dumps(amis, indent=2)
