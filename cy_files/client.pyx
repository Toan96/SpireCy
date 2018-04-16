cimport client_lib

import multiprocessing
try:
    import queue
except ImportError:
    import Queue as queue
from multiprocessing.managers import SyncManager

cdef client_lib.node_t * cfl_list

def call_c_CFL(str):
    cfl_list = client_lib.CFL(str)
    client_lib.print_list_reverse(cfl_list)
    client_lib.free_list(cfl_list)


PORTNUM = 5000
AUTHKEY = b'abc'
IP = '127.0.0.1'

def factorizer_worker(job_q, result_q):
    """ A worker function to be launched in a separate process. Takes jobs from
        job_q - each job a list of numbers to factorize. When the job is done,
        the result (dict mapping number -> list of factors) is placed into
        result_q. Runs until job_q is empty.
    """
    """
    while True:
        try:
            job = job_q.get_nowait()
            outdict = {n: factorize_naive(n) for n in job}
            result_q.put(outdict)
        except queue.Empty:
            return
    """
    block = job_q.get_nowait() # oppure bloccante
    call_c_CFL(block[1])


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
    mp_factorizer(job_q, result_q, 1) # num of blocks taken from queue


runclient()