"""
Terraform

Works out how many manager/worker instances
to create and then runs the Terraform script
"""
import json
import os
import sys
from subprocess import call

cwd = sys.argv[1]
ami_list = json.loads(sys.argv[2])

config = {
    'manager_instances': int(os.environ['TERRAFORM_MANAGER_INSTANCES'] or '0'),
    'worker_instances': int(os.environ['TERRAFORM_WORKER_INSTANCES'] or '0'),
}

# Are we applying or destroying changes?
if config['manager_instances'] == 0 and config['worker_instances'] == 0:
    # Destroy
    call([
        'terraform',
        'destroy',
        '-force'
    ], cwd=cwd)
else:
    # Apply
    def call_terraform(action):
        args = [
            'terraform',
            action
        ]

        for key in config:
            value = config[key]

            args.append('-var=' + key + '=' + str(value))

        return call(args, cwd=cwd)

    call_terraform('plan')
    call_terraform('apply')
