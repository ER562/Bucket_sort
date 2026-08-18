`timescale 1ns / 1ps

module bucket#(
    parameter DATA_WIDTH = 8,
    parameter SIZE_OF_BUCKET = 10
)(
    input logic clk,
    input logic rst,

    //data writing 
    input logic write_en,
    input logic [DATA_WIDTH - 1 : 0] write_data,
    
    //data eading
    input logic read_en,
    output logic [DATA_WIDTH - 1 : 0] read_data,
    
    //sorting control
    input logic be,
    output logic done,
    
    //number of elements currently in this instance
    logic [$clog2(SIZE_OF_BUCKET + 1) - 1 : 0] stack_pointer   //stack pointer is always in place where new data point would be placed
);
    //memory
    logic [DATA_WIDTH - 1 : 0] memory [SIZE_OF_BUCKET - 1 : 0];
    
    //sorting
    logic currently_sorting;
    logic [$clog2(SIZE_OF_BUCKET + 1) - 1 : 0] sorter_loop;
    logic odd_even;

    always_ff @(posedge clk)begin
        if(currently_sorting ==0)begin
            done <= 0;
        end
        
        if(rst)begin
            odd_even <= 0;
            stack_pointer <= 0;
            done <= 0;
            currently_sorting <= 0;
            sorter_loop <= 0;
        end else begin
            if(write_en && stack_pointer < SIZE_OF_BUCKET && currently_sorting == 0)begin
                memory[stack_pointer] <= write_data;
                stack_pointer <= stack_pointer + 1;
            end else if(read_en && stack_pointer != 0 && currently_sorting == 0)begin
                read_data <= memory[stack_pointer - 1];
                stack_pointer <= stack_pointer - 1;
            end else if(be && currently_sorting == 0)begin
                currently_sorting <= 1;
                sorter_loop <= 0;
                odd_even <= 0;
            end else if(currently_sorting)begin
                if(sorter_loop >= stack_pointer)begin
                    currently_sorting <= 0;
                    done <= 1;
                    sorter_loop <= 0;
                end else begin
                    if(odd_even == 0)begin
                        for(int i = 0 ; i < SIZE_OF_BUCKET - 1 ; i = i + 2)begin
                            if(i + 1 < stack_pointer)begin
                                if(memory[i] < memory[i + 1])begin
                                    memory[i] <= memory[i + 1];
                                    memory[i + 1] <= memory[i];
                                end
                            end
                        end
                    end else begin
                        for(int i = 1 ; i < SIZE_OF_BUCKET - 1 ; i = i + 2)begin
                            if(i + 1 < stack_pointer)begin
                                if(memory[i] < memory[i + 1])begin
                                    memory[i] <= memory[i + 1];
                                    memory[i + 1] <= memory[i];
                                end
                            end
                        end
                    end
                    odd_even <= ~odd_even;
                    sorter_loop <= sorter_loop + 1;
                end
            end
        end
    end
endmodule
