import sys
import os
import jinja2

env = {k: v
    for k, v in os.environ.items()}

jenv = jinja2.Environment(loader=jinja2.FileSystemLoader('/opt/jinja-templates/'))

def gen_cfg(tmpl, target):
    print("Generating {} from template {}".format(target, tmpl))
    cfg = jenv.get_template(tmpl).render(env)
    with open(target, 'w') as fd:
        fd.write(cfg)