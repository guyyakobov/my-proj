import  json

files_json = os.getenv("CHANGED_FILES_JSON", "[]")
changed_files = json.loads(files_json)

matrix=[]

for file  in changed_files:
  segments = file.split('/')
  entry = {
    "service": segments[2],
    "values-file": segments[3]
  }
  matrix.append(entry)

matrix_json = json.dumps(matrix)