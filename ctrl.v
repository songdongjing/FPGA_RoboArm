module ctrl(
	clk,
	reset_n,
	key_flag,
	key_state,
	rx_done,
	tx_done,
	addra,
	addrb,
	wea,
	send_en,
	led
);
	wire reset=~reset_n;
	input clk;     //时钟输入50M
	input reset_n;    //模块复位，低有效
	input key_flag;   //按键标志信号
	input key_state;  //按键状态信号
	input rx_done;    //串口一次数据接收完成标志  
	input tx_done;    //串口一次数据发送完成标志
	output [12:0]addrb;      //RAM读地址
	output [12:0]addra;      //RAM写地址
	output wea;        //RAM写使能
	output send_en;    //串口发送使能
	output led;			//时间状态
	
	reg [12:0]addrb;
	reg [12:0]addra;
	reg send_en;
	reg send_state;
	reg send_1st_en;
	reg tx_done_dly1;
	reg tx_done_dly2;
   	reg [6:0]tx_cnt;
	reg [25:0]time1s;
	reg led;
	reg keyup;
	
	wire send_en_pre;
	
	assign wea = rx_done;
	
	//一键启动信号
	always@(posedge clk or posedge reset)
	if(reset)
		keyup <= 1'd0;
	else if(key_flag && !key_state)
		keyup <= 1'd1;
	else
		keyup <= keyup;
	
	//1s计数器
	always@(posedge clk or posedge reset)
	if(reset)
		time1s <= 26'd0;
	else if (keyup && time1s == 26'd50_000_000)
		time1s <= 26'd0;
	else if(keyup)
		time1s <= time1s + 1'b1;
	else
		time1s <= 26'd0;
		
	always@(posedge clk or posedge reset)
	if(reset)
		addra <= 13'd0;
	else if(rx_done)
		addra <= addra + 1'b1;
	else 
		addra <= addra;

	always@(posedge clk or posedge reset)
	if(reset)	
		addrb <= 13'd0;
	else if(tx_done)
		addrb <= addrb + 1'b1;
	else
		addrb <= addrb;
		
	always@(posedge clk or posedge reset)
	if(reset)
		led<=1'b0;
	else if(time1s == 26'd50_000_000)
		led <= ~led;
	else
		led <= led;
		
  //按键控制数据发送的状态，
  //为1表示从dpram读出数据从串口发出
	always@(posedge clk or posedge reset)
	if(reset)
		send_state <= 1'b0;
	else if(tx_cnt==7'd97)
		send_state <= 1'b0;
	else if(key_flag && !key_state || time1s == 26'd50_000_000)
		send_state <= 1'b1;
	else
		send_state <= send_state;
		
  //打两拍
	always@(posedge clk or posedge reset)
	if(reset)
	begin
		tx_done_dly1 <= 1'b0;
		tx_done_dly2 <= 1'b0;

	end
	else
	begin
		tx_done_dly1 <= tx_done;
		tx_done_dly2 <= tx_done_dly1; 

	end
	
  //发送位数计数器
	always@(posedge clk or posedge reset)
	if(reset)
		tx_cnt <= 1'b1;
	else if(tx_done && tx_cnt < 7'd97)
		tx_cnt <= tx_cnt+1'b1;
	else if(tx_cnt==7'd97 && time1s == 26'd50_000_000)
		tx_cnt <= 1'b1;
	else
		tx_cnt <= tx_cnt;	
		
	assign send_en_pre = send_state == 1'b1;

	always@(posedge clk or posedge reset)
	if(reset)
		send_en <= 1'b0;
	else
		send_en <= send_en_pre;
endmodule