#!/usr/bin/python

# Copyright: (c) 2022, Anthonius Munthi <me@itstoni.com>
# License: MIT

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
    domain:
        description: The domain name
        required: true
        type: str
    target:
        description: Target domain name
        required: true
        type: str

'''

EXAMPLES = '''
# configure cname
- name: Ensure pihole cname configured
  pihole_cname:
    domain: pihole.itstoni.com
    target: server.lan
'''

import os
from collections import OrderedDict
from ansible.module_utils.basic import AnsibleModule

PIHOLE_CNAME_FILE='PIHOLE_CNAME_FILE'

class PiholeCname(object):
    def __init__(self, module):
        self.module = module
        self.debugmsg = []
        self.changed = False
        self.cnames = {}
        self.domain = ""
        self.target = ""
        self.cname_file = ""
        self.result = dict(
            changed=False,
            cnames={},
            msg=""
        )

    def run_present(self):
        self._vv('run present mode')

        # add new domain to file
        if self.domain not in self.cnames:
            self.changed = True
            self.cnames[self.domain] = self.target
            return

        # change target if domain already exists
        if self.cnames[self.domain] != self.target:
            self.changed = True
            self.cnames[self.domain] = self.target
            return


    def run_absent(self):
        self._vv('run absent mode')
        if self.domain in self.cnames and self.cnames[self.domain] == self.target:
            self.changed = True
            self.cnames.pop(self.domain)


    def write_cname_file(self):
        ordered = OrderedDict(sorted(self.cnames.items()))
        contents = []
        for domain, target in ordered.items():
            content = "cname=%s,%s" % (domain, target)
            contents.append(content)
        text = "\n".join(contents)

        self._vv("new cname config: \n" + text)
        # writing to
        if not self.module.check_mode:
            f = open(self.cname_file,'w')
            f.write(text)
            f.close()
            self._vv('cname file updated')


    def read_cname_file(self):
        if None == self.cname_file:
            self.module.fail_json(
                msg="Environment variables "+PIHOLE_CNAME_FILE+" should be configured",
            )

        self._vv('reading configuration from '+self.cname_file)

        file = open(self.cname_file, 'r+')
        contents = file.read().splitlines()
        file.close()

        for content in contents:
            content = content.replace('cname=', '')
            split = content.split(',')
            key = split[0]
            value = split[1]
            self.cnames[key] = value


    def run(self):
        self.domain = self.module.params['domain']
        self.target = self.module.params['target']
        self.state = self.module.params['state']
        self.cname_file = self.module.params['cname_file']

        self.read_cname_file()

        if 'absent' == self.state:
            self.run_absent()
        else:
            self.run_present()

        if self.changed:
            self.write_cname_file()

        if self.module._verbosity >= 2:
            self.result['debug'] = "\n".join((self.debugmsg))

        self.result['changed'] = self.changed
        return self.result

    def _vv(self,msg):
        self.debugmsg.append("{}".format(msg))

def main():
    module_args = dict(
        domain=dict(type='str', required=True),
        target=dict(type='str', required=True),
        cname_file=dict(type='str', required=True),
        state=dict(type=str,required=False,default='present',choices=['present', 'absent'])
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    cname = PiholeCname(module)
    result = cname.run()

    module.exit_json(**result)

    if module.check_mode:
        module.exit_json(**result)


if __name__ == '__main__':
    main()
