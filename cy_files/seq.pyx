import datetime, os

cimport client_lib
from libc.stdlib cimport free

cdef client_lib.node_t * cfl_list

def call_c_CFL(str):
    cdef char *factorization_c
    cfl_list = client_lib.CFL(str)
    #client_lib.print_list_reverse(cfl_list)
    factorization_c = client_lib.list_to_string(cfl_list, 0)
    #free fact created by malloc in c function (other free need import module level from cpython.mem cimport PyMem_Free)
    try:
        factorization = <bytes> factorization_c
    finally:
        free(factorization_c)
    return factorization


def call_c_CFL_icfl(str, c):
    cdef char *factorization_c
    cfl_list = client_lib.CFL_icfl(str, c)
    #client_lib.print_list_reverse(cfl_list)
    factorization_c = client_lib.list_to_string(cfl_list, 0)
    #free fact created by malloc in c function (other free need import module level from cpython.mem cimport PyMem_Free)
    try:
        factorization = <bytes> factorization_c
    finally:
        free(factorization_c)
    return factorization


def call_c_ICFL(str):
    cdef char *factorization_c
    cfl_list = client_lib.ICFL_recursive(str)
    #client_lib.print_list_reverse(cfl_list)
    factorization_c = client_lib.list_to_string(cfl_list, 1)
    #free fact created by malloc in c function (other free need import module level from cpython.mem cimport PyMem_Free)
    try:
        factorization = <bytes> factorization_c
    finally:
        free(factorization_c)
    return factorization


def call_c_ICFL_cfl(str, c):
    cdef char *factorization_c
    cfl_list = client_lib.ICFL_cfl(str, c)
    #client_lib.print_list_reverse(cfl_list)
    factorization_c = client_lib.list_to_string(cfl_list, 1)
    #free fact created by malloc in c function (other free need import module level from cpython.mem cimport PyMem_Free)
    try:
        factorization = <bytes> factorization_c
    finally:
        free(factorization_c)
    return factorization


C = 50
BLOCK_SIZE = 1
dir_path_experiment = '/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001'
#dir_path_experiment = '/home/spire/Scrivania/SAMPLES/SRP000001'
#dir_path_experiment = '/mnt/e/DATASET_BAM'
#dir_path_experiment = '/mnt/c/Users/Antonio/Desktop/DATASET_BAM'
#fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
#print("List of runs in " + str(dir_path_experiment))
list_runs = os.listdir(dir_path_experiment)
#per limitare file analizzati
#i = 0
for run in list_runs:
    #if i == 5: #numero file da analizzare
    #   break
    run_path = dir_path_experiment + "/" + run
    #test_factorizations_run_by_fasta(run_path)
    list_fasta = os.listdir(run_path)
    list_fasta = [file for file in list_fasta if file.endswith('.fasta')]
    #print(list_fasta)

    if len(list_fasta) == 0:#or len(list_fasta) > 1:
        print("La directory deve contenere un file .fasta")
        continue

    fasta = open(run_path + "/" + list_fasta[0], 'r')
    pos = fasta.tell()  # check file
    row = fasta.readline()
    if row == "" or row[0] != '>':
        print("Errore file fasta")
    fasta.seek(pos)

    filename = '/results_' + run + '.txt'
    mode = 'w' # make a new file if not
    results = open(run_path + filename, mode)
    #results.write(datetime.datetime.now().ctime())
    #results.write("\n\n")

    first = True
    last_block_size = -1
    part = ' '  #
    #j = 1
    while True:
        if part == ' ':  #first time#
            results.write(fasta.readline().rstrip() + '\n')  #primo id su file
        #check read e id
        part = ' '
        while part[0] != '>':  # o last_block_size cambiato
            if first:
                read = fasta.readline().rstrip()
                first = False
            else:
                part = fasta.readline().rstrip()
                if part == "":
                    fact = call_c_CFL(read)
                    results.write(str(fact))
                    last_block_size = 10
                    break
                elif part[0] == '>':
                    #part(id) su file e fact su file
                    fact = call_c_CFL(read)
                    #print j
                    #j+=1
                    results.write(str(fact) + '\n' + str(part) + '\n')
                    first = True
                else:
                    read += part.rstrip()

        if last_block_size != -1:  # end for
            break
    #i += 1
    results.close()
    fasta.close()
    print('finito fasta ' + run)
print('finito')
