import datetime, time, os
from multiprocessing import Process, Value, Lock
try:
    from multiprocessing import Queue
except ImportError:
    from multiprocessing import queue as Queue
from multiprocessing.managers import SyncManager

from ctypes import c_int

DIR_PATH_EXPERIMENT = '/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001'
PORTNUM = 5000
AUTHKEY = b'abc'
LOCALHOST = '' #localhost ma visibile anche dall'esterno
BLOCK_SIZE = 1000
MAX_DIFFERENT_FASTA = 5
MAX_LIST_SIZE = 500
TIME_SLEEP = 1
FINE_TO_SEND = 10

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
    class JobQueueManager(SyncManager): #not picklable on windows
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

    wrong_blocks = [] #usato per mantenere blocchi di file successivi
    slow_count = 0 #usato per tenere traccia di possibili blocchi persi
    list_runs = os.listdir(dir_path_experiment)
    file_number = 0
    num_results_list = [] #lista di liste(file, num risultati per file) per mantenere corrispondenza
    for run in list_runs:
        #sleep finche' non e' iniziato l'invio dei blocchi del corrispondente file
        while len(id_list) <= file_number:
            time.sleep(TIME_SLEEP)
        #serve solo quando limitiamo
        if id_list[file_number] == 'fine':
            break
        path = dir_path_experiment + '/' + id_list[file_number]
        filename = '/results_' + id_list[file_number] + '.txt'
        mode = 'w' # make a new file if not
        results = open(path + filename, mode)
        results.write(datetime.datetime.now().ctime())
        results.write("\n\n")
        # Wait until all results are ready in shared_result_q
        num_results_list.insert(file_number, [run, 0])
        first = True #usato per tenere traccia di inizio salvataggio
        prev_results = None
        for block in wrong_blocks:
            block_id = block[0].split('.')[0][1:]
            #elimino dalla lista i blocchi del file aperto in questa iterazione (se aggiunti in precedenza)
            if block_id == id_list[file_number]:
                if first:
                    print('inizio salvataggio risultati fasta ' + id_list[file_number])
                    first = False
                for i in range(len(block)):
                    if i % 2 == 0:
                        results.write(block[i] + '\n')
                    else:
                        results.write(block[i] + '\n\n')
                num_results_list[file_number][1] += 1
            #elimino dalla lista i blocchi di iterazioni precedenti e li scrivo su rispettivi file
            else:
                index_of_file_block = next((x for x in num_results_list if x[0] == block_id), None)
                if index_of_file_block is None: #blocco preso si riferisce a iterazioni successive
                    continue
                index_of_file = num_results_list.index(index_of_file_block)
                if prev_results is None or prev_results.name != '/results_' + block_id + '.txt': #se stesso file continuo altrimenti chiudo e apro file corretto
                    #prev_results.close() #dovrebbe essere fatto automaticamente riassegnando
                    prev_results = open(dir_path_experiment + '/' + block_id + '/results_' + block_id + '.txt', 'a')
                for i in range(len(block)):
                    if i % 2 == 0:
                        prev_results.write(block[i] + '\n')
                    else:
                        prev_results.write(block[i] + '\n\n')
                num_results_list[index_of_file][1] += 1
                if num_results_list[index_of_file][1] >= sent_blocks_list[index_of_file] and all_sent_list[index_of_file] == 1: #non dovrebbe essere mai >
                    print('risultati salvati fasta ' + id_list[index_of_file])
                    different_fasta_in_queue.decrement()
            wrong_blocks.remove(block)
        if prev_results is not None:
            prev_results.close()

        #numresults inizia da 0 quindi <
        while num_results_list[file_number][1] < sent_blocks_list[file_number] or all_sent_list[file_number] != 1: #((sent_blocks * BLOCK_SIZE) - (BLOCK_SIZE - last_block_size)):# o all_sent != 1:
            # prende da coda_result id e fact e scrive su file
            if result_q.empty(): #per evitare di bloccarsi con la get quando la coda e' vuota all'ultima iterazione e i blocchi sono gia stati aggiunti alla lista wrong
                break
            res_block = result_q.get() #bloccante
            if different_fasta_in_queue.value() > 1: #probabilmente ci sono blocchi di file diversi nelle code
                #scriviamo su file se blocco corretto (continue) altrimenti si aggiunge a lista blocchi e salvato su file a iterazioni successive
                if res_block[0].split('.')[0] != ('>' + id_list[file_number]):
                    wrong_blocks.append(res_block)
                    #print('\n\nblocco (primo id' + res_block[0] + ') aggiunto a lista_wrong (ora ' + repr(len(wrong_blocks)) + ' elementi)' + ', sto cercando ' + id_list[file_number] + '\n')
                    if len(wrong_blocks) > MAX_LIST_SIZE:
                        #print('\n\nlista wrong molto grande, e\' possibile che si sia verificata una perdita di blocchi o un rallentamento in un client connesso\n')
                        print('possibile rallentamento di un client, passo al salvataggio dei risultati successivi')
                        slow_count += 1
                        break
                    continue
            if first:
                print('inizio salvataggio risultati fasta ' + id_list[file_number])
                first = False
            for i in range(len(res_block)):
                if i % 2 == 0:
                    results.write(res_block[i] + '\n')
                else:
                    results.write(res_block[i] + '\n\n')
            num_results_list[file_number][1] += 1
        if num_results_list[file_number][1] >= sent_blocks_list[file_number] and all_sent_list[file_number] == 1: #non dovrebbe essere mai >
            print('risultati salvati fasta ' + id_list[file_number])
            different_fasta_in_queue.decrement()
        file_number += 1
        results.close() #to do: close if ctrl+c
    prev_results = None
    while len(wrong_blocks) > 0:
        block = wrong_blocks[0]
        block_id = block[0].split('.')[0][1:]
        #elimino dalla lista i blocchi di iterazioni precedenti e li scrivo su rispettivi file
        index_of_file_block = next((x for x in num_results_list if x[0] == block_id), None)
        if index_of_file_block is None: #dovrebbe esserci sicuramente quindi controllo inutie
            continue
        index_of_file = num_results_list.index(index_of_file_block)
        if prev_results is None or prev_results.name != '/results_' + block_id + '.txt': #se stesso file continuo altrimenti chiudo e apro file corretto
            #prev_results.close() #dovrebbe essere fatto automaticamente riassegnando
            prev_results = open(dir_path_experiment + '/' + block_id + '/results_' + block_id + '.txt', 'a')
        for i in range(len(block)):
            if i % 2 == 0:
                prev_results.write(block[i] + '\n')
            else:
                prev_results.write(block[i] + '\n\n')
        num_results_list[index_of_file][1] += 1
        if num_results_list[index_of_file][1] >= sent_blocks_list[index_of_file] and all_sent_list[index_of_file] == 1: #non dovrebbe essere mai >
            print('risultati salvati fasta ' + id_list[index_of_file])
            different_fasta_in_queue.decrement()
        wrong_blocks.remove(block)
    if prev_results is not None:
        prev_results.close()
    if len(wrong_blocks) > 0:
        print('numero blocchi non salvati = ' + repr(len(wrong_blocks)) + ',\npossibile perdita di blocchi (' + repr(slow_count) + ')\n\n')


def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

    different_fasta_in_queue = Counter(0) #indica numero di fasta aperti(possibile presenza di blocchi di fasta diversi in code)

    #fasta = open('./fasta/example.fasta', 'r')
    #fasta = open('/mnt/c/Users/Antonio/Documents/SAMPLES/SRP000001/SRR000001/SRR000001.fasta', 'r')
    dir_path_experiment = DIR_PATH_EXPERIMENT
    list_runs = os.listdir(dir_path_experiment)
    sent_blocks_list = manager.list()
    #last_block_size_list = []
    all_sent_list = manager.list()
    id_list = manager.list()

    #start result process: factorizations to file
    p = Process(
        target=write_results,
        args=(shared_result_q, sent_blocks_list, all_sent_list, dir_path_experiment, different_fasta_in_queue, id_list)) #last_block_size se necessario
    p.start()
    file_number = 0
    for run in list_runs:
        #serve a limitare file analizzati
        if file_number == 5:
           break
        sent_blocks_list.insert(file_number, 0)
        last_block_size = -1 #non piu' utilizzato (solo per uscire da cicli)
        all_sent_list.insert(file_number, 0)
        id_list.append(run)
        run_path = dir_path_experiment + "/" + run
        list_fasta = os.listdir(run_path)
        list_fasta = [file for file in list_fasta if file.endswith('.fasta')]

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
            if part == ' ': #primo id letto
                block = [fasta.readline().rstrip()]#
            else:
                block = [part.rstrip()] #primo id letto per ogni altro blocco
            for i in range(BLOCK_SIZE):
                #check read e id, aggiunta al blocco
                part = ' '
                while part[0] != '>': # o last_block_size cambiato
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

        fasta.close() #to do: close fasta if ctrl+c is pressed
        all_sent_list[file_number] = 1 #true py
        file_number += 1
        print('blocchi inviati fasta ' + run)

    #serve solo quando limitiamo
    id_list.append('fine')
    print('tutti i file fasta sono stati inviati, in attesa dei risultati..')

    #invio blocchi sentinella per terminare client
    for i in range(FINE_TO_SEND):
        shared_job_q.put('fine')

    # se il server non si spegne alcune read sono andate perdute e il processo resta in attesa
    p.join()

    # Sleep a bit before shutting down the server - to give clients time to
    # realize the job queue is empty and exit in an orderly way.
    time.sleep(TIME_SLEEP) #tempo per client di ricevere blocchi fine e chiudersi
    print("shutting down...")
    manager.shutdown()


runserver()
