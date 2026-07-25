import  json
import os

github_output = os.environ["GITHUB_OUTPUT"]
files_json = os.environ["CHANGED_FILES"]
files = json.loads(files_json)

matrix = []
seen = set()

for file in files:
  segments = file.split('/')
  service = segments[2]
  helm_file = segments[3]
  if helm_file in ["Chart.yaml", "values.yaml", "templates"]:
    environments = ["dev", "staging", "prod"]
  else:
    environments = [
      helm_file.removeprefix("values-").removesuffix(".yaml")
    ]
  for env in environments:
    key = (service, env)

    if key not in seen:
      seen.add(key)

      matrix.append({
        "service": service,
        "environment": env
      })

matrix_json = json.dumps(matrix)

with open(github_output, "a") as f:
    f.write(f"matrix={matrix_json}\n")
    