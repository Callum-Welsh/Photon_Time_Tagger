// light up the LED when the push-button is pressed

module PushButton(input pb, output LED);

/////////////////////////////////
// light up the LED when the push-button is pressed
assign LED = ~pb;	// push-button is active low, LED is active high

endmodule