#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include <pthread.h>
#include "utils.h"
//#include "thpool.h"

int index_in_alphabet(char t, char typ_alphabet_list[]) {
    int i;
    for (i = 0; i < strlen(typ_alphabet_list); i++) {
        if (typ_alphabet_list[i] == t)
            return i;
    }
    return -1;
}

// ---------------------- CFL -----------------------------------------------------------------
// CFL - Lyndon factorization - Duval's algorithm
node_t *CFL(char word[]) {

    //CFL Duval's algorithm.

	node_t *current_pointer = NULL;

    int k = 0, i, j;
    int word_len = strlen(word);

    while (k < word_len) {
        i = k + 1;
        j = k + 2;
        while (1) {
            if (j == word_len + 1 || word[j - 1] < word[i - 1]) {
                while (k < i) {
                	node_t *node = (node_t *) malloc(sizeof(node_t));
                	node->factor = word;//substring(word, k, k + j - i);
                	node->next = current_pointer;
                	current_pointer = node;
                    k = k + j - i;
                }
                break;
            } else {
                if (word[j - 1] > word[i - 1]) {
                    i = k + 1;
                } else {
                    i = i + 1;
                }
                j = j + 1;
            }
        }
    }
    return current_pointer;
}
/*
// CFL - Lyndon factorization - Duval's algorithm - on a specific alphabet
node_t *CFL_for_alphabet(char word[], char list_alphabet[]) {

    //CFL Duval's algorithm.

	node_t *current_pointer = NULL;

    int k = 0, i, j;
    int word_len = strlen(word);

    while (k < word_len) {
        i = k + 1;
        j = k + 2;
        while (1) {
            if (j == word_len + 1 || index_in_alphabet(word[j - 1], list_alphabet) < index_in_alphabet(word[i - 1], list_alphabet)) {
                while (k < i) {
                	node_t *node = (node_t *) malloc(sizeof(node_t));
                	node->factor = substring(word, k, k + j - i);
                	node->next = current_pointer;
                	current_pointer = node;
                    k = k + j - i;
                }
                break;
            } else {
                if (index_in_alphabet(word[j - 1], list_alphabet) > index_in_alphabet(word[i - 1], list_alphabet)) {
                    i = k + 1;
                } else {
                    i = i + 1;
                }
                j = j + 1;
            }
        }
    }
    return current_pointer;
}

// ----------------------- ICFL ----------------------------------------------------------------------

//no empty string
//returns 2 factors as a list in first-last order
node_t *find_pre(char word[]) {

	int word_len = strlen(word);
	node_t *fact1 = NULL, *fact2 = NULL;

    if (word_len == 1) {

    	fact1 = (node_t *) malloc(sizeof(node_t));

		char *new_fact;
		new_fact = (char *) malloc(word_len + 2);
		int z;
		for (z = 0; z < word_len; z++){
			new_fact[z] = word[z];
		}
		new_fact[z] = '$';
		new_fact[z+1] = '\0';

		fact1->factor = new_fact;
		//strcat(fact1->factor, word);
		//strcat(fact1->factor, "$");

    	fact2 = (node_t *) malloc(sizeof(node_t));
    	fact2->factor = malloc(1);
    	strcpy(fact2->factor, "");
    	//fact2->factor = "";
    	fact2->next = NULL;

    	fact1->next = fact2;

        return fact1;

    } else {
        int i = 0, j = 1;

        while ((j < word_len) && (word[j] <= word[i])) {
            if (word[j] < word[i])
                i = 0;
            else
                i = i + 1;

            j = j + 1;
        }

        if (j == word_len) {

        	fact1 = (node_t *) malloc(sizeof(node_t));

        	char *new_fact;
        	new_fact = (char *) malloc(word_len + 2);
        	int z;
        	for (z = 0; z < word_len; z++){
        		new_fact[z] = word[z];
        	}
        	new_fact[z] = '$';
        	new_fact[z+1] = '\0';

        	fact1->factor = new_fact;
        	//strcat(fact1->factor, word);
        	//strcat(fact1->factor, "$");

			fact2 = (node_t *) malloc(sizeof(node_t));
			fact2->factor = malloc(1);
			strcpy(fact2->factor, "");
			//fact2->factor = "";
			fact2->next = NULL;

			fact1->next = fact2;

			return fact1;

        } else {

        	fact1 = (node_t *) malloc(sizeof(node_t));
        	fact1->factor = substring(word, 0, j + 1);

        	fact2 = (node_t *) malloc(sizeof(node_t));
        	fact2->factor = substring(word, j + 1, word_len);
        	fact2->next = NULL;

        	fact1->next = fact2;

            return fact1;
        }
    }
}

//returns 2 factors as a list in first-last order
node_t *find_pre_for_alphabet(char word[], char list_alphabet[]) {

	int word_len = strlen(word);
	node_t *fact1 = NULL, *fact2 = NULL;

    if (word_len == 1) {

    	fact1 = (node_t *) malloc(sizeof(node_t));

    	char *new_fact;
		new_fact = (char *) malloc(word_len + 2);
		int z;
		for (z = 0; z < word_len; z++){
			new_fact[z] = word[z];
		}
		new_fact[z] = '$';
		new_fact[z+1] = '\0';

		fact1->factor = new_fact;
		//strcat(fact1->factor, word);
		//strcat(fact1->factor, "$");

    	fact2 = (node_t *) malloc(sizeof(node_t));
    	fact2->factor = malloc(1);
		strcpy(fact2->factor, "");
		//fact2->factor = "";
    	fact2->next = NULL;

    	fact1->next = fact2;

        return fact1;

    } else {
        int i = 0, j = 1;

        while ((j < word_len) && (index_in_alphabet(word[j], list_alphabet) <= index_in_alphabet(word[i],list_alphabet))) {
            if (index_in_alphabet(word[j], list_alphabet) < index_in_alphabet(word[i],list_alphabet))
                i = 0;
            else
                i = i + 1;

            j = j + 1;
        }

        if (j == word_len) {

        	fact1 = (node_t *) malloc(sizeof(node_t));

        	char *new_fact;
			new_fact = (char *) malloc(word_len + 2);
			int z;
			for (z = 0; z < word_len; z++){
				new_fact[z] = word[z];
			}
			new_fact[z] = '$';
			new_fact[z+1] = '\0';

			fact1->factor = new_fact;
			//strcat(fact1->factor, word);
			//strcat(fact1->factor, "$");

			fact2 = (node_t *) malloc(sizeof(node_t));
			fact2->factor = malloc(1);
			strcpy(fact2->factor, "");
			//fact2->factor = "";
			fact2->next = NULL;

			fact1->next = fact2;

			return fact1;

        } else {

        	fact1 = (node_t *) malloc(sizeof(node_t));
        	fact1->factor = substring(word, 0, j + 1);

        	fact2 = (node_t *) malloc(sizeof(node_t));
        	fact2->factor = substring(word, j + 1, word_len);
        	fact2->next = NULL;

        	fact1->next = fact2;

            return fact1;
        }
    }
}

void border(char p[], int **pi) {
    int l = strlen(p);
    *pi = (int *) malloc(sizeof(int) * l);
    int k = 0;
    int i, j = 1;

    *(pi[0]) = 0;

    for (i = 1; i < l; i++) {
        while ((k > 0) && (p[k] != p[i])) {
        	k = (*pi)[k-1];
        }

        if (p[k] == p[i]) {
            k++;
        }
        (*pi)[j] = k;
        j++;
    }
}

//returns 3 factors and an index as a list in first-last order
node_t *find_bre(char *w, char *v) {

    node_t *fact1 = NULL, *fact2 = NULL, *fact3 = NULL, *last_index = NULL;

    if ((v[0] == '\0') && (strchr(w, '$') != NULL)) {

    	fact1 = (node_t *) malloc(sizeof(node_t));
    	fact2 = (node_t *) malloc(sizeof(node_t));
    	fact3 = (node_t *) malloc(sizeof(node_t));
    	last_index = (node_t *) malloc(sizeof(node_t));

    	fact1->factor = malloc(strlen(w) + 1);
    	strcpy(fact1->factor, w);
    	fact2->factor = malloc(1);
    	strcpy(fact2->factor, "");
		//fact2->factor = "";
    	fact3->factor = malloc(1);
		strcpy(fact3->factor, "");
		//fact3->factor = "";
		last_index->factor = malloc(2);
		strcpy(last_index->factor, "0");
    	//last_index->factor = "0";

    	last_index->next = NULL;
    	fact3->next = last_index;
    	fact2->next = fact3;
    	fact1->next = fact2;

    	return fact1;

    } else {
        int n = strlen(w) - 1;
        int *f = NULL;
        char *sub = substring(w, 0, n);
        border(sub, &f);

        int i = n;
        int last = f[i-1];

        while (i > 0) {
            if (w[f[i-1]] < w[n])
                last = f[i-1];
            i = f[i-1];
        }

        free(sub);
        free(f);

        fact1 = (node_t *) malloc(sizeof(node_t));
		fact2 = (node_t *) malloc(sizeof(node_t));
		fact3 = (node_t *) malloc(sizeof(node_t));

		//count digits in last
		i = last;
		int digit_count = 0;
		while(i != 0) {
		    i /= 10;
		    digit_count += 1;
		}

		last_index = (node_t *) malloc(sizeof(node_t));
		last_index->factor = (char *) malloc(digit_count + 1);

		fact1->factor = substring(w, 0, n - last);
		fact2->factor = substring(w, n - last, n + 1);
		fact3->factor = malloc(strlen(v) + 1);
		strcpy(fact3->factor, v);
		sprintf(last_index->factor, "%d", last);

		last_index->next = NULL;
		fact3->next = last_index;
		fact2->next = fact3;
		fact1->next = fact2;

		return fact1;
    }
}

//returns 3 factors and an index as a list in first-last order
node_t *find_bre_for_alphabet(char *w, char *v, char list_alphabet[]) {

    node_t *fact1 = NULL, *fact2 = NULL, *fact3 = NULL, *last_index = NULL;

    if ((v[0] == '\0') && (strchr(w, '$') != NULL)) {

    	fact1 = (node_t *) malloc(sizeof(node_t));
    	fact2 = (node_t *) malloc(sizeof(node_t));
    	fact3 = (node_t *) malloc(sizeof(node_t));
    	last_index = (node_t *) malloc(sizeof(node_t));

    	fact1->factor = malloc(strlen(w) + 1);
    	strcpy(fact1->factor, w);
    	fact2->factor = malloc(1);
    	strcpy(fact2->factor, "");
		//fact2->factor = "";
    	fact3->factor = malloc(1);
		strcpy(fact3->factor, "");
		//fact3->factor = "";
		last_index->factor = malloc(2);
		strcpy(last_index->factor, "0");
    	//last_index->factor = "0";

    	last_index->next = NULL;
    	fact3->next = last_index;
    	fact2->next = fact3;
    	fact1->next = fact2;

    	return fact1;

    } else {
        int n = strlen(w) - 1;
        int *f = NULL;
		char *sub = substring(w, 0, n);
		border(sub, &f);

        int i = n;
        int last = f[i-1];

        while (i > 0) {
            if (index_in_alphabet(w[f[i-1]], list_alphabet) < index_in_alphabet(w[n], list_alphabet))
                last = f[i-1];
            i = f[i-1];
        }

        free(sub);
        free(f);

        fact1 = (node_t *) malloc(sizeof(node_t));
		fact2 = (node_t *) malloc(sizeof(node_t));
		fact3 = (node_t *) malloc(sizeof(node_t));

		//count digits in last
		i = last;
		int digit_count = 0;
		while(i != 0) {
		    i /= 10;
		    digit_count += 1;
		}

		last_index = (node_t *) malloc(sizeof(node_t));
		last_index->factor = (char *) malloc(digit_count + 1);

		fact1->factor = substring(w, 0, n - last);
		fact2->factor = substring(w, n - last, n + 1);
		fact3->factor = malloc(strlen(v) + 1);
		strcpy(fact3->factor, v);
		sprintf(last_index->factor, "%d", last);

		last_index->next = NULL;
		fact3->next = last_index;
		fact2->next = fact3;
		fact1->next = fact2;

		return fact1;
    }
}

void compute_icfl_recursive(char word[], node_t **curr_pointer_icfl) {

    // At each step compute the current bre
    node_t *pre_pair = find_pre(word);
    char *fact1 = malloc(strlen(pre_pair->factor) + 1);
    char *fact2 = malloc(strlen(pre_pair->next->factor) + 1);
    strcpy(fact1, pre_pair->factor);
    strcpy(fact2, pre_pair->next->factor);
    node_t *current_bre_quad = find_bre(fact1, fact2);

    free(fact1);
    free(fact2);
    free_list(pre_pair);

    if ((current_bre_quad->next->factor[0] == '\0') && (strchr(current_bre_quad->factor, '$') != NULL)) {
        char *w = current_bre_quad->factor;
        node_t * icfl_node = (node_t *) malloc(sizeof(node_t));
        icfl_node->factor = substring(w, 0, strlen(w) - 1);

        if (*curr_pointer_icfl == NULL) {
        	 icfl_node->next = NULL;
        	 *curr_pointer_icfl = icfl_node;
        } else {
        	icfl_node->next = *curr_pointer_icfl;
        	*curr_pointer_icfl = icfl_node;
        }
        free_list(current_bre_quad);
        return;

    } else {
    	char *fact1_fact2 = (char *) malloc(strlen(current_bre_quad->next->factor) + strlen(current_bre_quad->next->next->factor) + 1);
    	fact1_fact2[0] = '\0';
    	strcat(fact1_fact2, current_bre_quad->next->factor);
    	strcat(fact1_fact2, current_bre_quad->next->next->factor);

        compute_icfl_recursive(fact1_fact2, curr_pointer_icfl);
        if (strlen((*curr_pointer_icfl)->factor) > atoi(current_bre_quad->next->next->next->factor)) {

        	node_t * icfl_node = (node_t *) malloc(sizeof(node_t));
        	icfl_node->factor = malloc(strlen(current_bre_quad->factor) + 1);
        	strcpy(icfl_node->factor, current_bre_quad->factor);

        	if (*curr_pointer_icfl == NULL) {
        		icfl_node->next = NULL;
        	    *curr_pointer_icfl = icfl_node;
        	} else {
        	    icfl_node->next = *curr_pointer_icfl;
        	    *curr_pointer_icfl = icfl_node;
        	}

        } else {
        	node_t *new_icfl_node = (node_t *) malloc(sizeof(node_t));
        	new_icfl_node->factor = malloc(strlen(current_bre_quad->factor) + 1);
        	strcpy(new_icfl_node->factor, current_bre_quad->factor);
        	//strcat(new_icfl_node->factor, current_bre_quad->factor);
        	strcat(new_icfl_node->factor, (*curr_pointer_icfl)->factor);
        	new_icfl_node->next = (*curr_pointer_icfl)->next;
        	(*curr_pointer_icfl)->next = NULL;
        	*curr_pointer_icfl = new_icfl_node;
        }
        free(fact1_fact2);
        free_list(current_bre_quad);
        return;
    }
}

//ICFL recursive (without using of compute_br)- Inverse Lyndon factorization - on a specific alphabet
void compute_icfl_recursive_for_alphabet(char word[], node_t **curr_pointer_icfl, char list_alphabet[]) {

    // At each step compute the current bre
    node_t *pre_pair = find_pre_for_alphabet(word, list_alphabet);
    char *fact1 = malloc(strlen(pre_pair->factor) + 1);
	char *fact2 = malloc(strlen(pre_pair->next->factor) + 1);
	strcpy(fact1, pre_pair->factor);
	strcpy(fact2, pre_pair->next->factor);
	node_t *current_bre_quad = find_bre_for_alphabet(fact1, fact2, list_alphabet);

	free(fact1);
	free(fact2);
    free_list(pre_pair);

    if ((current_bre_quad->next->factor[0] == '\0') && (strchr(current_bre_quad->factor, '$') != NULL)) {
        char *w = current_bre_quad->factor;
        node_t * icfl_node = (node_t *) malloc(sizeof(node_t));
        icfl_node->factor = substring(w, 0, strlen(w) - 1);

        if (*curr_pointer_icfl == NULL) {
        	 icfl_node->next = NULL;
        	 *curr_pointer_icfl = icfl_node;
        } else {
        	icfl_node->next = *curr_pointer_icfl;
        	*curr_pointer_icfl = icfl_node;
        }
        free_list(current_bre_quad);
        return;

    } else {
    	char *fact1_fact2 = (char *) malloc(strlen(current_bre_quad->next->factor) + strlen(current_bre_quad->next->next->factor) + 1);
    	fact1_fact2[0] = '\0';
    	strcat(fact1_fact2, current_bre_quad->next->factor);
    	strcat(fact1_fact2, current_bre_quad->next->next->factor);

        compute_icfl_recursive_for_alphabet(fact1_fact2, curr_pointer_icfl, list_alphabet);
        if (strlen((*curr_pointer_icfl)->factor) > atoi(current_bre_quad->next->next->next->factor)) {

        	node_t * icfl_node = (node_t *) malloc(sizeof(node_t));
        	icfl_node->factor = malloc(strlen(current_bre_quad->factor) + 1);
			strcpy(icfl_node->factor, current_bre_quad->factor);

        	if (*curr_pointer_icfl == NULL) {
        		icfl_node->next = NULL;
        	    *curr_pointer_icfl = icfl_node;
        	} else {
        	    icfl_node->next = *curr_pointer_icfl;
        	    *curr_pointer_icfl = icfl_node;
        	}

        } else {

        	node_t *new_icfl_node = (node_t *) malloc(sizeof(node_t));
        	new_icfl_node->factor = malloc(strlen(current_bre_quad->factor) + 1);
			strcpy(new_icfl_node->factor, current_bre_quad->factor);
        	//strcat(new_icfl_node->factor, current_bre_quad->factor);
        	strcat(new_icfl_node->factor, (*curr_pointer_icfl)->factor);
        	new_icfl_node->next = (*curr_pointer_icfl)->next;
        	(*curr_pointer_icfl)->next = NULL;
        	*curr_pointer_icfl = new_icfl_node;
        }
        free(fact1_fact2);
        free_list(current_bre_quad);
        return;
    }
}

//ICFL recursive (without using of compute_br)- Inverse Lyndon factorization
node_t *ICFL_recursive(char word[]) {
    //In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word

	node_t *curr_pointer_icfl = NULL;

    compute_icfl_recursive(word, &curr_pointer_icfl);

    return curr_pointer_icfl;
}

node_t *ICFL_recursive_for_alphabet(char word[], char list_alphabet[]) {
    //In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word

	node_t *curr_pointer_icfl = NULL;

    compute_icfl_recursive_for_alphabet(word, &curr_pointer_icfl, list_alphabet);

    return curr_pointer_icfl;
}

// ------------------------ CFL_icfl ---------------------------------------------------------------------
// CFL factorization - ICFL subdecomposition
node_t *CFL_icfl(char word[], int C) {
	node_t *CFL_list = NULL;
	int k = 0, i, j, word_len = strlen(word);
	char *w;

	while(k < word_len) {
		i = k + 1;
		j = k + 2;

		while(1) {
			if ((j == (word_len + 1)) || (word[j - 1] < word[i - 1])) {
				while (k < i) {
					w = substring(word, k, k + j - i);
					if (strlen(w) <= C) {
						node_t *cfl_node = (node_t *) malloc(sizeof(node_t));
						cfl_node->factor = malloc(strlen(w) + 1);
						strcpy(cfl_node->factor, w);
						cfl_node->next = CFL_list;
						CFL_list = cfl_node;
					} else {
						node_t *ICFL_list = ICFL_recursive(w);
						//Insert << to indicate the begin of the subdecomposition of w
						node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
						start_delimiter->factor = malloc(3);
						strcpy(start_delimiter->factor, "<<");
						start_delimiter->next = CFL_list;
						CFL_list = start_delimiter;

						while(ICFL_list != NULL) {
							node_t *tmp = ICFL_list;
							ICFL_list = ICFL_list->next;
							tmp->next = CFL_list;
							CFL_list = tmp;
						}

						//Insert << to indicate the begin of the subdecomposition of w
						node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
						end_delimiter->factor = malloc(3);
						strcpy(end_delimiter->factor, ">>");
						end_delimiter->next = CFL_list;
						CFL_list = end_delimiter;
					}
					k = k + j - i;
					free(w);
				}
				break;
			} else {
				if (word[j - 1] > word[i - 1]) {
					i = k + 1;
				}  else {
					i = i + 1;
				}
				j = j + 1;
			}
		}
	}
	return CFL_list;
}

node_t *CFL_icfl_for_alphabet(char word[], int C, char list_alphabet[]) {
	node_t *CFL_list = NULL;
	int k = 0, i, j, word_len = strlen(word);
	char *w;

	while(k < word_len) {
		i = k + 1;
		j = k + 2;

		while(1) {
			if ((j == (word_len + 1)) || (index_in_alphabet(word[j - 1], list_alphabet) < index_in_alphabet(word[i - 1], list_alphabet))) {
				while (k < i) {
					w = substring(word, k, k + j - i);
					if (strlen(w) <= C) {
						node_t *cfl_node = (node_t *) malloc(sizeof(node_t));
						cfl_node->factor = malloc(strlen(w) + 1);
						strcpy(cfl_node->factor, w);
						cfl_node->next = CFL_list;
						CFL_list = cfl_node;
					} else {
						node_t *ICFL_list = ICFL_recursive_for_alphabet(w, list_alphabet);
						//Insert << to indicate the begin of the subdecomposition of w
						node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
						start_delimiter->factor = malloc(3);
						strcpy(start_delimiter->factor, "<<");
						start_delimiter->next = CFL_list;
						CFL_list = start_delimiter;

						while(ICFL_list != NULL) {
							node_t *tmp = ICFL_list;
							ICFL_list = ICFL_list->next;
							tmp->next = CFL_list;
							CFL_list = tmp;
						}

						//Insert << to indicate the begin of the subdecomposition of w
						node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
						end_delimiter->factor = malloc(3);
						strcpy(end_delimiter->factor, ">>");
						end_delimiter->next = CFL_list;
						CFL_list = end_delimiter;
					}
					k = k + j - i;
					free(w);
				}
				break;
			} else {
				if (index_in_alphabet(word[j - 1],list_alphabet) > index_in_alphabet(word[i - 1],list_alphabet)) {
					i = k + 1;
				}  else {
					i = i + 1;
				}
				j = j + 1;
			}
		}
	}
	return CFL_list;
}

// --------------------------ICFL_cfl-------------------------------------------------------------------

//ICFL recursive factorization - CFL subdecomposition
node_t *ICFL_cfl(char word[], int C) {
	//In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word
	node_t *icfl_list = NULL;

	compute_icfl_recursive(word, &icfl_list);

	node_t *ICFL_cfl_list = NULL;
	node_t *track_pointer_ICFL_cfl = NULL;
	node_t *track_pointer_icfl = icfl_list;
	while (track_pointer_icfl != NULL) {
		if (strlen(track_pointer_icfl->factor) <= C) {
			if (ICFL_cfl_list == NULL) {
				ICFL_cfl_list = (node_t *) malloc(sizeof(node_t));
				ICFL_cfl_list->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(ICFL_cfl_list->factor, track_pointer_icfl->factor);
			    ICFL_cfl_list->next = NULL;
			    track_pointer_ICFL_cfl = ICFL_cfl_list;
			} else {
				node_t *new_node = (node_t *) malloc(sizeof(node_t));
				new_node->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(new_node->factor, track_pointer_icfl->factor);
				new_node->next = NULL;
				track_pointer_ICFL_cfl->next = new_node;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}
		} else {
			node_t *CFL_list = CFL(track_pointer_icfl->factor);
			//Insert << to indicate the begin of the subdecomposition of w
			node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
			start_delimiter->factor = malloc(3);
			strcpy(start_delimiter->factor, "<<");
			if (track_pointer_ICFL_cfl == NULL) {
				ICFL_cfl_list = start_delimiter;
				track_pointer_ICFL_cfl = start_delimiter;
			} else {
				track_pointer_ICFL_cfl->next = start_delimiter;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}

			//Insert << to indicate the begin of the subdecomposition of w
			node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
			end_delimiter->factor = malloc(3);
			strcpy(end_delimiter->factor, ">>");

			track_pointer_ICFL_cfl = end_delimiter;

			while(CFL_list->next != NULL) {
				node_t *tmp = CFL_list;
				CFL_list = CFL_list->next;
				tmp->next = end_delimiter;
				end_delimiter = tmp;
			}

			start_delimiter->next = CFL_list;
			CFL_list->next = end_delimiter;
		}
		track_pointer_icfl = track_pointer_icfl->next;
	}
	track_pointer_ICFL_cfl->next = NULL;
	free_list(icfl_list);
	return ICFL_cfl_list;
}

node_t *ICFL_cfl_for_alphabet(char word[], int C, char list_alphabet[]) {
	//In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word
	node_t *icfl_list = NULL;

	compute_icfl_recursive_for_alphabet(word, &icfl_list, list_alphabet);

	node_t *ICFL_cfl_list = NULL;
	node_t *track_pointer_ICFL_cfl = NULL;
	node_t *track_pointer_icfl = icfl_list;
	while (track_pointer_icfl != NULL) {
		if (strlen(track_pointer_icfl->factor) <= C) {
			if (ICFL_cfl_list == NULL) {
				ICFL_cfl_list = (node_t *) malloc(sizeof(node_t));
				ICFL_cfl_list->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(ICFL_cfl_list->factor, track_pointer_icfl->factor);
			    ICFL_cfl_list->next = NULL;
			    track_pointer_ICFL_cfl = ICFL_cfl_list;
			} else {
				node_t *new_node = (node_t *) malloc(sizeof(node_t));
				new_node->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(new_node->factor, track_pointer_icfl->factor);
				new_node->next = NULL;
				track_pointer_ICFL_cfl->next = new_node;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}
		} else {
			node_t *CFL_list = CFL_for_alphabet(track_pointer_icfl->factor, list_alphabet);
			//Insert << to indicate the begin of the subdecomposition of w
			node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
			start_delimiter->factor = malloc(3);
			strcpy(start_delimiter->factor, "<<");
			if (track_pointer_ICFL_cfl == NULL) {
				ICFL_cfl_list = start_delimiter;
				track_pointer_ICFL_cfl = start_delimiter;
			} else {
				track_pointer_ICFL_cfl->next = start_delimiter;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}

			//Insert << to indicate the begin of the subdecomposition of w
			node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
			end_delimiter->factor = malloc(3);
			strcpy(end_delimiter->factor, ">>");

			track_pointer_ICFL_cfl = end_delimiter;

			while(CFL_list->next != NULL) {
				node_t *tmp = CFL_list;
				CFL_list = CFL_list->next;
				tmp->next = end_delimiter;
				end_delimiter = tmp;
			}

			start_delimiter->next = CFL_list;
			CFL_list->next = end_delimiter;
		}
		track_pointer_icfl = track_pointer_icfl->next;
	}
	track_pointer_ICFL_cfl->next = NULL;
	free_list(icfl_list);
	return ICFL_cfl_list;
}
/*
//multithreading
// ------------------------ CFL_icfl ---------------------------------------------------------------------

//function executed by a thread in CFL_icfl factorization
void ICFL_thread(void *args) {
	params *parameters = (params *) args;
	node_t *ICFL_list;
	if (parameters->list_alphabet == NULL) {
		ICFL_list = ICFL_recursive(parameters->w);
	} else {
		ICFL_list = ICFL_recursive_for_alphabet(parameters->w, parameters->list_alphabet);
		free(parameters->list_alphabet);
	}

	while(ICFL_list != NULL) {
		node_t *tmp = ICFL_list;
		ICFL_list = ICFL_list->next;
		tmp->next = parameters->start_d;
		parameters->start_d = tmp;
	}

	parameters->end_d->next = parameters->start_d;

	//free list_alphabet in else
	free(parameters->w);
	free(parameters);

	return;
}

//function executed by a thread in ICFL_cfl factorization
void CFL_thread(void *args) {
	params *parameters = (params *) args;
	node_t *CFL_list;
	if (parameters->list_alphabet == NULL) {
		CFL_list = CFL(parameters->w);
	} else {
		CFL_list = CFL_for_alphabet(parameters->w, parameters->list_alphabet);
		free(parameters->list_alphabet);
	}

	while(CFL_list->next != NULL) {
		node_t *tmp = CFL_list;
		CFL_list = CFL_list->next;
		tmp->next = parameters->end_d;
		parameters->end_d = tmp;
	}

	parameters->start_d->next = CFL_list;
	CFL_list->next = parameters->end_d;

	//free list_alphabet in else
	free(parameters->w);
	free(parameters);

	return;
}

// CFL factorization - ICFL subdecomposition
node_t *CFL_icfl_multithread_pool(char word[], int C) {
	node_t *CFL_list = NULL;
	int k = 0, i, j, word_len = strlen(word);
	char *w;
	//node_thread *thread_list = NULL;

	while(k < word_len) {
		i = k + 1;
		j = k + 2;

		while(1) {
			if ((j == (word_len + 1)) || (word[j - 1] < word[i - 1])) {
				while (k < i) {
					w = substring(word, k, k + j - i);
					if (strlen(w) <= C) {
						node_t *cfl_node = (node_t *) malloc(sizeof(node_t));
						cfl_node->factor = malloc(strlen(w) + 1);
						strcpy(cfl_node->factor, w);
						cfl_node->next = CFL_list;
						CFL_list = cfl_node;
					} else {
						//Insert << to indicate the begin of the subdecomposition of w
						node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
						start_delimiter->factor = malloc(3);
						strcpy(start_delimiter->factor, "<<");
						start_delimiter->next = CFL_list;

						//Insert << to indicate the begin of the subdecomposition of w
						node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
						end_delimiter->factor = malloc(3);
						strcpy(end_delimiter->factor, ">>");
						CFL_list = end_delimiter;

						params *parameters = (params *) malloc(sizeof(params));
						parameters->w = (char *) malloc(strlen(w) + 1);
						strcpy(parameters->w, w);
						parameters->list_alphabet = NULL;
						parameters->start_d = start_delimiter;
						parameters->end_d = end_delimiter;
						/
						node_thread *new_thread = (node_thread *) malloc(sizeof(node_thread));
						new_thread->next = thread_list;
						thread_list = new_thread;
						 /
						//pthread_create(&new_thread->tid, NULL, ICFL_thread, (void *) parameters);
/						thpool_add_work(thpool, (void*) ICFL_thread, (void *) parameters);
					}
					k = k + j - i;
					free(w);
				}
				break;
			} else {
				if (word[j - 1] > word[i - 1]) {
					i = k + 1;
				}  else {
					i = i + 1;
				}
				j = j + 1;
			}
		}
	}
	thpool_wait(thpool);
	/
	void *t_ret;
	while (thread_list != NULL) {
		node_thread *tmp = thread_list;
		pthread_join(thread_list->tid, &t_ret);
		thread_list = thread_list->next;
		free(tmp);
	}
	/
/	return CFL_list;
}

node_t *CFL_icfl_for_alphabet_multithread_pool(char word[], int C, char list_alphabet[]) {
	node_t *CFL_list = NULL;
	int k = 0, i, j, word_len = strlen(word);
	char *w;
	//node_thread *thread_list = NULL;

	while(k < word_len) {
		i = k + 1;
		j = k + 2;

		while(1) {
			if ((j == (word_len + 1)) || (index_in_alphabet(word[j - 1], list_alphabet) < index_in_alphabet(word[i - 1], list_alphabet))) {
				while (k < i) {
					w = substring(word, k, k + j - i);
					if (strlen(w) <= C) {
						node_t *cfl_node = (node_t *) malloc(sizeof(node_t));
						cfl_node->factor = malloc(strlen(w) + 1);
						strcpy(cfl_node->factor, w);
						cfl_node->next = CFL_list;
						CFL_list = cfl_node;
					} else {
						//Insert << to indicate the begin of the subdecomposition of w
						node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
						start_delimiter->factor = malloc(3);
						strcpy(start_delimiter->factor, "<<");
						start_delimiter->next = CFL_list;

						//Insert << to indicate the begin of the subdecomposition of w
						node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
						end_delimiter->factor = malloc(3);
						strcpy(end_delimiter->factor, ">>");
						CFL_list = end_delimiter;

						params *parameters = (params *) malloc(sizeof(params));
						parameters->w = (char *) malloc(strlen(w) + 1);
						strcpy(parameters->w, w);
						parameters->list_alphabet = (char *) malloc(strlen(list_alphabet) + 1);
						strcpy(parameters->list_alphabet, list_alphabet);
						parameters->start_d = start_delimiter;
						parameters->end_d = end_delimiter;
						/
						node_thread *new_thread = (node_thread *) malloc(sizeof(node_thread));
						new_thread->next = thread_list;
						thread_list = new_thread;
						/
						//pthread_create(&new_thread->tid, NULL, ICFL_thread, (void *) parameters);
/						thpool_add_work(thpool, (void*) ICFL_thread, (void *) parameters);
					}
					k = k + j - i;
					free(w);
				}
				break;
			} else {
				if (index_in_alphabet(word[j - 1],list_alphabet) > index_in_alphabet(word[i - 1],list_alphabet)) {
					i = k + 1;
				}  else {
					i = i + 1;
				}
				j = j + 1;
			}
		}
	}
	thpool_wait(thpool);
	/
	void *t_ret;
	while (thread_list != NULL) {
		node_thread *tmp = thread_list;
		pthread_join(thread_list->tid, &t_ret);
		thread_list = thread_list->next;
		free(tmp);
	}
	/
/	return CFL_list;
}

//ICFL recursive factorization - CFL subdecomposition
node_t *ICFL_cfl_multithread_pool(char word[], int C) {
	//In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word
	node_t *icfl_list = NULL;
	//node_thread *thread_list = NULL;

	compute_icfl_recursive(word, &icfl_list);

	node_t *ICFL_cfl_list = NULL;
	node_t *track_pointer_ICFL_cfl = NULL;
	node_t *track_pointer_icfl = icfl_list;
	while (track_pointer_icfl != NULL) {
		if (strlen(track_pointer_icfl->factor) <= C) {
			if (ICFL_cfl_list == NULL) {
				ICFL_cfl_list = (node_t *) malloc(sizeof(node_t));
				ICFL_cfl_list->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(ICFL_cfl_list->factor, track_pointer_icfl->factor);
			    ICFL_cfl_list->next = NULL;
			    track_pointer_ICFL_cfl = ICFL_cfl_list;
			} else {
				node_t *new_node = (node_t *) malloc(sizeof(node_t));
				new_node->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(new_node->factor, track_pointer_icfl->factor);
				new_node->next = NULL;
				track_pointer_ICFL_cfl->next = new_node;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}
		} else {
			//Insert << to indicate the begin of the subdecomposition of w
			node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
			start_delimiter->factor = malloc(3);
			strcpy(start_delimiter->factor, "<<");

			if (track_pointer_ICFL_cfl == NULL) {
				ICFL_cfl_list = start_delimiter;
				track_pointer_ICFL_cfl = start_delimiter;
			} else {
				track_pointer_ICFL_cfl->next = start_delimiter;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}

			//Insert << to indicate the begin of the subdecomposition of w
			node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
			end_delimiter->factor = malloc(3);
			strcpy(end_delimiter->factor, ">>");

			track_pointer_ICFL_cfl = end_delimiter;

			params *parameters = (params *) malloc(sizeof(params));
			parameters->w = (char *) malloc(strlen(track_pointer_icfl->factor) + 1);
			strcpy(parameters->w, track_pointer_icfl->factor);
			parameters->list_alphabet = NULL;
			parameters->start_d = start_delimiter;
			parameters->end_d = end_delimiter;
			/
			node_thread *new_thread = (node_thread *) malloc(sizeof(node_thread));
			new_thread->next = thread_list;
			thread_list = new_thread;
			/
			//pthread_create(&new_thread->tid, NULL, CFL_thread, (void *) parameters);
/		thpool_add_work(thpool, (void*) CFL_thread, (void *) parameters);
		}
		track_pointer_icfl = track_pointer_icfl->next;
	}
	track_pointer_ICFL_cfl->next = NULL;
	free_list(icfl_list);
	thpool_wait(thpool);
	/
	void *t_ret;
	while (thread_list != NULL) {
		node_thread *tmp = thread_list;
		pthread_join(thread_list->tid, &t_ret);
		thread_list = thread_list->next;
		free(tmp);
	}
	/
/	return ICFL_cfl_list;
}

node_t *ICFL_cfl_for_alphabet_multithread_pool(char word[], int C, char list_alphabet[]) {
	//In this version of ICFL, we don't execute compute_br - one only O(n) scanning of word
	node_t *icfl_list = NULL;
	//node_thread *thread_list = NULL;

	compute_icfl_recursive_for_alphabet(word, &icfl_list, list_alphabet);

	node_t *ICFL_cfl_list = NULL;
	node_t *track_pointer_ICFL_cfl = NULL;
	node_t *track_pointer_icfl = icfl_list;
	while (track_pointer_icfl != NULL) {
		if (strlen(track_pointer_icfl->factor) <= C) {
			if (ICFL_cfl_list == NULL) {
				ICFL_cfl_list = (node_t *) malloc(sizeof(node_t));
				ICFL_cfl_list->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(ICFL_cfl_list->factor, track_pointer_icfl->factor);
			    ICFL_cfl_list->next = NULL;
			    track_pointer_ICFL_cfl = ICFL_cfl_list;
			} else {
				node_t *new_node = (node_t *) malloc(sizeof(node_t));
				new_node->factor = malloc(strlen(track_pointer_icfl->factor) + 1);
				strcpy(new_node->factor, track_pointer_icfl->factor);
				new_node->next = NULL;
				track_pointer_ICFL_cfl->next = new_node;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}
		} else {
			//Insert << to indicate the begin of the subdecomposition of w
			node_t *start_delimiter = (node_t *) malloc(sizeof(node_t));
			start_delimiter->factor = malloc(3);
			strcpy(start_delimiter->factor, "<<");

			if (track_pointer_ICFL_cfl == NULL) {
				ICFL_cfl_list = start_delimiter;
				track_pointer_ICFL_cfl = start_delimiter;
			} else {
				track_pointer_ICFL_cfl->next = start_delimiter;
				track_pointer_ICFL_cfl = track_pointer_ICFL_cfl->next;
			}

			//Insert << to indicate the begin of the subdecomposition of w
			node_t *end_delimiter = (node_t *) malloc(sizeof(node_t));
			end_delimiter->factor = malloc(3);
			strcpy(end_delimiter->factor, ">>");

			track_pointer_ICFL_cfl = end_delimiter;

			params *parameters = (params *) malloc(sizeof(params));
			parameters->w = (char *) malloc(strlen(track_pointer_icfl->factor) + 1);
			strcpy(parameters->w, track_pointer_icfl->factor);
			parameters->list_alphabet = (char *) malloc(strlen(list_alphabet) + 1);
			strcpy(parameters->list_alphabet, list_alphabet);
			parameters->start_d = start_delimiter;
			parameters->end_d = end_delimiter;
			/
			node_thread *new_thread = (node_thread *) malloc(sizeof(node_thread));
			new_thread->next = thread_list;
			thread_list = new_thread;
			/
			//pthread_create(&new_thread->tid, NULL, CFL_thread, (void *) parameters);
/			thpool_add_work(thpool, (void*) CFL_thread, (void *) parameters);
		}
		track_pointer_icfl = track_pointer_icfl->next;
	}
	track_pointer_ICFL_cfl->next = NULL;
	free_list(icfl_list);
	thpool_wait(thpool);
	/
	void *t_ret;
	while (thread_list != NULL) {
		node_thread *tmp = thread_list;
		pthread_join(thread_list->tid, &t_ret);
		thread_list = thread_list->next;
		free(tmp);
	}
	*/
/*	return ICFL_cfl_list;
}
*/