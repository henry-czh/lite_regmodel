
class lite_field;
    logic [31:0] mirror_value;
    local logic [31:0] desire_value;
    local logic [31:0] update_value;

    string m_fname;

    bit [31:0]              m_size;
    int                     m_lsd;
    string            m_access;
    local bit               m_volatile;
    local lite_reg_data_t   m_reset;
    local bit               m_has_reset;
    local bit               m_is_rand;
    local bit               m_individually_accessible;
    bit                     ren;
    bit                     wen;

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
        desire_value = m_reset;
        mirror_value = m_reset;
        if(m_access=="RO"||
           m_access=="RW"||
           m_access=="RC"||
           m_access=="RS"||
           m_access=="WRS"||
           m_access=="WSRC"||
           m_access=="W1SRC"||
           m_access=="W1CRS"||
           m_access=="W0SRC"||
           m_access=="W0CRS"
           )
           ren=1;
        else
           ren=0;

        if(m_access=="RO"||
           m_access=="RC"||
           m_access=="RS"
           )
           wen=0;
        else
           wen=1;

    endfunction

    function lite_reg_data_t get_mirror();
        return mirror_value;
    endfunction

    function void update_mirror(input lite_reg_data_t data);
        if(ren)
            this.mirror_value=data;
        if(ren && data != this.desire_value) begin
            $display("Lite_Error update_mirror @ %0tns : %s compare failed!",$time,m_fname);
            $display("\t\tdesire_value is \'h%h ;mirror value is 'h%h",this.desire_value,data);
        end
    endfunction

    function lite_reg_data_t get_desire();
         return desire_value;
    endfunction

    function void update_desire(input lite_reg_data_t data);
        if(wen)
            this.desire_value=data;
    endfunction

    function void hdl_check(input string hdl_path);
        lite_reg_data_t value;
        string full_path;
        full_path={hdl_path,".",m_fname};
        if(uvm_hdl_check_path(full_path)==0) begin
            $display("LITE_ERROR @ %0tns : %s hdl path check Failed!",$time,m_fname);
            $display("\t\thdl_path \"%s\"can't be found!",full_path);
        end
        else
            $display("LITE_INFP @ %0tns : \"%s\" hdl path check Successfully!",$time,m_fname);
    endfunction

    function void reset_check(input string hdl_path);
        lite_reg_data_t value;
        string full_path;
        full_path={hdl_path,".",m_fname};
        void'(uvm_hdl_read(full_path,value));
        if(value!= m_reset) begin
            $display("LITE_ERROR @ %0tns : %s reset value check Failed!",$time,m_fname);
            $display("\t\tdesire_value is \'h%h ;mirror value is 'h%h",m_reset,value);
        end
        else
            $display("LITE_INFP @ %0tns : \"%s\" reset value check Successfully!",$time,m_fname);
    endfunction

    function void bkdr_rd(input string hdl_path);
        lite_reg_data_t value;
        string full_path;
        full_path={hdl_path,".",m_fname};
        //$display("      [%0t Lite field Info] %s : The hdl_path \"%s\" is read",$time,m_fname,full_path);
        void'(uvm_hdl_read(full_path,value));
        //if(ren)
        mirror_value=value;
        //$display("      [%0t Lite field Info] %s: The value is %d'h%5h",$time,m_fname,m_size,mirror_value);
        if(mirror_value != desire_value) begin
            $display("LITE_ERROR bkdr_rd @ %0tns : %s compare Failed!",$time,m_fname);
            $display("\t\tdesire_value is \'h%h ;mirror value is 'h%h",this.desire_value,this.mirror_value);
        end
    endfunction

    function void force_wr(input string hdl_path,input lite_reg_data_t value);
        string full_path;
        full_path={hdl_path,".",m_fname};
        void'(uvm_hdl_force(full_path,value));
        desire_value=value & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_size));
    endfunction

    function void release_wr(input string hdl_path);
        string full_path;
        full_path={hdl_path,".",m_fname};
        void'(uvm_hdl_release(full_path));
    endfunction

    function void bkdr_wr(input string hdl_path,input lite_reg_data_t value);
        string full_path;
        full_path={hdl_path,".",m_fname};
        //$display("      [%0t Lite field Info] : The hdl_path \"%s\" is wrote",$time,full_path);
        void'(uvm_hdl_deposit(full_path,value));
        desire_value=value & ({`LITE_REG_MAX_WIDTH{1'b1}} >> (32-m_size));
        //$display("      [%0t Lite field Info] %s: The value is %d'h%h",$time,m_fname,m_size,value);
    endfunction

endclass


