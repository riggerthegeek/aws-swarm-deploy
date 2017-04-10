"""
Terraform

Works out how many manager/worker instances
to create and then runs the Terraform script
"""
import os
import sys
from subprocess import call

cwd = sys.argv[1]

access_key = os.environ['AWS_ACCESS_KEY']
secret_key = os.environ['AWS_SECRET_KEY']

config = {
    'manager_instances': int(os.environ['TERRAFORM_MANAGER_INSTANCES'] or '0'),
    'worker_instances': int(os.environ['TERRAFORM_WORKER_INSTANCES'] or '0'),
}

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

        if exit_code > 0:
            exit(exit_code)

        return exit_code

    call_terraform('plan')
    call_terraform('apply')
