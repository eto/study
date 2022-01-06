# file handling

# 1) without using with statement
file = open('t1.txt', 'w')
file.write('hello world !')
file.close()

# 2) without using with statement
file = open('t2.txt', 'w')
try:
    file.write('hello world')
finally:
    file.close()

# 3) using with statement
with open('t3.txt', 'w') as file:
    file.write('hello world !')
