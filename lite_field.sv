
class lite_field;
    local logic [31:0] mirror_value;
    local logic [31:0] desire_value;
    local logic [31:0] update_value;

    local string m_fname;

    local bit [63:0]        m_size;
    bit               m_lsd;
    local string            m_access;
    local bit               m_volatile;
    local lite_reg_data_t   m_reset;
    local bit               m_has_reset;
    local bit               m_is_rand;
    local bit               m_individually_accessible;

    function new(string name="lite_field");
        this.m_fname = name;
    endfunction

    virtual function void configure(
                           int unsigned     size,
                           int unsigned     lsd_pos,
                           string           access,
                           bit              volatile,
                           lite_reg_data_t  reset,
                           bit              has_reset,
                           bit              is_rand,
                           bit              individually_accessible);
        m_size      = size;
        m_lsd       = lsd_pos;
        m_access    = access;
        m_volatile  = volatile;
        m_reset     = reset;
        m_has_reset = has_reset;
        m_is_rand   = is_rand;
        m_individually_accessible = individually_accessible;
    endfunction

    function lite_reg_data_t get_mirror();
        return mirror_value;
    endfunction

    function void get_desire(output lite_reg_data_t data);
         data = this.desire_value;
    endfunction

    function void bkdr_rd(input string hdl_path);
        lite_reg_data_t value;
        string full_path;
        full_path={hdl_path,".",m_fname};
        $display(full_path);
        void'(uvm_hdl_read(full_path,value));
        mirror_value=value;
        $display("read back data is %h",mirror_value);
    endfunction

    function void bkdr_wr(input string hdl_path,input lite_reg_data_t value);
        string full_path;
        full_path={hdl_path,".",m_fname};
        $display(full_path);
        void'(uvm_hdl_deposit(full_path,value));
        mirror_value=value;
    endfunction

endclass


