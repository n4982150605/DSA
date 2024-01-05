`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 0716031
//////////////////////////////////////////////////////////////////////////////////


module core2float #( parameter XLEN = 32, parameter AXI_ADDR_LEN = 8)
(
    input                 clk_i,
    input                 rst_i,
    (* mark_debug = "true" *)input [XLEN - 1 : 0]  pc_dsa,
    
    // Aquila
    (* mark_debug = "true" *)input                 strobe_i,
    (* mark_debug = "true" *)input [XLEN-1 : 0]    dev_addr_i,
    (* mark_debug = "true" *)input                 rw_i,
    (* mark_debug = "true" *)input [XLEN/8-1 : 0]  byte_enable_i,
    (* mark_debug = "true" *)input [XLEN-1 : 0]    data_i,
    (* mark_debug = "true" *)output                data_ready_o,
    (* mark_debug = "true" *)output reg [XLEN-1 : 0]   data_o,
    
    // AXI
    (* mark_debug = "true" *)output reg                float_a_valid,
    (* mark_debug = "true" *)output reg [XLEN - 1 : 0] float_a_data,
    (* mark_debug = "true" *)output reg                float_b_valid,
    (* mark_debug = "true" *)output reg [XLEN - 1 : 0] float_b_data,
    (* mark_debug = "true" *)input                 float_result_valid,
    (* mark_debug = "true" *)input [XLEN - 1 : 0]  float_result,
    (* mark_debug = "true" *)output [XLEN - 1 : 0] float_c_data
);

wire             raddr;
(* mark_debug = "true" *)wire [14 - 1: 0] waddr;
assign raddr = (dev_addr_i[12 - 1 : 0] == 12'h8)? 1:0;
assign waddr = dev_addr_i[16 - 1 : 2];

(* mark_debug = "true" *)reg en;
reg write_done;
reg read_done;

reg  [XLEN-1 : 0] a_input_buffer_mem;
reg  [XLEN-1 : 0] b_input_buffer_mem;

reg  [XLEN-1 : 0] feeder_mem[0 : 1];
//(* mark_debug = "true" *)reg  [XLEN-1 : 0] vector_size;
(* mark_debug = "true" *)integer count;

(* mark_debug = "true" *)reg PC_start;
(* mark_debug = "true" *)reg               comp;
(* mark_debug = "true" *)reg  [XLEN-1 : 0] comp_clock;
(* mark_debug = "true" *)reg               feed;
(* mark_debug = "true" *)reg  [XLEN-1 : 0] feeding_clock;


always @(posedge clk_i) begin
    if (rst_i)
    begin
        a_input_buffer_mem <= 32'b0;
        b_input_buffer_mem <= 32'b0;
        en <= 0;
        write_done <= 0;
        feed <= 0;
    end
    else if(strobe_i & rw_i)
    begin
        if(waddr == 12'h1) begin
            en <= 1;
            feed <= 0;
        end
        else if(waddr >= 12'h4 && waddr < 12'h400) begin
            case(byte_enable_i)
                4'b1000: begin
                    a_input_buffer_mem <= {data_i[31: 24],a_input_buffer_mem[23: 0]};
                end
                4'b0100: begin
                    a_input_buffer_mem <= {a_input_buffer_mem[31: 24],data_i[23: 16],a_input_buffer_mem[15: 0]};
                end
                4'b0010: begin
                    a_input_buffer_mem <= {a_input_buffer_mem[31: 16],data_i[15: 8],a_input_buffer_mem[7: 0]};
                end
                4'b0001: begin
                    a_input_buffer_mem <= {a_input_buffer_mem[31: 8],data_i[7: 0]};
                end
                4'b1111: begin
                    //word
                    a_input_buffer_mem <= data_i;
                end
            endcase
           en <= 0;
           feed <= 1;
        end
        else if(waddr >= 12'h400) begin
            case(byte_enable_i)
                4'b1000: begin
                    b_input_buffer_mem <= {data_i[31: 24],b_input_buffer_mem[23: 0]};
                end
                4'b0100: begin
                    b_input_buffer_mem <= {b_input_buffer_mem[31: 24],data_i[23: 16],b_input_buffer_mem[15: 0]};
                end
                4'b0010: begin
                    b_input_buffer_mem <= {b_input_buffer_mem[31: 16],data_i[15: 8],b_input_buffer_mem[7: 0]};
                end
                4'b0001: begin
                    b_input_buffer_mem <= {b_input_buffer_mem[31: 8],data_i[7: 0]};
                end
                4'b1111: begin
                    //word
                    b_input_buffer_mem <= data_i;
                end
            endcase
            en <= 0;
            feed <= 1;
        end
        write_done <= 1;
    end
    else begin
        en <= 0;
        write_done <= 0;
    end
end

assign float_c_data = (count == 1 || count == 0)? 32'b0 : feeder_mem[0];
always @(posedge clk_i) begin
    if (rst_i) begin
        float_a_valid <= 0;
        float_a_data <= 32'b0;
        float_b_valid <= 0;
        float_b_data <= 32'b0;
        count <= 0;
        feeder_mem[0] <= 32'b0;
        feeder_mem[1] <= 32'b0;
        comp <= 0;
        //vector_size <= 0;
    end
    else if(en) begin
        count <= count + 1;
        float_a_valid <= 1;
        float_a_data <= a_input_buffer_mem;
        float_b_valid <= 1;
        float_b_data <= b_input_buffer_mem;
        comp <= 1;
    end
    else begin
        float_a_valid <= 0;
        float_b_valid <= 0;
    end
    if(float_result_valid && ~rst_i) begin
            feeder_mem[0] <= float_result;
            feeder_mem[1] <= 1;
            //comp <= 0;
    end
    else if(strobe_i & ~rw_i & raddr == 0 && ~rst_i) begin
        feeder_mem[1] <= 0;
    end
    if(float_result_valid && ~rst_i && ~en) begin
            comp <= 0;
    end
    if(strobe_i & rw_i & waddr == 12'h3 & ~rst_i) begin
        //vector_size <= data_i;
        count <= 0;
    end
end

always @(posedge clk_i) begin
    if(rst_i) begin
        read_done <= 0;
    end
    else begin
        if(strobe_i & ~rw_i)
        begin
            data_o <= feeder_mem[raddr]; 
            read_done <= 1;
        end
        else begin
            read_done <= 0;
        end
    end
end

assign data_ready_o = write_done | read_done;

//PC
always @(posedge clk_i) begin
    if (rst_i) begin
        PC_start <= 0;
    end
    else if(pc_dsa == 32'h80001f14) PC_start <= 1;
end

//clock counting
always @(posedge clk_i) begin
    if (rst_i) begin
        comp_clock <= 0;
        feeding_clock <= 0;
    end
    else if(PC_start == 1)begin
        if(comp == 1) comp_clock <= comp_clock + 1;
        if(feed == 1) feeding_clock <= feeding_clock + 1;
    end
end

endmodule
