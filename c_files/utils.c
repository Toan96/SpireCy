#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
//#include <pthread.h>

//struct of any list's node, generally nodes are considered in last-first order
typedef struct node {
    char *factor;
    struct node *next;
} node_t;
/*
typedef struct node_th {
	pthread_t tid;
	struct node_th *next;
} node_thread;
*/
typedef struct param {
	char *w;
	char *list_alphabet;
	node_t *start_d;
	node_t *end_d;
} params;

//check if word and alphabet are in correct format
int check_word_and_alphabet(char word[], char list_alphabet[]) {

	int i = 0;
	while (list_alphabet[i] != '\0') {
		if (isupper(list_alphabet[i]) == 0) {
			printf("\n\nError, a char in alphabet is lowercase: position %d (%c).\n\n", i, list_alphabet[i]);
			return 0;//false
		}
		i++;
	}
	i = 0;
	while (word[i] != '\0') {
		if (isupper(word[i]) == 0) {
			printf("\n\nError, a char in word is lowercase: position %d (%c).\n\n", i, word[i]);
			return 0;//false
		}
		if (strchr(list_alphabet, word[i]) == NULL) {
			printf("\n\nError, char in position %d (%c) is not a char in alphabet.\n\n", i, word[i]);
			return 0;//false
		}
		i++;
	}
	return 1;//true
}

void free_list(node_t *head) {
	node_t* tmp;

	while (head != NULL) {
		tmp = head;
		head = head->next;
		free(tmp->factor);
		free(tmp);
	}
}

int count_for_print;
//recursive print of nodes in first-last order
void print_list_reverse(node_t *node) {
	if (node->next != NULL) {
		count_for_print++;
		print_list_reverse(node->next);
	} else {
		printf("[ ");
	}
	printf("\"%s\" ", node->factor);
	if (count_for_print == 0) {
		printf("]");
		count_for_print = 1;
	}
	count_for_print--;
}

void print_list(node_t *node) {
	printf("[ ");
	while (node != NULL) {
		printf("\"%s\" ", node->factor);
		node = node->next;
	}
	printf("]");
}

char *substring(char word[], int x, int y) {
	int k = 0, i;
	char *sub = (char *) malloc((y-x + 1));

	for (i = x; i < y; i++) {
		sub[k++] = word[i];
	}
	sub[k] = '\0';

	return sub;
}


char *list_to_string(node_t *list, int reverse) { //0 true 1 false

    node_t *current = list;
    if (reverse == 0) {
        node_t *prev = NULL;
        node_t *tmp;
        while(current->next != NULL) {
            tmp = current;
            current = current->next;
            tmp->next = prev;
            prev = tmp;
	    }
	    current->next = prev;
    }

    int allocated = 400;
    char *to_string = malloc(allocated);
    strcpy(to_string, "[ ");

    int length = 5; //memory for [  ]\0
    node_t *list_t = current;
    while (current != NULL) {
        if ((length + strlen(current->factor) + 3) > allocated) { //3memory for " "
            allocated += (strlen(current->factor) + 3); //cosi sempre precisa oppure numero fisso
            void *temp = realloc(to_string, allocated);
            if (temp != NULL) {
                to_string = temp;
            } else {
                printf("REALLOC FAILED");
            }
            //to_string = realloc(to_string, allocated);
        }
        strcat(to_string, "\"");
        strcat(to_string, current->factor);
        strcat(to_string, "\"");
        if (current->next != NULL) {
            //strcat(to_string, ", ");
            strcat(to_string, " ");
            length += 1;
        }
        length += (strlen(current->factor) + 2);
        current = current->next;
    }

    strcat(to_string, " ]");

    if (strlen(to_string) < allocated) {
        void *temp = realloc(to_string, length);
        if (temp != NULL) {
            to_string = temp;
        } else {
            printf("REALLOC FAILED");
        }
        //to_string = realloc(to_string, length);
    }

    free_list(list_t);
    return to_string;
}




