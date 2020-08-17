import yaml
import io

with io.open('inventory.yml', 'r') as file:
  data_loaded= yaml.load(file)

print(data == data_loaded)
