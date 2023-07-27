#from enum import Enum

#class OP(Enum):
#  OR = 1
#  AND = 2

# Using readlines()

def file_to_list(path):
  file1 = open(path, 'r')
  Lines = file1.readlines()
  data = []  

  count = 0
  # Strips the newline character
  for line in Lines:
    try:
      data.append(int(line.strip(), base=16))
    except:
      continue
  return data

col_a = file_to_list('col_data_a.hex')
col_b = file_to_list('col_data_b.hex')

#print(col_a, len(col_a))
#print(col_b, len(col_b))

#print([hex(i) for i in col_a])
#print([hex(i) for i in col_b])


def operation(op, x, y):
  if (op == "OR"):
    return x | y

result = []
for i in range(len(col_a)):
  result.append(operation("OR", col_a[i], col_b[i]))

print("Result")
for r in [hex(i) for i in result]:
  print(r)
