#!/usr/bin/python3
# this script converts XML jinja2 templates to XML files
# input parameters:
#   yaml-vars - YAML file containing variables to be substituted in XML files
#   xml-j2-input-directory - directory containing .xml.j2 input files
#   xml-output-directory - directory containing .xml output files
#   yaml-subtree - dot-delimited keys to drill down to where the vars are

import sys
import os
from sys import argv
import jinja2, yaml, json

NOTOK=1

def usage(msg):
    print('ERROR: ' + msg)
    print('usage: yaml_to_xml.py yaml-vars xml-j2-input-directory xml-output-directory yaml-subtree')
    sys.exit(NOTOK)

if len(argv) < 5:
    usage('not enough CLI parameters')

yamlPath = argv[1]
templateDir = argv[2]
outputDir = argv[3]
yamlSubtree = argv[4]

print('yaml input file is %s, template directory is %s, output directory is %s' %
        (yamlPath, templateDir, outputDir))
print('yaml subtree is %s' % yamlSubtree)

with open(yamlPath) as config:
    yamlConfig = yaml.load(config, Loader=yaml.FullLoader)
keys = yamlSubtree.split('.')
for k in keys:
    yamlConfig = yamlConfig[k]
print('parameter subtree:')
print(json.dumps(yamlConfig, indent=2))
print('')

jinjaEnv = jinja2.Environment(
                loader=jinja2.FileSystemLoader(templateDir))

templates = [ x for x in os.listdir(templateDir) if x.endswith('.xml.j2') ]
for t in templates:
    jTemplate = jinjaEnv.get_template(t)
    # perform the substitution of variables into the XML template
    output = jTemplate.render(the=yamlConfig)
    outFilePath = os.path.join(outputDir, t[:-3])
    with open(outFilePath, 'w') as ofile:


