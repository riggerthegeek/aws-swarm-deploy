import json
import os
import sys
from string import Template

cwd = sys.argv[1]
ami_list = json.loads(sys.argv[2])

access_key = os.environ['AWS_ACCESS_KEY']
secret_key = os.environ['AWS_SECRET_KEY']

config = {
    'manager_instances': int(os.environ['TERRAFORM_MANAGER_INSTANCES'] or '0'),
    'worker_instances': int(os.environ['TERRAFORM_WORKER_INSTANCES'] or '0'),
}

# Generate the files
for region in ami_list:
    print 'Generating region config: ' + region

    # Get the base file
    template_file = open(os.path.dirname(os.path.realpath(__file__)) + '/templates/terraform.txt')

    src = Template(template_file.read())
    output = src.substitute({
        'access_key': access_key,
        'ami': ami_list[region],
        'availability_zone': os.environ['AWS_AVAILABILITY_ZONE'],
        'base_instance': os.environ['AWS_BASE_INSTANCE'],
        'key_pair': os.environ['AWS_KEY_PAIR'],
        'manager_instances': config['manager_instances'],
        'manager_instance_types': '{}',
        'manager_name': os.environ['AWS_MANAGER_NAME'],
        'module_name': 'swarm-' + region,
        'region': region,
        'secret_key': secret_key,
        'worker_instances': config['worker_instances'],
        'worker_instance_types': '{}',
        'worker_name': os.environ['AWS_WORKER_NAME']
    })

    output_file = open(cwd + '/' + region + '.tf', 'w')
    output_file.write(output)
