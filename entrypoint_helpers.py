import sys
import os
import logging
import jinja2 as j2
import re

env = {k: v
    for k, v in os.environ.items()}

jenv = j2.Environment(loader=j2.FileSystemLoader('/opt/jinja-templates/'))

def gen_cfg(tmpl, target):
    print "Generating {} from template {}".format(target, tmpl)
    cfg = jenv.get_template(tmpl).render(env)
    with open(target, 'w') as fd:
        fd.write(cfg)

def set_props(props, target):
    try:
        with open(target, 'r') as f:
            input = f.read()
    except IOError:
       input = ''
    tmpInput = input.splitlines()
    output = []
    for k, v in props.items():
        print "Setting {}={} in {}".format(k, v, target)
        key_found = False
        if output:
            tmpInput = output
            output = []
        for line in tmpInput:
            m = re.search(r'^\s*([^=\s]+)\s*=\s*([^=\s]+)?\s*$', line)
            if m and m.group(1) == k:
                key_found = True
                if m.group(2) == v:
                    output.append(line)
                else:
                    output.append("{}={}".format(k,v))
            else:
                output.append(line)
        if not key_found:
            output.append("{}={}".format(k,v))    
    with open(target,'w') as f:
        f.write('\n'.join(output))