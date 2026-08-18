`timescale 1ns / 1ps

module bucket_sorter #(
    parameter DATA_WIDTH = 8,   //wielkoœæ pojedyñczego elementu
    parameter DATA_VOLUME = 9,   //iloœæ elementów, które mo¿na zapisaæ
    parameter DECISION_BITS = 3
)(
    input logic clk,
    input logic rst,

    //zapisywanie 
    input logic write_en,
    input logic [DATA_WIDTH - 1 : 0] write_data,
    
    //odczytywanie
    input logic read_en,
    output logic [DATA_WIDTH - 1 : 0] read_data,
    output logic valid_output,
    
    //sterowanie sortowaniem
    input logic be,
    output logic done,
    
    //iloœæ danych
    output logic [$clog2(DATA_VOLUME + 1) - 1 : 0] num_of_elements
);

    //zmienne do obs³ugi kube³ków
    logic [2**DECISION_BITS - 1 : 0] write_en_bus;
    logic [DATA_WIDTH - 1 : 0] write_data_buffer;
    
    logic [2**DECISION_BITS - 1 : 0] read_en_bus;
    logic [DATA_WIDTH - 1 : 0] read_data_buffer [2**DECISION_BITS - 1 : 0];
    logic [$clog2(DATA_VOLUME + 1) - 1 : 0] stack_pointer_buffer [2**DECISION_BITS - 1 : 0];
    
    logic be_sorting;
    logic [2**DECISION_BITS - 1 : 0] done_sorting;
    logic [2**DECISION_BITS - 1 : 0] done_sorting_latch;    //sortowania koñcz¹ siê w ró¿nych momentach w czasiê wiêc trzeba wszystkie dodaæ do zatrzasku

    genvar z;
    generate
        for(z = 0 ; z < 2**DECISION_BITS ; z = z + 1)begin : bucket_list
            bucket #(
                .DATA_WIDTH (DATA_WIDTH),
                .SIZE_OF_BUCKET (DATA_VOLUME)
            )bucket_inst(
                .clk (clk),
                .rst (rst),
            
                .write_en (write_en_bus[z]),
                .write_data (write_data_buffer),
                
                .read_en (read_en_bus[z]),
                .read_data (read_data_buffer[z]),
                
                .be (be_sorting),
                .done (done_sorting[z]),
                
                .stack_pointer (stack_pointer_buffer[z])
            );
        end
    endgenerate
    
    //pozosta³e zmienne
    logic currently_sorting;
    logic [2**DECISION_BITS - 1 : 0] current_bucket;
    logic currently_reading;
    logic read_delay;
    
    //maski do kube³ków
    logic [DECISION_BITS - 1 : 0] decision_bit_mask [2**DECISION_BITS - 1 : 0];
    genvar h;
    generate
        for(h = 0 ; h < 2**DECISION_BITS ; h = h + 1)begin : gen_mask
            assign decision_bit_mask[h] = h[DECISION_BITS - 1 : 0];
        end
    endgenerate
    
    always @(posedge clk)begin
        if(rst)begin
            done <= 0;
            currently_sorting <= 0;
            currently_reading <= 0;
            num_of_elements <= 0;
            current_bucket <= 0;
            valid_output <= 0;
            be_sorting <= '0;
            read_delay <= 0;
            done_sorting_latch <= '0;
        end else begin
            done_sorting_latch <= done_sorting_latch | done_sorting;
        
            if(write_en && currently_sorting == 0)begin   //zapis
                write_data_buffer <= write_data;
                num_of_elements <= num_of_elements + 1;
                for(int i = 0 ; i < 2**DECISION_BITS ; i = i + 1)begin
                    if(write_data[DATA_WIDTH - 1 : DATA_WIDTH - DECISION_BITS] == decision_bit_mask[i])begin
                        write_en_bus <= (1'b1 << i);
                    end
                end
            end else if(read_en && currently_sorting == 0) begin   //odczyt danych
                if(num_of_elements >= 0)begin
                    if(read_delay)begin
                        read_data <= read_data_buffer[current_bucket];
                        valid_output <= 1;
                        if(read_en == 0 || stack_pointer_buffer[current_bucket] == 0)begin
                            read_delay <= 0;
                        end else begin
                            num_of_elements <= num_of_elements - 1;
                        end
                    end else if(stack_pointer_buffer[current_bucket] > 0)begin   //w kube³ku s¹ dane
                        valid_output <= 0;  //to musi byæ gdy zmieniamy kube³ek ¿eby ostatni element 
                        read_en_bus <= 1'b1 << current_bucket;
                        read_delay <= 1;
                    end else begin
                        valid_output <= 0;  //to musi byæ gdy zmieniamy kube³ek ¿eby ostatni element odczytaæ
                        current_bucket <= current_bucket + 1;
                    end
                end else begin
                    valid_output <= 0;
                end
            end else if(be && currently_sorting == 0)begin    //w³¹czenie sortowania
                be_sorting <= 1;
                currently_sorting <= 1;
            end else if(currently_sorting)begin //wy³¹czenie sortowana
                be_sorting <= 0;
                if(done_sorting_latch == '1)begin
                    currently_sorting <= 0;
                    done <= 1;
                    done_sorting_latch <= '0;
                end
            end else begin  //stan do którego nie powinno siê wchodziæ je¿eli s¹ wykonywane jakiekolwiek operacje
                write_en_bus <= '0;
                done <= 0;
                valid_output <= 0;
                be_sorting <= 0;
            end
        end
    end
endmodule
