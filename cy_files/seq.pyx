import datetime
cimport client_lib
from libc.stdlib cimport free

cdef client_lib.node_t * cfl_list

def call_c_CFL(str):
    cdef char *factorization_c
    cfl_list = client_lib.CFL(str)
    #client_lib.print_list_reverse(cfl_list)
    factorization_c = client_lib.list_to_string(cfl_list, 0)
    #free fact created by malloc in c function (need import module level from cpython.mem cimport PyMem_Free)
    try:
        factorization = <bytes> factorization_c
    finally:
        free(factorization_c)
    return factorization

filename = './fasta/results.txt'
fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
BLOCK_SIZE = 1
pos = fasta.tell()  # check file
row = fasta.readline()
if row == "" or row[0] != '>':
    print("Errore file fasta")
fasta.seek(pos)

mode = 'w' # make a new file if not
results = open(filename, mode)
results.write(datetime.datetime.now().ctime())
results.write("\n\n")

first = True
last_block_size = -1
part = ' '  #
while True:
    if part == ' ':  #first time#
        results.write(fasta.readline().rstrip())  #primo id su file
    #check reads and id
    part = ' '
    while part[0] != '>':  # or last_block_size is changed
        if first:
            read = fasta.readline().rstrip()
            first = False
        else:
            part = fasta.readline()
            if part == "":
                last_block_size = 10
                break
            elif part[0] == '>':
                #part su file fact su file
                fact = call_c_CFL(read)
                results.write(str(part) + '\n' + str(fact) + '\n\n')
                first = True
            else:
                read += part.rstrip()

    if last_block_size != -1:  # end for
        break

results.close()
fasta.close()
print('finito')
