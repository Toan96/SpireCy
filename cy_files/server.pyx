import datetime, time, os
from multiprocessing import Process, Value, Lock
try:
    from multiprocessing import Queue
except ImportError:
    from multiprocessing import queue as Queue
from multiprocessing.managers import SyncManager

from ctypes import c_int

PORTNUM = 5000
AUTHKEY = b'abc'
LOCALHOST = '127.0.0.1'
BLOCK_SIZE = 1000
MAX_DIFFERENT_FASTA = 5
TIME_SLEEP = 1

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


def write_results(result_q, sent_blocks_list, all_sent_list, dir_path_experiment, different_fasta_in_queue, id_list):
    while result_q.empty():
        time.sleep(TIME_SLEEP)

    wrong_blocks = []
    list_runs = os.listdir(dir_path_experiment)
    file_number = 0
    for run in list_runs:
        while len(id_list) <= 0:
            time.sleep(TIME_SLEEP)
        path = dir_path_experiment + '/' + id_list[file_number]
        filename = '/results_' + id_list[file_number] + '.txt'
        mode = 'w' # make a new file if not
        results = open(path + filename, mode)
        results.write(datetime.datetime.now().ctime())
        results.write("\n\n")
        # Wait until all results are ready in shared_result_q
        numresults = 0

        for block in wrong_blocks:
            if block[0].split('.')[0] == ('>' + id_list[file_number]):
                for i in range(len(res_block)):
                    if i % 2 == 0:
                        results.write(res_block[i] + '\n')
                    else:
                        results.write(res_block[i] + '\n\n')
                numresults += 1
                wrong_blocks.remove(block)

        first = True
        #numresults inizia da 0 quindi <
        while numresults < sent_blocks_list[file_number] or all_sent_list[file_number] != 1: #((sent_blocks.value * BLOCK_SIZE) - (BLOCK_SIZE - last_block_size.value)):# or all_sent.value != 1:
            # prende da coda_result id e fact e scrive su file
            res_block = result_q.get() #bloccante
            if different_fasta_in_queue.value() > 1: #probabilmente ci sono blocchi di file diversi nelle code
                if res_block[0].split('.')[0] != ('>' + id_list[file_number]):
                    wrong_blocks.append(res_block)
                    continue
            #scriviamo su file se blocco corretto altrimenti in lista blocchi e salvati su file a iterazioni successive

            if first:
                print('inizio salvataggio risultati fasta ' + id_list[file_number])
                first = False

            #results.write(str(read_id) + '\n' + str(fact) + '\n\n')
            for i in range(len(res_block)):
                if i % 2 == 0:
                    results.write(res_block[i] + '\n')
                else:
                    results.write(res_block[i] + '\n\n')
            numresults += 1

        print('risultati salvati fasta ' + id_list[file_number])
        #del id_list[0]
        #del sent_blocks_list[0]
        #del all_sent_list[0]
        file_number += 1
        different_fasta_in_queue.decrement()
        results.close() #close if ctrl+c
    if len(wrong_blocks) > 0:
        print('list wrong blocks len = ' + repr(len(wrong_blocks)))


def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

    different_fasta_in_queue = Counter(0) #indicates possible blocks of different fasta(indicates number of fasta)

    #fasta = open('./fasta/example.fasta', 'r')
    #fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
    dir_path_experiment = '/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001'
    list_runs = os.listdir(dir_path_experiment)
    sent_blocks_list = manager.list()
    #last_block_size_list = []
    all_sent_list = manager.list()
    id_list = manager.list()

    #start result process: save factorizations to file
    p = Process(
        target=write_results,
        args=(shared_result_q, sent_blocks_list, all_sent_list, dir_path_experiment, different_fasta_in_queue, id_list)) #last_block_size if needed
    p.start()
    file_number = 0
    for run in list_runs:
        #sent_blocks = Value(c_int, 0)
        sent_blocks_list.insert(file_number, 0)
        #last_block_size = Value(c_int, 0)
        last_block_size = -1
        #all_sent = Value(c_int, 0) #false py
        all_sent_list.insert(file_number, 0)
        id_list.append(run)
        run_path = dir_path_experiment + "/" + run
        list_fasta = os.listdir(run_path)
        list_fasta = [file for file in list_fasta if file.endswith('.fasta')]
        #print(list_fasta)

        if len(list_fasta) == 0: #or len(list_fasta) > 1:
            print("La directory deve contenere un file .fasta")
            return

        fasta = open(run_path + "/" + list_fasta[0], 'r')

        pos = fasta.tell()  # check file
        row = fasta.readline()
        if row == "" or row[0] != '>':
            print("Errore file fasta")
            return
        fasta.seek(pos)

        while different_fasta_in_queue.value() >= MAX_DIFFERENT_FASTA: #numero di file aperti e non fattorizzati
            time.sleep(TIME_SLEEP)
        different_fasta_in_queue.increment()

        first = True
        part = ' '
        print('inizio invio blocchi fasta ' + run)
        while True:
            if part == ' ': #first time
                block = [fasta.readline().rstrip()]#
            else:
                block = [part.rstrip()] #every other block first id
            for i in range(BLOCK_SIZE):
                #check reads and id, append them to block
                part = ' '
                while part[0] != '>': # or last_block_size.value is changed
                    if first:
                        read = fasta.readline().rstrip()
                        first = False
                    else:
                        part = fasta.readline()
                        if part == "":
                            block.append(read)
                            last_block_size = i
                            break
                        elif part[0] == '>':
                            block.append(read)
                            if i < BLOCK_SIZE -1:
                                block.append(part.rstrip())
                            first = True
                        else:
                            read += part.rstrip()

                if last_block_size != -1: # end for
                    break

            #invio a coda
            shared_job_q.put(block)
            sent_blocks_list[file_number] += 1
            if last_block_size != -1: # end while
                break

        fasta.close() #close fasta if ctrl+c is pressed
        all_sent_list[file_number] = 1 #true py
        file_number += 1
        print('blocchi inviati fasta in ' + run)

    print('tutti i file fasta sono stati inviati, in attesa dei risultati..')

    #to kill client
    for i in range(10):
        shared_job_q.put('fine')

    # se il server non si spegne alcune read sono andate perdute e i processi restano in attesa
    p.join()

    # Sleep a bit before shutting down the server - to give clients time to
    # realize the job queue is empty and exit in an orderly way.
    #time.sleep(2) #non necessario il join dà tempo ai client
    print("shutting down...")
    manager.shutdown()


runserver()
