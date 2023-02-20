// VGA demo - Pong game
// (c) fpga4fun.com KNJN LLC - 2004-2007

module pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B);
input clk;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

//input quadA, quadB;  // these used to be inputs for the paddle
wire [8:0] PaddlePosition = 264;  // the paddle logic has been removed, so let's fix the paddle position

/////////////////////////////////////////////////////////////////
wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(
	.clk(clk), 
	.CounterX(CounterX), .CounterY(CounterY),
	.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
	.inDisplayArea(inDisplayArea)
);

/////////////////////////////////////////////////////////////////
reg [9:0] ballX;
reg [8:0] ballY;
reg ball_inX, ball_inY;

always @(posedge clk)
if(ball_inX==0) ball_inX <= (CounterX==ballX) & ball_inY; else ball_inX <= !(CounterX==ballX+16);

always @(posedge clk)
if(ball_inY==0) ball_inY <= (CounterY==ballY); else ball_inY <= !(CounterY==ballY+16);

wire ball = ball_inX & ball_inY;

/////////////////////////////////////////////////////////////////
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire paddle = (CounterX>=PaddlePosition+8) && (CounterX<=PaddlePosition+120) && (CounterY[8:4]==27);
wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

reg ResetCollision;
always @(posedge clk) ResetCollision <= (CounterY==500) & (CounterX==0);  // active only once for every video frame

reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
always @(posedge clk) if(ResetCollision) CollisionX1<=1'b0; else if(BouncingObject & (CounterX==ballX   ) & (CounterY==ballY+ 8)) CollisionX1<=1'b1;
always @(posedge clk) if(ResetCollision) CollisionX2<=1'b0; else if(BouncingObject & (CounterX==ballX+16) & (CounterY==ballY+ 8)) CollisionX2<=1'b1;
always @(posedge clk) if(ResetCollision) CollisionY1<=1'b0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY   )) CollisionY1<=1'b1;
always @(posedge clk) if(ResetCollision) CollisionY2<=1'b0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY+16)) CollisionY2<=1'b1;

/////////////////////////////////////////////////////////////////
wire UpdateBallPosition = ResetCollision;  // update the ball position at the same time that we reset the collision detectors

reg ball_dirX, ball_dirY;
always @(posedge clk)
if(UpdateBallPosition)
begin
	if(~(CollisionX1 & CollisionX2))        // if collision on both X-sides, don't move in the X direction
	begin
		if(ball_dirX) ballX <= ballX - 10'h1; else ballX <= ballX + 10'h1;
		if(CollisionX2) ball_dirX <= 1'b1; else if(CollisionX1) ball_dirX <= 1'b0;
	end

	if(~(CollisionY1 & CollisionY2))        // if collision on both Y-sides, don't move in the Y direction
	begin
		if(ball_dirY) ballY <= ballY - 9'h1; else ballY <= ballY + 9'h1;
		if(CollisionY2) ball_dirY <= 1'b1; else if(CollisionY1) ball_dirY <= 1'b0;
	end
end 

/////////////////////////////////////////////////////////////////
wire R = BouncingObject | ball | (CounterX[3] ^ CounterY[3]);
wire G = BouncingObject | ball;
wire B = BouncingObject | ball;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
	vga_R <= R & inDisplayArea;
	vga_G <= G & inDisplayArea;
	vga_B <= B & inDisplayArea;
end

endmodule




/////////////////////////////////////////////////////////////////
module hvsync_generator(clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input clk;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [8:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg [8:0] CounterY;
wire CounterXmaxed = (CounterX==10'h2FF);

always @(posedge clk)
if(CounterXmaxed)
	CounterX <= 10'h0;
else
	CounterX <= CounterX + 10'h1;

always @(posedge clk)
if(CounterXmaxed) CounterY <= CounterY + 9'h1;

reg	vga_HS, vga_VS;
always @(posedge clk)
begin
	vga_HS <= (CounterX[9:4]==6'h2D); // change this value to move the display horizontally
	vga_VS <= (CounterY==500); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==639);
	
assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule
