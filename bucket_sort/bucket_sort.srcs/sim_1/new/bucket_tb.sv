`timescale 1ns / 1ps

module bucket_tb#(
    parameter DATA_WIDTH = 8,
    parameter DATA_VOLUME = 10,
    parameter SIZE_OF_BUCKET = 15
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
    
    //instancja modu³u
    bucket#(
        .DATA_WIDTH (DATA_WIDTH),
        .SIZE_OF_BUCKET (SIZE_OF_BUCKET)
    )bucket_instance(
        .clk (clk),
        .rst (rst),
    
        //zapisywanie 
        .write_en (write_en),
        .write_data (write_data),
        
        //odczytywanie
        .read_en (read_en),
        .read_data (read_data),
        
        //sterowanie sortowaniem
        .be (be),
        .done (done)
    );
    
    initial begin
        //inicjalizacja tablic i sygna³ów
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
        
        //testowanie modu³u
        #10
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        
        //zapisanie danych do modu³u
        @(posedge clk);
        write_en <= 1;
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            write_data <= input_data[i];
            @(posedge clk);
        end
        write_en <= 0;
        @(posedge clk);
        //w³¹czenie sortowania
        be <= 1;
        @(posedge clk);
        be <= 0;
        
        wait(done == 1);
        //odczytywanie
        @(posedge clk);
        read_en <= 1;
        @(posedge clk);
        @(posedge clk);
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            output_data[i] <= read_data;
            @(posedge clk);
        end
        #1
        read_en <= 0;
        
        //porównanie
        input_data.sort();
        for(i = 0 ; i < DATA_VOLUME ; i = i + 1)begin
            $display("wejœcie: %0d    wyjœcie: %0d", input_data[i], output_data[i]);
        end
        $display("Porównywanie");
        if(input_data == output_data)begin
            $display("dane s¹ posortowane");
        end else begin
            $display("dane nie s¹ posortowane");
        end
        
        $finish;
    end
endmodule