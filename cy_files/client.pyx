cimport client_lib
from libc.stdlib cimport free

import multiprocessing
try:
    import queue
except ImportError:
    import Queue as queue
from multiprocessing.managers import SyncManager

cdef client_lib.node_t * cfl_list

PORTNUM = 5000
AUTHKEY = b'abc'
IP = '127.0.0.1'
NUM_BLOCKS = multiprocessing.cpu_count()/2 if multiprocessing.cpu_count() > 1 else 1 #3-4 ottimo su una macchina(4 core)
MAX_EMPTY_RECEIVED = 10

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

def factorizer_worker(job_q, result_q):
    """ A worker function to be launched in a separate process. Takes jobs from
        job_q - each job a list of numbers to factorize. When the job is done,
        the result is placed into result_q. Runs until job_q is empty.
    """
    result_dict = {}
    empty_received = 0
    while True:
        try:
            block = job_q.get_nowait() #bloccante
            #print('noexcept')
            read_id = 0
            for i in range(len(block)):
                if i % 2 == 0:
                    #print("\n")
                    #print(block[i])
                    read_id = block[i]
                else:
                    block[i] = call_c_CFL(block[i])
                    #print("\n")
                    #result_dict = {read_id: factorization}
                    #result_q.put(result_dict)
            result_q.put(block)
        except queue.Empty:
            #print('except')
            if job_q.empty():
                #print('except2')
                empty_received += 1
            if empty_received > MAX_EMPTY_RECEIVED:
                #print('except20')
                return
        #handling lost of reads
        except KeyboardInterrupt: #try to handle kill by user, try to factorize last taken block and only after return
            print('pressed CTRL+C, waiting for last block factorizations..')
            is_busy = True
            while is_busy: #if something went wrong and user continue to kill process, otherwise one time
                try:
                    while i < (len(block)):
                        if i % 2 == 0:
                            #print("\n")
                            #print(block[i])
                            read_id = block[i]
                        else:
                            block[i] = call_c_CFL(block[i])
                            #print("\n")
                            #result_dict = {read_id: factorization}
                            #result_q.put(result_dict)
                        i += 1
                    result_q.put(block)
                    is_busy = False
                except KeyboardInterrupt:
                    print('another CTRL+C, waiting for last block factorizations..')
            return


def mp_factorizer(shared_job_q, shared_result_q, nprocs):
    """ Split the work with jobs in shared_job_q and results in
        shared_result_q into several processes. Launch each process with
        factorizer_worker as the worker function, and wait until all are
        finished.
    """
    procs = []
    for i in range(nprocs):
        p = multiprocessing.Process(
                target=factorizer_worker,
                args=(shared_job_q, shared_result_q))
        procs.append(p)
        p.start()

    for p in procs:
        p.join()


def make_client_manager(ip, port, authkey):
    """ Create a manager for a client. This manager connects to a server on the
        given address and exposes the get_job_q and get_result_q methods for
        accessing the shared queues from the server.
        Return a manager object.
    """
    class ServerQueueManager(SyncManager):
        pass

    ServerQueueManager.register('get_job_q')
    ServerQueueManager.register('get_result_q')

    manager = ServerQueueManager(address=(ip, port), authkey=authkey)
    manager.connect()

    print('Client connected to %s:%s' % (ip, port))
    return manager


def runclient():
    manager = make_client_manager(IP, PORTNUM, AUTHKEY)
    job_q = manager.get_job_q()
    result_q = manager.get_result_q()
    mp_factorizer(job_q, result_q, NUM_BLOCKS) # num of blocks taken from queue


runclient()