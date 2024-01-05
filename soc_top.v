//DSA
wire [XLEN-1 : 0]    f_a,f_b,f_c,f_result;
wire                 f_a_valid,f_b_valid,f_c_valid,f_result_valid;

//assign f_c = f_result;
//assign f_c_valid = f_result_valid;

core2float #(.XLEN(32), .AXI_ADDR_LEN(7))
Data_feeder (
    .clk_i(clk),
    .rst_i(rst),
    .pc_dsa(pc_dsa),
    
    .strobe_i(dev_strobe & dsa_sel),
    .dev_addr_i(dev_addr),
    .rw_i(dev_we),
    .byte_enable_i(dev_be),
    .data_i(dev_din),
    .data_ready_o(dsa_ready),
    .data_o(dsa_dout),
    
    .float_a_valid(f_a_valid),
    .float_a_data(f_a),
    .float_b_valid(f_b_valid),
    .float_b_data(f_b),
    .float_c_data(f_c),
    .float_result_valid(f_result_valid),
    .float_result(f_result)
);

floating_point_0 float(
    .aclk(clk),
    //.s_axis_aresetn(~rst),
    .s_axis_a_tvalid(f_a_valid),
    .s_axis_a_tdata(f_a),
    .s_axis_b_tvalid(f_b_valid),
    .s_axis_b_tdata(f_b),
    //.s_axis_c_tvalid(f_c_valid),
    .s_axis_c_tvalid(1'b1),
    .s_axis_c_tdata(f_c),
    //.s_axis_c_tdata(32'b0),
    .s_axis_operation_tvalid(1'b1),
    .s_axis_operation_tdata(5'b0),
    .m_axis_result_tvalid(f_result_valid),
    .m_axis_result_tdata(f_result)
);

// ----------------------------------------------------------------------------