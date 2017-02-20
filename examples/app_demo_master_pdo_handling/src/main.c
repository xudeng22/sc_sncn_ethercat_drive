/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#define _XOPEN_SOURCE

#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
#include <ecrt.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <signal.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/resource.h>
#include <string.h>
#include <curses.h>

#define MAX_UINT8                   0xff
#define MAX_UINT16                  0xffff
#define MAX_UINT32                  0xffffffff

/* Index of receiving (in) PDOs */
#define PDO_INDEX_STATUSWORD                  0
#define PDO_INDEX_OPMODEDISP                  1
#define PDO_INDEX_POSITION_VALUE              2
#define PDO_INDEX_VELOCITY_VALUE              3
#define PDO_INDEX_TORQUE_VALUE                4
#define PDO_INDEX_SECONDARY_POSITION_VALUE    5
#define PDO_INDEX_SECONDARY_VELOCITY_VALUE    6
#define PDO_INDEX_ANALOG_INPUT1               7
#define PDO_INDEX_ANALOG_INPUT2               8
#define PDO_INDEX_ANALOG_INPUT3               9
#define PDO_INDEX_ANALOG_INPUT4              10
#define PDO_INDEX_TUNING_STATUS              11
#define PDO_INDEX_DIGITAL_INPUT1             12
#define PDO_INDEX_DIGITAL_INPUT2             13
#define PDO_INDEX_DIGITAL_INPUT3             14
#define PDO_INDEX_DIGITAL_INPUT4             15
#define PDO_INDEX_USER_MISO                  16

/* Index of sending (out) PDOs */
#define PDO_INDEX_CONTROLWORD                 0
#define PDO_INDEX_OPMODE                      1
#define PDO_INDEX_TORQUE_REQUEST              2
#define PDO_INDEX_POSITION_REQUEST            3
#define PDO_INDEX_VELOCITY_REQUEST            4
#define PDO_INDEX_OFFFSET_TORQUE              5
#define PDO_INDEX_TUNING_COMMAND              6
#define PDO_INDEX_DIGITAL_OUTPUT1             7
#define PDO_INDEX_DIGITAL_OUTPUT2             8
#define PDO_INDEX_DIGITAL_OUTPUT3             9
#define PDO_INDEX_DIGITAL_OUTPUT4            10
#define PDO_INDEX_USER_MOSI                  11

struct _input_t {
    unsigned int statusword;
    unsigned int op_mode_display;
    unsigned int position_value;
    unsigned int velocity_value;
    unsigned int torque_value;
    unsigned int secondary_position_value;
    unsigned int secondary_velocity_value;
    unsigned int analog_input1;
    unsigned int analog_input2;
    unsigned int analog_input3;
    unsigned int analog_input4;
    unsigned int tuning_status;
    unsigned int digital_input1;
    unsigned int digital_input2;
    unsigned int digital_input3;
    unsigned int digital_input4;
    unsigned int user_miso;
};

struct _output_t {
    unsigned int controlword;
    unsigned int op_mode;
    unsigned int target_position;
    unsigned int target_velocity;
    unsigned int target_torque;
    unsigned int tuning_command;
    unsigned int offset_torque;
    unsigned int digital_output1;
    unsigned int digital_output2;
    unsigned int digital_output3;
    unsigned int digital_output4;
    unsigned int user_mosi;
};

static int g_running = 1;
static unsigned int sig_alarms  = 0;
static unsigned int user_alarms = 0;

/* set eventually higher priority */


static void set_priority(void)
{
    if (getuid() != 0) {
        fprintf(stderr, "Warning, be root to get higher priority\n");
        return;
    }

    pid_t pid = getpid();
    if (setpriority(PRIO_PROCESS, pid, -19))
        fprintf(stderr, "Warning: Failed to set priority: %s\n",
                strerror(errno));
}

/* Signal handling */

void signal_handler(int signum) {
    switch (signum) {
        case SIGINT:
        case SIGTERM:
            g_running = 0;
            break;
        case SIGALRM:
            sig_alarms++;
            break;
    }
}

static void setup_signal_handler(struct sigaction *sa)
{
    /* setup signal handler */
    sa->sa_handler = signal_handler;
    sigemptyset(&(sa->sa_mask));
    sa->sa_flags = 0;
    if (sigaction(SIGALRM, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }

    if (sigaction(SIGTERM, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }

    if (sigaction(SIGINT, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }
}

static void setup_timer(struct itimerval *tv)
{
    /* setup timer */
    tv->it_interval.tv_sec = 0;
    tv->it_interval.tv_usec = 1000000 / 1000;
    tv->it_value.tv_sec = 0;
    tv->it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }
}

static void data_update_pdos(Ethercat_Slave_t *slave,
                        struct _input_t  *input,
                        struct _output_t *output)
{
    unsigned int received = 0;

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
    if (received == input->statusword) {
        input->statusword = received;
        output->controlword = (input->statusword >= MAX_UINT16) ? 0 : input->statusword + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, output->controlword);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_OPMODEDISP);
    if (received == input->op_mode_display) {
        input->op_mode_display = received;
        output->op_mode = (input->op_mode_display >= MAX_UINT8) ? 0 : input->op_mode_display + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_OPMODE, output->op_mode);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_TORQUE_VALUE);
    if (received == input->torque_value) {
        input->torque_value = input->torque_value;
        output->target_torque = (input->torque_value >= MAX_UINT16) ? 0 : input->torque_value + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_TORQUE_REQUEST, output->target_torque);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_POSITION_VALUE);
    if (received == input->position_value) {
        input->position_value = received;
        output->target_position = (input->position_value >= MAX_UINT32) ? 0 : input->position_value + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_POSITION_REQUEST, output->target_position);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_VELOCITY_VALUE);
    if (received == input->velocity_value) {
        input->velocity_value = received;
        output->target_velocity = (input->velocity_value >= MAX_UINT32) ? 0 : input->velocity_value + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_VELOCITY_REQUEST, output->target_velocity);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_USER_MISO);
    if (received == input->user_miso) {
        input->user_miso = received;
        output->user_mosi = (input->user_miso >= MAX_UINT32) ? 0 : input->user_miso + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_USER_MOSI, output->user_mosi);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_TUNING_STATUS);
    if (received == input->tuning_status) {
        input->tuning_status = received;
        output->tuning_command = (input->tuning_status >= MAX_UINT32) ? 0 : input->tuning_status + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_TUNING_COMMAND, output->tuning_command);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_SECONDARY_POSITION_VALUE);
    if (received == input->secondary_position_value) {
        input->secondary_position_value = received;
        output->offset_torque = (input->secondary_position_value >= MAX_UINT32) ? 0 : input->secondary_position_value + 1;
        ecw_slave_set_out_value(slave, PDO_INDEX_TUNING_COMMAND, output->offset_torque);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT1);
    if (received == input->digital_input1) {
        input->digital_input1 = received;
        output->digital_output1 = ~input->digital_input1 & 0x1;
        ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT1, output->digital_output1);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT2);
    if (received == input->digital_input2) {
        input->digital_input2 = received;
        output->digital_output2 = ~input->digital_input2 & 0x1;
        ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT2, output->digital_output2);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT3);
    if (received == input->digital_input3) {
        input->digital_input3 = received;
        output->digital_output3 = ~input->digital_input3 & 0x1;
        ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT3, output->digital_output3);
    }

    received = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT4);
    if (received == input->digital_input4) {
        input->digital_input4 = received;
        output->digital_output4 = ~input->digital_input4 & 0x1;
        ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT4, output->digital_output4);
    }

    input->analog_input1 = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT1);
    input->analog_input2 = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT2);
    input->analog_input3 = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT3);
    input->analog_input4 = (unsigned int)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT4);
}

static void display_update(WINDOW *wnd, struct _input_t *input, struct _output_t *output)
{
    int row = 0;
    int output_column = 0;
    int input_column  = 20;

    wmove(wnd, row++, 0);
    wprintw(wnd, "Send Values");
    wmove(wnd, row++, 0);
    wprintw(wnd, "-----------");

    /* print the output values */
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->controlword);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->op_mode);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->target_position);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->target_velocity);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->target_torque);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->tuning_command);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->digital_output1);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->digital_output2);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->digital_output3);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->digital_output4);
    wmove(wnd, row++, output_column);
    wprintw(wnd, "%d", output->user_mosi);

    row = 0;

    wmove(wnd, row++, input_column);
    wprintw(wnd, "Receive Values");
    wmove(wnd, row++, input_column);
    wprintw(wnd, "-----------");

    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->statusword);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->op_mode_display);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->position_value);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->velocity_value);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->torque_value);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->secondary_position_value);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->secondary_velocity_value);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->analog_input1);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->analog_input2);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->analog_input3);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->analog_input4);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->tuning_status);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->digital_input1);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->digital_input2);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->digital_input3);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->digital_input4);
    wmove(wnd, row++, input_column);
    wprintw(wnd, "%d", input->user_miso);

    wrefresh(wnd);
}

int main(int argc, char *argv[])
{
	int slaveid = 0;

    struct sigaction sa;
    struct itimerval tv;

    /* FIXME use getopt(1) with -h, -v etc. */
    if (argc > 1) {
        slaveid =  atoi(argv[1]);
    }

    FILE *ecatlog = fopen("./ecat.log", "w");

	/* Initialize EtherCAT Master */
    Ethercat_Master_t *master = ecw_master_init(0, ecatlog);
    if (master == NULL) {
        fprintf(stderr, "Error, could not initialize master\n");
        return -1;
    }

    size_t slave_count = ecw_master_slave_count(master);

    if (slave_count < ((unsigned int)slaveid + 1)) {
        fprintf(stderr, "Error only %lu slaves present, but requested slave index is %d\n",
                slave_count, slaveid);
        return -1;
    }

    /* only talk to slave 0 */
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    if (slave == NULL) {
        fprintf(stderr, "Error could not retrieve slave %d", slaveid);
        return -1;
    }

    ecw_master_start(master);
	printf("starting Master application\n");

    set_priority();
    setup_signal_handler(&sa);
    setup_timer(&tv);

    /* Init display */
    WINDOW *wnd = initscr();
    noecho();
    clear();
    refresh();
    nodelay(stdscr, TRUE);

    struct _input_t input   = { 0 };
    struct _output_t output = { 0 };

    display_update(wnd, &input, &output);

	while(g_running) {
        pause();

        while (sig_alarms != user_alarms) {
            user_alarms++;

            ecw_master_cyclic_function(master);

            data_update_pdos(slave, &input, &output);
        }

        display_update(wnd, &input, &output);
	}

    endwin();
    ecw_master_release(master);
    fclose(ecatlog);

	return 0;
}



