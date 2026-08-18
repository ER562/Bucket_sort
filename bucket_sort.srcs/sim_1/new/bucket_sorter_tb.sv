`timescale 1ns / 1ps

module bucket_sorter_tb#(
    parameter DATA_WIDTH = 10,
    parameter DATA_VOLUME = 1000,
    parameter DECISION_BITS = 4
)(

);

    int input_data [DATA_VOLUME];
    int output_data [DATA_VOLUME];
    integer i;
    
    logic clk;
    initial clk = 0;
    always #1 clk = ~clk;
    
    logic rst;
    logic be;
    logic done;
    
    logic write_en;
    logic [DATA_WIDTH - 1 : 0] write_data;
    
    logic read_en;
    logic [DATA_WIDTH - 1 : 0] read_data;
    logic valid_output;
    
    logic [$clog2(DATA_VOLUME + 1) - 1 : 0] num_of_elements;
    
    //module instance
    bucket_sorter#(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_VOLUME (DATA_VOLUME),
        .DECISION_BITS (DECISION_BITS)
    )bucket_instance(
        .clk (clk),
        .rst (rst),
    
        //data writing
        .write_en (write_en),
        .write_data (write_data),
        
        //data reading
        .read_en (read_en),
        .read_data (read_data),
        .valid_output (valid_output),
        
        //sorting control
        .be (be),
        .done (done),
        
        .num_of_elements (num_of_elements)
    );
    
    initial begin
        //array and signal initialization
        $srandom(234);
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            @(posedge clk);
            input_data[i] = $urandom_range((2**DATA_WIDTH) - 1, 0);
        end
        
        rst = 0;
        write_en = 0;
        write_data = 0;
        read_en = 0;
        be = 0;
        
        //module testing
        #10
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        
        //writing data to module instance
        @(posedge clk);
        write_en <= 1;
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            write_data <= input_data[i];
            @(posedge clk);
        end
        write_en <= 0;
        @(posedge clk);
        //sorting initialization
        be <= 1;
        @(posedge clk);
        be <= 0;
        
        wait(done == 1);
        //data reading
        i <= 0;
        @(posedge clk);
        read_en <= 1;
        while(num_of_elements > 0)begin
            @(posedge clk);
            if(valid_output)begin
                @(posedge clk);
                while(valid_output)begin
                    output_data[i] <= read_data;
                    i <= i + 1;
                    @(posedge clk);
                end
            end
        end
        #1
        read_en <= 0;
        
        //comparing
        input_data.sort();
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            $display("input: %0d    output: %0d", input_data[i], output_data[i]);
        end
        $display("Comparing");
        if(input_data == output_data)begin
            $display("data is sorted");
        end else begin
            $display("data is not sorted");
        end
        
        $finish;
    end
endmodule