cdef extern from "../c_files/utils.h":

    struct node:
        char * factor
        node * next
    ctypedef node node_t

    void free_list(node_t *head)

    void print_list_reverse(node_t *node)



cdef extern from "../c_files/factorizations.h":

    int index_in_alphabet(char t, char typ_alphabet_list[])

    node_t *CFL(char word[])