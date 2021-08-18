from jinja2 import Template
from glob import glob
import re


# Get all the ShinyApps on the system

shinyapps = glob("/home/*/ShinyApps/*/")
pattern = re.compile(r'/home/(\w+)/ShinyApps/(\w+)')
applist = []
for app in shinyapps:
   appparts = pattern.findall(app)
   if appparts[0][1] != "log":
       applist.append({"user": appparts[0][0], "appname": appparts[0][1]})


with open('application.yml', 'r') as f:
    template = f.read()

# Apply to the application template

j2_template = Template(template)

print(j2_template.render(apps=applist))


