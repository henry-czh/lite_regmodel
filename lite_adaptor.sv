//typedef virtual interface avif

virtual class lite_adaptor;

    int period;

    virtual task bus2reg(input lite_reg_data_t addr,output lite_reg_data_t value);
    endtask

    virtual task reg2bus(input lite_reg_data_t addr,input lite_reg_data_t value);
    endtask

    task wread(string path,lite_reg_data_t value,int display=1);
        lite_reg_data_t wait_data;

        void'(uvm_hdl_read(path,wait_data));
        while(wait_data!=value) begin
            #period;
            void'(uvm_hdl_read(path,wait_data));
        end
        if(display)
            $display("LITE_INFO @ %0tns : \"%s\" write access is successfully!",$time,path);

    endtask

endclass
