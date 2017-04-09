"""
Terraform

Works out how many manager/worker instances
to create and then runs the Terraform script
"""
import json
import os
import sys
import time
from string import Template
from subprocess import call

cwd = sys.argv[1]
ami_list = json.loads(sys.argv[2])
tfvars_file = sys.argv[3]

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
        'availability_zone': 'b',
        'base_instance': 't2.micro',
        'key_pair': os.environ['AWS_KEY_PAIR'],
        'manager_instances': config['manager_instances'],
        'manager_instance_types': '{}',
        'manager_name': '',
        'module_name': 'swarm-' + region,
        'region': region,
        'secret_key': secret_key,
        'worker_instances': config['worker_instances'],
        'worker_instance_types': '{}',
        'worker_name': ''
    })

    output_file = open(cwd + '/' + region + '.tf', 'w')
    output_file.write(output)

# Initialise the Terraform goodness
code = call([
    'terraform',
    'init',
    '-input=false',
    '-backend=true',
    '-backend-config=' + tfvars_file
], cwd=cwd)

call([
    'terraform',
    'get'
], cwd=cwd)

exit(1)

if code > 0:
    exit(code)

# Are we applying or destroying changes?
if config['manager_instances'] == 0 and config['worker_instances'] == 0:
    # Destroy
    print "Destroying Terraform infrastructure"

    code = call([
        'terraform',
        'destroy',
        '-force'
    ], cwd=cwd)

    if code > 0:
        exit(code)
else:
    # Apply
    print "Applying Terraform infrastructure"

    def call_terraform(action):
        args = [
            'terraform',
            action
        ]

        exit_code = call(args, cwd=cwd)

        exit(1)

        if exit_code > 0:
            exit(exit_code)

        return exit_code

    call_terraform('plan')
    call_terraform('apply')
