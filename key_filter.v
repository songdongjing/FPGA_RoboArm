module key_filter(
	clk,
	reset_n,

	key_in,
	key_flag,
	key_state
);
	wire reset=~reset_n;
	input clk; //模块全局时钟输入，50M
	input reset_n; //复位信号输入，低有效
	input key_in; //按键输入

	output key_flag ; //按键标志信号
	output key_state; //按键状态信号

	reg key_flag ;
	reg key_state;
	
	localparam
		IDLE= 4'b0001,
		FILTER0= 4'b0010,
		DOWN= 4'b0100,
		FILTER1= 4'b1000;

	reg [3:0]state;  //状态机状态
	reg [19:0]cnt;    //计数器
	reg en_cnt; //使能计数寄存器
	reg cnt_full;	

	reg  key_in_sync1;
	reg  key_in_sync2;
	reg  key_in_reg1;
	reg  key_in_reg2;
	wire key_in_pedge;
	wire key_in_nedge;

//对外部输入的异步信号进行同步处理
	always@(posedge clk or posedge reset)
	if(reset)begin
		key_in_sync1 <= 1'b0;
		key_in_sync2 <= 1'b0;
	end
	else begin
		key_in_sync1 <= key_in;
		key_in_sync2 <= key_in_sync1;	
	end
	
//使用D触发器存储两个相邻时钟上升沿时外部输入信号（已经同步到系统时钟域中）的电平状态
	always@(posedge clk or posedge reset)
	if(reset)begin
		key_in_reg1 <= 1'b0;
		key_in_reg2 <= 1'b0;
	end
	else begin
		key_in_reg1 <= key_in_sync2;
		key_in_reg2 <= key_in_reg1;	
	end

//产生跳变沿信号	
	assign key_in_nedge = !key_in_reg1 & key_in_reg2;
	assign key_in_pedge = key_in_reg1 & (!key_in_reg2);

//按键消抖状态机	
	always@(posedge clk or posedge reset)
	if(reset)begin
		en_cnt <= 1'b0;
		state <= IDLE;
		key_flag <= 1'b0;
		key_state <= 1'b1;
	end
	else begin
		case(state)
			IDLE :begin
				key_flag <= 1'b0;
				if(key_in_nedge)begin
					state <= FILTER0;
					en_cnt <= 1'b1;
				end
				else
					state <= IDLE;
			end

			FILTER0:begin
				if(cnt_full)begin
					key_flag <= 1'b1;
					key_state <= 1'b0;
					en_cnt <= 1'b0;
					state <= DOWN;
				end
				else if(key_in_pedge)begin
					state <= IDLE;
					en_cnt <= 1'b0;
				end
				else
					state <= FILTER0;
			end

			DOWN:begin
					key_flag <= 1'b0;
					if(key_in_pedge)begin
						state <= FILTER1;
						en_cnt <= 1'b1;
					end
					else
						state <= DOWN;
			end

			FILTER1:begin
				if(cnt_full)begin
					key_flag <= 1'b1;
					key_state <= 1'b1;
					state <= IDLE;
					en_cnt <= 1'b0;
				end
				else if(key_in_nedge)begin
					en_cnt <= 1'b0;
					state <= DOWN;
				end
				else
					state <= FILTER1;
			end

			default:begin 
				state <= IDLE; 
				en_cnt <= 1'b0;		
				key_flag <= 1'b0;
				key_state <= 1'b1;
			end
				
		endcase	
	end
	
	always@(posedge clk or posedge reset)
	if(reset)
		cnt <= 20'd0;
	else if(en_cnt)
		cnt <= cnt + 1'b1;
	else
		cnt <= 20'd0;
	
	always@(posedge clk or posedge reset)
	if(reset)
		cnt_full <= 1'b0;
	else if(cnt == 20'd999_999)
		cnt_full <= 1'b1;
	else
		cnt_full <= 1'b0;	

endmodule



