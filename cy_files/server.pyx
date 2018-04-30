import datetime, time, os
from multiprocessing import Queue, Process, Value, Lock
from multiprocessing.managers import SyncManager

from ctypes import c_int

PORTNUM = 5000
AUTHKEY = b'abc'
LOCALHOST = '127.0.0.1'
BLOCK_SIZE = 1000
MAX_DIFFERENT_FASTA = 2
TIME_SLEEP = 3

#used for synchronized shared counter for different fasta in queue
class Counter(object):
    def __init__(self, init_val=0):
        self.val = Value(c_int, init_val)
        self.lock = Lock()

    def increment(self):
        with self.lock:
            self.val.value += 1

    def decrement(self):
        with self.lock:
            self.val.value -= 1

    def value(self):
        with self.lock:
            return self.val.value


def make_server_manager(port, authkey):
    """ Create a manager for the server, listening on the given port.
        Return a manager object with get_job_q and get_result_q methods.
    """
    totalMemory = int(os.popen("free -m").readlines()[1].split()[3])
    #print(totalMemory)
    job_q = Queue(totalMemory/4) #1/4 della ram libera (considerando 1MB a blocco)
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


def write_results(result_q, sent_blocks, all_sent, run_path, different_fasta_in_queue, file_id):
    #time.sleep(2)
    # create results file
    filename = '/results.txt' #magari file_id
    #import os
    #if os.path.exists(filename):
    #   mode = 'a' # append if already exists
    #else:
    mode = 'w' # make a new file if not
    results = open(run_path + filename, mode)
    results.write(datetime.datetime.now().ctime())
    results.write("\n\n")
    # Wait until all results are ready in shared_result_q
    numresults = 0

    first = True
    #numresults inizia da 0 quindi <
    while numresults < sent_blocks.value or all_sent.value != 1: #((sent_blocks.value * BLOCK_SIZE) - (BLOCK_SIZE - last_block_size.value)):# or all_sent.value != 1:
        # prende da coda_result id e fact e scrive su file
        #print(sent_blocks.value, BLOCK_SIZE, last_block_size.value, numresults)
        res_block = result_q.get()
        if first:
            print('inizio salvataggio risultati fasta ' + file_id)
            first = False
        if different_fasta_in_queue.value > 1: #probabilmente ci sono blocchi di file diversi nelle code
            if res_block[0].split('.')[0] != file_id:
                #blocco non corretto
                print('blocco non corretto, dovrebbbe essere ' + file_id + 'ma ' + res_block[0].split('.')[0] + '\n')
                result_q.put(res_block)
                import random
                time.sleep(TIME_SLEEP)
                continue

        #for read_id, fact in outdict.items():
        #    results.write(str(read_id) + '\n' + str(fact) + '\n\n')
        for i in range(len(res_block)):
            if i % 2 == 0:
                results.write(res_block[i] + '\n')
            else:
                results.write(res_block[i] + '\n\n')
        numresults += 1 #under else if count reads
    different_fasta_in_queue.decrement()
    print('risultati salvati fasta ' + file_id)
    results.close() #close if ctrl+c


def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

    different_fasta_in_queue = Counter(0) #indicates possible blocks of different fasta(indicates number of fasta)

    #fasta = open('./fasta/example.fasta', 'r')
    #fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
    dir_path_experiment = '/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001'
    #print("List of runs in " + str(dir_path_experiment))
    list_runs = os.listdir(dir_path_experiment)
    res_procs = []
    #sent_blocks_list = []
    #last_block_size_list = []
    #all_sent_list = []
    for run in list_runs:
        sent_blocks = Value(c_int, 0)
        last_block_size = Value(c_int, 0)
        all_sent = Value(c_int, 0) #false py
        run_path = dir_path_experiment + "/" + run
        #test_factorizations_run_by_fasta(run_path)
        list_fasta = os.listdir(run_path)
        list_fasta = [file for file in list_fasta if file.endswith('.fasta')]
        #print(list_fasta)

        if len(list_fasta) == 0:#or len(list_fasta) > 1:
            print("La directory deve contenere un file .fasta")
            return

        fasta = open(run_path + "/" + list_fasta[0], 'r')

        pos = fasta.tell()  # check file
        row = fasta.readline()
        if row == "" or row[0] != '>':
            print("Errore file fasta")
            return
        fasta.seek(pos)

        while different_fasta_in_queue.value() >= MAX_DIFFERENT_FASTA: #3 file aperti e non fattorizzati
            time.sleep(TIME_SLEEP)
        different_fasta_in_queue.increment()

        #start result process: save factorizations to file
        p = Process(
            target=write_results,
            args=(shared_result_q, sent_blocks, all_sent, run_path, different_fasta_in_queue, row.split('.')[0])) #last_block_size if needed
        res_procs.append(p)
        p.start()

        first = True
        last_block_size.value = -1
        part = ' '#
        print('inizio invio blocchi fasta ' + run)
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
            #print('blocco ' + repr(sent_blocks.value) + ' inviato')
            if last_block_size.value != -1: # end while
                break
        fasta.close() #close fasta if ctrl+c is pressed
        all_sent.value = 1 #true py
        print('blocchi inviati fasta in ' + run)

    print('tutti i file fasta sono stati inviati, in attesa dei risultati..')

    # se il server non si spegne alcune read sono andate perdute e i processi restano in attesa
    for p in res_procs:
        p.join()

    # Sleep a bit before shutting down the server - to give clients time to
    # realize the job queue is empty and exit in an orderly way.
    #time.sleep(2) #non necessario il join dà tempo ai client
    print("shutting down...")
    manager.shutdown()


runserver()
