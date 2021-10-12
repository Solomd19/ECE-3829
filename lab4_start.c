/* Author: Jennifer Stander (Edited by Drew Solomon)
 * Course: ECE 3829
 * Project: Lab 4
 * Description: Starting project for Lab 4.
 * Implements two functions
 * 1- reading switches and lighting their corresponding LED
 * 2 - outputs a tone corresponding to selected switch to the AMP2
 * It also initializes the anode and segment of the 7-seg display
 * for future development
 */


// Header Inclusions
/* xparameters.h set parameters names
 like XPAR_AXI_GPIO_0_DEVICE_ID that are referenced in you code
 each hardware module as a section in this file.
*/
#include "xparameters.h"
/* each hardware module type as a set commands you can use to
 * configure and access it. xgpio.h defines API commands for your gpio modules
 */
#include "xgpio.h"
/* this defines the recommend types like u32 */
#include "xil_types.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "sleep.h"
#include "xtmrctr.h"


void check_switches(u32 *sw_data, u32 *sw_data_old, u32 *sw_changes);
void update_LEDs(u32 led_data);
void update_amp2(u32 *amp2_data, u32 target_count, u32 *last_count);
u32 update_note(u32 note_data);


// Block Design Details
/* Timer device ID
 */
#define TMRCTR_DEVICE_ID XPAR_TMRCTR_0_DEVICE_ID
#define TIMER_COUNTER_0 0


/* LED are assigned to GPIO (CH 1) GPIO_0 Device
 * DIP Switches are assigned to GPIO2 (CH 2) GPIO_0 Device
 */
#define GPIO0_ID XPAR_GPIO_0_DEVICE_ID
#define GPIO0_LED_CH 1
#define GPIO0_SW_CH 2
// 16-bits of LED outputs (not tristated)
#define GPIO0_LED_TRI 0x00000000
#define GPIO0_LED_MASK 0x0000FFFF
// 16-bits SW inputs (tristated)
#define GPIO0_SW_TRI 0x0000FFFF
#define GPIO0_SW_MASK 0x0000FFFF

/*  7-SEG Anodes are assigned to GPIO (CH 1) GPIO_1 Device
 *  7-SEG Cathodes are assigned to GPIO (CH 2) GPIO_1 Device
 */
#define GPIO1_ID XPAR_GPIO_1_DEVICE_ID
#define GPIO1_ANODE_CH 1
#define GPIO1_CATHODE_CH 2
//4-bits of anode outputs (not tristated)
#define GPIO1_ANODE_TRI 0x00000000
#define GPIO1_ANODE_MASK 0x0000000F
//8-bits of cathode outputs (not tristated)
#define GPIO1_CATHODE_TRI 0x00000000
#define GPIO1_CATHODE_MASK 0x000000FF

#define GPIO2_ID XPAR_GPIO_2_DEVICE_ID
#define GPIO2_AMP2_CH 1
#define GPIO2_AMP2_TRI 0xFFFFFFF4
#define GPIO2_AMP2_MASK 0x00000001


// Timer Device instance
XTmrCtr TimerCounter;

// GPIO Driver Device
XGpio device0;
XGpio device1;
XGpio device2;

// IP Tutorial  Main
int main() {
	u32 sw_data = 0;
	u32 sw_data_old = 0;
	// bit[3] = SHUTDOWN_L and bit[1] = GAIN, bit[0] = Audio Input
	u32 amp2_data = 0x8;
	u32 target_count = 0xffffffff;
	u32 last_count = 0;
	u32 sw_changes = 0;

	XStatus status;


	//Initialize timer
	status = XTmrCtr_Initialize(&TimerCounter, XPAR_TMRCTR_0_DEVICE_ID);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization Timer failed\n\r");
		return 1;
	}
	//Make sure the timer is working
	status = XTmrCtr_SelfTest(&TimerCounter, TIMER_COUNTER_0);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization Timer failed\n\r");
		return 1;
	}
	//Configure the timer to Autoreload
	XTmrCtr_SetOptions(&TimerCounter, TIMER_COUNTER_0, XTC_AUTO_RELOAD_OPTION);
	//Initialize your timer values
	//Start your timer
	XTmrCtr_Start(&TimerCounter, TIMER_COUNTER_0);



	// Initialize the GPIO devices
	status = XGpio_Initialize(&device0, GPIO0_ID);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization GPIO_0 failed\n\r");
		return 1;
	}
	status = XGpio_Initialize(&device1, GPIO1_ID);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization GPIO_1 failed\n\r");
		return 1;
	}
	status = XGpio_Initialize(&device2, GPIO2_ID);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization GPIO_2 failed\n\r");
		return 1;
	}

	// Set directions for data ports tristates, '1' for input, '0' for output
	XGpio_SetDataDirection(&device0, GPIO0_LED_CH, GPIO0_LED_TRI);
	XGpio_SetDataDirection(&device0, GPIO0_SW_CH, GPIO0_SW_TRI);
	XGpio_SetDataDirection(&device1, GPIO1_ANODE_CH, GPIO1_ANODE_TRI);
	XGpio_SetDataDirection(&device1, GPIO1_CATHODE_CH, GPIO1_CATHODE_TRI);
	XGpio_SetDataDirection(&device2, GPIO2_AMP2_CH, GPIO2_AMP2_TRI);

	xil_printf("Demo initialized successfully\n\r");

	XGpio_DiscreteWrite(&device2, GPIO2_AMP2_CH, amp2_data);

	XGpio_DiscreteWrite(&device1, GPIO1_ANODE_CH, 0xE); //Enable only the rightmost seven segment display
	XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00FF); //Initialize seven segment display to show nothing (no note playing by default)

	// this loop checks for changes in the input switches
	// if they changed it updates the LED outputs to match the switch values.
	// target_count = (period of sound)/(2*10nsec)), 10nsec is the processor clock frequency
	// example count is middle C (C4) = 191110 count (261.62 Hz)
	//target_count = (1.0/(2.0*261.62*10e-9));

	//Song to play on startup: Super Mario Bros. Theme
	//E4 -> E4 -> E4 -> C4 -> E4 -> G4 -> G3

	u32 note_list[7] = {0x0200, 0x0200, 0x0200, 0x0080, 0x0200, 0x0800, 0x0010}; //List of notes to play in sequence

	for(int i = 0; i < 7; i++){ //Run through each note at constant pace
		u32 start_count = XTmrCtr_GetValue(&TimerCounter, TIMER_COUNTER_0); //Establish reference tick count

		target_count = update_note(note_list[i]); //Adjust target_count based on current note of note_list

		while(XTmrCtr_GetValue(&TimerCounter, TIMER_COUNTER_0) < start_count + 20000000){ //For .2s play current note
			update_amp2(&amp2_data, target_count, &last_count);
		};

		target_count = update_note(0xFFFF); //Silence current note for staccato

		while(XTmrCtr_GetValue(&TimerCounter, TIMER_COUNTER_0) < start_count + 30000000){ //For .1s play silence before next note
			update_amp2(&amp2_data, target_count, &last_count);
		};
	}
	target_count = update_note(0xFFFF); //Reset current note to none

	while (1) {
		check_switches(&sw_data, &sw_data_old, &sw_changes);
		if (sw_changes){
			update_LEDs(sw_data);
			target_count = update_note(sw_data);
		}
		update_amp2(&amp2_data, target_count, &last_count);
	}

}

// reads the value of the input switches and outputs if there were changes from last time
void check_switches(u32 *sw_data, u32 *sw_data_old, u32 *sw_changes) {
	*sw_data = XGpio_DiscreteRead(&device0, GPIO0_SW_CH);
	*sw_data &= GPIO0_SW_MASK;
	*sw_changes = 0;
	if (sw_data != sw_data_old) {
		// When any bswitch is toggled, the LED values are updated
		//  and report the state over UART.
		*sw_changes = *sw_data ^ *sw_data_old;
		*sw_data_old = *sw_data;
	}
}

// writes the value of led_data to the LED pins
void update_LEDs(u32 led_data) {
	led_data = (led_data) & GPIO0_LED_MASK;
	XGpio_DiscreteWrite(&device0, GPIO0_LED_CH, led_data);
}

// if the current count is - last_count > target_count toggle the amp2 output
void update_amp2(u32 *amp2_data, u32 target_count, u32 *last_count) {
	u32 current_count = XTmrCtr_GetValue(&TimerCounter, TIMER_COUNTER_0);
	if ((current_count - *last_count) > target_count) {
		// toggling the LSB of amp2 data
		*amp2_data = ((*amp2_data & 0x01) == 0) ? (*amp2_data | 0x1) : (*amp2_data & 0xe);
		XGpio_DiscreteWrite(&device2, GPIO2_AMP2_CH, *amp2_data );
		*last_count = current_count;
	}
}

u32 update_note(u32 note_data){ //Note data is the switch data
	note_data = (note_data) & GPIO0_SW_MASK; //Mask data input
	switch (note_data){ //Seven seg cathode data update (FORMAT: Note - binary of seven seg display)
		case(0x0001): //SW0
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00C6);
			return (1.0/(2.0*130.81*10e-9)); //C3 - 1100 0110
			break;
		case(0x0002): //SW1
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00A1);
			return (1.0/(2.0*146.83*10e-9)); //D3 - 1010 0001
			break;
		case(0x0004): //SW2
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0086);
			return (1.0/(2.0*164.81*10e-9)); //E3 - 1000 0110
			break;
		case(0x0008): //SW3
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x008E);
			return (1.0/(2.0*174.61*10e-9)); //F3 - 1000 1110
			break;
		case(0x0010): //SW4
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0090);
			return (1.0/(2.0*196*10e-9)); //G3 - 1001 0000
			break;
		case(0x0020): //SW5
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0088);
			return (1.0/(2.0*220*10e-9)); //A3 - 1000 1000
			break;
		case(0x0040): //SW6
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0083);
			return (1.0/(2.0*246.94*10e-9)); //B3 - 1000 0011
			break;
		case(0x0080): //SW7
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00C6);
			return (1.0/(2.0*261.63*10e-9)); //C4 - 1100 0110
			break;
		case(0x0100): //SW8
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00A1);
			return (1.0/(2.0*293.66*10e-9)); //D4 - 1010 0001
			break;
		case(0x0200): //SW9
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0086);
			return (1.0/(2.0*329.63*10e-9)); //E4 - 1000 0110
			break;
		case(0x0400): //SW10
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x008E);
			return (1.0/(2.0*349.23*10e-9)); //F4 - 1000 1110
			break;
		case(0x0800): //SW11
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0090);
			return (1.0/(2.0*392*10e-9)); //G4 - 1001 0000
			break;
		case(0x1000): //SW12
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0088);
			return (1.0/(2.0*440*10e-9)); //A4 - 1000 1000
			break;
		case(0x2000): //SW13
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x0083);
			return (1.0/(2.0*493.88*10e-9)); //B4 - 1000 0011
			break;
		case(0x4000): //SW14
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00C6);
			return (1.0/(2.0*523.25*10e-9)); //C5 - 1100 0110
			break;
		case(0x8000): //SW15
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00A1);
			return (1.0/(2.0*587.33*10e-9)); //D5 - 1010 0001
			break;
		default: //No switch or multiple switches
			XGpio_DiscreteWrite(&device1, GPIO1_CATHODE_CH, 0x00FF);
			return 0xffffffff;
			break;
	}
}
