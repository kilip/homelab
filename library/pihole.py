from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['stable'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: pihole_cname
short_description: Module to configure pihole cname
version_added: "2.7"
description: |
    This module will configure pihole cname
options:
'''

# import os
import docker
# from collections import OrderedDict
from ansible.module_utils.basic import AnsibleModule

class Pihole(object):

    def __init__(self,module):
        self.module = module
        self.debugmsg = []
        self.changed = False
        self.result = dict(
            changed=False,
            cnames={},
            msg=""
        )


    def do_run(self):
        client = docker.from_env()
        for container in client.containers.list(True):
            self.vv(container.id)
        self.vv('hello world')


    def vv(self, msg):
        self.debugmsg.append("{}".format(msg))


    def run(self):
        self.do_run()

        self.result['changed'] = self.changed
        if self.module._verbosity >= 2:
            self.result['debug'] = "\n".join((self.debugmsg))

        return self.result


def main():
    module_args = dict(
        url=dict(type='str', required=True),
        token=dict(type='str', required=True)
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    pihole = Pihole(module)
    result = pihole.run()

    module.exit_json(**result)
    if module.check_mode:
        module.exit_json(**result)


if __name__ == '__main__':
    main()
