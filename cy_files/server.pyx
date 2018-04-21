import datetime, time
from multiprocessing import Queue, Process, Value
from multiprocessing.managers import SyncManager

PORTNUM = 5000
AUTHKEY = b'abc'
LOCALHOST = '127.0.0.1'
BLOCK_SIZE = 1000

def make_server_manager(port, authkey):
    """ Create a manager for the server, listening on the given port.
        Return a manager object with get_job_q and get_result_q methods.
    """
    job_q = Queue()
    result_q = Queue()

    # This is based on the examples in the official docs of multiprocessing.
    # get_{job|result}_q return synchronized proxies for the actual Queue
    # objects.
    class JobQueueManager(SyncManager): #can't picklable on windows
        pass

    JobQueueManager.register('get_job_q', callable=lambda: job_q)
    JobQueueManager.register('get_result_q', callable=lambda: result_q)

    manager = JobQueueManager(address=(LOCALHOST, PORTNUM), authkey=AUTHKEY)
    manager.start()
    print('Server started at port %s' % PORTNUM)
    return manager


def write_results(result_q, sent_blocks, last_block_size):
    time.sleep(2)
    # create results file
    filename = './fasta/results.txt'
    #import os
    #if os.path.exists(filename):
    #   mode = 'a' # append if already exists
    #else:
    mode = 'w' # make a new file if not
    results = open(filename, mode)
    results.write(datetime.datetime.now().ctime())
    results.write("\n\n")
    # Wait until all results are ready in shared_result_q
    numresults = 0

    while numresults < ((sent_blocks.value * BLOCK_SIZE) - last_block_size.value):
        # prende da coda_result id e fact e scrive su file
        #print(sent_blocks.value, BLOCK_SIZE, last_block_size.value, numresults)
        outdict = result_q.get()
        for read_id, fact in outdict.items():
            results.write(str(read_id) + '\n' + str(fact) + '\n\n')
        numresults += 1

    results.close()


def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

    fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
    #fasta = open('./fasta/example.fasta', 'r')
    from ctypes import c_int
    sent_blocks = Value(c_int, 0)
    last_block_size = Value(c_int, 0)

    pos = fasta.tell()  # check file
    row = fasta.readline()
    if row == "" or row[0] != '>':
        print("Errore file fasta")
        return
    fasta.seek(pos)

    #start result process: save factorizations to file
    p = Process(
        target=write_results,
        args=(shared_result_q, sent_blocks, last_block_size))
    p.start()

    first = True
    last_block_size.value = -1
    part = ' '#
    while True:
        if part == ' ': #first time#
            block = [fasta.readline().rstrip()]#
        else:
            block = [part.rstrip()] #every other block first id#
        for i in range(BLOCK_SIZE):
            #check reads and id, append them to block
            part = ' '
            while part[0] != '>': # or last_block_size.value is changed
                if first:
                    #block.append(fasta.readline().rstrip()) #append first id to block##
                    read = fasta.readline().rstrip()
                    first = False
                else:
                    #pos = fasta.tell()##
                    part = fasta.readline()
                    if part == "":
                        block.append(read)
                        last_block_size.value = i
                        break
                    elif part[0] == '>':
                        block.append(read)
                        if i < BLOCK_SIZE -1:#
                            block.append(part.rstrip())
                        #fasta.seek(pos)##
                        first = True
                    else:
                        read += part.rstrip()

            if last_block_size.value != -1: # end for
                break

        #invio a coda
        shared_job_q.put(block)
        sent_blocks.value += 1
        print('blocco ' + repr(sent_blocks.value) + ' inviato')
        if last_block_size.value != -1: # end while
            break
    fasta.close()

    p.join()
    # Sleep a bit before shutting down the server - to give clients time to
    # realize the job queue is empty and exit in an orderly way.
    time.sleep(2)
    print("shutting down...")
    manager.shutdown()

runserver()
