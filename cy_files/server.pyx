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
TIME_SLEEP = 1
FINE_TO_SEND = 10


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


def make_file_path(dir_path_experiment, block_id):
    return dir_path_experiment + '/' + block_id + '/results_' + block_id + '.txt'


def write_results(result_q, sent_blocks_list, all_sent_list, dir_path_experiment, id_list):
    while result_q.empty():
        time.sleep(TIME_SLEEP)
    opened_file_list = [] #tiene traccia dei file in cui sono gia' stati salvati risultati
    file_pointer_list = [None] * 2 #lista che contiene gli ultimi due file pointer utilizzati
    file_id_list = [None] * 2 #lista che contiene file id utilizzati
    fp_list_max_index = len(file_pointer_list) -1
    curr_res_index = fp_list_max_index #indice che corrisponde all'ultimo file pointer utilizzato
    num_result = []
    while sum(num_result) < sum(sent_blocks_list) or 0 in all_sent_list: #almeno un file non e' stato completamente inviato
        block = result_q.get()
        block_id = block[0].split('.')[0][1:]
        index_to_update = id_list.index(block_id)
        if block_id != file_id_list[curr_res_index]:
            curr_res_index = fp_list_max_index - curr_res_index #uso l'altro file pointer (utilizzato meno recentemente)
            if block_id != file_id_list[curr_res_index]:
                file_path = make_file_path(dir_path_experiment, block_id)
                if block_id in opened_file_list:
                    file_pointer_list[curr_res_index] = open(file_path, 'a')
                    file_id_list[curr_res_index] = block_id
                else:
                    file_pointer_list[curr_res_index] = open(file_path, 'w')
                    file_pointer_list[curr_res_index].write(datetime.datetime.now().ctime())
                    file_pointer_list[curr_res_index].write("\n\n")
                    print('inizio salvataggio risultati fasta ' + block_id)
                    file_id_list[curr_res_index] = block_id
                    opened_file_list.append(block_id)
                    for i in range(index_to_update): #inizializza elementi precedenti lista
                        try:
                            if num_result[i] >= 0: #se elemento lista gia' stato inizializzato
                                continue
                        except IndexError:
                            num_result.insert(i, 0)
                    num_result.insert(index_to_update, 0)
        for i in range(len(block)):
            if i % 2 == 0:
                file_pointer_list[curr_res_index].write(block[i] + '\n')
            else:
                file_pointer_list[curr_res_index].write(block[i] + '\n\n')
        num_result[index_to_update] += 1
        if num_result[index_to_update] >= sent_blocks_list[index_to_update] and all_sent_list[index_to_update] == 1:
            print('risultati salvati fasta ' + block_id)
            file_pointer_list[curr_res_index].close()
    print('tutti i risultati sono stati salvati sui rispettivi file')


def runserver():
    # Start a shared manager server and access its queues
    manager = make_server_manager(PORTNUM, AUTHKEY)
    shared_job_q = manager.get_job_q()
    shared_result_q = manager.get_result_q()

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
        args=(shared_result_q, sent_blocks_list, all_sent_list, dir_path_experiment, id_list)) #last_block_size se necessario
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
