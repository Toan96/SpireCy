from multiprocessing import Queue
from multiprocessing.managers import SyncManager

import time

PORTNUM = 5000
AUTHKEY = b'abc'
LOCALHOST = '127.0.0.1'

"""
cdef extern from "../c_files/main.c":
    int main()

main()
"""

#crea coda  # problema su windows
def make_server_manager(port, authkey):
    """ Create a manager for the server, listening on the given port.
        Return a manager object with get_job_q and get_result_q methods.
    """
    job_q = Queue()
    result_q = Queue()

    # This is based on the examples in the official docs of multiprocessing.
    # get_{job|result}_q return synchronized proxies for the actual Queue
    # objects.
    class JobQueueManager(SyncManager):
        pass

    JobQueueManager.register('get_job_q', callable=lambda: job_q)
    JobQueueManager.register('get_result_q', callable=lambda: result_q)

    manager = JobQueueManager(address=(LOCALHOST, port), authkey=authkey)
    manager.start()
    print('Server started at port %s' % port)
    return manager

#crea server
def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

    block_size = 10
    fasta = open('./fasta/example.fasta', 'r')
    sent_blocks = 0
    while True:
        block = []
        pos = fasta.tell()
        if fasta.readline() == "":
            break
        fasta.seek(pos)
        for i in range(block_size):
            if i != 0:
                pos = fasta.tell()
                if fasta.readline() == "":
                    break
                fasta.seek(pos)
            block.append(fasta.readline().rstrip())
            block.append(fasta.readline().rstrip())
            # block.append(sent_blocks)

        #invio a coda
        shared_job_q.put(block)
        sent_blocks = sent_blocks + 1
        print('blocco ' + repr(sent_blocks) + ' inviato')
    fasta.close()

# ????
    # Wait until all results are ready in shared_result_q
    numresults = 0
    resultdict = {}
    while numresults < sent_blocks:
        outdict = shared_result_q.get()
        resultdict.update(outdict)
        numresults += len(outdict)

    # Sleep a bit before shutting down the server - to give clients time to
    # realize the job queue is empty and exit in an orderly way.
    time.sleep(2)
    print("shutting down...")
    manager.shutdown()

runserver()
