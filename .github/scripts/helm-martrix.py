import  json
import os

github_output = os.environ["GITHUB_OUTPUT"]
files_json = os.environ["CHANGED_FILES"]
files = json.loads(files_json)

matrix = []

for file in files:
  segments = file.split('/')
  service = segments[2]
  values_file = segments[3]
  matrix.append({
      "service": service,
      "values_file": values_file
    })

matrix_json = json.dumps(matrix)

with open(github_output, "a") as f:
    f.write(f"matrix={matrix_json}\n")
    