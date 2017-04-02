"""
Create AMI

This checks whether to create a new Amazon
Machine Image. It's done purely on the name/date
of the image, creating a new one if it's too
old
"""

from copy import copy
import json
import os
import string

base_amis = os.environ['AWS_BASE_AMI_ID']

packer_json = json.loads(open('./packer/base/base.json', 'r').read())

provisioner = packer_json['provisioners'][0]
builder = packer_json['builders'][0]

packer_json['provisioners'] = []
packer_json['builders'] = []

for base_ami in string.split(base_amis, ','):
    ami_region = string.split(base_ami, '=')

    new_builder = copy(builder)

    new_builder['region'] = ami_region[0]
    new_builder['source_ami'] = ami_region[1]
    new_builder['name'] = ami_region[0]

    packer_json['provisioners'].append(provisioner)
    packer_json['builders'].append(new_builder)

output_json = json.dumps(packer_json, indent=2)

write_file = open('./packer/tmp/base.json', 'w')

write_file.write(output_json)

write_file.close()
