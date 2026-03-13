#include <stdio.h>
#include <stddef.h>

#define KEY(ch, row) ((((unsigned int)(unsigned char)(ch)) << 3) | ((unsigned int)(row) & 0x7u))

static const char *char_art_row(unsigned char c, unsigned int row) {
    unsigned char uc = (c >= 'a' && c <= 'z') ? (unsigned char)(c - 32) : c;
    unsigned int key = KEY(uc, row);

    switch (key) {
        case KEY(' ',0): case KEY(' ',1): case KEY(' ',2): case KEY(' ',3): case KEY(' ',4): return "     ";
        case KEY('-',0): case KEY('-',1): return "     ";
        case KEY('-',2): return "#### ";
        case KEY('-',3): case KEY('-',4): return "     ";

        case KEY('0',0): return " ### "; case KEY('0',1): return "#   #";
        case KEY('0',2): return "#   #"; case KEY('0',3): return "#   #";
        case KEY('0',4): return " ### ";

        case KEY('1',0): return "  #  "; case KEY('1',1): return " ##  ";
        case KEY('1',2): return "  #  "; case KEY('1',3): return "  #  ";
        case KEY('1',4): return " ### ";

        case KEY('2',0): return " ### "; case KEY('2',1): return "    #";
        case KEY('2',2): return " ### "; case KEY('2',3): return "#    ";
        case KEY('2',4): return "#####";

        case KEY('3',0): return "#### "; case KEY('3',1): return "    #";
        case KEY('3',2): return " ### "; case KEY('3',3): return "    #";
        case KEY('3',4): return "#### ";

        case KEY('4',0): return "#   #"; case KEY('4',1): return "#   #";
        case KEY('4',2): return "#####"; case KEY('4',3): return "    #";
        case KEY('4',4): return "    #";

        case KEY('5',0): return "#####"; case KEY('5',1): return "#    ";
        case KEY('5',2): return "#### "; case KEY('5',3): return "    #";
        case KEY('5',4): return "#### ";

        case KEY('6',0): return " ### "; case KEY('6',1): return "#    ";
        case KEY('6',2): return "#### "; case KEY('6',3): return "#   #";
        case KEY('6',4): return " ### ";

        case KEY('7',0): return "#####"; case KEY('7',1): return "    #";
        case KEY('7',2): return "   # "; case KEY('7',3): return "  #  ";
        case KEY('7',4): return "  #  ";

        case KEY('8',0): return " ### "; case KEY('8',1): return "#   #";
        case KEY('8',2): return " ### "; case KEY('8',3): return "#   #";
        case KEY('8',4): return " ### ";

        case KEY('9',0): return " ### "; case KEY('9',1): return "#   #";
        case KEY('9',2): return " ####"; case KEY('9',3): return "    #";
        case KEY('9',4): return " ### ";

        case KEY('A',0): return "  #  "; case KEY('A',1): return " # # ";
        case KEY('A',2): return "#   #"; case KEY('A',3): return "#####";
        case KEY('A',4): return "#   #";

        case KEY('B',0): return "#### "; case KEY('B',1): return "#   #";
        case KEY('B',2): return "#### "; case KEY('B',3): return "#   #";
        case KEY('B',4): return "#### ";

        case KEY('C',0): return " ####"; case KEY('C',1): return "#    ";
        case KEY('C',2): return "#    "; case KEY('C',3): return "#    ";
        case KEY('C',4): return " ####";

        case KEY('D',0): return "#### "; case KEY('D',1): return "#   #";
        case KEY('D',2): return "#   #"; case KEY('D',3): return "#   #";
        case KEY('D',4): return "#### ";

        case KEY('E',0): return "#####"; case KEY('E',1): return "#    ";
        case KEY('E',2): return "###  "; case KEY('E',3): return "#    ";
        case KEY('E',4): return "#####";

        case KEY('F',0): return "#####"; case KEY('F',1): return "#    ";
        case KEY('F',2): return "###  "; case KEY('F',3): return "#    ";
        case KEY('F',4): return "#    ";

        case KEY('G',0): return " ####"; case KEY('G',1): return "#    ";
        case KEY('G',2): return "# ###"; case KEY('G',3): return "#   #";
        case KEY('G',4): return " ####";

        case KEY('H',0): return "#   #"; case KEY('H',1): return "#   #";
        case KEY('H',2): return "#####"; case KEY('H',3): return "#   #";
        case KEY('H',4): return "#   #";

        case KEY('I',0): return "#####"; case KEY('I',1): return "  #  ";
        case KEY('I',2): return "  #  "; case KEY('I',3): return "  #  ";
        case KEY('I',4): return "#####";

        case KEY('J',0): return "  ###"; case KEY('J',1): return "   # ";
        case KEY('J',2): return "   # "; case KEY('J',3): return "#  # ";
        case KEY('J',4): return " ##  ";

        case KEY('K',0): return "#   #"; case KEY('K',1): return "#  # ";
        case KEY('K',2): return "###  "; case KEY('K',3): return "#  # ";
        case KEY('K',4): return "#   #";

        case KEY('L',0): return "#    "; case KEY('L',1): return "#    ";
        case KEY('L',2): return "#    "; case KEY('L',3): return "#    ";
        case KEY('L',4): return "#####";

        case KEY('M',0): return "#   #"; case KEY('M',1): return "## ##";
        case KEY('M',2): return "# # #"; case KEY('M',3): return "#   #";
        case KEY('M',4): return "#   #";

        case KEY('N',0): return "#   #"; case KEY('N',1): return "##  #";
        case KEY('N',2): return "# # #"; case KEY('N',3): return "#  ##";
        case KEY('N',4): return "#   #";

        case KEY('O',0): return " ### "; case KEY('O',1): return "#   #";
        case KEY('O',2): return "#   #"; case KEY('O',3): return "#   #";
        case KEY('O',4): return " ### ";

        case KEY('P',0): return "#### "; case KEY('P',1): return "#   #";
        case KEY('P',2): return "#### "; case KEY('P',3): return "#    ";
        case KEY('P',4): return "#    ";

        case KEY('Q',0): return " ### "; case KEY('Q',1): return "#   #";
        case KEY('Q',2): return "# # #"; case KEY('Q',3): return "#  ##";
        case KEY('Q',4): return " ####";

        case KEY('R',0): return "#### "; case KEY('R',1): return "#   #";
        case KEY('R',2): return "#### "; case KEY('R',3): return "#  # ";
        case KEY('R',4): return "#   #";

        case KEY('S',0): return " ####"; case KEY('S',1): return "#    ";
        case KEY('S',2): return " ### "; case KEY('S',3): return "    #";
        case KEY('S',4): return "#### ";

        case KEY('T',0): return "#####"; case KEY('T',1): return "  #  ";
        case KEY('T',2): return "  #  "; case KEY('T',3): return "  #  ";
        case KEY('T',4): return "  #  ";

        case KEY('U',0): return "#   #"; case KEY('U',1): return "#   #";
        case KEY('U',2): return "#   #"; case KEY('U',3): return "#   #";
        case KEY('U',4): return " ### ";

        case KEY('V',0): return "#   #"; case KEY('V',1): return "#   #";
        case KEY('V',2): return "#   #"; case KEY('V',3): return " # # ";
        case KEY('V',4): return "  #  ";

        case KEY('W',0): return "#   #"; case KEY('W',1): return "#   #";
        case KEY('W',2): return "# # #"; case KEY('W',3): return "## ##";
        case KEY('W',4): return "#   #";

        case KEY('X',0): return "#   #"; case KEY('X',1): return " # # ";
        case KEY('X',2): return "  #  "; case KEY('X',3): return " # # ";
        case KEY('X',4): return "#   #";

        case KEY('Y',0): return "#   #"; case KEY('Y',1): return " # # ";
        case KEY('Y',2): return "  #  "; case KEY('Y',3): return "  #  ";
        case KEY('Y',4): return "  #  ";

        case KEY('Z',0): return "#####"; case KEY('Z',1): return "   # ";
        case KEY('Z',2): return " ### "; case KEY('Z',3): return "#    ";
        case KEY('Z',4): return "#####";

        case KEY('_',0): case KEY('_',1): case KEY('_',2): case KEY('_',3): return "     ";
        case KEY('_',4): return "#####";

        default: return "???? ";
    }
}

void print_ascii_art_c(const char *msg) {
    size_t i;
    unsigned int row;

    if (msg == NULL) {
        return;
    }

    printf("\n");
    for (row = 0; row < 5u; row++) {
        printf("  ");
        for (i = 0; msg[i] != '\0'; i++) {
            printf("%s ", char_art_row((unsigned char)msg[i], row));
        }
        printf("\n");
    }
    fflush(stdout);
}
