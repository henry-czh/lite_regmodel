
virtual class lite_adaptor;

    virtual task bus2reg(input lite_reg_data_t addr,output lite_reg_data_t value);
    endtask

    virtual task reg2bus(input lite_reg_data_t addr,input lite_reg_data_t value);
    endtask

endclass
